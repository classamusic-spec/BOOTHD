// Twilio webhooks (AC-0913, AC-0914, AC-0918): signatures checked with the
// official library, idempotent, forward-only status changes.

import { assert, assertEquals } from './helpers/assert.ts';
import {
  deliveryRequest,
  type Harness,
  jobRow,
  json,
  postSigned,
  readyBooth,
  runWorker,
  serviceTest,
  sign,
  uploadedDelivery,
} from './helpers/harness.ts';

async function sentDelivery(h: Harness) {
  const booth = await readyBooth(h);
  const id = await uploadedDelivery(h, booth.accessToken);
  await (await h.call('POST', `/v1/deliveries/${id}/commit`, { token: booth.accessToken })).body
    ?.cancel();
  return { booth, id, sid: h.twilio.messages[0].sid };
}

function status(h: Harness, sid: string, value: string, extra: Record<string, string> = {}) {
  return postSigned(h, '/webhooks/twilio/status', {
    AccountSid: h.twilio.accountSid,
    MessageSid: sid,
    MessageStatus: value,
    To: '+12125550147',
    ...extra,
  });
}

serviceTest(
  'status reports move the delivery forward; only delivered is delivered (AC-0913)',
  async (h) => {
    const { booth, id, sid } = await sentDelivery(h);
    const view = async () =>
      await json(await h.call('GET', `/v1/deliveries/${id}`, { token: booth.accessToken }));
    assertEquals((await view()).status, 'submitted');
    assertEquals((await status(h, sid, 'queued')).status, 204);
    assertEquals((await view()).status, 'submitted');
    assertEquals((await status(h, sid, 'sent')).status, 204);
    assertEquals((await view()).status, 'sent');
    assertEquals((await status(h, sid, 'delivered')).status, 204);
    const delivered = await view();
    assertEquals(delivered.status, 'delivered');
    // Late and repeated reports change nothing.
    await (await status(h, sid, 'sent')).body?.cancel();
    await (await status(h, sid, 'delivered')).body?.cancel();
    await (await status(h, sid, 'failed', { ErrorCode: '30003' })).body?.cancel();
    const final = await view();
    assertEquals(final.status, 'delivered');
    const history = (final.history as Record<string, unknown>[]).map((entry) => entry.status);
    assertEquals(history, [
      'queued',
      'uploading',
      'submitting',
      'submitting',
      'submitted',
      'sent',
      'delivered',
    ]);
    const events = await h.db.sql`select status from provider_events order by id`;
    assertEquals(events.map((event) => event.status), ['queued', 'sent', 'delivered', 'failed']);
  },
);

serviceTest('undelivered and failed end the delivery and take its link down', async (h) => {
  const { id, sid } = await sentDelivery(h);
  await (await status(h, sid, 'sent')).body?.cancel();
  await (await status(h, sid, 'undelivered', { ErrorCode: '30005' })).body?.cancel();
  const row = await jobRow(h, id);
  assertEquals(row.state, 'failed_permanent');
  assertEquals(row.failure_code, 'PROVIDER_ERROR_30005');
  const live = await h.db
    .sql`select 1 from access_grants where job_id = ${id} and revoked_at is null`;
  assertEquals(live.length, 0);
  assertEquals(h.store.objects.size, 0);
});

serviceTest('unsigned, tampered or foreign webhooks are refused (AC-0918)', async (h) => {
  const { id, sid } = await sentDelivery(h);
  const params = {
    AccountSid: h.twilio.accountSid,
    MessageSid: sid,
    MessageStatus: 'delivered',
  };
  const missing = await postSigned(h, '/webhooks/twilio/status', params, '');
  assertEquals(missing.status, 403);
  await missing.body?.cancel();
  const signature = sign(h, '/webhooks/twilio/status', params);
  const tampered = await postSigned(h, '/webhooks/twilio/status', {
    ...params,
    MessageStatus: 'read',
  }, signature);
  assertEquals(tampered.status, 403);
  await tampered.body?.cancel();
  const wrongUrl = await postSigned(
    h,
    '/webhooks/twilio/status',
    params,
    sign(h, '/webhooks/twilio/inbound', params),
  );
  assertEquals(wrongUrl.status, 403);
  await wrongUrl.body?.cancel();
  const foreign = await postSigned(h, '/webhooks/twilio/status', {
    ...params,
    AccountSid: `AC${'f'.repeat(32)}`,
  });
  assertEquals(foreign.status, 403);
  await foreign.body?.cancel();
  const inbound = await postSigned(h, '/webhooks/twilio/inbound', {
    AccountSid: h.twilio.accountSid,
    From: '+12125550147',
    Body: 'STOP',
  }, 'forged');
  assertEquals(inbound.status, 403);
  await inbound.body?.cancel();
  assertEquals((await jobRow(h, id)).state, 'provider_accepted');
  assertEquals((await h.db.sql`select count(*)::int as n from provider_events`)[0].n, 0);
  assertEquals((await h.db.sql`select count(*)::int as n from suppression_entries`)[0].n, 0);
  assert(h.logs.some((line) => line.includes('webhook.signature_rejected')));
});

serviceTest('a report that arrives before its message is recorded is applied later', async (h) => {
  const booth = await readyBooth(h);
  const id = await uploadedDelivery(h, booth.accessToken);
  h.twilio.modes.push('server_error_created');
  await (await h.call('POST', `/v1/deliveries/${id}/commit`, { token: booth.accessToken })).body
    ?.cancel();
  const sid = h.twilio.messages[0].sid;
  // Delivered is reported while the job still does not know its message.
  await (await status(h, sid, 'delivered')).body?.cancel();
  assertEquals((await jobRow(h, id)).state, 'delivery_unknown');
  h.clock.now = new Date(h.clock.now.getTime() + 3 * 60_000);
  await runWorker(h);
  assertEquals((await jobRow(h, id)).state, 'delivered');
});

serviceTest(
  "STOP ends a number's unsent deliveries; HELP gets no reply from us (AC-0914)",
  async (h) => {
    const booth = await readyBooth(h);
    const waiting = await uploadedDelivery(h, booth.accessToken);
    const help = await postSigned(h, '/webhooks/twilio/inbound', {
      AccountSid: h.twilio.accountSid,
      From: '+12125550147',
      Body: 'help',
    });
    assertEquals(help.status, 200);
    assertEquals(await help.text(), '<?xml version="1.0" encoding="UTF-8"?><Response></Response>');
    assertEquals((await jobRow(h, waiting)).state, 'uploading');
    const stop = await postSigned(h, '/webhooks/twilio/inbound', {
      AccountSid: h.twilio.accountSid,
      From: '+12125550147',
      Body: 'Unsubscribe please',
      OptOutType: 'STOP',
    });
    assertEquals(stop.status, 200);
    await stop.body?.cancel();
    const row = await jobRow(h, waiting);
    assertEquals(row.state, 'failed_permanent');
    assertEquals(row.failure_code, 'RECIPIENT_OPTED_OUT');
    const commit = await json(
      await h.call('POST', `/v1/deliveries/${waiting}/commit`, { token: booth.accessToken }),
    );
    assertEquals(commit.state, 'failed_permanent');
    assertEquals(h.twilio.requests, 0, 'nothing is sent after STOP');
    // Duplicate STOPs are harmless.
    await (await postSigned(h, '/webhooks/twilio/inbound', {
      AccountSid: h.twilio.accountSid,
      From: '+12125550147',
      Body: 'STOP',
    })).body?.cancel();
    assertEquals((await h.db.sql`select count(*)::int as n from suppression_entries`)[0].n, 1);
    const refused = await h.call('POST', '/v1/deliveries', {
      token: booth.accessToken,
      json: deliveryRequest({ outputId: '44444444-4444-4444-8444-444444444444' }),
    });
    assertEquals(refused.status, 403);
    await refused.body?.cancel();
  },
);
