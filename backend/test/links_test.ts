// The two kinds of link (AC-0909, AC-0910, AC-0917, AC-0919): the
// provider's short-lived preview fetch and the guest's download page.

import { assert, assertEquals, assertMatch, assertNotMatch } from './helpers/assert.ts';
import { sha256Hex } from '../supabase/functions/_shared/crypto.ts';
import {
  fixture,
  type Harness,
  minutes,
  readyBooth,
  serviceTest,
  uploadedDelivery,
} from './helpers/harness.ts';

async function sent(h: Harness) {
  const booth = await readyBooth(h);
  const id = await uploadedDelivery(h, booth.accessToken);
  await (await h.call('POST', `/v1/deliveries/${id}/commit`, { token: booth.accessToken })).body
    ?.cancel();
  const message = h.twilio.messages[0];
  const link = /\/p\/[A-Za-z0-9_-]{43}/.exec(message.body)![0];
  const media = new URL(message.mediaUrl).pathname;
  return { booth, id, link, media };
}

serviceTest(
  'the preview answers GET and HEAD with the right headers, then expires (AC-0909)',
  async (h) => {
    const { media } = await sent(h);
    for (const method of ['HEAD', 'GET']) {
      const response = await h.call(method, media);
      assertEquals(response.status, 200);
      assertEquals(response.headers.get('content-type'), 'image/jpeg');
      assertEquals(
        Number(response.headers.get('content-length')),
        (await fixture('preview_400x600.jpg')).length,
      );
      assertMatch(response.headers.get('content-disposition')!, /^inline/);
      assertMatch(response.headers.get('cache-control')!, /no-store/);
      assertMatch(response.headers.get('x-robots-tag')!, /noindex/);
      const bytes = new Uint8Array(await response.arrayBuffer());
      if (method === 'GET') {
        assertEquals(await sha256Hex(bytes), await sha256Hex(await fixture('preview_400x600.jpg')));
      } else {
        assertEquals(bytes.length, 0);
      }
    }
    minutes(h, 61);
    const late = await h.call('GET', media);
    assertEquals(late.status, 410);
    await late.body?.cancel();
    const unknown = await h.call('GET', `/m/${'A'.repeat(43)}`);
    assertEquals(unknown.status, 404);
    await unknown.body?.cancel();
  },
);

serviceTest(
  'the preview link never gives the finished photo, and the links are not interchangeable',
  async (h) => {
    const { link, media } = await sent(h);
    const mediaToken = media.split('/').pop()!;
    const linkToken = link.split('/').pop()!;
    const crossed = await h.call('GET', `/p/${mediaToken}`);
    assertEquals(crossed.status, 404);
    await crossed.body?.cancel();
    const crossedBack = await h.call('GET', `/m/${linkToken}`);
    assertEquals(crossedBack.status, 404);
    await crossedBack.body?.cancel();
    const download = await h.call('GET', `/p/${mediaToken}/download`);
    assertEquals(download.status, 404);
    await download.body?.cancel();
  },
);

serviceTest('the download page is private, unindexed and honest (AC-0910, AC-0919)', async (h) => {
  const { link } = await sent(h);
  const page = await h.call('GET', link);
  assertEquals(page.status, 200);
  assertMatch(page.headers.get('content-type')!, /^text\/html/);
  assertMatch(page.headers.get('content-security-policy')!, /default-src 'none'/);
  assertMatch(page.headers.get('x-robots-tag')!, /noindex/);
  assertEquals(page.headers.get('referrer-policy'), 'no-referrer');
  assertMatch(page.headers.get('cache-control')!, /no-store/);
  assertEquals(page.headers.get('x-frame-options'), 'DENY');
  const html = await page.text();
  assertMatch(html, /<meta name="robots" content="noindex, nofollow, noarchive">/);
  assertMatch(html, /<meta name="referrer" content="no-referrer">/);
  assertMatch(html, /Your photos from Garden Wedding/);
  assertMatch(html, /Download full quality/);
  assertMatch(html, /Available until /);
  assertMatch(html, /Anyone who has this link can see and download these photos/);
  assertMatch(html, /help@example\.test/);
  assertNotMatch(html, /<script/i);
  // Nothing loads from anywhere else; the only absolute links are the
  // operator's own privacy and terms pages.
  const absolute = [...html.matchAll(/(?:src|href)="(https?:[^"]+)"/g)].map((match) => match[1]);
  assertEquals(absolute.sort(), [
    'https://photos.example.test/privacy',
    'https://photos.example.test/terms',
  ]);
  assert(!html.includes('2125550147'));
  const token = link.split('/').pop()!;
  const preview = await h.call('GET', `/p/${token}/preview.jpg`);
  assertEquals(preview.headers.get('content-type'), 'image/jpeg');
  assertEquals(
    await sha256Hex(new Uint8Array(await preview.arrayBuffer())),
    await sha256Hex(await fixture('preview_400x600.jpg')),
  );
});

serviceTest(
  'the full-quality file is the exact finished photo, as an attachment (AC-0912 host part)',
  async (h) => {
    const { link } = await sent(h);
    const download = await h.call('GET', `${link}/download`);
    assertEquals(download.status, 200);
    assertEquals(download.headers.get('content-type'), 'image/jpeg');
    assertMatch(
      download.headers.get('content-disposition')!,
      /^attachment; filename="garden-wedding-photo\.jpg"$/,
    );
    const bytes = new Uint8Array(await download.arrayBuffer());
    assertEquals(await sha256Hex(bytes), await sha256Hex(await fixture('final_1200x1800.jpg')));
    const [grant] = await h.db.sql`select access_count from access_grants where kind = 'download'`;
    assertEquals(grant.access_count, 1);
  },
);

serviceTest(
  'expired, revoked, deleted and used-up links get honest pages (AC-0917, AC-0919)',
  async (h) => {
    const { booth, id, link } = await sent(h);
    await h.db.sql`update access_grants set max_access = 1 where kind = 'download'`;
    await (await h.call('GET', `${link}/download`)).body?.cancel();
    const usedUp = await h.call('GET', link);
    assertEquals(usedUp.status, 410);
    assertMatch(await usedUp.text(), /used up/);
    await h.db.sql`update access_grants set max_access = 200 where kind = 'download'`;

    const revoke = await h.call('POST', `/v1/deliveries/${id}/revoke`, {
      token: booth.accessToken,
    });
    assertEquals(revoke.status, 200);
    await revoke.body?.cancel();
    const gone = await h.call('GET', link);
    assertEquals(gone.status, 410);
    const text = await gone.text();
    assertMatch(text, /deleted|turned off/);
    assert(!text.includes('Garden Wedding'), 'says nothing about the event');
    assertEquals(h.store.objects.size, 0, 'hosted files deleted');
    assertEquals(h.twilio.mediaDeletes, [h.twilio.messages[0].sid], 'provider media deleted');
    const [audit] = await h.db
      .sql`select reason, provider_media, objects_deleted from deletion_audit`;
    assertEquals(audit.reason, 'revoked');
    assertEquals(audit.provider_media, 'deleted');
    assertEquals(audit.objects_deleted, 2);
    const file = await h.call('GET', `${link}/download`);
    assertEquals(file.status, 410);
    await file.body?.cancel();
  },
);

serviceTest('a link expires after its days (AC-0910)', async (h) => {
  const { link } = await sent(h);
  minutes(h, 7 * 24 * 60 - 5);
  const before = await h.call('GET', link);
  assertEquals(before.status, 200);
  await before.body?.cancel();
  minutes(h, 10);
  const after = await h.call('GET', link);
  assertEquals(after.status, 410);
  assertMatch(await after.text(), /expired/);
  const missing = await h.call('GET', `/p/${'B'.repeat(43)}`);
  assertEquals(missing.status, 404);
  assertMatch(await missing.text(), /Link not found/);
  const malformed = await h.call('GET', '/p/short');
  assertEquals(malformed.status, 404);
  await malformed.body?.cancel();
});

serviceTest('the page is rate limited per network (AC-0910)', async (h) => {
  const { link } = await sent(h);
  let limited = 0;
  for (let i = 0; i < 125; i++) {
    const response = await h.call('GET', link, { headers: { 'x-forwarded-for': '203.0.113.9' } });
    if (response.status === 429) limited++;
    await response.body?.cancel();
  }
  assert(limited >= 5);
  const other = await h.call('GET', link, { headers: { 'x-forwarded-for': '198.51.100.7' } });
  assertEquals(other.status, 200);
  await other.body?.cancel();
  const counters = await h.db.sql`select key from rate_counters where key like 'page:%'`;
  assert(
    counters.every((row) => !String(row.key).includes('203.0.113.9')),
    'addresses stored hashed',
  );
});

serviceTest('search engines are told to stay away', async (h) => {
  const robots = await h.call('GET', '/robots.txt');
  assertEquals(await robots.text(), 'User-agent: *\nDisallow: /\n');
});
