// Delivery job rows and the changes every part of the service makes to
// them: state changes with history, grant revocation, erasing the
// recipient and removing hosted images.

import type { Deps } from './context.ts';
import type { Sql, TransactionSql } from './deps.ts';
import type { MediaCleanup } from './provider.ts';
import { type DeliveryState, publicStatus } from './states.ts';

export interface JobRow {
  id: string;
  booth_id: string;
  tenant_id: string;
  event_id: string;
  event_name: string;
  event_send_limit: number;
  session_id: string;
  output_id: string;
  idempotency_key: string;
  request_digest: string;
  recipient_ciphertext: string | null;
  recipient_digest: string;
  recipient_last4: string;
  link_days: number;
  state: DeliveryState;
  final_format: 'jpeg' | 'png' | null;
  final_sha256: string | null;
  final_bytes: number | null;
  final_width: number | null;
  final_height: number | null;
  final_key: string | null;
  preview_sha256: string | null;
  preview_bytes: number | null;
  preview_width: number | null;
  preview_height: number | null;
  preview_key: string | null;
  provider_message_sid: string | null;
  attempts: number;
  next_attempt_at: Date | null;
  lease_until: Date | null;
  submit_started_at: Date | null;
  reconcile_after: Date | null;
  review_reason: string | null;
  failure_code: string | null;
  expires_at: Date;
  dispatched_at: Date | null;
  link_expires_at: Date | null;
  link_revoked_at: Date | null;
  purged_at: Date | null;
  created_at: Date;
  updated_at: Date;
}

export interface HistoryRow {
  state: DeliveryState;
  code: string | null;
  at: Date;
}

/** The connection or a transaction on it (the same query interface). */
export type Db = Sql | TransactionSql;

/** [db] as a plain query function; both kinds take the same queries. */
function q(db: Db): Sql {
  return db as Sql;
}

/**
 * Moves [job] to [state] (recording it in the history) with [fields], but
 * only if it is still in one of [from]: a concurrent change wins and this
 * one does nothing. Returns the updated row, or null.
 */
export async function moveJob(
  db: Db,
  jobId: string,
  from: readonly DeliveryState[],
  state: DeliveryState,
  now: Date,
  fields: Partial<JobRow> = {},
  code: string | null = null,
): Promise<JobRow | null> {
  const changes = { ...fields, state, updated_at: now } as Record<string, unknown>;
  const sql = q(db);
  const rows = await sql<JobRow[]>`
    update delivery_jobs set ${sql(changes)}
    where id = ${jobId} and state in ${sql(from as DeliveryState[])}
    returning *`;
  const row = rows[0] ?? null;
  if (row) {
    await sql`insert into delivery_history (job_id, state, code, at)
      values (${jobId}, ${state}, ${code}, ${now})`;
  }
  return row;
}

/** Revokes the job's live grants of [kinds] (all by default). */
export async function revokeGrants(
  db: Db,
  jobId: string,
  now: Date,
  kinds: readonly ('download' | 'preview')[] = ['download', 'preview'],
): Promise<void> {
  const sql = q(db);
  await sql`update access_grants set revoked_at = ${now}
    where job_id = ${jobId} and revoked_at is null and kind in ${sql(kinds as string[])}`;
  await sql`delete from upload_grants where job_id = ${jobId}`;
}

/** Forgets the recipient's number (the digest and last four stay). */
export async function eraseRecipient(db: Db, jobId: string): Promise<void> {
  await q(db)`update delivery_jobs set recipient_ciphertext = null where id = ${jobId}`;
}

/**
 * Deletes the job's hosted images and, when asked, the provider's copy of
 * its media; records what happened in the deletion audit. Hosted copies
 * are what this service controls: carriers' and phones' copies are not.
 */
export async function purgeJob(
  deps: Deps,
  job: JobRow,
  reason: 'expired' | 'revoked' | 'canceled' | 'retention' | 'failed' | 'operator',
  { providerMedia = false } = {},
): Promise<{ objectsDeleted: number; providerMedia: MediaCleanup; complete: boolean }> {
  let objectsDeleted = 0;
  let complete = true;
  for (const key of [job.final_key, job.preview_key]) {
    if (!key) continue;
    try {
      await deps.store.delete(key);
      objectsDeleted++;
    } catch {
      complete = false;
    }
  }
  let media: MediaCleanup = 'none';
  if (providerMedia && job.provider_message_sid) {
    media = await deps.provider.deleteMedia(job.provider_message_sid);
    if (media === 'failed') complete = false;
  }
  const now = deps.now();
  await deps.sql.begin(async (tx) => {
    await revokeGrants(tx, job.id, now);
    await eraseRecipient(tx, job.id);
    await tx`insert into deletion_audit (job_id, reason, objects_deleted, provider_media)
      values (${job.id}, ${reason}, ${objectsDeleted}, ${media})`;
    // The keys stay as a record of what was hosted; purged_at says the
    // files are gone. An incomplete purge is tried again by retention.
    if (complete) {
      await tx`update delivery_jobs set purged_at = ${now}
        where id = ${job.id} and purged_at is null`;
    }
  });
  deps.log.info('delivery.purged', {
    job: job.id,
    reason,
    objects: objectsDeleted,
    providerMedia: media,
    complete,
  });
  return { objectsDeleted, providerMedia: media, complete };
}

/** What a booth is told about a job: no number, no tokens (UX-PD6). */
export function jobView(job: JobRow, history: HistoryRow[] = []) {
  return {
    id: job.id,
    state: job.state,
    status: publicStatus(job.state),
    recipientLast4: job.recipient_last4,
    eventId: job.event_id,
    sessionId: job.session_id,
    outputId: job.output_id,
    attempts: job.attempts,
    failureCode: job.failure_code,
    reviewReason: job.review_reason,
    createdAt: job.created_at.toISOString(),
    updatedAt: job.updated_at.toISOString(),
    expiresAt: job.expires_at.toISOString(),
    dispatchedAt: job.dispatched_at?.toISOString() ?? null,
    linkExpiresAt: job.link_expires_at?.toISOString() ?? null,
    linkRevokedAt: job.link_revoked_at?.toISOString() ?? null,
    hostedFilesDeleted: job.purged_at !== null,
    history: history.map((entry) => ({
      state: entry.state,
      status: publicStatus(entry.state),
      code: entry.code,
      at: entry.at.toISOString(),
    })),
  };
}

export async function historyOf(db: Db, jobId: string): Promise<HistoryRow[]> {
  return await q(db)<HistoryRow[]>`select state, code, at from delivery_history
    where job_id = ${jobId} order by id`;
}
