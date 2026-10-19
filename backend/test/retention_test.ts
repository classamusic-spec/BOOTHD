// Retention (AC-0906, AC-0917, AC-0921): unsent deliveries expire 24 hours
// after consent with the number erased; sent ones are purged when their
// link expires, including the provider's media copy; rows go after the
// retention period; opt-outs stay.

import { assert, assertEquals } from './helpers/assert.ts';
import {
  deliveryRequest,
  jobRow,
  json,
  minutes,
  postSigned,
  readyBooth,
  runWorker,
  serviceTest,
  uploadedDelivery,
} from './helpers/harness.ts';

serviceTest('unsent deliveries expire after 24 hours and lose the number (AC-0906)', async (h) => {
  const booth = await readyBooth(h);
  const queued = String(
    (await json(
      await h.call('POST', '/v1/deliveries', {
        token: booth.accessToken,
        json: deliveryRequest(),
      }),
    )).id,
  );
  const uploaded = await uploadedDelivery(
    h,
    booth.accessToken,
    deliveryRequest({ phone: '(206) 555-0100' }),
  );
  assertEquals(h.store.objects.size, 2);
  minutes(h, 23 * 60);
  await runWorker(h);
  assertEquals((await jobRow(h, queued)).state, 'created', 'not yet');
  minutes(h, 61);
  const result = await runWorker(h);
  assertEquals((result.retention as Record<string, unknown>).expired, 2);
  for (const id of [queued, uploaded]) {
    const row = await jobRow(h, id);
    assertEquals(row.state, 'expired');
    assertEquals(row.failure_code, 'CONSENT_WINDOW_ENDED');
    assertEquals(row.recipient_ciphertext, null);
    assert(row.purged_at);
  }
  assertEquals(h.store.objects.size, 0);
  assertEquals(h.twilio.requests, 0, 'never sent late');
});

serviceTest(
  'sent deliveries are purged when the link expires, provider media too (AC-0917)',
  async (h) => {
    const booth = await readyBooth(h);
    const id = await uploadedDelivery(h, booth.accessToken);
    await (await h.call('POST', `/v1/deliveries/${id}/commit`, { token: booth.accessToken })).body
      ?.cancel();
    const sid = h.twilio.messages[0].sid;
    await (await postSigned(h, '/webhooks/twilio/status', {
      AccountSid: h.twilio.accountSid,
      MessageSid: sid,
      MessageStatus: 'delivered',
    })).body?.cancel();
    minutes(h, 6 * 24 * 60);
    await runWorker(h);
    assertEquals(h.store.objects.size, 2, 'kept while the link lives');
    minutes(h, 24 * 60 + 1);
    await runWorker(h);
    const row = await jobRow(h, id);
    assertEquals(row.state, 'delivered', 'the outcome stays recorded');
    assert(row.purged_at);
    assertEquals(row.recipient_ciphertext, null);
    assertEquals(row.recipient_last4, '0147');
    assertEquals(h.store.objects.size, 0);
    assertEquals(h.twilio.mediaDeletes, [sid]);
    const [audit] = await h.db.sql`select reason, provider_media from deletion_audit`;
    assertEquals(audit.reason, 'retention');
    assertEquals(audit.provider_media, 'deleted');
    // After the retention period the row goes; the opt-out list does not.
    await h.db.sql`insert into suppression_entries (recipient_digest, reason) values (${
      'c'.repeat(64)
    }, 'stop')`;
    minutes(h, 90 * 24 * 60);
    const token = String(
      (await json(await h.call('POST', '/v1/booths/token', { token: booth.credential })))
        .accessToken,
    );
    assert(token);
    const result = await runWorker(h);
    assertEquals((result.retention as Record<string, unknown>).rowsDeleted, 1);
    assertEquals((await h.db.sql`select count(*)::int as n from consent_receipts`)[0].n, 0);
    assertEquals((await h.db.sql`select count(*)::int as n from suppression_entries`)[0].n, 1);
  },
);

serviceTest('storage trouble during a purge is retried, never forgotten', async (h) => {
  const booth = await readyBooth(h);
  const id = await uploadedDelivery(h, booth.accessToken);
  await (await h.call('POST', `/v1/deliveries/${id}/commit`, { token: booth.accessToken })).body
    ?.cancel();
  minutes(h, 7 * 24 * 60 + 1);
  h.store.failing = true;
  const first = await runWorker(h);
  assertEquals((first.retention as Record<string, unknown>).incomplete, 1);
  assertEquals((await jobRow(h, id)).purged_at, null);
  h.store.failing = false;
  await runWorker(h);
  assert((await jobRow(h, id)).purged_at);
  assertEquals(h.store.objects.size, 0);
});
