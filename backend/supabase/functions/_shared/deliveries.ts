// The booth's delivery API (PD-05): create a delivery with the guest's
// consent, upload exactly two images under single-use grants, commit, and
// follow, cancel, revoke or resolve it. Nothing is sent unless the consent
// receipt was accepted and stored and both images were verified (AC-0904,
// AC-0908); quotas and throttles apply before anything is accepted
// (AC-0907, AC-0916).

import type { AuthenticatedBooth, TenantRow } from './auth.ts';
import { addMinutes, type Deps } from './context.ts';
import { encryptText, randomToken, recipientDigest, sha256Hex } from './crypto.ts';
import { dispatchJob } from './dispatch.ts';
import { ApiError, int, obj, readBody, readJson, str, tokenPattern, uuidPattern } from './http.ts';
import { inspectImage } from './images.ts';
import { historyOf, type JobRow, jobView, moveJob, purgeJob, revokeGrants } from './jobs.ts';
import { parsePhone } from './phone.ts';
import { sendingReadiness } from './readiness.ts';
import { isSuppressed } from './suppression.ts';

/** At most this many deliveries to one number per hour and per day. */
export const recipientHourly = 3;
export const recipientDaily = 6;

const sha256Pattern = /^[0-9a-f]{64}$/;

/** Deliveries that count against limits: sent or still able to send. */
const countedStates = `state not in ('canceled', 'expired')
  and not (state = 'failed_permanent' and provider_message_sid is null)`;

async function count(deps: Deps, where: string, ...values: unknown[]): Promise<number> {
  // `where` is one of the fixed clauses below; values are bound.
  const [row] = await deps.sql.unsafe<{ n: string }[]>(
    `select count(*) as n from delivery_jobs where ${countedStates} and ${where}`,
    values as never[],
  );
  return Number(row.n);
}

async function checkQuotas(
  deps: Deps,
  { booth, tenant }: AuthenticatedBooth,
  eventId: string,
  eventSendLimit: number,
  digest: string,
): Promise<void> {
  const now = deps.now();
  const hourAgo = new Date(now.getTime() - 3600_000);
  const dayAgo = new Date(now.getTime() - 86_400_000);
  const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
  if (
    await count(deps, 'recipient_digest = $1 and created_at > $2', digest, hourAgo) >=
      recipientHourly ||
    await count(deps, 'recipient_digest = $1 and created_at > $2', digest, dayAgo) >=
      recipientDaily
  ) {
    throw new ApiError(429, 'RECIPIENT_RATE_LIMITED');
  }
  if (
    await count(deps, 'booth_id = $1 and created_at > $2', booth.id, dayAgo) >=
      booth.daily_send_limit
  ) {
    throw new ApiError(429, 'BOOTH_DAILY_LIMIT');
  }
  if (
    await count(deps, 'tenant_id = $1 and created_at > $2', tenant.id, dayAgo) >=
      tenant.daily_send_limit
  ) {
    throw new ApiError(429, 'DAILY_LIMIT');
  }
  const eventLimit = Math.min(eventSendLimit, tenant.event_send_limit);
  if (await count(deps, 'tenant_id = $1 and event_id = $2', tenant.id, eventId) >= eventLimit) {
    throw new ApiError(429, 'EVENT_LIMIT');
  }
  const month = await count(deps, 'tenant_id = $1 and created_at >= $2', tenant.id, monthStart);
  if ((month + 1) * tenant.estimated_cost_millicents > tenant.monthly_budget_cents * 1000) {
    throw new ApiError(429, 'BUDGET_REACHED');
  }
}

async function ownedJob(deps: Deps, boothId: string, jobId: string): Promise<JobRow> {
  if (!uuidPattern.test(jobId)) throw new ApiError(404, 'DELIVERY_NOT_FOUND');
  const [job] = await deps.sql<JobRow[]>`select * from delivery_jobs
    where id = ${jobId} and booth_id = ${boothId}`;
  if (!job) throw new ApiError(404, 'DELIVERY_NOT_FOUND');
  return job;
}

async function view(deps: Deps, job: JobRow) {
  return jobView(job, await historyOf(deps.sql, job.id));
}

/** POST /v1/deliveries */
export async function createDelivery(
  deps: Deps,
  auth: AuthenticatedBooth,
  request: Request,
): Promise<{ status: number; body: unknown }> {
  const { booth, tenant } = auth;
  const body = await readJson(request);
  const eventId = str(body, 'eventId', uuidPattern);
  const eventName = str(body, 'eventName', /^\P{Cc}{1,80}$/u).trim();
  if (!eventName) throw new ApiError(400, 'FIELD_INVALID', { field: 'eventName' });
  const sessionId = str(body, 'sessionId', uuidPattern);
  const outputId = str(body, 'outputId', uuidPattern);
  const idempotencyKey = str(body, 'idempotencyKey', /^[0-9A-Za-z-]{16,64}$/);
  const linkDays = int(body, 'linkDays', 1, 30);
  const eventSendLimit = int(body, 'eventSendLimit', 1, 100000);
  const phoneInput = str(body, 'phone', /^.{1,32}$/);
  const consent = obj(body, 'consent');
  // The receipt must say the box was checked: anything else is no consent.
  if (consent.accepted !== true) throw new ApiError(422, 'CONSENT_REQUIRED');
  const textVersion = str(consent, 'textVersion', /^[0-9A-Za-z._-]{1,32}$/);
  const textDigest = str(consent, 'textDigest', sha256Pattern);
  const locale = str(consent, 'locale', /^[a-z]{2}(-[A-Z]{2})?$/);
  const sourceScreen = str(consent, 'sourceScreen', /^S[0-9]{2}$/);
  const acceptedAt = new Date(
    str(consent, 'acceptedAt', /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?Z$/),
  );
  const now = deps.now();
  if (Number.isNaN(acceptedAt.getTime()) || acceptedAt > addMinutes(now, 5)) {
    throw new ApiError(422, 'CONSENT_TIME_INVALID');
  }
  const expiresAt = new Date(acceptedAt.getTime() + deps.config.queueHours * 3600_000);
  if (expiresAt <= now) throw new ApiError(422, 'CONSENT_EXPIRED');
  if (linkDays > tenant.link_days_max) {
    throw new ApiError(422, 'LINK_DAYS_TOO_LONG', { max: tenant.link_days_max });
  }
  const phone = parsePhone(phoneInput);
  if (!phone.ok) throw new ApiError(422, phone.problem);
  const digest = await recipientDigest(deps.config.digestKey, phone.e164);
  const requestDigest = await sha256Hex(JSON.stringify([
    eventId,
    sessionId,
    outputId,
    digest,
    textVersion,
    textDigest,
    acceptedAt.toISOString(),
    linkDays,
  ]));

  // A repeated request (a retry after a lost answer) gets the same job.
  const [existing] = await deps.sql<JobRow[]>`select * from delivery_jobs
    where booth_id = ${booth.id} and idempotency_key = ${idempotencyKey}`;
  if (existing) {
    if (existing.request_digest !== requestDigest) {
      throw new ApiError(409, 'IDEMPOTENCY_KEY_REUSED');
    }
    return { status: 200, body: await view(deps, existing) };
  }
  // The same photo to the same number again within the hour is a duplicate,
  // whatever its key (a double tap that became two submissions).
  const [duplicate] = await deps.sql<{ id: string }[]>`select id from delivery_jobs
    where booth_id = ${booth.id} and output_id = ${outputId}
      and recipient_digest = ${digest}
      and created_at > ${new Date(now.getTime() - 3600_000)}
      and state not in ('canceled', 'expired', 'failed_permanent')`;
  if (duplicate) throw new ApiError(409, 'DUPLICATE_REQUEST', { deliveryId: duplicate.id });

  const readiness = sendingReadiness(deps, tenant);
  if (!readiness.ready) {
    throw new ApiError(409, 'SENDING_NOT_READY', { reasons: readiness.reasons });
  }
  if (deps.config.environment === 'staging') {
    const approved = await deps.sql`select 1 from approved_test_recipients
      where tenant_id = ${tenant.id} and recipient_digest = ${digest}`;
    if (approved.length === 0) throw new ApiError(403, 'RECIPIENT_NOT_APPROVED');
  }
  if (await isSuppressed(deps, tenant.id, digest)) throw new ApiError(403, 'RECIPIENT_OPTED_OUT');

  const ciphertext = await encryptText(deps.config.phoneKey, phone.e164);
  const job = await deps.sql.begin(async (tx) => {
    // One intake at a time per tenant, so concurrent requests cannot both
    // pass the limits.
    await tx`select pg_advisory_xact_lock(hashtext(${tenant.id}))`;
    await checkQuotas({ ...deps, sql: tx as never }, auth, eventId, eventSendLimit, digest);
    const [job] = await tx<JobRow[]>`insert into delivery_jobs ${
      tx({
        booth_id: booth.id,
        tenant_id: tenant.id,
        event_id: eventId,
        event_name: eventName,
        event_send_limit: eventSendLimit,
        session_id: sessionId,
        output_id: outputId,
        idempotency_key: idempotencyKey,
        request_digest: requestDigest,
        recipient_ciphertext: ciphertext,
        recipient_digest: digest,
        recipient_last4: phone.last4,
        link_days: linkDays,
        state: 'created',
        expires_at: expiresAt,
        created_at: now,
        updated_at: now,
      })
    } returning *`;
    await tx`insert into consent_receipts ${
      tx({
        job_id: job.id,
        booth_id: booth.id,
        event_id: eventId,
        session_id: sessionId,
        recipient_digest: digest,
        accepted: true,
        text_version: textVersion,
        text_digest: textDigest,
        accepted_at: acceptedAt,
        locale,
        source_screen: sourceScreen,
        received_at: now,
      })
    }`;
    await tx`insert into delivery_history (job_id, state, at) values (${job.id}, 'created', ${now})`;
    return job;
  });
  deps.log.info('delivery.created', { job: job.id, booth: booth.id });
  return { status: 201, body: await view(deps, job) };
}

interface Declared {
  format: 'jpeg' | 'png';
  bytes: number;
  sha256: string;
  width: number;
  height: number;
}

function declared(
  body: Record<string, unknown>,
  key: 'final' | 'preview',
  tenant: TenantRow,
  finalMax: number,
): Declared {
  const part = obj(body, key);
  const format = key === 'preview'
    ? 'jpeg'
    : str(part, 'format', /^(jpeg|png)$/) as Declared['format'];
  if (key === 'preview' && part.format !== undefined && part.format !== 'jpeg') {
    throw new ApiError(422, 'PREVIEW_MUST_BE_JPEG');
  }
  const max = key === 'preview' ? tenant.preview_max_bytes : finalMax;
  const bytes = part.bytes;
  if (typeof bytes === 'number' && Number.isInteger(bytes) && bytes > max) {
    throw new ApiError(422, key === 'preview' ? 'PREVIEW_TOO_LARGE' : 'FINAL_TOO_LARGE', {
      maxBytes: max,
    });
  }
  const side = key === 'preview' ? 4096 : 20000;
  return {
    format,
    bytes: int(part, 'bytes', 1, max),
    sha256: str(part, 'sha256', sha256Pattern),
    width: int(part, 'width', 1, side),
    height: int(part, 'height', 1, side),
  };
}

/** POST /v1/deliveries/{id}/upload-init: one grant per image, nothing else. */
export async function initUpload(
  deps: Deps,
  { booth, tenant }: AuthenticatedBooth,
  jobId: string,
  request: Request,
): Promise<unknown> {
  const job = await ownedJob(deps, booth.id, jobId);
  const body = await readJson(request);
  const final = declared(body, 'final', tenant, deps.config.finalMaxBytes);
  const preview = declared(body, 'preview', tenant, deps.config.finalMaxBytes);
  if (preview.width > final.width || preview.height > final.height) {
    throw new ApiError(422, 'PREVIEW_LARGER_THAN_FINAL');
  }
  const now = deps.now();
  const expiresAt = addMinutes(now, deps.config.uploadGrantMinutes);
  const tokens = { final: randomToken(), preview: randomToken() };
  const moved = await deps.sql.begin(async (tx) => {
    const fields = {
      final_format: final.format,
      final_bytes: final.bytes,
      final_sha256: final.sha256,
      final_width: final.width,
      final_height: final.height,
      final_key: null,
      preview_bytes: preview.bytes,
      preview_sha256: preview.sha256,
      preview_width: preview.width,
      preview_height: preview.height,
      preview_key: null,
    };
    const row = job.state === 'uploading'
      ? (await tx<JobRow[]>`update delivery_jobs set ${tx({ ...fields, updated_at: now })}
          where id = ${job.id} and state = 'uploading' returning *`)[0] ?? null
      : await moveJob(tx, job.id, ['created'], 'uploading', now, fields as Partial<JobRow>);
    if (!row) return null;
    await tx`delete from upload_grants where job_id = ${job.id}`;
    for (const kind of ['final', 'preview'] as const) {
      await tx`insert into upload_grants (token_hash, job_id, kind, expires_at)
        values (${await sha256Hex(tokens[kind])}, ${job.id}, ${kind}, ${expiresAt})`;
    }
    return row;
  });
  if (!moved) throw new ApiError(409, 'DELIVERY_NOT_UPLOADABLE', { state: job.state });
  const base = deps.config.publicBaseUrl;
  return {
    uploads: [
      {
        kind: 'final',
        method: 'PUT',
        url: `${base}/v1/uploads/${tokens.final}`,
        contentType: final.format === 'png' ? 'image/png' : 'image/jpeg',
        bytes: final.bytes,
        expiresAt: expiresAt.toISOString(),
      },
      {
        kind: 'preview',
        method: 'PUT',
        url: `${base}/v1/uploads/${tokens.preview}`,
        contentType: 'image/jpeg',
        bytes: preview.bytes,
        expiresAt: expiresAt.toISOString(),
      },
    ],
  };
}

/**
 * PUT /v1/uploads/{token}: the image under a single-use grant. The bytes
 * must match what was declared: length, SHA-256, type (from the bytes),
 * pixel size, and a complete file.
 */
export async function receiveUpload(deps: Deps, token: string, request: Request): Promise<unknown> {
  if (!tokenPattern.test(token)) throw new ApiError(404, 'UPLOAD_GRANT_INVALID');
  const hash = await sha256Hex(token);
  const [grant] = await deps.sql<
    { job_id: string; kind: 'final' | 'preview'; expires_at: Date; used_at: Date | null }[]
  >`
    select job_id, kind, expires_at, used_at from upload_grants where token_hash = ${hash}`;
  if (!grant) throw new ApiError(404, 'UPLOAD_GRANT_INVALID');
  if (grant.used_at) throw new ApiError(409, 'UPLOAD_GRANT_USED');
  if (grant.expires_at <= deps.now()) throw new ApiError(410, 'UPLOAD_GRANT_EXPIRED');
  const [job] = await deps.sql<JobRow[]>`select * from delivery_jobs where id = ${grant.job_id}`;
  if (!job || job.state !== 'uploading') throw new ApiError(409, 'DELIVERY_NOT_UPLOADABLE');
  const final = grant.kind === 'final';
  const expect = {
    format: final ? job.final_format! : 'jpeg',
    bytes: (final ? job.final_bytes : job.preview_bytes)!,
    sha256: (final ? job.final_sha256 : job.preview_sha256)!,
    width: (final ? job.final_width : job.preview_width)!,
    height: (final ? job.final_height : job.preview_height)!,
  };
  const bytes = await readBody(request, expect.bytes);
  if (bytes.length !== expect.bytes) throw new ApiError(422, 'UPLOAD_SIZE_MISMATCH');
  const sha256 = await sha256Hex(bytes);
  if (sha256 !== expect.sha256) throw new ApiError(422, 'UPLOAD_CHECKSUM_MISMATCH');
  const facts = inspectImage(bytes);
  if (!facts.ok) {
    throw new ApiError(
      422,
      facts.problem === 'IMAGE_TRUNCATED' ? 'UPLOAD_TRUNCATED' : 'UPLOAD_NOT_IMAGE',
    );
  }
  if (facts.format !== expect.format) throw new ApiError(422, 'UPLOAD_TYPE_MISMATCH');
  if (facts.width !== expect.width || facts.height !== expect.height) {
    throw new ApiError(422, 'UPLOAD_DIMENSIONS_MISMATCH');
  }
  const key = final
    ? `final/${job.id}.${expect.format === 'png' ? 'png' : 'jpg'}`
    : `preview/${job.id}.jpg`;
  try {
    await deps.store.put(key, bytes, expect.format === 'png' ? 'image/png' : 'image/jpeg');
  } catch {
    deps.log.error('upload.store_failed', { job: job.id, kind: grant.kind });
    throw new ApiError(503, 'STORAGE_UNAVAILABLE');
  }
  const recorded = await deps.sql.begin(async (tx) => {
    const used = await tx`update upload_grants set used_at = ${deps.now()}
      where token_hash = ${hash} and used_at is null returning job_id`;
    if (used.length === 0) return false;
    // Only if the declaration did not change meanwhile.
    const updated = final
      ? await tx`update delivery_jobs set final_key = ${key}, updated_at = ${deps.now()}
          where id = ${job.id} and state = 'uploading' and final_sha256 = ${sha256} returning id`
      : await tx`update delivery_jobs set preview_key = ${key}, updated_at = ${deps.now()}
          where id = ${job.id} and state = 'uploading' and preview_sha256 = ${sha256} returning id`;
    return updated.length > 0;
  });
  if (!recorded) throw new ApiError(409, 'UPLOAD_SUPERSEDED');
  deps.log.info('upload.verified', { job: job.id, kind: grant.kind, bytes: bytes.length });
  return {
    kind: grant.kind,
    bytes: bytes.length,
    sha256,
    width: facts.width,
    height: facts.height,
  };
}

/**
 * POST /v1/deliveries/{id}/commit: both images verified, so the delivery
 * may be sent. It is dispatched at once when possible (within this
 * request; nothing runs after the answer), else by the worker.
 */
export async function commitDelivery(
  deps: Deps,
  { booth, tenant }: AuthenticatedBooth,
  jobId: string,
): Promise<unknown> {
  let job = await ownedJob(deps, booth.id, jobId);
  const now = deps.now();
  // Committed before (a retry after a lost answer): its state as it is.
  if (job.state !== 'created' && job.state !== 'uploading') return await view(deps, job);
  if (job.state !== 'uploading' || !job.final_key || !job.preview_key) {
    throw new ApiError(409, 'UPLOAD_INCOMPLETE');
  }
  if (job.expires_at <= now) {
    await moveJob(deps.sql, job.id, ['uploading'], 'expired', now, {}, 'CONSENT_WINDOW_ENDED');
    await purgeJob(deps, job, 'expired');
    return await view(deps, await ownedJob(deps, booth.id, jobId));
  }
  const readiness = sendingReadiness(deps, tenant);
  if (!readiness.ready) {
    throw new ApiError(409, 'SENDING_NOT_READY', { reasons: readiness.reasons });
  }
  if (await isSuppressed(deps, tenant.id, job.recipient_digest)) {
    await moveJob(deps.sql, job.id, ['uploading'], 'failed_permanent', now, {
      failure_code: 'RECIPIENT_OPTED_OUT',
    }, 'RECIPIENT_OPTED_OUT');
    await purgeJob(deps, job, 'failed');
    return await view(deps, await ownedJob(deps, booth.id, jobId));
  }
  await moveJob(deps.sql, job.id, ['uploading'], 'dispatch_pending', now, {
    next_attempt_at: now,
  });
  await dispatchJob(deps, job.id);
  job = await ownedJob(deps, booth.id, jobId);
  return await view(deps, job);
}

/** GET /v1/deliveries/{id} */
export async function deliveryStatus(
  deps: Deps,
  { booth }: AuthenticatedBooth,
  jobId: string,
): Promise<unknown> {
  return await view(deps, await ownedJob(deps, booth.id, jobId));
}

const unsent = ['created', 'uploading', 'dispatch_pending', 'failed_retryable'] as const;

/** POST /v1/deliveries/{id}/cancel: only before submission. */
export async function cancelDelivery(
  deps: Deps,
  { booth }: AuthenticatedBooth,
  jobId: string,
): Promise<unknown> {
  const job = await ownedJob(deps, booth.id, jobId);
  if (['canceled', 'expired', 'failed_permanent'].includes(job.state)) return await view(deps, job);
  if (job.state === 'dispatching') throw new ApiError(409, 'DELIVERY_IN_FLIGHT');
  if (job.state === 'delivery_unknown') throw new ApiError(409, 'DELIVERY_OUTCOME_UNKNOWN');
  if (!(unsent as readonly string[]).includes(job.state)) {
    throw new ApiError(409, 'DELIVERY_ALREADY_SUBMITTED');
  }
  const moved = await moveJob(deps.sql, job.id, unsent, 'canceled', deps.now(), {
    next_attempt_at: null,
  }, 'CANCELED_BY_OPERATOR');
  if (!moved) throw new ApiError(409, 'DELIVERY_IN_FLIGHT');
  await purgeJob(deps, moved, 'canceled');
  deps.log.info('delivery.canceled', { job: job.id });
  return await view(deps, await ownedJob(deps, booth.id, jobId));
}

/**
 * POST /v1/deliveries/{id}/revoke: the download link stops working and the
 * hosted images are deleted, with the provider's media copy where it
 * allows. Texts already on phones cannot be recalled.
 */
export async function revokeDelivery(
  deps: Deps,
  auth: AuthenticatedBooth,
  jobId: string,
): Promise<unknown> {
  const job = await ownedJob(deps, auth.booth.id, jobId);
  if ((unsent as readonly string[]).includes(job.state)) {
    return await cancelDelivery(deps, auth, jobId);
  }
  if (job.state === 'dispatching') throw new ApiError(409, 'DELIVERY_IN_FLIGHT');
  const now = deps.now();
  await deps.sql.begin(async (tx) => {
    await revokeGrants(tx, job.id, now);
    await tx`update delivery_jobs set link_revoked_at = coalesce(link_revoked_at, ${now}),
        reconcile_after = null, updated_at = ${now},
        review_reason = case when state = 'delivery_unknown' then 'LINK_REVOKED' else review_reason end
      where id = ${job.id}`;
  });
  await purgeJob(deps, job, 'revoked', { providerMedia: true });
  deps.log.info('delivery.revoked', { job: job.id });
  return await view(deps, await ownedJob(deps, auth.booth.id, jobId));
}

/**
 * POST /v1/deliveries/{id}/resolve: an operator decides a delivery whose
 * submission outcome stayed unknown after reconciliation (AC-0915):
 * `close` (treat as not sent) or `resend` (send again, accepting that the
 * guest may get two texts; the first link is turned off).
 */
export async function resolveDelivery(
  deps: Deps,
  { booth }: AuthenticatedBooth,
  jobId: string,
  request: Request,
): Promise<unknown> {
  const job = await ownedJob(deps, booth.id, jobId);
  const body = await readJson(request);
  const action = str(body, 'action', /^(close|resend)$/);
  if (job.state !== 'delivery_unknown') throw new ApiError(409, 'DELIVERY_NOT_UNKNOWN');
  const now = deps.now();
  if (action === 'close') {
    const moved = await moveJob(deps.sql, job.id, ['delivery_unknown'], 'failed_permanent', now, {
      failure_code: 'CLOSED_BY_OPERATOR',
      reconcile_after: null,
    }, 'CLOSED_BY_OPERATOR');
    if (moved) await purgeJob(deps, moved, 'operator', { providerMedia: true });
  } else {
    if (body.acknowledgeDuplicateRisk !== true) {
      throw new ApiError(422, 'DUPLICATE_RISK_NOT_ACKNOWLEDGED');
    }
    if (job.expires_at <= now || job.recipient_ciphertext === null) {
      throw new ApiError(409, 'DELIVERY_WINDOW_ENDED');
    }
    await deps.sql.begin(async (tx) => {
      await revokeGrants(tx, job.id, now);
      await moveJob(tx, job.id, ['delivery_unknown'], 'failed_retryable', now, {
        next_attempt_at: now,
        reconcile_after: null,
        review_reason: null,
      }, 'RESEND_BY_OPERATOR');
    });
    await dispatchJob(deps, job.id);
  }
  deps.log.info('delivery.resolved', { job: job.id, action });
  return await view(deps, await ownedJob(deps, booth.id, jobId));
}
