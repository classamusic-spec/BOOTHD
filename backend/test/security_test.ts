// Security checks across the service (AC-0907, AC-0910, AC-0918): the
// database denies the public roles, nothing readable about a guest is
// stored or logged, and errors never echo secrets.

import { assert, assertEquals } from './helpers/assert.ts';
import { sha256Hex } from '../supabase/functions/_shared/crypto.ts';
import { json, postSigned, readyBooth, serviceTest, uploadedDelivery } from './helpers/harness.ts';

serviceTest(
  'row-level security is on everywhere and the public roles have no access',
  async (h) => {
    const tables = await h.db.sql`select c.relname, c.relrowsecurity
    from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r'`;
    assert(tables.length >= 15);
    for (const table of tables) {
      assertEquals(table.relrowsecurity, true, String(table.relname));
      for (const role of ['anon', 'authenticated']) {
        for (const privilege of ['select', 'insert', 'update', 'delete']) {
          const [row] = await h.db
            .sql`select has_table_privilege(${role}, ${`public.${table.relname}`}, ${privilege}) as ok`;
          assertEquals(row.ok, false, `${role} ${privilege} ${table.relname}`);
        }
      }
    }
    const policies = await h.db
      .sql`select count(*)::int as n from pg_policies where schemaname = 'public'`;
    assertEquals(policies[0].n, 0, 'no policies: deny by default');
  },
);

serviceTest(
  'a full delivery leaves no number, token or credential in the logs or tables (AC-0918)',
  async (h) => {
    const booth = await readyBooth(h);
    const id = await uploadedDelivery(h, booth.accessToken);
    await (await h.call('POST', `/v1/deliveries/${id}/commit`, { token: booth.accessToken })).body
      ?.cancel();
    const message = h.twilio.messages[0];
    await (await postSigned(h, '/webhooks/twilio/status', {
      AccountSid: h.twilio.accountSid,
      MessageSid: message.sid,
      MessageStatus: 'delivered',
      To: message.to,
    })).body?.cancel();
    const link = /\/p\/([A-Za-z0-9_-]{43})/.exec(message.body)![1];
    const media = /\/m\/([A-Za-z0-9_-]{43})/.exec(message.mediaUrl)![1];
    await (await h.call('GET', `/p/${link}`)).body?.cancel();
    await (await h.call('GET', `/p/${link}/download`)).body?.cancel();
    await (await h.call('GET', `/m/${media}`)).body?.cancel();
    const secrets = [
      '2125550147',
      '212-555-0147',
      link,
      media,
      booth.credential,
      booth.accessToken,
      h.deps.config.phoneKey,
    ];
    const logs = h.logs.join('\n');
    assert(h.logs.length > 10);
    for (const secret of secrets) assert(!logs.includes(secret), `log leaks ${secret.slice(0, 6)}`);
    const dump = JSON.stringify(await h.db.sql`select * from delivery_jobs`) +
      JSON.stringify(await h.db.sql`select * from consent_receipts`) +
      JSON.stringify(await h.db.sql`select * from access_grants`) +
      JSON.stringify(await h.db.sql`select * from registered_booths`) +
      JSON.stringify(await h.db.sql`select * from booth_access_tokens`) +
      JSON.stringify(await h.db.sql`select * from provider_events`);
    for (const secret of secrets) {
      assert(
        !dump.includes(secret),
        `table leaks ${secret.slice(0, 6)}`,
      );
    }
    // What is stored instead: hashes.
    assert(dump.includes(await sha256Hex(link)));
  },
);

serviceTest('unexpected errors answer with a code only', async (h) => {
  const booth = await readyBooth(h);
  await h.db.sql`alter table delivery_jobs rename to delivery_jobs_gone`;
  await h.db.sql`alter table access_grants rename to access_grants_gone`;
  const response = await h.call('GET', `/v1/deliveries/${crypto.randomUUID()}`, {
    token: booth.accessToken,
  });
  assertEquals(response.status, 500);
  assertEquals(await json(response), { error: { code: 'INTERNAL' } });
  const page = await h.call('GET', `/p/${'C'.repeat(43)}`);
  assertEquals(page.status, 503);
  assert((await page.text()).includes('Temporarily unavailable'));
  await h.db.sql`alter table delivery_jobs_gone rename to delivery_jobs`;
  await h.db.sql`alter table access_grants_gone rename to access_grants`;
  assert(h.logs.some((line) => line.includes('request.failed')));
  assert(!h.logs.join('\n').includes('_gone'), 'no error text in logs');
});

serviceTest('requests are bounded and methods checked', async (h) => {
  const big = await h.call('POST', '/v1/booths/pair', {
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ code: 'x'.repeat(40_000) }),
  });
  assertEquals(big.status, 413);
  await big.body?.cancel();
  const wrong = await h.call('DELETE', '/v1/deliveries');
  assertEquals(wrong.status, 405);
  await wrong.body?.cancel();
  const text = await h.call('POST', '/v1/booths/pair', {
    headers: { 'content-type': 'text/plain' },
    body: 'hello',
  });
  assertEquals(text.status, 415);
  await text.body?.cancel();
  let limited = false;
  for (let i = 0; i < 12; i++) {
    const response = await h.call('POST', '/v1/booths/pair', {
      json: { code: 'AAAA-BBBB-CCCC', boothName: 'x' },
    });
    if (response.status === 429) limited = true;
    await response.body?.cancel();
  }
  assert(limited, 'pairing attempts are rate limited');
});
