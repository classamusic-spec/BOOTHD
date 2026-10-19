// A local delivery service for the booth app's contract test
// (test/delivery/live_contract_test.dart): a fresh database, the stand-in
// for Twilio, storage in memory and a tenant that is ready to send. It
// prints one JSON line (its address, a pairing code and a control port)
// and serves until stopped. Nothing leaves this machine.
//
//   DELIVERY_TEST_DATABASE_URL=... deno run -A backend/tool/serve_local.ts
//
// The control port lets the test act as Twilio and the scheduler:
//   GET  /messages          the messages the stand-in received
//   POST /report            {sid, status}: a signed status callback
//   POST /worker            one worker pass

import { adminToken, json, postSigned, startHarness } from '../test/helpers/harness.ts';

const harness = await startHarness();
const tenant = await json(
  await harness.call('POST', '/v1/admin/tenants', {
    token: adminToken,
    json: {
      name: 'Local contract test',
      brandName: 'Porcelain Booth',
      privacyUrl: 'https://photos.example.test/privacy',
      termsUrl: 'https://photos.example.test/terms',
      supportContact: 'help@example.test',
    },
  }),
);
await (await harness.call('POST', `/v1/admin/tenants/${tenant.id}/attestations`, {
  token: adminToken,
  json: { registration: true, registrationReference: 'LOCAL-TEST-ONLY', legalReview: true },
})).body?.cancel();
await (await harness.call('PATCH', `/v1/admin/tenants/${tenant.id}`, {
  token: adminToken,
  json: { sendingEnabled: true },
})).body?.cancel();
const code = await json(
  await harness.call('POST', `/v1/admin/tenants/${tenant.id}/pairing-codes`, {
    token: adminToken,
  }),
);

const control = Deno.serve(
  { hostname: '127.0.0.1', port: 0, onListen: () => {} },
  async (request) => {
    const path = new URL(request.url).pathname;
    if (request.method === 'GET' && path === '/messages') {
      return Response.json(harness.twilio.messages.map((message) => ({
        sid: message.sid,
        to: message.to,
        body: message.body,
        mediaUrl: message.mediaUrl,
        media: message.media,
      })));
    }
    if (request.method === 'POST' && path === '/report') {
      const { sid, status } = await request.json() as { sid: string; status: string };
      const response = await postSigned(harness, '/webhooks/twilio/status', {
        AccountSid: harness.twilio.accountSid,
        MessageSid: sid,
        MessageStatus: status,
      });
      await response.body?.cancel();
      return new Response(null, { status: response.status });
    }
    if (request.method === 'POST' && path === '/worker') {
      const response = await harness.call('POST', '/v1/admin/worker/run', { token: adminToken });
      return new Response(await response.text(), { status: response.status });
    }
    return new Response('not found', { status: 404 });
  },
);

console.log(JSON.stringify({
  baseUrl: harness.baseUrl,
  pairingCode: code.code,
  controlUrl: `http://127.0.0.1:${control.addr.port}`,
}));

const stop = async () => {
  await control.shutdown();
  await harness.close();
  Deno.exit(0);
};
Deno.addSignalListener('SIGTERM', stop);
Deno.addSignalListener('SIGINT', stop);
