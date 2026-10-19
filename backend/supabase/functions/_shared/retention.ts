// Retention (PD-01, PD-06, AC-0906, AC-0917): runs with the worker.
//
// - Deliveries not submitted within the queue window (24 hours after
//   consent) expire: links revoked, hosted images deleted, number erased.
// - Sent deliveries whose link has expired are purged the same way, and
//   the provider's stored copy of the media is deleted where Twilio allows.
// - Failed, canceled and unresolved deliveries are purged too.
// - Spent grants, tokens, codes and counters are removed, and delivery
//   rows (with their consent receipts and history) after
//   `jobRetentionDays`. Opt-outs are kept: they must outlive the photos.

import { addMinutes, type Deps } from './context.ts';
import { type JobRow, moveJob, purgeJob } from './jobs.ts';

export interface RetentionSummary {
  expired: number;
  purged: number;
  incomplete: number;
  rowsDeleted: number;
}

export async function runRetention(deps: Deps, { max = 100 } = {}): Promise<RetentionSummary> {
  const now = deps.now();
  let expired = 0;
  let purged = 0;
  let incomplete = 0;

  const overdue = await deps.sql<JobRow[]>`select * from delivery_jobs
    where state in ('created', 'uploading', 'dispatch_pending', 'failed_retryable')
      and expires_at <= ${now}
    limit ${max}`;
  for (const job of overdue) {
    const moved = await moveJob(deps.sql, job.id, [job.state], 'expired', now, {
      failure_code: 'CONSENT_WINDOW_ENDED',
      next_attempt_at: null,
    }, 'CONSENT_WINDOW_ENDED');
    if (!moved) continue;
    expired++;
    const result = await purgeJob(deps, moved, 'expired');
    if (!result.complete) incomplete++;
  }

  // Unresolved submissions: their links lapse like any other.
  const due = await deps.sql<JobRow[]>`select * from delivery_jobs
    where purged_at is null and (
      (link_expires_at is not null and link_expires_at <= ${now})
      or state in ('failed_permanent', 'canceled', 'expired')
      or (state = 'delivery_unknown'
        and submit_started_at + make_interval(days => link_days) <= ${now}))
    limit ${max}`;
  for (const job of due) {
    const result = await purgeJob(deps, job, 'retention', {
      providerMedia: job.provider_message_sid !== null,
    });
    if (result.complete) purged++;
    else incomplete++;
  }

  const dayAgo = addMinutes(now, -24 * 60);
  await deps.sql`delete from upload_grants where expires_at <= ${now}`;
  await deps.sql`delete from booth_access_tokens where expires_at <= ${now}`;
  await deps.sql`delete from pairing_codes where expires_at <= ${dayAgo}`;
  await deps.sql`delete from rate_counters where window_start <= ${addMinutes(now, -48 * 60)}`;
  const cutoff = addMinutes(now, -deps.config.jobRetentionDays * 24 * 60);
  const deleted = await deps.sql`delete from delivery_jobs
    where created_at <= ${cutoff} and purged_at is not null
      and state not in ('dispatching') returning id`;
  await deps.sql`delete from provider_events where received_at <= ${cutoff}`;
  await deps.sql`insert into service_health (key, at, detail) values ('worker.retention', ${now},
      ${`expired ${expired}, purged ${purged}, incomplete ${incomplete}`})
    on conflict (key) do update set at = excluded.at, detail = excluded.detail`;
  const summary = { expired, purged, incomplete, rowsDeleted: deleted.length };
  deps.log.info('retention.run', summary);
  return summary;
}
