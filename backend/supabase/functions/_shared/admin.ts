// Administrator operations (PD-03, PD-07, PD-08). Only the administrator
// token reaches these; no booth can. Attestations record evidence the
// administrator has (sender registration, legal review) and are never
// inferred; sending stays off until every gate is open.

import type { TenantRow } from './auth.ts';
import { newPairingCode, normalizePairingCode } from './auth.ts';
import { addMinutes, type Deps } from './context.ts';
import { recipientDigest, sha256Hex } from './crypto.ts';
import { runDispatcher } from './dispatch.ts';
import { ApiError, int, readJson, str, uuidPattern } from './http.ts';
import { parsePhone } from './phone.ts';
import { sendingReadiness } from './readiness.ts';
import { runRetention } from './retention.ts';
import { suppress } from './suppression.ts';

const httpsUrl = /^https:\/\/[^ ]{3,300}$/;

async function tenantOr404(deps: Deps, id: string): Promise<TenantRow> {
  if (!uuidPattern.test(id)) throw new ApiError(404, 'TENANT_NOT_FOUND');
  const [tenant] = await deps.sql<TenantRow[]>`select * from tenants where id = ${id}`;
  if (!tenant) throw new ApiError(404, 'TENANT_NOT_FOUND');
  return tenant;
}

function tenantView(deps: Deps, tenant: TenantRow) {
  return {
    id: tenant.id,
    name: tenant.name,
    brandName: tenant.brand_name,
    privacyUrl: tenant.privacy_url,
    termsUrl: tenant.terms_url,
    supportContact: tenant.support_contact,
    sendingEnabled: tenant.sending_enabled,
    registrationAttestedAt: tenant.registration_attested_at?.toISOString() ?? null,
    registrationReference: tenant.registration_reference,
    legalReviewAttestedAt: tenant.legal_review_attested_at?.toISOString() ?? null,
    dailySendLimit: tenant.daily_send_limit,
    eventSendLimit: tenant.event_send_limit,
    monthlyBudgetCents: tenant.monthly_budget_cents,
    estimatedCostMillicents: tenant.estimated_cost_millicents,
    linkDaysDefault: tenant.link_days_default,
    linkDaysMax: tenant.link_days_max,
    previewMaxBytes: tenant.preview_max_bytes,
    readiness: sendingReadiness(deps, tenant),
  };
}

/** POST /v1/admin/tenants */
export async function createTenant(deps: Deps, request: Request) {
  const body = await readJson(request);
  const [tenant] = await deps.sql<TenantRow[]>`insert into tenants ${
    deps.sql({
      name: str(body, 'name', /^\P{Cc}{1,80}$/u).trim(),
      brand_name: str(body, 'brandName', /^\P{Cc}{1,40}$/u).trim(),
      privacy_url: str(body, 'privacyUrl', httpsUrl),
      terms_url: str(body, 'termsUrl', httpsUrl),
      support_contact: str(body, 'supportContact', /^\P{Cc}{3,120}$/u),
    })
  } returning *`;
  deps.log.info('admin.tenant_created', { tenant: tenant.id });
  return tenantView(deps, tenant);
}

/** PATCH /v1/admin/tenants/{id}: limits and the sending switch. */
export async function updateTenant(deps: Deps, id: string, request: Request) {
  await tenantOr404(deps, id);
  const body = await readJson(request);
  const changes: Record<string, unknown> = {};
  if ('sendingEnabled' in body) {
    if (typeof body.sendingEnabled !== 'boolean') {
      throw new ApiError(400, 'FIELD_INVALID', { field: 'sendingEnabled' });
    }
    changes.sending_enabled = body.sendingEnabled;
  }
  const limits: [string, string, number, number][] = [
    ['dailySendLimit', 'daily_send_limit', 0, 100000],
    ['eventSendLimit', 'event_send_limit', 0, 100000],
    ['monthlyBudgetCents', 'monthly_budget_cents', 0, 10000000],
    ['estimatedCostMillicents', 'estimated_cost_millicents', 1, 100000],
    ['linkDaysDefault', 'link_days_default', 1, 30],
    ['linkDaysMax', 'link_days_max', 1, 30],
    ['previewMaxBytes', 'preview_max_bytes', 50000, 4999999],
  ];
  for (const [field, column, min, max] of limits) {
    if (field in body) changes[column] = int(body, field, min, max);
  }
  if (Object.keys(changes).length === 0) throw new ApiError(400, 'NOTHING_TO_CHANGE');
  let tenant: TenantRow;
  try {
    [tenant] = await deps.sql<TenantRow[]>`update tenants set ${deps.sql(changes)}
      where id = ${id} returning *`;
  } catch {
    throw new ApiError(422, 'TENANT_LIMITS_INVALID');
  }
  deps.log.info('admin.tenant_updated', { tenant: id, fields: Object.keys(changes).join(',') });
  return tenantView(deps, tenant);
}

/**
 * POST /v1/admin/tenants/{id}/attestations: the administrator records the
 * sender registration (with its reference) and the legal review, or
 * withdraws them.
 */
export async function attest(deps: Deps, id: string, request: Request) {
  await tenantOr404(deps, id);
  const body = await readJson(request);
  const now = deps.now();
  const changes: Record<string, unknown> = {};
  if (body.registration === true) {
    changes.registration_attested_at = now;
    changes.registration_reference = str(
      body,
      'registrationReference',
      /^\P{Cc}{3,120}$/u,
    );
  } else if (body.registration === false) {
    changes.registration_attested_at = null;
    changes.registration_reference = null;
  }
  if (body.legalReview === true) changes.legal_review_attested_at = now;
  else if (body.legalReview === false) changes.legal_review_attested_at = null;
  if (Object.keys(changes).length === 0) throw new ApiError(400, 'NOTHING_TO_CHANGE');
  const [tenant] = await deps.sql<TenantRow[]>`update tenants set ${deps.sql(changes)}
    where id = ${id} returning *`;
  deps.log.info('admin.attested', { tenant: id, fields: Object.keys(changes).join(',') });
  return tenantView(deps, tenant);
}

/** POST /v1/admin/tenants/{id}/pairing-codes: a single-use code for 30 minutes. */
export async function issuePairingCode(deps: Deps, id: string) {
  await tenantOr404(deps, id);
  const code = newPairingCode();
  const expiresAt = addMinutes(deps.now(), deps.config.pairingCodeMinutes);
  await deps.sql`insert into pairing_codes (code_hash, tenant_id, expires_at)
    values (${await sha256Hex(normalizePairingCode(code))}, ${id}, ${expiresAt})`;
  deps.log.info('admin.pairing_code', { tenant: id });
  return { code, expiresAt: expiresAt.toISOString() };
}

/** POST /v1/admin/booths/{id}/revoke: the booth's credential and tokens stop. */
export async function revokeBooth(deps: Deps, id: string) {
  if (!uuidPattern.test(id)) throw new ApiError(404, 'BOOTH_NOT_FOUND');
  const rows = await deps
    .sql`update registered_booths set revoked_at = coalesce(revoked_at, ${deps.now()})
    where id = ${id} returning id`;
  if (rows.length === 0) throw new ApiError(404, 'BOOTH_NOT_FOUND');
  await deps.sql`delete from booth_access_tokens where booth_id = ${id}`;
  deps.log.info('admin.booth_revoked', { booth: id });
  return { boothId: id, revoked: true };
}

/** POST /v1/admin/tenants/{id}/test-recipients: staging's approved numbers. */
export async function addTestRecipient(deps: Deps, id: string, request: Request) {
  await tenantOr404(deps, id);
  const body = await readJson(request);
  const phone = parsePhone(str(body, 'phone', /^.{1,32}$/));
  if (!phone.ok) throw new ApiError(422, phone.problem);
  const label = str(body, 'label', /^\P{Cc}{1,40}$/u);
  await deps.sql`insert into approved_test_recipients (tenant_id, recipient_digest, label)
    values (${id}, ${await recipientDigest(deps.config.digestKey, phone.e164)}, ${label})
    on conflict (tenant_id, recipient_digest) do update set label = excluded.label`;
  return { label, last4: phone.last4 };
}

/** POST /v1/admin/suppressions: an operator's manual block. */
export async function addSuppression(deps: Deps, request: Request) {
  const body = await readJson(request);
  const phone = parsePhone(str(body, 'phone', /^.{1,32}$/));
  if (!phone.ok) throw new ApiError(422, phone.problem);
  await suppress(deps, await recipientDigest(deps.config.digestKey, phone.e164), 'manual');
  return { last4: phone.last4, suppressed: true };
}

/** POST /v1/admin/worker/run: one dispatcher and retention pass (scheduled). */
export async function runWorker(deps: Deps) {
  const dispatch = await runDispatcher(deps);
  const retention = await runRetention(deps);
  return { dispatch, retention };
}

/** GET /v1/admin/tenants/{id}/summary: counts and the month's estimate. */
export async function tenantSummary(deps: Deps, id: string) {
  const tenant = await tenantOr404(deps, id);
  const now = deps.now();
  const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
  const states = await deps.sql<{ state: string; n: string }[]>`select state, count(*) as n
    from delivery_jobs where tenant_id = ${id} and created_at >= ${monthStart} group by state`;
  const submitted = await deps.sql<{ n: string }[]>`select count(*) as n from delivery_jobs
    where tenant_id = ${id} and created_at >= ${monthStart} and provider_message_sid is not null`;
  const sent = Number(submitted[0].n);
  return {
    month: monthStart.toISOString().slice(0, 7),
    byState: Object.fromEntries(states.map((row) => [row.state, Number(row.n)])),
    submitted: sent,
    estimatedCents: Math.round((sent * tenant.estimated_cost_millicents) / 1000),
    monthlyBudgetCents: tenant.monthly_budget_cents,
    note:
      'Estimate only: carrier fees, number rental, registration, storage and taxes are billed separately.',
  };
}
