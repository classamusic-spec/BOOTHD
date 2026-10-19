// The delivery service as tests use it: a fresh database, the real
// handler served on a local port (so the fake Twilio can fetch previews
// from it), private storage in memory, a clock tests can move and every
// log line captured for redaction checks.

import { createHandler } from '../../supabase/functions/_shared/app.ts';
import type { DeliveryConfig } from '../../supabase/functions/_shared/config.ts';
import type { Deps } from '../../supabase/functions/_shared/context.ts';
import { base64Url, sha256Hex } from '../../supabase/functions/_shared/crypto.ts';
import { getExpectedTwilioSignature } from '../../supabase/functions/_shared/deps.ts';
import { Logger } from '../../supabase/functions/_shared/log.ts';
import { TwilioRestProvider } from '../../supabase/functions/_shared/provider.ts';
import { MemoryObjectStore } from '../../supabase/functions/_shared/store.ts';
import { freshDatabase, type TestDatabase } from './db.ts';
import { type FakeTwilio, startFakeTwilio } from './fake_twilio.ts';

export const adminToken = 'admin-token-for-tests-0123456789abcdef0123456789';
export const authToken = 'fake-twilio-auth-token-0123456789';
export const messagingServiceSid = `MG${'ab'.repeat(16)}`;

export interface Harness {
  db: TestDatabase;
  deps: Deps;
  twilio: FakeTwilio;
  store: MemoryObjectStore;
  logs: string[];
  baseUrl: string;
  clock: { now: Date };
  call(
    method: string,
    path: string,
    options?: { token?: string; json?: unknown; body?: BodyInit; headers?: Record<string, string> },
  ): Promise<Response>;
  close(): Promise<void>;
}

export async function startHarness(
  {
    twilioConfigured = true,
    environment = 'test' as DeliveryConfig['environment'],
    publicBaseUrl = undefined as string | undefined,
  } = {},
): Promise<Harness> {
  const db = await freshDatabase();
  const clock = { now: new Date() };
  const twilio = await startFakeTwilio({ now: () => clock.now });
  const store = new MemoryObjectStore();
  const logs: string[] = [];
  let handler: (request: Request) => Promise<Response> = () =>
    Promise.reject(new Error('not ready'));
  const server = Deno.serve(
    { hostname: '127.0.0.1', port: 0, onListen: () => {} },
    (request) => handler(request),
  );
  const baseUrl = `http://127.0.0.1:${server.addr.port}`;
  const config: DeliveryConfig = {
    environment,
    // Staging and production need https; tests that do not fetch through
    // the public address may give one.
    publicBaseUrl: publicBaseUrl ?? baseUrl,
    pathPrefixes: ['/functions/v1/delivery', '/delivery'],
    databaseUrl: db.url,
    phoneKey: base64Url(crypto.getRandomValues(new Uint8Array(32))),
    digestKey: 'digest-key-for-tests-0123456789abcdef',
    adminTokenSha256: await sha256Hex(adminToken),
    twilio: twilioConfigured
      ? {
        accountSid: twilio.accountSid,
        apiKeySid: twilio.apiKeySid,
        apiKeySecret: twilio.apiKeySecret,
        authToken,
        messagingServiceSid,
        apiBase: twilio.apiBase,
      }
      : null,
    storage: null,
    accessTokenMinutes: 15,
    uploadGrantMinutes: 15,
    previewGrantMinutes: 60,
    pairingCodeMinutes: 30,
    queueHours: 24,
    jobRetentionDays: 90,
    finalMaxBytes: 25 * 1024 * 1024,
  };
  const deps: Deps = {
    sql: db.sql,
    config,
    store,
    provider: new TwilioRestProvider(
      {
        ...config.twilio ?? {
          accountSid: twilio.accountSid,
          apiKeySid: twilio.apiKeySid,
          apiKeySecret: twilio.apiKeySecret,
          messagingServiceSid,
          apiBase: twilio.apiBase,
        },
      },
      fetch,
      1000,
    ),
    now: () => clock.now,
    log: new Logger((line) => logs.push(line)),
    random: () => 0.5,
  };
  handler = createHandler(deps);
  return {
    db,
    deps,
    twilio,
    store,
    logs,
    baseUrl,
    clock,
    async call(method, path, options = {}) {
      const headers: Record<string, string> = { ...options.headers };
      if (options.token) headers.authorization = `Bearer ${options.token}`;
      let body = options.body;
      if (options.json !== undefined) {
        headers['content-type'] = 'application/json';
        body = JSON.stringify(options.json);
      }
      return await fetch(`${baseUrl}${path}`, { method, headers, body });
    },
    async close() {
      await server.shutdown();
      await twilio.close();
      await db.drop();
    },
  };
}

/** A valid Twilio signature for [params] posted to [path]. */
export function sign(harness: Harness, path: string, params: Record<string, string>): string {
  return getExpectedTwilioSignature(authToken, `${harness.baseUrl}${path}`, params);
}

export async function postSigned(
  harness: Harness,
  path: string,
  params: Record<string, string>,
  signature = sign(harness, path, params),
): Promise<Response> {
  return await harness.call('POST', path, {
    headers: {
      'content-type': 'application/x-www-form-urlencoded',
      ...(signature ? { 'x-twilio-signature': signature } : {}),
    },
    body: new URLSearchParams(params).toString(),
  });
}

export async function json(response: Response): Promise<Record<string, unknown>> {
  return await response.json() as Record<string, unknown>;
}

export async function fixture(name: string): Promise<Uint8Array<ArrayBuffer>> {
  return new Uint8Array(await Deno.readFile(new URL(`../fixtures/${name}`, import.meta.url)));
}

/**
 * A tenant ready to send (both attestations recorded, sending on) and a
 * booth paired to it with a fresh access token.
 */
export async function readyBooth(harness: Harness, { ready = true } = {}) {
  const admin = { token: adminToken };
  const tenant = await json(
    await harness.call('POST', '/v1/admin/tenants', {
      ...admin,
      json: {
        name: 'Studio Example',
        brandName: 'Porcelain Booth',
        privacyUrl: 'https://photos.example.test/privacy',
        termsUrl: 'https://photos.example.test/terms',
        supportContact: 'help@example.test',
      },
    }),
  );
  const tenantId = String(tenant.id);
  if (ready) {
    await harness.call('POST', `/v1/admin/tenants/${tenantId}/attestations`, {
      ...admin,
      json: { registration: true, registrationReference: 'CAMPAIGN-TEST-1', legalReview: true },
    });
    await harness.call('PATCH', `/v1/admin/tenants/${tenantId}`, {
      ...admin,
      json: { sendingEnabled: true },
    });
  }
  const code = await json(
    await harness.call('POST', `/v1/admin/tenants/${tenantId}/pairing-codes`, admin),
  );
  const paired = await json(
    await harness.call('POST', '/v1/booths/pair', {
      json: { code: code.code, boothName: 'Front entrance' },
    }),
  );
  const token = await json(
    await harness.call('POST', '/v1/booths/token', {
      token: String(paired.credential),
    }),
  );
  return {
    tenantId,
    boothId: String(paired.boothId),
    credential: String(paired.credential),
    accessToken: String(token.accessToken),
  };
}

export const ids = {
  event: '11111111-1111-4111-8111-111111111111',
  session: '22222222-2222-4222-8222-222222222222',
  output: '33333333-3333-4333-8333-333333333333',
};

export function deliveryRequest(
  overrides: Record<string, unknown> = {},
  consent: Record<string, unknown> = {},
) {
  return {
    eventId: ids.event,
    eventName: 'Garden Wedding',
    sessionId: ids.session,
    outputId: ids.output,
    phone: '+1 (212) 555-0147',
    idempotencyKey: crypto.randomUUID(),
    linkDays: 7,
    eventSendLimit: 200,
    consent: {
      accepted: true,
      textVersion: 'pd-consent-1',
      textDigest: 'a'.repeat(64),
      acceptedAt: new Date().toISOString(),
      locale: 'en-US',
      sourceScreen: 'S31',
      ...consent,
    },
    ...overrides,
  };
}

/** Creates a delivery and uploads both images; returns its id (uncommitted). */
export async function uploadedDelivery(
  harness: Harness,
  accessToken: string,
  request = deliveryRequest(),
): Promise<string> {
  const created = await harness.call('POST', '/v1/deliveries', {
    token: accessToken,
    json: request,
  });
  if (created.status !== 201) throw new Error(`create ${created.status} ${await created.text()}`);
  const id = String((await json(created)).id);
  const final = await fixture('final_1200x1800.jpg');
  const preview = await fixture('preview_400x600.jpg');
  const init = await json(
    await harness.call('POST', `/v1/deliveries/${id}/upload-init`, {
      token: accessToken,
      json: {
        final: {
          format: 'jpeg',
          bytes: final.length,
          sha256: await sha256Hex(final),
          width: 1200,
          height: 1800,
        },
        preview: {
          bytes: preview.length,
          sha256: await sha256Hex(preview),
          width: 400,
          height: 600,
        },
      },
    }),
  );
  const uploads = init.uploads as { kind: string; url: string }[];
  for (const upload of uploads) {
    const response = await fetch(upload.url, {
      method: 'PUT',
      headers: { 'content-type': 'image/jpeg' },
      body: upload.kind === 'final' ? final : preview,
    });
    if (response.status !== 201) {
      throw new Error(`upload ${response.status} ${await response.text()}`);
    }
    await response.body?.cancel();
  }
  return id;
}

/**
 * A test against a fresh service. Op and resource sanitizers are off: the
 * provider's request timeouts outlive a fast test by design.
 */
export function serviceTest(
  name: string,
  fn: (harness: Harness) => Promise<void>,
  options: Parameters<typeof startHarness>[0] = {},
): void {
  Deno.test({
    name,
    sanitizeOps: false,
    sanitizeResources: false,
    async fn() {
      const harness = await startHarness(options);
      try {
        await fn(harness);
      } finally {
        await harness.close();
      }
    },
  });
}

/** Runs the scheduled worker once (dispatch, reconcile, retention). */
export async function runWorker(harness: Harness): Promise<Record<string, unknown>> {
  const response = await harness.call('POST', '/v1/admin/worker/run', { token: adminToken });
  if (response.status !== 200) {
    throw new Error(`worker ${response.status} ${await response.text()}`);
  }
  return await json(response);
}

export async function jobRow(harness: Harness, id: string): Promise<Record<string, unknown>> {
  const [row] = await harness.db.sql`select * from delivery_jobs where id = ${id}`;
  return row as Record<string, unknown>;
}

export function minutes(harness: Harness, n: number): void {
  harness.clock.now = new Date(harness.clock.now.getTime() + n * 60_000);
}
