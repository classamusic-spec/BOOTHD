// Supabase Edge Function `delivery` (deploy with JWT verification off:
// Twilio, guests and booths authenticate with this service's own tokens,
// see backend/supabase/config.toml). All configuration comes from the
// function's secrets; see docs/delivery/SETUP_AND_CREDENTIALS.md.

import { createHandler } from '../_shared/app.ts';
import { configFromEnv } from '../_shared/config.ts';
import { postgres } from '../_shared/deps.ts';
import { Logger } from '../_shared/log.ts';
import { TwilioRestProvider, UnconfiguredProvider } from '../_shared/provider.ts';
import { MemoryObjectStore, SupabaseObjectStore } from '../_shared/store.ts';

const config = configFromEnv((name) => Deno.env.get(name));
// Transaction pooler: no prepared statements.
const sql = postgres(config.databaseUrl, { prepare: false, max: 3, idle_timeout: 20 });

Deno.serve(createHandler({
  sql,
  config,
  store: config.storage
    ? new SupabaseObjectStore(config.storage.url, config.storage.serviceRoleKey)
    : new MemoryObjectStore(),
  provider: config.twilio ? new TwilioRestProvider(config.twilio) : new UnconfiguredProvider(),
  now: () => new Date(),
  log: new Logger(),
  random: Math.random,
}));
