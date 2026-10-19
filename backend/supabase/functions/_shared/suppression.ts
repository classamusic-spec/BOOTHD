// The suppression list (PD-07, AC-0914): numbers that replied STOP, that
// the provider reports as unsubscribed, or that an operator blocked. Kept
// as keyed digests only. STOP applies to the whole sending service.

import type { Deps } from './context.ts';

/** Is the number on the list (service-wide or for this tenant)? */
export async function isSuppressed(deps: Deps, tenantId: string, digest: string): Promise<boolean> {
  const rows = await deps.sql`select 1 from suppression_entries
    where recipient_digest = ${digest} and scope in ('service', ${`tenant:${tenantId}`})`;
  return rows.length > 0;
}

export async function suppress(
  deps: Deps,
  digest: string,
  reason: 'stop' | 'carrier' | 'manual',
  scope = 'service',
): Promise<void> {
  await deps.sql`insert into suppression_entries (recipient_digest, scope, reason)
    values (${digest}, ${scope}, ${reason}) on conflict do nothing`;
}

/** START after STOP: only an opt-out the recipient made is lifted. */
export async function unsuppress(deps: Deps, digest: string): Promise<void> {
  await deps.sql`delete from suppression_entries
    where recipient_digest = ${digest} and scope = 'service' and reason = 'stop'`;
}
