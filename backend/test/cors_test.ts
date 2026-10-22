// The booth API answers browser pages only from the configured origins
// (ADR-0018, the web test build); the administrator API, Twilio's webhooks
// and the guest pages never answer across origins.

import { assert, assertEquals } from './helpers/assert.ts';
import { adminToken, boothOrigin, readyBooth, serviceTest } from './helpers/harness.ts';

serviceTest('an allowed page may call the booth API', async (h) => {
  const pre = await h.call('OPTIONS', '/v1/deliveries', {
    headers: {
      origin: boothOrigin,
      'access-control-request-method': 'POST',
      'access-control-request-headers': 'authorization, content-type',
    },
  });
  await pre.body?.cancel();
  assertEquals(pre.status, 204);
  assertEquals(pre.headers.get('access-control-allow-origin'), boothOrigin);
  assert(pre.headers.get('access-control-allow-methods')!.includes('PUT'));
  assert(pre.headers.get('access-control-allow-headers')!.includes('authorization'));
  assertEquals(pre.headers.get('access-control-allow-credentials'), null, 'no cookies');

  const booth = await readyBooth(h);
  const answer = await h.call('GET', '/v1/delivery/capabilities', {
    token: booth.accessToken,
    headers: { origin: boothOrigin },
  });
  await answer.body?.cancel();
  assertEquals(answer.status, 200);
  assertEquals(answer.headers.get('access-control-allow-origin'), boothOrigin);
  assertEquals(answer.headers.get('access-control-expose-headers'), 'retry-after');
  assertEquals(answer.headers.get('vary'), 'Origin');
  assertEquals(answer.headers.get('cache-control'), 'no-store, max-age=0');

  // Errors carry the headers too, so the page can read the code.
  const refused = await h.call('GET', '/v1/delivery/capabilities', {
    token: 'x'.repeat(43),
    headers: { origin: boothOrigin },
  });
  await refused.body?.cancel();
  assertEquals(refused.status, 401);
  assertEquals(refused.headers.get('access-control-allow-origin'), boothOrigin);
});

serviceTest('any other page is refused', async (h) => {
  const other = 'https://elsewhere.example.test';
  const pre = await h.call('OPTIONS', '/v1/booths/pair', {
    headers: { origin: other, 'access-control-request-method': 'POST' },
  });
  await pre.body?.cancel();
  assertEquals(pre.status, 403);
  assertEquals(pre.headers.get('access-control-allow-origin'), null);
  const answer = await h.call('POST', '/v1/booths/pair', {
    json: { code: 'AAAA-BBBB', boothName: 'x' },
    headers: { origin: other },
  });
  await answer.body?.cancel();
  assertEquals(answer.headers.get('access-control-allow-origin'), null);
});

serviceTest('the administrator API, webhooks and guest pages stay closed', async (h) => {
  for (const path of ['/v1/admin/worker/run', '/webhooks/twilio/status', '/p/x', '/m/x']) {
    const pre = await h.call('OPTIONS', path, {
      headers: { origin: boothOrigin, 'access-control-request-method': 'POST' },
    });
    await pre.body?.cancel();
    assert(pre.status !== 204, path);
    assertEquals(pre.headers.get('access-control-allow-origin'), null, path);
  }
  const worker = await h.call('POST', '/v1/admin/worker/run', {
    token: adminToken,
    headers: { origin: boothOrigin },
  });
  await worker.body?.cancel();
  assertEquals(worker.headers.get('access-control-allow-origin'), null);
});
