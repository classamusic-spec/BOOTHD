// The dispatcher (PD-05): a database-backed queue with leases, so no
// delivery depends on a function invocation outliving its response.
//
// A job is claimed with `for update skip locked` and a lease, its two
// grants are created (the provider's preview fetch link and the guest's
// download link: different tokens, different paths, AC-0909), and one
// message is submitted. Only a definite answer moves it on: accepted,
// rejected for good, or certainly not received (retried with backoff and
// jitter). A timeout or server error may have created the message, so the
// job becomes `delivery_unknown` and is reconciled with the provider's
// records, never re-sent blindly (AC-0915). A lease that runs out (a
// crashed worker) is treated the same way.

import { addMinutes, addSeconds, type Deps } from './context.ts';
import { decryptText, randomToken, sha256Hex } from './crypto.ts';
import { type JobRow, moveJob, purgeJob, revokeGrants } from './jobs.ts';
import { sendingReadiness } from './readiness.ts';
import { isSuppressed, suppress } from './suppression.ts';
import type { TenantRow } from './auth.ts';
import { type DeliveryState, providerMayMove, stateForProviderStatus } from './states.ts';

export const maxAttempts = 8;
export const leaseSeconds = 120;
/** How long a submission may stay unknown before an operator decides. */
export const reconcileMinutes = 30;

/** The text (PD-02): sender identity, link, availability, STOP and HELP. */
export function messageBody(brand: string, eventName: string, link: string, linkDays: number) {
  const days = linkDays === 1 ? '1 day' : `${linkDays} days`;
  return `${brand}: Your photos from ${eventName} are ready: ${link} ` +
    `(available for ${days}). Reply STOP to opt out, HELP for help.`;
}

function backoffSeconds(attempts: number, random: () => number): number {
  const base = Math.min(900, 30 * 2 ** Math.max(0, attempts - 1));
  return Math.round(base * (0.5 + random() / 2));
}

async function claim(deps: Deps, jobId: string | null): Promise<JobRow | null> {
  const now = deps.now();
  const only = jobId ? deps.sql`and id = ${jobId}` : deps.sql``;
  const [job] = await deps.sql<JobRow[]>`
    update delivery_jobs set state = 'dispatching', lease_until = ${addSeconds(now, leaseSeconds)},
      attempts = attempts + 1, submit_started_at = ${now}, updated_at = ${now}
    where id = (
      select id from delivery_jobs
      where state in ('dispatch_pending', 'failed_retryable')
        and (next_attempt_at is null or next_attempt_at <= ${now}) ${only}
      order by next_attempt_at nulls first, created_at
      limit 1 for update skip locked)
    returning *`;
  if (!job) return null;
  await deps.sql`insert into delivery_history (job_id, state, at)
    values (${job.id}, 'dispatching', ${now})`;
  return job;
}

/** Dispatches [jobId] now if it is ready and nobody else holds it. */
export async function dispatchJob(deps: Deps, jobId: string): Promise<void> {
  const job = await claim(deps, jobId);
  if (job) await submit(deps, job);
}

async function submit(deps: Deps, job: JobRow): Promise<void> {
  const now = deps.now();
  const holding = ['dispatching'] as const;
  const [tenant] = await deps.sql<TenantRow[]>`select * from tenants where id = ${job.tenant_id}`;
  const stop = async (state: DeliveryState, code: string, fields: Partial<JobRow> = {}) => {
    const moved = await moveJob(deps.sql, job.id, holding, state, now, {
      lease_until: null,
      next_attempt_at: null,
      failure_code: state === 'failed_permanent' || state === 'expired' ? code : null,
      ...fields,
    }, code);
    return moved;
  };

  if (job.expires_at <= now) {
    // The guest's consent window is over: never send late (PD-01).
    const moved = await stop('expired', 'CONSENT_WINDOW_ENDED');
    if (moved) await purgeJob(deps, moved, 'expired');
    return;
  }
  if (await isSuppressed(deps, job.tenant_id, job.recipient_digest)) {
    const moved = await stop('failed_permanent', 'RECIPIENT_OPTED_OUT');
    if (moved) await purgeJob(deps, moved, 'failed');
    return;
  }
  const readiness = sendingReadiness(deps, tenant);
  if (!readiness.ready) {
    // Switched off or not set up: nothing was sent, and the wait does not
    // use up an attempt.
    await stop('failed_retryable', 'SENDING_NOT_READY', {
      next_attempt_at: addMinutes(now, 5),
      attempts: job.attempts - 1,
    });
    return;
  }
  if (job.attempts > maxAttempts) {
    const moved = await stop('failed_permanent', 'PROVIDER_RETRIES_EXHAUSTED');
    if (moved) await purgeJob(deps, moved, 'failed');
    return;
  }
  let to: string;
  try {
    if (!job.recipient_ciphertext) throw new Error('erased');
    to = await decryptText(deps.config.phoneKey, job.recipient_ciphertext);
  } catch {
    const moved = await stop('failed_permanent', 'RECIPIENT_UNREADABLE');
    if (moved) await purgeJob(deps, moved, 'failed');
    return;
  }

  const previewToken = randomToken();
  const downloadToken = randomToken();
  await deps.sql.begin(async (tx) => {
    await tx`insert into access_grants (job_id, kind, token_hash, expires_at) values
      (${job.id}, 'preview', ${await sha256Hex(previewToken)},
        ${addMinutes(now, deps.config.previewGrantMinutes)})`;
    await tx`insert into access_grants (job_id, kind, token_hash, expires_at, max_access) values
      (${job.id}, 'download', ${await sha256Hex(downloadToken)},
        ${addMinutes(now, job.link_days * 24 * 60)}, 200)`;
  });
  const base = deps.config.publicBaseUrl;
  const outcome = await deps.provider.send({
    to,
    body: messageBody(
      tenant.brand_name,
      job.event_name,
      `${base}/p/${downloadToken}`,
      job.link_days,
    ),
    mediaUrl: `${base}/m/${previewToken}`,
    statusCallback: `${base}/webhooks/twilio/status`,
  });
  deps.log.info('dispatch.outcome', { job: job.id, outcome: outcome.kind, attempt: job.attempts });

  switch (outcome.kind) {
    case 'accepted': {
      let next = stateForProviderStatus(outcome.status) ?? 'provider_accepted';
      if (next !== 'provider_sent' && next !== 'delivered' && next !== 'failed_permanent') {
        next = 'provider_accepted';
      }
      // The lease may have run out meanwhile (the job is then unknown):
      // record the message either way.
      const moved = await moveJob(
        deps.sql,
        job.id,
        ['dispatching', 'delivery_unknown'],
        next,
        now,
        {
          provider_message_sid: outcome.sid,
          dispatched_at: now,
          link_expires_at: addMinutes(now, job.link_days * 24 * 60),
          lease_until: null,
          next_attempt_at: null,
          reconcile_after: null,
          review_reason: null,
          failure_code: next === 'failed_permanent' ? 'PROVIDER_FAILED' : null,
        },
      );
      if (moved && next === 'failed_permanent') await purgeJob(deps, moved, 'failed');
      await applyStoredEvents(deps, outcome.sid);
      return;
    }
    case 'rejected': {
      if (outcome.code === 'RECIPIENT_OPTED_OUT') {
        await suppress(deps, job.recipient_digest, 'stop');
      }
      const moved = await stop('failed_permanent', outcome.code);
      if (moved) await purgeJob(deps, moved, 'failed');
      return;
    }
    case 'retryable': {
      if (job.attempts >= maxAttempts) {
        const moved = await stop('failed_permanent', 'PROVIDER_RETRIES_EXHAUSTED');
        if (moved) await purgeJob(deps, moved, 'failed');
        return;
      }
      const delay = outcome.retryAfterSeconds ?? backoffSeconds(job.attempts, deps.random);
      await deps.sql.begin(async (tx) => {
        // Certainly not sent: this attempt's links never left.
        await revokeGrants(tx, job.id, now);
        await moveJob(tx, job.id, holding, 'failed_retryable', now, {
          lease_until: null,
          next_attempt_at: addSeconds(now, delay),
        }, outcome.code);
      });
      return;
    }
    case 'ambiguous': {
      // Maybe sent: keep the links (they may be on the guest's phone) and
      // find out before doing anything else.
      await stop('delivery_unknown', outcome.code, {
        reconcile_after: addMinutes(now, 2),
      });
      return;
    }
  }
}

/**
 * Applies a provider status report to the job with message [sid]: forward
 * only (AC-0913); `delivered` only when the provider says delivered.
 */
export async function applyProviderStatus(
  deps: Deps,
  sid: string,
  status: string,
  errorCode: string | null,
): Promise<'applied' | 'ignored' | 'unknown_message'> {
  const next = stateForProviderStatus(status);
  if (!next) return 'ignored';
  const [job] = await deps.sql<JobRow[]>`select * from delivery_jobs
    where provider_message_sid = ${sid}`;
  if (!job) return 'unknown_message';
  if (!providerMayMove(job.state, next)) return 'ignored';
  const code = next === 'failed_permanent'
    ? (errorCode ? `PROVIDER_ERROR_${errorCode}` : `PROVIDER_${status.toUpperCase()}`)
    : null;
  const moved = await moveJob(deps.sql, job.id, [job.state], next, deps.now(), {
    failure_code: code ?? job.failure_code,
    reconcile_after: null,
    review_reason: null,
  }, code);
  if (moved && next === 'failed_permanent') {
    if (errorCode === '21610') await suppress(deps, job.recipient_digest, 'stop');
    await purgeJob(deps, moved, 'failed', { providerMedia: true });
  }
  return moved ? 'applied' : 'ignored';
}

/** Reports that arrived before the job knew its message id. */
async function applyStoredEvents(deps: Deps, sid: string): Promise<void> {
  const events = await deps.sql<{ status: string; error_code: string | null }[]>`
    select status, error_code from provider_events where message_sid = ${sid} order by id`;
  for (const event of events) {
    await applyProviderStatus(deps, sid, event.status, event.error_code);
  }
}

/** Jobs whose dispatcher lease ran out: their outcome is unknown. */
async function expireLeases(deps: Deps): Promise<number> {
  const now = deps.now();
  const rows = await deps.sql<{ id: string }[]>`
    update delivery_jobs set state = 'delivery_unknown', lease_until = null,
      reconcile_after = ${now}, updated_at = ${now}
    where state = 'dispatching' and lease_until < ${now}
    returning id`;
  for (const row of rows) {
    await deps.sql`insert into delivery_history (job_id, state, code, at)
      values (${row.id}, 'delivery_unknown', 'LEASE_EXPIRED', ${now})`;
  }
  return rows.length;
}

const linkPattern = /\/p\/([A-Za-z0-9_-]{43})/g;

/**
 * Looks for unknown submissions in the provider's records, matching the
 * message by its download link (only that job's link hashes match). Found:
 * the job takes the message's id and status. Not found after
 * [reconcileMinutes]: an operator decides (resend or close).
 */
export async function reconcileUnknown(deps: Deps, max = 10): Promise<number> {
  const now = deps.now();
  const jobs = await deps.sql<JobRow[]>`select * from delivery_jobs
    where state = 'delivery_unknown' and reconcile_after <= ${now}
    order by reconcile_after limit ${max}`;
  let resolved = 0;
  for (const job of jobs) {
    const started = job.submit_started_at ?? job.updated_at;
    if (!job.recipient_ciphertext) {
      await moveJob(deps.sql, job.id, ['delivery_unknown'], 'delivery_unknown', now, {
        reconcile_after: null,
        review_reason: 'RECIPIENT_ERASED',
      }, 'NEEDS_OPERATOR_REVIEW');
      continue;
    }
    const to = await decryptText(deps.config.phoneKey, job.recipient_ciphertext);
    const messages = await deps.provider.findSent(to, addMinutes(started, -2));
    if (messages === null) {
      await deps.sql`update delivery_jobs set reconcile_after = ${addMinutes(now, 5)}
        where id = ${job.id} and state = 'delivery_unknown'`;
      continue;
    }
    const hashes = new Set(
      (await deps.sql<{ token_hash: string }[]>`select token_hash from access_grants
        where job_id = ${job.id} and kind = 'download'`).map((row) => row.token_hash),
    );
    let found: (typeof messages)[number] | undefined;
    for (const message of messages) {
      for (const match of message.body.matchAll(linkPattern)) {
        if (hashes.has(await sha256Hex(match[1]))) found = message;
      }
      if (found) break;
    }
    if (found) {
      let next = stateForProviderStatus(found.status) ?? 'provider_accepted';
      if (next !== 'provider_sent' && next !== 'delivered' && next !== 'failed_permanent') {
        next = 'provider_accepted';
      }
      const moved = await moveJob(deps.sql, job.id, ['delivery_unknown'], next, now, {
        provider_message_sid: found.sid,
        dispatched_at: started,
        link_expires_at: addMinutes(started, job.link_days * 24 * 60),
        reconcile_after: null,
        review_reason: null,
        failure_code: next === 'failed_permanent' ? 'PROVIDER_FAILED' : null,
      }, 'RECONCILED_FOUND');
      if (moved && next === 'failed_permanent') await purgeJob(deps, moved, 'failed');
      await applyStoredEvents(deps, found.sid);
      resolved++;
    } else if (now.getTime() - started.getTime() > reconcileMinutes * 60_000) {
      await moveJob(deps.sql, job.id, ['delivery_unknown'], 'delivery_unknown', now, {
        reconcile_after: null,
        review_reason: 'NOT_FOUND_AT_PROVIDER',
      }, 'NEEDS_OPERATOR_REVIEW');
    } else {
      await deps.sql`update delivery_jobs set reconcile_after = ${addMinutes(now, 5)}
        where id = ${job.id} and state = 'delivery_unknown'`;
    }
  }
  return resolved;
}

/**
 * One worker pass (scheduled every minute): leases that ran out, due jobs
 * within a time budget, then reconciliation.
 */
export async function runDispatcher(
  deps: Deps,
  { maxJobs = 25, budgetMs = 20_000 } = {},
): Promise<{ leasesExpired: number; dispatched: number; reconciled: number }> {
  const started = Date.now();
  const leasesExpired = await expireLeases(deps);
  let dispatched = 0;
  while (dispatched < maxJobs && Date.now() - started < budgetMs) {
    const job = await claim(deps, null);
    if (!job) break;
    await submit(deps, job);
    dispatched++;
  }
  const reconciled = await reconcileUnknown(deps);
  await deps.sql`insert into service_health (key, at) values ('worker.dispatch', ${deps.now()})
    on conflict (key) do update set at = excluded.at`;
  return { leasesExpired, dispatched, reconciled };
}
