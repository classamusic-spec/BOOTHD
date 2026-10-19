// What a paired booth may do right now (PD-05 capabilities, UX-PD5,
// UX-PD6): whether sending is ready (and why not), the certified region,
// link and queue windows, image limits, remaining quotas, the month's
// estimated spend and when background work last ran. No secrets, no
// numbers.

import type { AuthenticatedBooth } from './auth.ts';
import type { Deps } from './context.ts';
import { sha256Hex } from './crypto.ts';
import { ApiError, readBody } from './http.ts';
import { inspectImage } from './images.ts';
import { limit } from './limits.ts';
import { sendingReadiness } from './readiness.ts';

const counted = `state not in ('canceled', 'expired')
  and not (state = 'failed_permanent' and provider_message_sid is null)`;

/** GET /v1/delivery/capabilities */
export async function capabilities(deps: Deps, { booth, tenant }: AuthenticatedBooth) {
  const now = deps.now();
  const dayAgo = new Date(now.getTime() - 86_400_000);
  const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
  const [usage] = await deps.sql.unsafe<{ tenant_day: string; booth_day: string; month: string }[]>(
    `select
      (select count(*) from delivery_jobs where ${counted} and tenant_id = $1 and created_at > $3) as tenant_day,
      (select count(*) from delivery_jobs where ${counted} and booth_id = $2 and created_at > $3) as booth_day,
      (select count(*) from delivery_jobs where ${counted} and tenant_id = $1 and created_at >= $4) as month`,
    [tenant.id, booth.id, dayAgo, monthStart] as never[],
  );
  const health = Object.fromEntries(
    (await deps.sql<{ key: string; at: Date }[]>`select key, at from service_health`)
      .map((row) => [row.key, row.at.toISOString()]),
  );
  const readiness = sendingReadiness(deps, tenant);
  const month = Number(usage.month);
  return {
    apiVersion: 1,
    environment: deps.config.environment,
    booth: { id: booth.id, name: booth.name },
    brandName: tenant.brand_name,
    privacyUrl: tenant.privacy_url,
    termsUrl: tenant.terms_url,
    supportContact: tenant.support_contact,
    regions: ['US'],
    deliveryMode: 'mms_with_link',
    sending: readiness,
    linkDays: { default: tenant.link_days_default, max: tenant.link_days_max },
    queueHours: deps.config.queueHours,
    previewMaxBytes: tenant.preview_max_bytes,
    finalMaxBytes: deps.config.finalMaxBytes,
    limits: {
      tenantDailyRemaining: Math.max(0, tenant.daily_send_limit - Number(usage.tenant_day)),
      boothDailyRemaining: Math.max(0, booth.daily_send_limit - Number(usage.booth_day)),
      eventSendLimitMax: tenant.event_send_limit,
      monthlyBudgetCents: tenant.monthly_budget_cents,
      monthEstimatedCents: Math.round((month * tenant.estimated_cost_millicents) / 1000),
      estimatedCostMillicents: tenant.estimated_cost_millicents,
    },
    health: {
      statusWebhookAt: health['webhook.status'] ?? null,
      inboundWebhookAt: health['webhook.inbound'] ?? null,
      dispatchWorkerAt: health['worker.dispatch'] ?? null,
      retentionWorkerAt: health['worker.retention'] ?? null,
    },
    serverTime: now.toISOString(),
  };
}

/**
 * POST /v1/diagnostics/upload-test: a fixture image checked like a real
 * upload, then discarded. Proves the booth can authenticate and upload;
 * stores nothing and sends nothing.
 */
export async function uploadTest(deps: Deps, { booth }: AuthenticatedBooth, request: Request) {
  await limit(deps, `upload-test:${booth.id}`, 3600, 30, 'DIAGNOSTICS_RATE_LIMITED');
  const bytes = await readBody(request, 1024 * 1024);
  const facts = inspectImage(bytes);
  if (!facts.ok) throw new ApiError(422, 'UPLOAD_NOT_IMAGE');
  return {
    format: facts.format,
    width: facts.width,
    height: facts.height,
    bytes: bytes.length,
    sha256: await sha256Hex(bytes),
    stored: false,
  };
}
