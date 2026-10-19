// Fixed-window rate limits (AC-0907, AC-0916), counted in Postgres so
// every function instance shares them. Network addresses are only ever
// stored as a keyed hash that changes daily.

import type { Deps } from './context.ts';
import { recipientDigest } from './crypto.ts';
import { ApiError, clientAddress } from './http.ts';

/**
 * Counts one hit on [key] in its current window of [windowSeconds];
 * throws a 429 with [code] once more than [limit] hits fell in it.
 */
export async function limit(
  deps: Deps,
  key: string,
  windowSeconds: number,
  max: number,
  code: string,
): Promise<void> {
  const now = deps.now();
  const start = new Date(Math.floor(now.getTime() / (windowSeconds * 1000)) * windowSeconds * 1000);
  const [row] = await deps.sql<{ count: number }[]>`
    insert into rate_counters (key, window_start, count) values (${key}, ${start}, 1)
    on conflict (key, window_start) do update set count = rate_counters.count + 1
    returning count`;
  if (row.count > max) {
    const retryAfter = Math.ceil((start.getTime() + windowSeconds * 1000 - now.getTime()) / 1000);
    throw new ApiError(429, code, { retryAfterSeconds: retryAfter });
  }
}

/** A daily-rotating keyed hash of the caller's network address. */
export async function addressKey(deps: Deps, request: Request): Promise<string> {
  const day = deps.now().toISOString().slice(0, 10);
  const digest = await recipientDigest(
    deps.config.digestKey,
    `addr:${day}:${clientAddress(request)}`,
  );
  return digest.slice(0, 32);
}
