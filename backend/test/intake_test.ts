// Creating deliveries (AC-0902..AC-0904, AC-0907, AC-0916): consent,
// numbers, idempotency, suppression, quotas and staging restrictions.

import { assert, assertEquals, assertRejects } from './helpers/assert.ts';
import {
  adminToken,
  deliveryRequest,
  ids,
  json,
  postSigned,
  readyBooth,
  serviceTest,
} from './helpers/harness.ts';

async function errorCode(response: Response): Promise<string> {
  return String(((await json(response)).error as Record<string, unknown>).code);
}

async function jobCount(h: Parameters<Parameters<typeof serviceTest>[1]>[0]): Promise<number> {
  const [row] = await h.db.sql`select count(*)::int as n from delivery_jobs`;
  return Number(row.n);
}

serviceTest('no consent, no delivery (AC-0904)', async (h) => {
  const booth = await readyBooth(h);
  for (const consent of [{ accepted: false }, { accepted: 'true' }, { accepted: undefined }]) {
    const response = await h.call('POST', '/v1/deliveries', {
      token: booth.accessToken,
      json: deliveryRequest({}, consent),
    });
    assertEquals(response.status, 422);
    assertEquals(await errorCode(response), 'CONSENT_REQUIRED');
  }
  const missingVersion = await h.call('POST', '/v1/deliveries', {
    token: booth.accessToken,
    json: deliveryRequest({}, { textVersion: '' }),
  });
  assertEquals(missingVersion.status, 400);
  await missingVersion.body?.cancel();
  assertEquals(await jobCount(h), 0);
  assertEquals(h.twilio.requests, 0);
});

serviceTest('a delivery stores an immutable consent receipt and no readable number', async (h) => {
  const booth = await readyBooth(h);
  const request = deliveryRequest();
  const response = await h.call('POST', '/v1/deliveries', {
    token: booth.accessToken,
    json: request,
  });
  assertEquals(response.status, 201);
  const view = await json(response);
  assertEquals(view.state, 'created');
  assertEquals(view.status, 'queued');
  assertEquals(view.recipientLast4, '0147');
  const text = JSON.stringify(view);
  assert(!text.includes('2125550147'), 'the number never comes back');

  const [receipt] = await h.db.sql`select * from consent_receipts`;
  assertEquals(receipt.accepted, true);
  assertEquals(receipt.text_version, 'pd-consent-1');
  assertEquals(receipt.text_digest, 'a'.repeat(64));
  assertEquals(receipt.source_screen, 'S31');
  assertEquals(receipt.locale, 'en-US');
  assertEquals(receipt.event_id, ids.event);
  assertEquals(receipt.session_id, ids.session);
  await assertRejects(() => h.db.sql`update consent_receipts set accepted = true`);

  const rows = await h.db.sql`select * from delivery_jobs`;
  const all = JSON.stringify(rows) + JSON.stringify(await h.db.sql`select * from consent_receipts`);
  assert(!all.includes('2125550147'), 'stored only encrypted and as a keyed digest');
  assert(String(rows[0].recipient_ciphertext).startsWith('v1.'));
  // Expires 24 hours after consent (PD-01).
  const consentAt = new Date(String((request.consent as Record<string, unknown>).acceptedAt));
  assertEquals((rows[0].expires_at as Date).getTime() - consentAt.getTime(), 24 * 3600_000);
});

serviceTest(
  'numbers are checked: invalid, unsupported regions, old consent (AC-0903)',
  async (h) => {
    const booth = await readyBooth(h);
    const cases: [Record<string, unknown>, Record<string, unknown>, number, string][] = [
      [{ phone: '555-0147' }, {}, 422, 'PHONE_INVALID'],
      [{ phone: '+44 20 7946 0958' }, {}, 422, 'PHONE_REGION_UNSUPPORTED'],
      [{ phone: '+1 416 555 0147' }, {}, 422, 'PHONE_REGION_UNSUPPORTED'],
      [
        {},
        { acceptedAt: new Date(Date.now() - 25 * 3600_000).toISOString() },
        422,
        'CONSENT_EXPIRED',
      ],
      [
        {},
        { acceptedAt: new Date(Date.now() + 3600_000).toISOString() },
        422,
        'CONSENT_TIME_INVALID',
      ],
      [{ linkDays: 20 }, {}, 422, 'LINK_DAYS_TOO_LONG'],
    ];
    for (const [overrides, consent, status, code] of cases) {
      const response = await h.call('POST', '/v1/deliveries', {
        token: booth.accessToken,
        json: deliveryRequest(overrides, consent),
      });
      assertEquals(response.status, status, code);
      assertEquals(await errorCode(response), code);
    }
    assertEquals(await jobCount(h), 0);
  },
);

serviceTest('sending not ready: nothing is accepted', async (h) => {
  const booth = await readyBooth(h, { ready: false });
  const response = await h.call('POST', '/v1/deliveries', {
    token: booth.accessToken,
    json: deliveryRequest(),
  });
  assertEquals(response.status, 409);
  const body = await json(response);
  assertEquals((body.error as Record<string, unknown>).code, 'SENDING_NOT_READY');
  assertEquals(await jobCount(h), 0);
});

serviceTest(
  'a repeated request gets the same delivery; a reused key with other content is refused (AC-0915)',
  async (h) => {
    const booth = await readyBooth(h);
    const request = deliveryRequest();
    const first = await json(
      await h.call('POST', '/v1/deliveries', { token: booth.accessToken, json: request }),
    );
    const replay = await h.call('POST', '/v1/deliveries', {
      token: booth.accessToken,
      json: request,
    });
    assertEquals(replay.status, 200);
    assertEquals((await json(replay)).id, first.id);
    const reused = await h.call('POST', '/v1/deliveries', {
      token: booth.accessToken,
      json: { ...request, outputId: '44444444-4444-4444-8444-444444444444' },
    });
    assertEquals(reused.status, 409);
    assertEquals(await errorCode(reused), 'IDEMPOTENCY_KEY_REUSED');
    // A second submission of the same photo to the same number (a new key).
    const twice = await h.call('POST', '/v1/deliveries', {
      token: booth.accessToken,
      json: { ...request, idempotencyKey: crypto.randomUUID() },
    });
    assertEquals(twice.status, 409);
    const twiceBody = await json(twice);
    assertEquals((twiceBody.error as Record<string, unknown>).code, 'DUPLICATE_REQUEST');
    assertEquals((twiceBody.error as Record<string, unknown>).deliveryId, first.id);
    assertEquals(await jobCount(h), 1);
  },
);

serviceTest('STOP blocks later deliveries; START lifts it (AC-0914)', async (h) => {
  const booth = await readyBooth(h);
  const stop = await postSigned(h, '/webhooks/twilio/inbound', {
    AccountSid: h.twilio.accountSid,
    From: '+12125550147',
    To: '+12065550100',
    Body: 'Stop',
    MessageSid: `SM${'1'.repeat(32)}`,
  });
  assertEquals(stop.status, 200);
  assertEquals(await stop.text(), '<?xml version="1.0" encoding="UTF-8"?><Response></Response>');
  const refused = await h.call('POST', '/v1/deliveries', {
    token: booth.accessToken,
    json: deliveryRequest(),
  });
  assertEquals(refused.status, 403);
  assertEquals(await errorCode(refused), 'RECIPIENT_OPTED_OUT');
  // Another number is unaffected.
  const other = await h.call('POST', '/v1/deliveries', {
    token: booth.accessToken,
    json: deliveryRequest({ phone: '(206) 555-0100' }),
  });
  assertEquals(other.status, 201);
  await other.body?.cancel();
  await (await postSigned(h, '/webhooks/twilio/inbound', {
    AccountSid: h.twilio.accountSid,
    From: '+12125550147',
    To: '+12065550100',
    Body: 'START',
    MessageSid: `SM${'2'.repeat(32)}`,
  })).body?.cancel();
  const allowed = await h.call('POST', '/v1/deliveries', {
    token: booth.accessToken,
    json: deliveryRequest(),
  });
  assertEquals(allowed.status, 201);
  await allowed.body?.cancel();
});

serviceTest(
  'per-number, per-event, per-booth, daily and budget limits (AC-0907, AC-0916)',
  async (h) => {
    const booth = await readyBooth(h);
    const output = (n: number) => `33333333-3333-4333-8333-${String(n).padStart(12, '0')}`;
    for (let i = 0; i < 3; i++) {
      const ok = await h.call('POST', '/v1/deliveries', {
        token: booth.accessToken,
        json: deliveryRequest({ outputId: output(i) }),
      });
      assertEquals(ok.status, 201);
      await ok.body?.cancel();
    }
    const fourth = await h.call('POST', '/v1/deliveries', {
      token: booth.accessToken,
      json: deliveryRequest({ outputId: output(3) }),
    });
    assertEquals(fourth.status, 429);
    assertEquals(await errorCode(fourth), 'RECIPIENT_RATE_LIMITED');

    // The event's own cap (3 sent already).
    const event = await h.call('POST', '/v1/deliveries', {
      token: booth.accessToken,
      json: deliveryRequest({ outputId: output(4), phone: '(206) 555-0100', eventSendLimit: 3 }),
    });
    assertEquals(event.status, 429);
    assertEquals(await errorCode(event), 'EVENT_LIMIT');

    await h.db.sql`update registered_booths set daily_send_limit = 3`;
    const boothCap = await h.call('POST', '/v1/deliveries', {
      token: booth.accessToken,
      json: deliveryRequest({ outputId: output(5), phone: '(206) 555-0100' }),
    });
    assertEquals(boothCap.status, 429);
    assertEquals(await errorCode(boothCap), 'BOOTH_DAILY_LIMIT');

    await h.db.sql`update registered_booths set daily_send_limit = 100`;
    await (await h.call('PATCH', `/v1/admin/tenants/${booth.tenantId}`, {
      token: adminToken,
      json: { dailySendLimit: 3 },
    })).body?.cancel();
    const daily = await h.call('POST', '/v1/deliveries', {
      token: booth.accessToken,
      json: deliveryRequest({ outputId: output(6), phone: '(206) 555-0100' }),
    });
    assertEquals(daily.status, 429);
    assertEquals(await errorCode(daily), 'DAILY_LIMIT');

    // $0.10 a month at $0.032 a text: three texts fit, a fourth does not.
    await (await h.call('PATCH', `/v1/admin/tenants/${booth.tenantId}`, {
      token: adminToken,
      json: { dailySendLimit: 100, monthlyBudgetCents: 10 },
    })).body?.cancel();
    const budget = await h.call('POST', '/v1/deliveries', {
      token: booth.accessToken,
      json: deliveryRequest({ outputId: output(7), phone: '(206) 555-0100' }),
    });
    assertEquals(budget.status, 429);
    assertEquals(await errorCode(budget), 'BUDGET_REACHED');
  },
);

serviceTest('staging sends only to approved test numbers (AC-0921)', async (h) => {
  const booth = await readyBooth(h);
  const refused = await h.call('POST', '/v1/deliveries', {
    token: booth.accessToken,
    json: deliveryRequest(),
  });
  assertEquals(refused.status, 403);
  assertEquals(await errorCode(refused), 'RECIPIENT_NOT_APPROVED');
  const added = await h.call('POST', `/v1/admin/tenants/${booth.tenantId}/test-recipients`, {
    token: adminToken,
    json: { phone: '+1 212 555 0147', label: 'QA phone 1' },
  });
  assertEquals(added.status, 201);
  assertEquals((await json(added)).last4, '0147');
  const approved = await h.call('POST', '/v1/deliveries', {
    token: booth.accessToken,
    json: deliveryRequest(),
  });
  assertEquals(approved.status, 201);
  await approved.body?.cancel();
}, { environment: 'staging', publicBaseUrl: 'https://photos.staging.example.test' });

serviceTest('another booth cannot see or touch a delivery', async (h) => {
  const first = await readyBooth(h);
  const created = await json(
    await h.call('POST', '/v1/deliveries', {
      token: first.accessToken,
      json: deliveryRequest(),
    }),
  );
  const code = await json(
    await h.call('POST', `/v1/admin/tenants/${first.tenantId}/pairing-codes`, {
      token: adminToken,
    }),
  );
  const second = await json(
    await h.call('POST', '/v1/booths/pair', {
      json: { code: code.code, boothName: 'Second booth' },
    }),
  );
  const token = await json(
    await h.call('POST', '/v1/booths/token', { token: String(second.credential) }),
  );
  for (
    const [method, path] of [
      ['GET', `/v1/deliveries/${created.id}`],
      ['POST', `/v1/deliveries/${created.id}/cancel`],
      ['POST', `/v1/deliveries/${created.id}/commit`],
    ]
  ) {
    const response = await h.call(method, path, { token: String(token.accessToken) });
    assertEquals(response.status, 404, path);
    await response.body?.cancel();
  }
});
