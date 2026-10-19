// Unit tests of the backend's pure parts: tokens and encryption, phone
// parsing (shared vectors with the booth app), state rules, image checks,
// the message text, log redaction, routing and configuration.

import {
  assert,
  assertEquals,
  assertMatch,
  assertNotEquals,
  assertRejects,
  assertThrows,
} from './helpers/assert.ts';
import { routePath } from '../supabase/functions/_shared/app.ts';
import { newPairingCode, normalizePairingCode } from '../supabase/functions/_shared/auth.ts';
import { ConfigError, configFromEnv } from '../supabase/functions/_shared/config.ts';
import {
  base64Url,
  constantTimeEqual,
  decryptText,
  encryptText,
  fromBase64Url,
  randomToken,
  recipientDigest,
  sha256Hex,
} from '../supabase/functions/_shared/crypto.ts';
import { messageBody } from '../supabase/functions/_shared/dispatch.ts';
import { inspectImage } from '../supabase/functions/_shared/images.ts';
import { redact } from '../supabase/functions/_shared/log.ts';
import { escapeHtml } from '../supabase/functions/_shared/page.ts';
import { maskPhone, parsePhone } from '../supabase/functions/_shared/phone.ts';
import {
  finalStates,
  providerMayMove,
  publicStatus,
  stateForProviderStatus,
} from '../supabase/functions/_shared/states.ts';
import { fixture } from './helpers/harness.ts';

Deno.test('tokens carry 256 random bits as 43 base64url characters', () => {
  const tokens = new Set<string>();
  for (let i = 0; i < 2000; i++) {
    const token = randomToken();
    assertMatch(token, /^[A-Za-z0-9_-]{43}$/);
    assertEquals(fromBase64Url(token).length, 32);
    tokens.add(token);
  }
  assertEquals(tokens.size, 2000);
});

Deno.test('SHA-256 matches the standard vector', async () => {
  assertEquals(
    await sha256Hex('abc'),
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
  );
});

Deno.test('constant-time comparison', () => {
  assert(constantTimeEqual('abc', 'abc'));
  assert(!constantTimeEqual('abc', 'abd'));
  assert(!constantTimeEqual('abc', 'abcd'));
  assert(!constantTimeEqual('', 'a'));
});

Deno.test('phone numbers are encrypted with AES-256-GCM and tampering is detected', async () => {
  const key = base64Url(crypto.getRandomValues(new Uint8Array(32)));
  const sealed = await encryptText(key, '+12125550147');
  assertMatch(sealed, /^v1\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/);
  assert(!sealed.includes('2125550147'));
  assertNotEquals(sealed, await encryptText(key, '+12125550147'), 'a fresh IV each time');
  assertEquals(await decryptText(key, sealed), '+12125550147');
  const [version, iv, data] = sealed.split('.');
  const flipped = data.slice(0, -2) + (data.at(-2) === 'A' ? 'B' : 'A') + data.at(-1);
  await assertRejects(() => decryptText(key, `${version}.${iv}.${flipped}`));
  const other = base64Url(crypto.getRandomValues(new Uint8Array(32)));
  await assertRejects(() => decryptText(other, sealed));
  await assertRejects(() => encryptText(base64Url(new Uint8Array(16)), 'x'));
});

Deno.test('recipient digests are stable, keyed and hide the number', async () => {
  const a = await recipientDigest('key-one-0123456789abcdef0123456789', '+12125550147');
  assertEquals(a, await recipientDigest('key-one-0123456789abcdef0123456789', '+12125550147'));
  assertNotEquals(a, await recipientDigest('key-two-0123456789abcdef0123456789', '+12125550147'));
  assertMatch(a, /^[0-9a-f]{64}$/);
});

Deno.test('phone parsing agrees with the shared vectors (AC-0903)', async () => {
  const vectors = JSON.parse(
    await Deno.readTextFile(new URL('./fixtures/phone_cases.json', import.meta.url)),
  ) as { cases: { input: string; e164?: string; last4?: string; problem?: string }[] };
  assert(vectors.cases.length >= 19);
  for (const vector of vectors.cases) {
    const parsed = parsePhone(vector.input);
    if (vector.e164) {
      assert(parsed.ok, `${vector.input} should parse`);
      assertEquals(parsed.ok && parsed.e164, vector.e164);
      assertEquals(parsed.ok && parsed.last4, vector.last4);
    } else {
      assert(!parsed.ok, `${vector.input} should be refused`);
      assertEquals(!parsed.ok && parsed.problem, vector.problem, vector.input);
    }
  }
  assertEquals(maskPhone('0147'), '•••-•••-0147');
});

Deno.test('provider statuses map to states; only delivered means delivered (AC-0913)', () => {
  assertEquals(stateForProviderStatus('accepted'), 'provider_accepted');
  assertEquals(stateForProviderStatus('queued'), 'provider_accepted');
  assertEquals(stateForProviderStatus('sending'), 'provider_sent');
  assertEquals(stateForProviderStatus('sent'), 'provider_sent');
  assertEquals(stateForProviderStatus('delivered'), 'delivered');
  assertEquals(stateForProviderStatus('undelivered'), 'failed_permanent');
  assertEquals(stateForProviderStatus('failed'), 'failed_permanent');
  assertEquals(stateForProviderStatus('read'), null);
  assertEquals(stateForProviderStatus('received'), null);
  assertEquals(publicStatus('provider_accepted'), 'submitted');
  assertEquals(publicStatus('provider_sent'), 'sent');
  assertEquals(publicStatus('delivered'), 'delivered');
  assertEquals(publicStatus('delivery_unknown'), 'unknown');
  for (const state of ['provider_accepted', 'provider_sent', 'delivery_unknown'] as const) {
    assertNotEquals(publicStatus(state), 'delivered');
  }
});

Deno.test('provider reports only move a delivery forward', () => {
  assert(providerMayMove('provider_accepted', 'provider_sent'));
  assert(providerMayMove('provider_sent', 'delivered'));
  assert(providerMayMove('delivery_unknown', 'provider_accepted'));
  assert(providerMayMove('provider_sent', 'failed_permanent'));
  assert(!providerMayMove('delivered', 'provider_sent'));
  assert(!providerMayMove('provider_sent', 'provider_accepted'));
  for (const state of finalStates) assert(!providerMayMove(state, 'delivered'));
});

Deno.test('images are recognized from their bytes, with size and completeness', async () => {
  const jpeg = await fixture('final_1200x1800.jpg');
  const png = await fixture('final_1200x1800.png');
  const preview = await fixture('preview_400x600.jpg');
  assertEquals(inspectImage(jpeg), { ok: true, format: 'jpeg', width: 1200, height: 1800 });
  assertEquals(inspectImage(png), { ok: true, format: 'png', width: 1200, height: 1800 });
  assertEquals(inspectImage(preview), { ok: true, format: 'jpeg', width: 400, height: 600 });
  assertEquals(inspectImage(jpeg.slice(0, jpeg.length - 100)).ok, false);
  assertEquals(inspectImage(jpeg.slice(0, jpeg.length - 100)), {
    ok: false,
    problem: 'IMAGE_TRUNCATED',
  });
  assertEquals(inspectImage(png.slice(0, png.length - 12)).ok, false);
  assertEquals(inspectImage(new TextEncoder().encode('GIF89a not a jpeg')), {
    ok: false,
    problem: 'IMAGE_TYPE',
  });
  assertEquals(inspectImage(new Uint8Array([0xff, 0xd8, 0xff, 0xd9])).ok, false);
});

Deno.test('the text names the sender, the event, the link, its life, STOP and HELP', () => {
  const body = messageBody(
    'Porcelain Booth',
    'Garden Wedding',
    'https://photos.example.test/p/abc',
    7,
  );
  assertEquals(
    body,
    'Porcelain Booth: Your photos from Garden Wedding are ready: https://photos.example.test/p/abc ' +
      '(available for 7 days). Reply STOP to opt out, HELP for help.',
  );
  assert(messageBody('B', 'E', 'L', 1).includes('available for 1 day)'));
  assert(body.length < 320);
});

Deno.test('logs never carry numbers or tokens', () => {
  const token = randomToken();
  assertEquals(redact(`to +12125550147 now`), 'to [redacted] now');
  assertEquals(redact(`(212) 555-0147`), '[redacted]');
  assertEquals(redact(`link /p/${token}`), 'link /p/[redacted]');
  const uuid = crypto.randomUUID();
  assertEquals(redact(`job ${uuid}`), `job ${uuid}`);
});

Deno.test('pairing codes are 60-bit, readable and forgiving to type', () => {
  const code = newPairingCode();
  assertMatch(code, /^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$/);
  assertEquals(normalizePairingCode(' abcd-efgh-jkmn '), 'ABCDEFGHJKMN');
  assertEquals(normalizePairingCode('O1lI-0000-0000'), '011100000000');
});

Deno.test('platform path prefixes are stripped', () => {
  const prefixes = ['/functions/v1/delivery', '/delivery'];
  assertEquals(routePath('/functions/v1/delivery/p/abc', prefixes), '/p/abc');
  assertEquals(routePath('/delivery/v1/deliveries', prefixes), '/v1/deliveries');
  assertEquals(routePath('/p/abc', prefixes), '/p/abc');
  assertEquals(routePath('/deliveryx/p', prefixes), '/deliveryx/p');
});

Deno.test('HTML is escaped', () => {
  assertEquals(
    escapeHtml(`<a href="x">'&'</a>`),
    '&lt;a href=&quot;x&quot;&gt;&#39;&amp;&#39;&lt;/a&gt;',
  );
});

Deno.test('configuration refuses unsafe production settings', async () => {
  const hash = await sha256Hex('admin');
  const base: Record<string, string> = {
    DELIVERY_PUBLIC_BASE_URL: 'https://photos.example.test',
    DELIVERY_DATABASE_URL: 'postgres://example',
    DELIVERY_PHONE_KEY: base64Url(new Uint8Array(32)),
    DELIVERY_DIGEST_KEY: 'x'.repeat(32),
    DELIVERY_ADMIN_TOKEN_SHA256: hash,
    SUPABASE_URL: 'https://project.supabase.co',
    SUPABASE_SERVICE_ROLE_KEY: 'service-role',
  };
  const read = (env: Record<string, string>) => configFromEnv((name) => env[name]);
  const config = read(base);
  assertEquals(config.environment, 'production');
  assertEquals(config.twilio, null, 'no Twilio settings: sending stays off');
  assertThrows(
    () => read({ ...base, DELIVERY_PUBLIC_BASE_URL: 'http://photos.example.test' }),
    ConfigError,
  );
  assertThrows(() => read({ ...base, DELIVERY_ADMIN_TOKEN_SHA256: 'short' }), ConfigError);
  assertThrows(() => read({ ...base, DELIVERY_DIGEST_KEY: 'short' }), ConfigError);
  assertThrows(() => read({ ...base, SUPABASE_URL: '' }), ConfigError);
  const twilio = read({
    ...base,
    TWILIO_ACCOUNT_SID: 'AC1',
    TWILIO_API_KEY_SID: 'SK1',
    TWILIO_API_KEY_SECRET: 's',
    TWILIO_AUTH_TOKEN: 't',
    TWILIO_MESSAGING_SERVICE_SID: 'MG1',
  });
  assertEquals(twilio.twilio?.apiBase, 'https://api.twilio.com');
  assertThrows(
    () =>
      read({
        ...base,
        TWILIO_ACCOUNT_SID: 'AC1',
        TWILIO_API_KEY_SID: 'SK1',
        TWILIO_API_KEY_SECRET: 's',
        TWILIO_AUTH_TOKEN: 't',
        TWILIO_MESSAGING_SERVICE_SID: 'MG1',
        TWILIO_API_BASE: 'http://api.twilio.test',
      }),
    ConfigError,
  );
});
