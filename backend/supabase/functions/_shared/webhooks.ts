// Twilio webhooks (PD-05, AC-0913, AC-0914, AC-0918). Every request is
// checked with Twilio's official signature validation against the exact
// public URL Twilio was given; anything unsigned, tampered with or from
// another account is refused before it is read further. Repeated reports
// change nothing (one row per message and status), and reports never move
// a delivery backwards.

import { applyProviderStatus } from './dispatch.ts';
import type { Deps } from './context.ts';
import { recipientDigest } from './crypto.ts';
import { validateRequest } from './deps.ts';
import { ApiError, baseHeaders, readForm } from './http.ts';
import { type JobRow, moveJob, purgeJob } from './jobs.ts';
import { parsePhone } from './phone.ts';
import { suppress, unsuppress } from './suppression.ts';

const sidPattern = /^[A-Z]{2}[0-9a-f]{32}$/;

/** Twilio's standard opt-out, opt-in and help keywords. */
const stopWords = new Set([
  'STOP',
  'STOPALL',
  'UNSUBSCRIBE',
  'CANCEL',
  'END',
  'QUIT',
  'OPTOUT',
  'REVOKE',
]);
const startWords = new Set(['START', 'UNSTOP', 'YES']);
const helpWords = new Set(['HELP', 'INFO']);

async function verified(
  deps: Deps,
  request: Request,
  path: string,
): Promise<Record<string, string>> {
  const twilio = deps.config.twilio;
  // Without the provider's settings nothing can be verified: refuse.
  if (!twilio) throw new ApiError(403, 'SIGNATURE_INVALID');
  const signature = request.headers.get('x-twilio-signature');
  if (!signature) throw new ApiError(403, 'SIGNATURE_INVALID');
  const params = await readForm(request);
  const url = `${deps.config.publicBaseUrl}${path}`;
  if (!validateRequest(twilio.authToken, signature, url, params)) {
    deps.log.warn('webhook.signature_rejected', { path });
    throw new ApiError(403, 'SIGNATURE_INVALID');
  }
  if (params.AccountSid !== twilio.accountSid) throw new ApiError(403, 'ACCOUNT_MISMATCH');
  return params;
}

async function touch(deps: Deps, key: string): Promise<void> {
  await deps.sql`insert into service_health (key, at) values (${key}, ${deps.now()})
    on conflict (key) do update set at = excluded.at`;
}

/** POST /webhooks/twilio/status */
export async function statusWebhook(deps: Deps, request: Request): Promise<Response> {
  const params = await verified(deps, request, '/webhooks/twilio/status');
  const sid = params.MessageSid ?? params.SmsSid ?? '';
  const status = (params.MessageStatus ?? params.SmsStatus ?? '').toLowerCase();
  const errorCode = params.ErrorCode && /^[0-9]{1,6}$/.test(params.ErrorCode)
    ? params.ErrorCode
    : null;
  if (!sidPattern.test(sid) || !/^[a-z_]{2,32}$/.test(status)) {
    throw new ApiError(400, 'WEBHOOK_INVALID');
  }
  await touch(deps, 'webhook.status');
  const inserted = await deps.sql`insert into provider_events (message_sid, status, error_code)
    values (${sid}, ${status}, ${errorCode}) on conflict do nothing returning id`;
  if (inserted.length === 0) {
    deps.log.info('webhook.status_duplicate', { status });
    return new Response(null, { status: 204, headers: baseHeaders });
  }
  const result = await applyProviderStatus(deps, sid, status, errorCode);
  deps.log.info('webhook.status', { status, result, errorCode });
  return new Response(null, { status: 204, headers: baseHeaders });
}

/** Empty TwiML: this service never replies itself, so no duplicate replies. */
function emptyTwiml(): Response {
  return new Response('<?xml version="1.0" encoding="UTF-8"?><Response></Response>', {
    status: 200,
    headers: { ...baseHeaders, 'content-type': 'text/xml; charset=utf-8' },
  });
}

/**
 * POST /webhooks/twilio/inbound: STOP adds the number to the suppression
 * list and ends its unsent deliveries; START lifts an opt-out the number
 * made; HELP is answered by the Messaging Service's own configured reply.
 */
export async function inboundWebhook(deps: Deps, request: Request): Promise<Response> {
  const params = await verified(deps, request, '/webhooks/twilio/inbound');
  await touch(deps, 'webhook.inbound');
  const optOut = (params.OptOutType ?? '').toUpperCase();
  const word = (params.Body ?? '').trim().split(/\s+/)[0]?.toUpperCase().replace(/[^A-Z]/g, '') ??
    '';
  const keyword = optOut === 'STOP' || stopWords.has(word)
    ? 'stop'
    : optOut === 'START' || startWords.has(word)
    ? 'start'
    : optOut === 'HELP' || helpWords.has(word)
    ? 'help'
    : 'other';
  const phone = parsePhone(params.From ?? '');
  if (keyword === 'stop' || keyword === 'start') {
    // Numbers outside the certified region cannot have been sent to; the
    // digest is still recorded so an opt-out is never lost.
    const e164 = phone.ok ? phone.e164 : (params.From ?? '').replace(/[^+0-9]/g, '');
    if (!/^\+[0-9]{8,15}$/.test(e164)) return emptyTwiml();
    const digest = await recipientDigest(deps.config.digestKey, e164);
    if (keyword === 'stop') {
      await suppress(deps, digest, 'stop');
      const pending = await deps.sql<JobRow[]>`select * from delivery_jobs
        where recipient_digest = ${digest}
          and state in ('created', 'uploading', 'dispatch_pending', 'failed_retryable')`;
      for (const job of pending) {
        const moved = await moveJob(deps.sql, job.id, [job.state], 'failed_permanent', deps.now(), {
          failure_code: 'RECIPIENT_OPTED_OUT',
          next_attempt_at: null,
        }, 'RECIPIENT_OPTED_OUT');
        if (moved) await purgeJob(deps, moved, 'failed');
      }
      deps.log.info('webhook.opt_out', { endedDeliveries: pending.length });
    } else {
      await unsuppress(deps, digest);
      deps.log.info('webhook.opt_in', {});
    }
  } else {
    deps.log.info('webhook.inbound', { keyword });
  }
  return emptyTwiml();
}
