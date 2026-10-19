// The production adapters against recorded request shapes: Supabase
// Storage's REST API and Twilio's error classification.

import { assert, assertEquals, assertRejects } from './helpers/assert.ts';
import { SupabaseObjectStore } from '../supabase/functions/_shared/store.ts';
import { TwilioRestProvider } from '../supabase/functions/_shared/provider.ts';

interface Seen {
  method: string;
  url: string;
  headers: Headers;
  body: string;
}

function recorder(respond: (request: Seen) => Response) {
  const seen: Seen[] = [];
  const fetcher = (async (input: string | URL | Request, init?: RequestInit) => {
    const request = new Request(input, init);
    const entry = {
      method: request.method,
      url: request.url,
      headers: request.headers,
      body: request.body ? await request.text() : '',
    };
    seen.push(entry);
    return respond(entry);
  }) as typeof fetch;
  return { seen, fetcher };
}

Deno.test('Supabase storage: private buckets, service key, no other paths', async () => {
  const absent = '99999999-9999-4999-8999-999999999999';
  const { seen, fetcher } = recorder((request) =>
    request.method === 'GET' && request.url.endsWith(`${absent}.jpg`)
      ? new Response('{}', { status: 400 })
      : new Response('{}', { status: 200, headers: { 'content-type': 'image/jpeg' } })
  );
  const store = new SupabaseObjectStore('https://project.supabase.co', 'service-key', fetcher);
  const id = '11111111-1111-4111-8111-111111111111';
  await store.put(`final/${id}.jpg`, new Uint8Array([1, 2, 3]), 'image/jpeg');
  await store.get(`preview/${id}.jpg`);
  await store.delete(`final/${id}.jpg`);
  assertEquals(seen[0].method, 'POST');
  assertEquals(
    seen[0].url,
    `https://project.supabase.co/storage/v1/object/delivery-final/${id}.jpg`,
  );
  assertEquals(seen[0].headers.get('authorization'), 'Bearer service-key');
  assertEquals(seen[0].headers.get('content-type'), 'image/jpeg');
  assertEquals(
    seen[1].url,
    `https://project.supabase.co/storage/v1/object/delivery-preview/${id}.jpg`,
  );
  assertEquals(seen[2].method, 'DELETE');
  assertEquals(seen[2].url, 'https://project.supabase.co/storage/v1/object/delivery-final');
  assertEquals(JSON.parse(seen[2].body), { prefixes: [`${id}.jpg`] });
  await assertRejects(() => store.put(`original/${id}.jpg`, new Uint8Array([1]), 'image/jpeg'));
  await assertRejects(() => store.get('../etc/passwd'));
  assertEquals(await store.get(`preview/${absent}.jpg`), null);
});

Deno.test('Twilio: request shape and outcome classification', async () => {
  const config = {
    accountSid: `AC${'1'.repeat(32)}`,
    apiKeySid: `SK${'2'.repeat(32)}`,
    apiKeySecret: 'secret',
    messagingServiceSid: `MG${'3'.repeat(32)}`,
    apiBase: 'https://api.twilio.test',
  };
  const responses: Response[] = [];
  const { seen, fetcher } = recorder(() => responses.shift()!);
  const provider = new TwilioRestProvider(config, fetcher);
  const send = () =>
    provider.send({
      to: '+12125550147',
      body: 'Brand: hello',
      mediaUrl: 'https://photos.test/m/x',
      statusCallback: 'https://photos.test/webhooks/twilio/status',
    });
  const reply = (status: number, body: unknown, headers: Record<string, string> = {}) =>
    new Response(JSON.stringify(body), { status, headers });

  responses.push(reply(201, { sid: `MM${'a'.repeat(32)}`, status: 'accepted' }));
  assertEquals(await send(), { kind: 'accepted', sid: `MM${'a'.repeat(32)}`, status: 'accepted' });
  assertEquals(
    seen[0].url,
    `https://api.twilio.test/2010-04-01/Accounts/${config.accountSid}/Messages.json`,
  );
  assertEquals(seen[0].headers.get('authorization'), `Basic ${btoa(`${config.apiKeySid}:secret`)}`);
  const form = new URLSearchParams(seen[0].body);
  assertEquals(form.get('To'), '+12125550147');
  assertEquals(form.get('MessagingServiceSid'), config.messagingServiceSid);
  assertEquals(form.get('MediaUrl'), 'https://photos.test/m/x');
  assertEquals(form.get('StatusCallback'), 'https://photos.test/webhooks/twilio/status');

  responses.push(reply(429, { code: 20429 }, { 'retry-after': '30' }));
  assertEquals(await send(), {
    kind: 'retryable',
    code: 'PROVIDER_RATE_LIMITED',
    retryAfterSeconds: 30,
  });
  responses.push(reply(400, { code: 21614 }));
  assertEquals(await send(), {
    kind: 'rejected',
    code: 'PROVIDER_NOT_MOBILE',
    providerCode: '21614',
  });
  responses.push(reply(400, { code: 99999 }));
  assertEquals((await send()).kind, 'rejected');
  responses.push(reply(401, { code: 20003 }));
  assertEquals((await send()).kind, 'retryable');
  responses.push(reply(503, {}));
  assertEquals(await send(), { kind: 'ambiguous', code: 'PROVIDER_SERVER_ERROR' });
  responses.push(reply(201, { sid: 'not-a-sid' }));
  assertEquals((await send()).kind, 'ambiguous');

  // Nothing listening: certainly not sent.
  const refused = new TwilioRestProvider(
    { ...config, apiBase: 'http://127.0.0.1:59999' },
    fetch,
    2000,
  );
  const outcome = await refused.send({ to: '+1', body: 'x', mediaUrl: 'x', statusCallback: 'x' });
  assertEquals(outcome.kind, 'retryable');
  assert(outcome.kind === 'retryable' && outcome.code === 'PROVIDER_UNREACHABLE');
});
