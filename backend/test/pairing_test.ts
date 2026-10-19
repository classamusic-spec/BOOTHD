// Booth pairing, credentials, access tokens, revocation and readiness
// (AC-0901, AC-0907, AC-0911).

import { assert, assertEquals, assertMatch } from './helpers/assert.ts';
import { adminToken, json, minutes, readyBooth, serviceTest } from './helpers/harness.ts';

serviceTest('a pairing code works once and gives a credential and tokens', async (h) => {
  const tenant = await json(
    await h.call('POST', '/v1/admin/tenants', {
      token: adminToken,
      json: {
        name: 'Studio',
        brandName: 'Porcelain Booth',
        privacyUrl: 'https://photos.example.test/privacy',
        termsUrl: 'https://photos.example.test/terms',
        supportContact: 'help@example.test',
      },
    }),
  );
  const issued = await json(
    await h.call('POST', `/v1/admin/tenants/${tenant.id}/pairing-codes`, {
      token: adminToken,
    }),
  );
  assertMatch(String(issued.code), /^[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}$/);
  const typed = String(issued.code).toLowerCase().replaceAll('-', ' ');
  const paired = await h.call('POST', '/v1/booths/pair', {
    json: { code: typed, boothName: 'Front entrance' },
  });
  assertEquals(paired.status, 201);
  const booth = await json(paired);
  assertMatch(String(booth.credential), /^[A-Za-z0-9_-]{43}$/);
  assertEquals(booth.brandName, 'Porcelain Booth');

  // Only hashes are stored.
  const [row] = await h.db.sql`select credential_hash from registered_booths where id = ${
    String(booth.boothId)
  }`;
  assert(row.credential_hash !== booth.credential);
  const [code] = await h.db.sql`select code_hash, used_at from pairing_codes`;
  assert(!String(code.code_hash).includes(String(issued.code)));
  assert(code.used_at);

  const again = await h.call('POST', '/v1/booths/pair', {
    json: { code: issued.code, boothName: 'Second' },
  });
  assertEquals(again.status, 400);
  assertEquals(((await json(again)).error as Record<string, unknown>).code, 'PAIRING_CODE_INVALID');

  const token = await json(
    await h.call('POST', '/v1/booths/token', { token: String(booth.credential) }),
  );
  assertMatch(String(token.accessToken), /^[A-Za-z0-9_-]{43}$/);
  const capabilities = await h.call('GET', '/v1/delivery/capabilities', {
    token: String(token.accessToken),
  });
  assertEquals(capabilities.status, 200);
  await capabilities.body?.cancel();
});

serviceTest('expired pairing codes and wrong credentials are refused', async (h) => {
  const tenant = await json(
    await h.call('POST', '/v1/admin/tenants', {
      token: adminToken,
      json: {
        name: 'Studio',
        brandName: 'Booth',
        privacyUrl: 'https://p.example.test/privacy',
        termsUrl: 'https://p.example.test/terms',
        supportContact: 'help@example.test',
      },
    }),
  );
  const issued = await json(
    await h.call('POST', `/v1/admin/tenants/${tenant.id}/pairing-codes`, {
      token: adminToken,
    }),
  );
  minutes(h, 31);
  const late = await h.call('POST', '/v1/booths/pair', {
    json: { code: issued.code, boothName: 'Late' },
  });
  assertEquals(late.status, 400);
  await late.body?.cancel();
  const forged = await h.call('POST', '/v1/booths/token', { token: 'x'.repeat(43) });
  assertEquals(forged.status, 401);
  await forged.body?.cancel();
  const noToken = await h.call('GET', '/v1/delivery/capabilities');
  assertEquals(noToken.status, 401);
  await noToken.body?.cancel();
  const badAdmin = await h.call('POST', '/v1/admin/tenants', { token: 'y'.repeat(43), json: {} });
  assertEquals(badAdmin.status, 401);
  await badAdmin.body?.cancel();
  // A booth's token is not an administrator's.
  const booth = await readyBooth(h);
  const asBooth = await h.call('POST', '/v1/admin/worker/run', { token: booth.accessToken });
  assertEquals(asBooth.status, 401);
  await asBooth.body?.cancel();
});

serviceTest('access tokens expire and a revoked booth is shut out at once', async (h) => {
  const booth = await readyBooth(h);
  minutes(h, 16);
  const expired = await h.call('GET', '/v1/delivery/capabilities', { token: booth.accessToken });
  assertEquals(expired.status, 401);
  await expired.body?.cancel();
  const fresh = await json(await h.call('POST', '/v1/booths/token', { token: booth.credential }));
  const revoke = await h.call('POST', `/v1/admin/booths/${booth.boothId}/revoke`, {
    token: adminToken,
  });
  assertEquals(revoke.status, 200);
  await revoke.body?.cancel();
  const after = await h.call('GET', '/v1/delivery/capabilities', {
    token: String(fresh.accessToken),
  });
  assertEquals(after.status, 401);
  await after.body?.cancel();
  const exchange = await h.call('POST', '/v1/booths/token', { token: booth.credential });
  assertEquals(exchange.status, 401);
  await exchange.body?.cancel();
});

serviceTest('a rotated credential replaces the old one after a short grace', async (h) => {
  const booth = await readyBooth(h);
  const rotated = await json(
    await h.call('POST', '/v1/booths/rotate', { token: booth.accessToken }),
  );
  const fresh = String(rotated.credential);
  assert(fresh !== booth.credential);
  const withNew = await h.call('POST', '/v1/booths/token', { token: fresh });
  assertEquals(withNew.status, 200);
  await withNew.body?.cancel();
  const withOld = await h.call('POST', '/v1/booths/token', { token: booth.credential });
  assertEquals(withOld.status, 200, 'the old credential still works briefly');
  await withOld.body?.cancel();
  minutes(h, 11);
  const late = await h.call('POST', '/v1/booths/token', { token: booth.credential });
  assertEquals(late.status, 401);
  await late.body?.cancel();
});

serviceTest('sending is off until every gate is open (AC-0901, AC-0911)', async (h) => {
  const booth = await readyBooth(h, { ready: false });
  const off = await json(
    await h.call('GET', '/v1/delivery/capabilities', { token: booth.accessToken }),
  );
  assertEquals(off.sending, {
    ready: false,
    reasons: ['REGISTRATION_NOT_ATTESTED', 'LEGAL_REVIEW_NOT_ATTESTED', 'SENDING_DISABLED'],
  });
  assertEquals(off.regions, ['US']);
  assertEquals(off.deliveryMode, 'mms_with_link');
  // Registration alone does not open it.
  await (await h.call('POST', `/v1/admin/tenants/${booth.tenantId}/attestations`, {
    token: adminToken,
    json: { registration: true, registrationReference: 'CAMPAIGN-1' },
  })).body?.cancel();
  await (await h.call('PATCH', `/v1/admin/tenants/${booth.tenantId}`, {
    token: adminToken,
    json: { sendingEnabled: true },
  })).body?.cancel();
  const partly = await json(
    await h.call('GET', '/v1/delivery/capabilities', { token: booth.accessToken }),
  );
  assertEquals((partly.sending as Record<string, unknown>).reasons, ['LEGAL_REVIEW_NOT_ATTESTED']);
  await (await h.call('POST', `/v1/admin/tenants/${booth.tenantId}/attestations`, {
    token: adminToken,
    json: { legalReview: true },
  })).body?.cancel();
  const ready = await h.call('GET', '/v1/delivery/capabilities', { token: booth.accessToken });
  const text = await ready.text();
  assertEquals((JSON.parse(text).sending as Record<string, unknown>).ready, true);
  // No secrets ever reach a booth.
  for (
    const secret of [
      h.deps.config.twilio!.authToken,
      h.deps.config.twilio!.apiKeySecret,
      h.deps.config.phoneKey,
      h.deps.config.digestKey,
      adminToken,
    ]
  ) {
    assert(!text.includes(secret));
  }
});

serviceTest('without provider settings nothing can be enabled to send', async (h) => {
  const booth = await readyBooth(h);
  const caps = await json(
    await h.call('GET', '/v1/delivery/capabilities', { token: booth.accessToken }),
  );
  assertEquals(caps.sending, { ready: false, reasons: ['PROVIDER_NOT_CONFIGURED'] });
}, { twilioConfigured: false });
