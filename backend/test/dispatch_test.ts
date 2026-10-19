// Uploads, commit and dispatch (AC-0908, AC-0909, AC-0913, AC-0915,
// AC-0916): only the two declared images, verified; one message per
// delivery; safe retries; ambiguous submissions reconciled, never re-sent
// blindly.

import { assert, assertEquals, assertMatch, assertNotEquals } from './helpers/assert.ts';
import { sha256Hex } from '../supabase/functions/_shared/crypto.ts';
import {
  deliveryRequest,
  fixture,
  type Harness,
  jobRow,
  json,
  minutes,
  readyBooth,
  runWorker,
  serviceTest,
  uploadedDelivery,
} from './helpers/harness.ts';

async function errorCode(response: Response): Promise<string> {
  return String(((await json(response)).error as Record<string, unknown>).code);
}

async function created(h: Harness, token: string): Promise<string> {
  const response = await h.call('POST', '/v1/deliveries', { token, json: deliveryRequest() });
  return String((await json(response)).id);
}

async function init(
  h: Harness,
  token: string,
  id: string,
  overrides: Record<string, unknown> = {},
) {
  const final = await fixture('final_1200x1800.jpg');
  const preview = await fixture('preview_400x600.jpg');
  return await h.call('POST', `/v1/deliveries/${id}/upload-init`, {
    token,
    json: {
      final: {
        format: 'jpeg',
        bytes: final.length,
        sha256: await sha256Hex(final),
        width: 1200,
        height: 1800,
      },
      preview: { bytes: preview.length, sha256: await sha256Hex(preview), width: 400, height: 600 },
      ...overrides,
    },
  });
}

async function commit(h: Harness, token: string, id: string) {
  return await json(await h.call('POST', `/v1/deliveries/${id}/commit`, { token }));
}

serviceTest(
  'exactly two upload grants: the finished photo and its preview (AC-0908)',
  async (h) => {
    const booth = await readyBooth(h);
    const id = await created(h, booth.accessToken);
    const response = await init(h, booth.accessToken, id, { original: { bytes: 1 } });
    assertEquals(response.status, 200);
    const body = await json(response);
    const uploads = body.uploads as Record<string, unknown>[];
    assertEquals(uploads.map((upload) => upload.kind), ['final', 'preview']);
    for (const upload of uploads) {
      assertMatch(String(upload.url), /\/v1\/uploads\/[A-Za-z0-9_-]{43}$/);
      assertEquals(upload.method, 'PUT');
    }
    assertNotEquals(uploads[0].url, uploads[1].url);
    // Only hashes are stored.
    const grants = await h.db.sql`select token_hash from upload_grants`;
    for (const grant of grants) {
      assert(!uploads.some((upload) => String(upload.url).includes(String(grant.token_hash))));
    }
  },
);

serviceTest('uploads must match what was declared, byte for byte (AC-0908)', async (h) => {
  const booth = await readyBooth(h);
  const id = await created(h, booth.accessToken);
  const final = await fixture('final_1200x1800.jpg');
  const png = await fixture('final_1200x1800.png');
  const preview = await fixture('preview_400x600.jpg');

  const tooBig = await init(h, booth.accessToken, id, {
    preview: { bytes: 700_000, sha256: 'b'.repeat(64), width: 400, height: 600 },
  });
  assertEquals(tooBig.status, 422);
  assertEquals(await errorCode(tooBig), 'PREVIEW_TOO_LARGE');

  // Declared as the JPEG; something else is sent.
  let grants = (await json(await init(h, booth.accessToken, id))).uploads as Record<
    string,
    string
  >[];
  const put = (url: string, body: Uint8Array<ArrayBuffer>) =>
    fetch(url, { method: 'PUT', headers: { 'content-type': 'image/jpeg' }, body });
  const larger = new Uint8Array(final.length + 10);
  larger.set(final);
  let response = await put(grants[0].url, larger);
  assertEquals(response.status, 413, 'larger than declared');
  await response.body?.cancel();
  response = await put(grants[0].url, png);
  assertEquals(response.status, 422, 'not the declared length');
  assertEquals(await errorCode(response), 'UPLOAD_SIZE_MISMATCH');
  const corrupted = final.slice();
  corrupted[5000] ^= 0xff;
  response = await put(grants[0].url, corrupted);
  assertEquals(response.status, 422);
  assertEquals(await errorCode(response), 'UPLOAD_CHECKSUM_MISMATCH');

  // A truncated file, declared honestly, is still refused.
  const truncated = final.slice(0, final.length - 400);
  await (await init(h, booth.accessToken, id, {
    final: {
      format: 'jpeg',
      bytes: truncated.length,
      sha256: await sha256Hex(truncated),
      width: 1200,
      height: 1800,
    },
  })).body?.cancel();
  grants = (await json(
    await init(h, booth.accessToken, id, {
      final: {
        format: 'jpeg',
        bytes: truncated.length,
        sha256: await sha256Hex(truncated),
        width: 1200,
        height: 1800,
      },
    }),
  )).uploads as Record<string, string>[];
  response = await put(grants[0].url, truncated);
  assertEquals(response.status, 422);
  assertEquals(await errorCode(response), 'UPLOAD_TRUNCATED');

  // Wrong pixel size declared.
  grants = (await json(
    await init(h, booth.accessToken, id, {
      final: {
        format: 'jpeg',
        bytes: final.length,
        sha256: await sha256Hex(final),
        width: 1800,
        height: 1200,
      },
      preview: { bytes: preview.length, sha256: await sha256Hex(preview), width: 400, height: 600 },
    }),
  )).uploads as Record<string, string>[];
  response = await put(grants[0].url, final);
  assertEquals(response.status, 422);
  assertEquals(await errorCode(response), 'UPLOAD_DIMENSIONS_MISMATCH');

  // A PNG declared as a JPEG.
  grants = (await json(
    await init(h, booth.accessToken, id, {
      final: {
        format: 'jpeg',
        bytes: png.length,
        sha256: await sha256Hex(png),
        width: 1200,
        height: 1800,
      },
    }),
  )).uploads as Record<string, string>[];
  response = await put(grants[0].url, png);
  assertEquals(response.status, 422);
  assertEquals(await errorCode(response), 'UPLOAD_TYPE_MISMATCH');

  // Not an image at all.
  const text = new TextEncoder().encode('x'.repeat(2000));
  grants = (await json(
    await init(h, booth.accessToken, id, {
      final: {
        format: 'jpeg',
        bytes: text.length,
        sha256: await sha256Hex(text),
        width: 1200,
        height: 1800,
      },
    }),
  )).uploads as Record<string, string>[];
  response = await put(grants[0].url, text);
  assertEquals(response.status, 422);
  assertEquals(await errorCode(response), 'UPLOAD_NOT_IMAGE');

  // The real files go; a grant works once; nothing was stored for the rest.
  grants = (await json(await init(h, booth.accessToken, id))).uploads as Record<string, string>[];
  assertEquals((await put(grants[0].url, final)).status, 201);
  const again = await put(grants[0].url, final);
  assertEquals(again.status, 409);
  assertEquals(await errorCode(again), 'UPLOAD_GRANT_USED');
  assertEquals((await put(grants[1].url, preview)).status, 201);
  assertEquals([...h.store.objects.keys()].sort(), [`final/${id}.jpg`, `preview/${id}.jpg`]);
  assertEquals(
    await sha256Hex(h.store.objects.get(`final/${id}.jpg`)!.bytes),
    await sha256Hex(final),
  );
  assertEquals(h.twilio.requests, 0, 'uploading sends nothing');
});

serviceTest('upload grants expire and commit needs both images', async (h) => {
  const booth = await readyBooth(h);
  const id = await created(h, booth.accessToken);
  const early = await h.call('POST', `/v1/deliveries/${id}/commit`, { token: booth.accessToken });
  assertEquals(early.status, 409);
  assertEquals(await errorCode(early), 'UPLOAD_INCOMPLETE');
  const grants = (await json(await init(h, booth.accessToken, id))).uploads as Record<
    string,
    string
  >[];
  minutes(h, 16);
  const late = await fetch(grants[0].url, {
    method: 'PUT',
    body: await fixture('final_1200x1800.jpg'),
  });
  assertEquals(late.status, 410);
  await late.body?.cancel();
  assertEquals(h.twilio.requests, 0);
});

serviceTest(
  'commit sends one MMS: preview link and download link differ (AC-0909, AC-0913)',
  async (h) => {
    const booth = await readyBooth(h);
    const id = await uploadedDelivery(h, booth.accessToken);
    const view = await commit(h, booth.accessToken, id);
    assertEquals(view.state, 'provider_accepted');
    assertEquals(view.status, 'submitted', 'accepted is not delivered');
    assertEquals(h.twilio.messages.length, 1);
    const message = h.twilio.messages[0];
    assertEquals(message.to, '+12125550147');
    assertMatch(message.body, /^Porcelain Booth: Your photos from Garden Wedding are ready: /);
    assertMatch(message.body, /\(available for 7 days\)\. Reply STOP to opt out, HELP for help\.$/);
    const link = /\/p\/([A-Za-z0-9_-]{43})/.exec(message.body)![1];
    const media = /\/m\/([A-Za-z0-9_-]{43})$/.exec(message.mediaUrl)![1];
    assertNotEquals(link, media);
    assertEquals(message.statusCallback, `${h.baseUrl}/webhooks/twilio/status`);
    // Twilio's fetch of the preview: HEAD and GET, a JPEG of the preview's size.
    assertEquals(message.media.head, 200);
    assertEquals(message.media.get, 200);
    assertEquals(message.media.contentType, 'image/jpeg');
    assertEquals(message.media.bytes, (await fixture('preview_400x600.jpg')).length);
    // A second commit (a retry after a lost answer) sends nothing more.
    const again = await commit(h, booth.accessToken, id);
    assertEquals(again.state, 'provider_accepted');
    await runWorker(h);
    assertEquals(h.twilio.requests, 1);
    const row = await jobRow(h, id);
    assertEquals(row.provider_message_sid, message.sid);
    assertEquals(row.attempts, 1);
  },
);

serviceTest(
  'a provider rate limit is retried safely; one message results (AC-0915, AC-0916)',
  async (h) => {
    const booth = await readyBooth(h);
    const id = await uploadedDelivery(h, booth.accessToken);
    h.twilio.modes.push('rate_limit');
    const view = await commit(h, booth.accessToken, id);
    assertEquals(view.state, 'failed_retryable');
    assertEquals(view.status, 'submitting');
    const firstGrants = await h.db.sql`select revoked_at from access_grants where job_id = ${id}`;
    assertEquals(firstGrants.length, 2);
    assert(firstGrants.every((grant) => grant.revoked_at), 'the unsent links are revoked');
    await runWorker(h);
    assertEquals(h.twilio.requests, 1, 'not before the backoff');
    minutes(h, 1);
    await runWorker(h);
    assertEquals(h.twilio.requests, 2);
    assertEquals(h.twilio.messages.length, 1);
    assertEquals((await jobRow(h, id)).state, 'provider_accepted');
  },
);

serviceTest(
  'a definite rejection ends the delivery; an unsubscribed number is suppressed',
  async (h) => {
    const booth = await readyBooth(h);
    const id = await uploadedDelivery(h, booth.accessToken);
    h.twilio.modes.push({ reject: '21610' });
    const view = await commit(h, booth.accessToken, id);
    assertEquals(view.state, 'failed_permanent');
    assertEquals(view.failureCode, 'RECIPIENT_OPTED_OUT');
    assertEquals((await h.db.sql`select reason from suppression_entries`)[0].reason, 'stop');
    const row = await jobRow(h, id);
    assertEquals(row.recipient_ciphertext, null, 'the number is erased');
    assertEquals(h.store.objects.size, 0, 'hosted images deleted');
    await runWorker(h);
    assertEquals(h.twilio.requests, 1);

    const second = await uploadedDelivery(
      h,
      booth.accessToken,
      deliveryRequest({ phone: '(206) 555-0100' }),
    );
    h.twilio.modes.push({ reject: '21211' });
    assertEquals(
      (await commit(h, booth.accessToken, second)).failureCode,
      'PROVIDER_INVALID_NUMBER',
    );
  },
);

serviceTest('an ambiguous submission is reconciled, not re-sent (AC-0915)', async (h) => {
  const booth = await readyBooth(h);
  const id = await uploadedDelivery(h, booth.accessToken);
  h.twilio.modes.push('server_error_created');
  const view = await commit(h, booth.accessToken, id);
  assertEquals(view.state, 'delivery_unknown');
  assertEquals(view.status, 'unknown');
  await runWorker(h);
  assertEquals(h.twilio.requests, 1, 'never retried blindly');
  minutes(h, 3);
  await runWorker(h);
  const row = await jobRow(h, id);
  assertEquals(row.state, 'provider_accepted');
  assertEquals(row.provider_message_sid, h.twilio.messages[0].sid);
  assertEquals(h.twilio.requests, 1);
  assertEquals(h.twilio.messages.length, 1);
  assert(h.twilio.listCalls >= 1);
});

serviceTest('a timeout after the provider created the message is reconciled too', async (h) => {
  const booth = await readyBooth(h);
  const id = await uploadedDelivery(h, booth.accessToken);
  h.twilio.modes.push('hang_created');
  const view = await commit(h, booth.accessToken, id);
  assertEquals(view.state, 'delivery_unknown');
  minutes(h, 3);
  await runWorker(h);
  assertEquals((await jobRow(h, id)).state, 'provider_accepted');
  assertEquals(h.twilio.messages.length, 1);
});

serviceTest(
  'not found at the provider: an operator decides; resend needs acknowledgement',
  async (h) => {
    const booth = await readyBooth(h);
    const id = await uploadedDelivery(h, booth.accessToken);
    h.twilio.modes.push('server_error_not_created');
    assertEquals((await commit(h, booth.accessToken, id)).state, 'delivery_unknown');
    for (const step of [3, 10, 20]) {
      minutes(h, step);
      await runWorker(h);
    }
    const row = await jobRow(h, id);
    assertEquals(row.state, 'delivery_unknown');
    assertEquals(row.review_reason, 'NOT_FOUND_AT_PROVIDER');
    assertEquals(h.twilio.requests, 1);
    const token = String(
      (await json(await h.call('POST', '/v1/booths/token', { token: booth.credential })))
        .accessToken,
    );
    const cancel = await h.call('POST', `/v1/deliveries/${id}/cancel`, { token });
    assertEquals(cancel.status, 409);
    assertEquals(await errorCode(cancel), 'DELIVERY_OUTCOME_UNKNOWN');
    const unacknowledged = await h.call('POST', `/v1/deliveries/${id}/resolve`, {
      token,
      json: { action: 'resend' },
    });
    assertEquals(unacknowledged.status, 422);
    await unacknowledged.body?.cancel();
    const resent = await json(
      await h.call('POST', `/v1/deliveries/${id}/resolve`, {
        token,
        json: { action: 'resend', acknowledgeDuplicateRisk: true },
      }),
    );
    assertEquals(resent.state, 'provider_accepted');
    assertEquals(h.twilio.requests, 2);
    const grants = await h.db
      .sql`select kind, revoked_at from access_grants where job_id = ${id} order by created_at`;
    assertEquals(grants.filter((grant) => grant.revoked_at).length, 2, 'the first links are off');
  },
);

serviceTest('closing an unknown delivery revokes its links', async (h) => {
  const booth = await readyBooth(h);
  const id = await uploadedDelivery(h, booth.accessToken);
  h.twilio.modes.push('server_error_not_created');
  await commit(h, booth.accessToken, id);
  const closed = await json(
    await h.call('POST', `/v1/deliveries/${id}/resolve`, {
      token: booth.accessToken,
      json: { action: 'close' },
    }),
  );
  assertEquals(closed.state, 'failed_permanent');
  assertEquals(closed.failureCode, 'CLOSED_BY_OPERATOR');
  const live = await h.db
    .sql`select 1 from access_grants where job_id = ${id} and revoked_at is null`;
  assertEquals(live.length, 0);
});

serviceTest('a worker that dies mid-submission leaves the outcome unknown (AC-0915)', async (h) => {
  const booth = await readyBooth(h);
  const id = await uploadedDelivery(h, booth.accessToken);
  // As if a worker had claimed it and crashed before recording anything.
  await h.db.sql`update delivery_jobs set state = 'dispatching', attempts = 1,
    lease_until = ${new Date(h.clock.now.getTime() - 1000)},
    submit_started_at = ${new Date(h.clock.now.getTime() - 200_000)}
    where id = ${id}`;
  await runWorker(h);
  const row = await jobRow(h, id);
  assertEquals(row.state, 'delivery_unknown');
  assertEquals(h.twilio.requests, 0, 'not re-sent');
  const [history] = await h.db.sql`select code from delivery_history where job_id = ${id}
    order by id desc limit 1`;
  assert(['LEASE_EXPIRED', 'NEEDS_OPERATOR_REVIEW'].includes(String(history.code)));
});

serviceTest('cancel works before submission only', async (h) => {
  const booth = await readyBooth(h);
  const id = await uploadedDelivery(h, booth.accessToken);
  const canceled = await json(
    await h.call('POST', `/v1/deliveries/${id}/cancel`, { token: booth.accessToken }),
  );
  assertEquals(canceled.state, 'canceled');
  assertEquals(h.store.objects.size, 0);
  assertEquals((await jobRow(h, id)).recipient_ciphertext, null);
  const after = await h.call('POST', `/v1/deliveries/${id}/commit`, { token: booth.accessToken });
  assertEquals((await json(after)).state, 'canceled', 'a canceled delivery is never sent');
  assertEquals(h.twilio.requests, 0);

  const sent = await uploadedDelivery(
    h,
    booth.accessToken,
    deliveryRequest({ phone: '(206) 555-0100' }),
  );
  await commit(h, booth.accessToken, sent);
  const late = await h.call('POST', `/v1/deliveries/${sent}/cancel`, { token: booth.accessToken });
  assertEquals(late.status, 409);
  assertEquals(await errorCode(late), 'DELIVERY_ALREADY_SUBMITTED');
});

serviceTest('the emergency switch stops dispatch without using up attempts', async (h) => {
  const booth = await readyBooth(h);
  const id = await uploadedDelivery(h, booth.accessToken);
  await h.db.sql`update tenants set sending_enabled = false`;
  const refused = await h.call('POST', `/v1/deliveries/${id}/commit`, { token: booth.accessToken });
  assertEquals(refused.status, 409);
  assertEquals(await errorCode(refused), 'SENDING_NOT_READY');
  assertEquals(h.twilio.requests, 0);
  // Committed before the switch went off: waits, unsent.
  await h.db.sql`update tenants set sending_enabled = true`;
  const second = await uploadedDelivery(
    h,
    booth.accessToken,
    deliveryRequest({ phone: '(206) 555-0100' }),
  );
  await h.db
    .sql`update delivery_jobs set state = 'dispatch_pending', next_attempt_at = ${h.clock.now}
    where id = ${second}`;
  await h.db.sql`update tenants set sending_enabled = false`;
  await runWorker(h);
  const row = await jobRow(h, second);
  assertEquals(row.state, 'failed_retryable');
  assertEquals(row.attempts, 0);
  assertEquals(h.twilio.requests, 0);
});

serviceTest(
  'a consent window that ends before sending expires the delivery (AC-0906)',
  async (h) => {
    const booth = await readyBooth(h);
    const id = await uploadedDelivery(h, booth.accessToken);
    minutes(h, 24 * 60 + 1);
    const token = String(
      (await json(await h.call('POST', '/v1/booths/token', { token: booth.credential })))
        .accessToken,
    );
    const view = await commit(h, token, id);
    assertEquals(view.state, 'expired');
    assertEquals(h.twilio.requests, 0);
    assertEquals((await jobRow(h, id)).recipient_ciphertext, null);
  },
);
