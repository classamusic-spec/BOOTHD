// The provider's preview fetch (PD-04, AC-0909): GET and HEAD of the small
// JPEG preview, under its own short-lived token. It never serves the
// finished photo, and an expired or revoked token gets 410.

import type { Deps } from './context.ts';
import { sha256Hex } from './crypto.ts';
import { ApiError, baseHeaders, tokenPattern } from './http.ts';
import type { JobRow } from './jobs.ts';

interface GrantRow {
  id: string;
  job_id: string;
  kind: 'download' | 'preview';
  expires_at: Date;
  revoked_at: Date | null;
  access_count: number;
  max_access: number | null;
}

/** The live grant for [token] of [kind] with its job, or why not. */
export async function grantFor(
  deps: Deps,
  token: string,
  kind: 'download' | 'preview',
): Promise<
  | { ok: true; grant: GrantRow; job: JobRow }
  | { ok: false; reason: 'unknown' | 'expired' | 'revoked' | 'deleted' | 'used_up' }
> {
  if (!tokenPattern.test(token)) return { ok: false, reason: 'unknown' };
  const hash = await sha256Hex(token);
  const [grant] = await deps.sql<GrantRow[]>`select id, job_id, kind, expires_at, revoked_at,
      access_count, max_access
    from access_grants where token_hash = ${hash} and kind = ${kind}`;
  if (!grant) return { ok: false, reason: 'unknown' };
  const [job] = await deps.sql<JobRow[]>`select * from delivery_jobs where id = ${grant.job_id}`;
  if (!job) return { ok: false, reason: 'unknown' };
  if (job.purged_at) return { ok: false, reason: 'deleted' };
  if (grant.revoked_at || job.link_revoked_at) return { ok: false, reason: 'revoked' };
  if (grant.expires_at <= deps.now()) return { ok: false, reason: 'expired' };
  if (grant.max_access !== null && grant.access_count >= grant.max_access) {
    return { ok: false, reason: 'used_up' };
  }
  return { ok: true, grant, job };
}

/** GET|HEAD /m/{token} */
export async function previewForProvider(
  deps: Deps,
  token: string,
  request: Request,
): Promise<Response> {
  const found = await grantFor(deps, token, 'preview');
  if (!found.ok) {
    throw new ApiError(found.reason === 'unknown' ? 404 : 410, 'PREVIEW_UNAVAILABLE');
  }
  const { job, grant } = found;
  if (!job.preview_key) throw new ApiError(410, 'PREVIEW_UNAVAILABLE');
  let object;
  try {
    object = await deps.store.get(job.preview_key);
  } catch {
    throw new ApiError(503, 'STORAGE_UNAVAILABLE');
  }
  if (!object) throw new ApiError(410, 'PREVIEW_UNAVAILABLE');
  await deps.sql`update access_grants set access_count = access_count + 1 where id = ${grant.id}`;
  const headers = {
    ...baseHeaders,
    'content-type': 'image/jpeg',
    'content-length': String(object.bytes.length),
    'content-disposition': 'inline; filename="photo.jpg"',
    'cache-control': 'private, no-store, max-age=0',
  };
  deps.log.info('preview.fetched', { job: job.id, method: request.method });
  return new Response(request.method === 'HEAD' ? null : object.bytes, { status: 200, headers });
}
