// What every handler works with: the database, configuration, private
// storage, the messaging provider, the clock and the log. Production wires
// the real ones (delivery/index.ts); tests wire fakes for the provider and
// storage around a real Postgres.

import type { DeliveryConfig } from './config.ts';
import type { Sql } from './deps.ts';
import type { Logger } from './log.ts';
import type { MessagingProvider } from './provider.ts';
import type { ObjectStore } from './store.ts';

export interface Deps {
  sql: Sql;
  config: DeliveryConfig;
  store: ObjectStore;
  provider: MessagingProvider;
  now: () => Date;
  log: Logger;
  /** A number in [0, 1) for retry jitter. */
  random: () => number;
}

export function addMinutes(date: Date, minutes: number): Date {
  return new Date(date.getTime() + minutes * 60_000);
}

export function addSeconds(date: Date, seconds: number): Date {
  return new Date(date.getTime() + seconds * 1000);
}
