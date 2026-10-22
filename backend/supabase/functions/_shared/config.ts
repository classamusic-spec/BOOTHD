// Backend configuration, read once from the environment (the platform's
// secret store in production). Nothing here is ever sent to a booth.

export type Environment = 'production' | 'staging' | 'test';

export interface TwilioConfig {
  accountSid: string;
  /** REST API key used to send (preferred over the account auth token). */
  apiKeySid: string;
  apiKeySecret: string;
  /** Twilio signs webhooks with the account's auth token. */
  authToken: string;
  /** The registered Messaging Service that owns the sender. */
  messagingServiceSid: string;
  /** `https://api.twilio.com` except in tests. */
  apiBase: string;
}

export interface SupabaseStorageConfig {
  url: string;
  serviceRoleKey: string;
}

export interface DeliveryConfig {
  environment: Environment;
  /** Where Twilio and guests reach this service, without a trailing slash. */
  publicBaseUrl: string;
  /** Path prefixes the platform adds before ours (`/delivery`). */
  pathPrefixes: string[];
  /**
   * Web pages allowed to call the booth API from a browser (the web test
   * build, ADR-0018): exact origins, empty for tablets only.
   */
  boothOrigins: string[];
  databaseUrl: string;
  /** AES-256 key (base64url, 32 bytes) for stored phone numbers. */
  phoneKey: string;
  /** HMAC key for recipient digests (suppression, throttles). */
  digestKey: string;
  /** SHA-256 (hex) of the administrator's bearer token. */
  adminTokenSha256: string;
  /** Null until every Twilio setting is present: sending is then off. */
  twilio: TwilioConfig | null;
  /** Null: objects are kept in memory (tests and local runs only). */
  storage: SupabaseStorageConfig | null;
  accessTokenMinutes: number;
  uploadGrantMinutes: number;
  previewGrantMinutes: number;
  pairingCodeMinutes: number;
  /** The local queue window: consent older than this is never sent. */
  queueHours: number;
  /** Delivery rows (and their receipts and history) are deleted after. */
  jobRetentionDays: number;
  finalMaxBytes: number;
}

export class ConfigError extends Error {}

type Env = (name: string) => string | undefined;

function required(env: Env, name: string): string {
  const value = env(name)?.trim();
  if (!value) throw new ConfigError(`${name} is not set`);
  return value;
}

function optional(env: Env, name: string): string | undefined {
  const value = env(name)?.trim();
  return value ? value : undefined;
}

/**
 * The browser origins of DELIVERY_BOOTH_ORIGINS (comma separated). Each is
 * an exact `https://host[:port]`; plain `http` only for localhost outside
 * production. No wildcard: a booth page's origin is known.
 */
export function boothOriginsFrom(value: string | undefined, environment: Environment): string[] {
  if (!value) return [];
  const origins = value.split(',').map((origin) => origin.trim()).filter((origin) => origin);
  for (const origin of origins) {
    let url: URL;
    try {
      url = new URL(origin);
    } catch {
      throw new ConfigError('DELIVERY_BOOTH_ORIGINS holds an invalid origin');
    }
    const local = url.hostname === 'localhost' || url.hostname === '127.0.0.1';
    const secure = url.protocol === 'https:' ||
      (url.protocol === 'http:' && local && environment !== 'production');
    if (!secure || url.origin !== origin) {
      throw new ConfigError(
        'DELIVERY_BOOTH_ORIGINS must list exact https origins (scheme and host, no path)',
      );
    }
  }
  return [...new Set(origins)];
}

/** Reads and checks the configuration; throws [ConfigError] if unusable. */
export function configFromEnv(env: Env): DeliveryConfig {
  const environment = (optional(env, 'DELIVERY_ENVIRONMENT') ?? 'production') as Environment;
  if (!['production', 'staging', 'test'].includes(environment)) {
    throw new ConfigError('DELIVERY_ENVIRONMENT must be production, staging or test');
  }
  const publicBaseUrl = required(env, 'DELIVERY_PUBLIC_BASE_URL').replace(/\/+$/, '');
  if (environment !== 'test' && !publicBaseUrl.startsWith('https://')) {
    throw new ConfigError('DELIVERY_PUBLIC_BASE_URL must use https');
  }
  const adminTokenSha256 = required(env, 'DELIVERY_ADMIN_TOKEN_SHA256').toLowerCase();
  if (!/^[0-9a-f]{64}$/.test(adminTokenSha256)) {
    throw new ConfigError('DELIVERY_ADMIN_TOKEN_SHA256 must be 64 hex digits');
  }
  const digestKey = required(env, 'DELIVERY_DIGEST_KEY');
  if (digestKey.length < 32) throw new ConfigError('DELIVERY_DIGEST_KEY is too short');

  const twilioNames = [
    'TWILIO_ACCOUNT_SID',
    'TWILIO_API_KEY_SID',
    'TWILIO_API_KEY_SECRET',
    'TWILIO_AUTH_TOKEN',
    'TWILIO_MESSAGING_SERVICE_SID',
  ];
  const twilioValues = twilioNames.map((name) => optional(env, name));
  const twilio: TwilioConfig | null = twilioValues.every((value) => value)
    ? {
      accountSid: twilioValues[0]!,
      apiKeySid: twilioValues[1]!,
      apiKeySecret: twilioValues[2]!,
      authToken: twilioValues[3]!,
      messagingServiceSid: twilioValues[4]!,
      apiBase: (optional(env, 'TWILIO_API_BASE') ?? 'https://api.twilio.com').replace(/\/+$/, ''),
    }
    : null;
  if (twilio && environment !== 'test' && !twilio.apiBase.startsWith('https://')) {
    throw new ConfigError('TWILIO_API_BASE must use https');
  }

  const storageUrl = optional(env, 'SUPABASE_URL');
  const storageKey = optional(env, 'SUPABASE_SERVICE_ROLE_KEY');
  const storage = storageUrl && storageKey
    ? { url: storageUrl.replace(/\/+$/, ''), serviceRoleKey: storageKey }
    : null;
  if (!storage && environment !== 'test') {
    throw new ConfigError('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required');
  }

  return {
    environment,
    publicBaseUrl,
    pathPrefixes: (optional(env, 'DELIVERY_PATH_PREFIXES') ?? '/functions/v1/delivery,/delivery')
      .split(',')
      .map((prefix) => prefix.trim().replace(/\/+$/, ''))
      .filter((prefix) => prefix.startsWith('/')),
    boothOrigins: boothOriginsFrom(optional(env, 'DELIVERY_BOOTH_ORIGINS'), environment),
    databaseUrl: required(env, 'DELIVERY_DATABASE_URL'),
    phoneKey: required(env, 'DELIVERY_PHONE_KEY'),
    digestKey,
    adminTokenSha256,
    twilio,
    storage,
    accessTokenMinutes: 15,
    uploadGrantMinutes: 15,
    previewGrantMinutes: 60,
    pairingCodeMinutes: 30,
    queueHours: 24,
    jobRetentionDays: 90,
    finalMaxBytes: 25 * 1024 * 1024,
  };
}
