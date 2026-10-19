# Phone delivery: operations (M09)

How to run texting once it is set up (`SETUP_AND_CREDENTIALS.md`): what it
costs, what guests receive, the caps, what to do when something goes
wrong, and the monthly review. Nothing here has been exercised against a
live sender yet: no account, registration or real phone exists
(`PREREQUISITES.md`). Figures are estimates to re-check before launch.

## 1. What a guest receives

One MMS (picture message) from the operator's registered sender:

```
<brand>: Your photos from <event name> are ready: https://photos.<operator-domain>/p/<private link> (available for 7 days). Reply STOP to opt out, HELP for help.
```

with a JPEG preview of the finished photo attached (at most 1024 px on the
longest side, under the tenant's preview budget, 600 kB by default;
carriers may shrink it further). The link opens a page with the full-
quality finished photo and a Download button. Exact wording:
`messageBody` in `backend/supabase/functions/_shared/dispatch.ts`; the
consent the guest agreed to: Event > Texting > What guests agree to (and
Export consent proof).

Nothing else is ever sent: no reminders, no marketing, no second text. A
reply of STOP stops all future texts to that number from this sender; HELP
gets the operator's HELP text from Twilio's Messaging Service.

## 2. Cost calculator

The booth shows an estimate (Event > Texting, Settings > Phone delivery);
the provider's invoice is the truth. Per successful text, from the spec's
October 2026 figures (PD-08), to re-check on Twilio's pricing page before
launch:

| Item | Per text | Notes |
| --- | ---: | --- |
| Twilio US outbound MMS | $0.022 | Base price |
| Carrier pass-through fee | $0.007 to $0.010 | Varies by carrier and sender type |
| **Estimate used by the service** | **$0.032** | `estimated_cost_millicents` = 3200; change per tenant |

Per event:

| Texts | Base only | Base + carrier fees |
| ---: | ---: | ---: |
| 100 | $2.20 | $2.90 to $3.20 |
| 200 (default event cap 500, booth day cap 150) | $4.40 | $5.80 to $6.40 |
| 500 | $11.00 | $14.50 to $16.00 |
| 1,000 | $22.00 | $29.00 to $32.00 |

Not included, billed separately: A2P 10DLC brand and campaign registration
fees (one-off and monthly) or toll-free verification, the phone number's
monthly rental, failed-message processing fees where charged, Supabase
plan, storage and egress (500 finished photos at about 3 MB is about
1.5 GB held for up to 7 days, plus about 125 MB of previews and each
guest's downloads), taxes.

Formula for a quote: `texts x (0.022 + carrier fee) + monthly number +
registration share + storage`. Keep a margin: guests who ask twice, and
operator re-sends after an unknown result, are billed too.

## 3. Caps (defaults; change per tenant and per event)

| Cap | Default | Where | What guests see when reached |
| --- | --- | --- | --- |
| Per number | 3 an hour, 6 a day | Server (fixed) | "Texting is paused for now" |
| Per booth | 150 a day | Server, per booth | Same |
| Per tenant | 200 a day | Server, admin API | Same |
| Per event | the smaller of the event's (S34, default 200) and the tenant's (500) | Server | Same |
| Monthly budget | $20 estimated | Server, admin API | Same; raise it deliberately |
| Link life | 7 days (max 14, admin can allow up to 30) | Event (S34), tenant | The page says the link has expired |
| Offline waiting | 24 hours, app open | Booth | "Waiting for a connection" |

Set the event cap from the guest count: guests x 1.2, rounded up to 10.
The booth's Texting tab shows the cap's estimated cost.

## 4. Turning texting on and off

- On: tenant `sendingEnabled` (admin API) after the attestations; the
  booth paired and its readiness "Ready" (Settings > Phone delivery); the
  event's "Offer Text my photos" (Event > Texting).
- One booth, at once: Settings > Phone delivery > Pause texting. New
  requests stop and nothing is handed over until resumed.
- Every booth, at once (emergency off): `PATCH /v1/admin/tenants/<id>`
  with `{"sendingEnabled": false}`. Requests already accepted wait on the
  server (checked every five minutes) until the switch returns or they
  expire 24 hours after consent; nothing is sent while it is off. Booths stop offering texting
  at their next check (at most ten minutes, or at once with Check now).
- One booth for good: revoke it (`POST /v1/admin/booths/<id>/revoke`).

## 5. Reading the booth's statuses (S35, S36)

| Status | Meaning | Operator action |
| --- | --- | --- |
| Queued locally | On the tablet, waiting for the service | Check the connection; Try now |
| Uploading / Sending | Being handed over / being submitted | None |
| Submitted | Twilio accepted it | None |
| Sent | Twilio handed it to the carrier | None; not proof of receipt |
| Delivered | The carrier reported delivery | None; texts never report being read |
| Failed | Not sent, or the carrier could not deliver | Read the code; never re-send to an opted-out number |
| Unknown | The service cannot tell whether Twilio queued it | Ask the guest if possible; "Close it" or "Send again" (may duplicate) |
| Expired | Not sent within 24 hours of consent | None; the number is already erased |
| Canceled | Canceled before sending | None |

"Turn link off" (S35) disables the guest's link and deletes the hosted
copy; a picture already on the guest's phone cannot be recalled.

## 6. Incidents

| Symptom | Likely cause | Response |
| --- | --- | --- |
| Booths show "Not ready: sender's registration not recorded" | Attestation missing or revoked | Record it only with the approved registration in hand |
| Many "Failed" with `PROVIDER_*` codes | Twilio account, sender or campaign problem | Emergency off; check Twilio's console and status page; fix; turn on |
| Many "Unknown" | Twilio timeouts or outage | Wait for reconciliation (every minute); resolve the rest one by one; do not mass re-send |
| "Status reports" time stops moving (S36) | Status webhook broken or signature failing | Check the webhook URL and `PUBLIC_BASE_URL`; signatures must match the exact public URL |
| "Sending worker" or "Clean-up" time stops moving | Scheduler stopped | Restart the scheduled call to `/v1/admin/worker/run` |
| Guests report no text | Carrier filtering, landline, opted out, delay | Check S35 status; "Sent" is not "received"; do not promise delivery |
| Suspected leaked booth credential | Lost tablet | Revoke the booth; re-pair its replacement |
| Suspected leaked Twilio key or admin token | Secret exposure | Rotate (setup guide section 9); review the audit log |
| Unexpected spend | Abuse or misconfiguration | Emergency off; lower caps; review the audit log and per-booth counts |
| Wrong photo sent | Should be impossible (the booth sends the session's own finished photo) | Turn the link off at once (S35); report it as a privacy incident |

Rollback of a backend release: switch sending off, redeploy the previous
release's function from its git tag, verify on staging, switch sending
back on. Migrations must stay additive (v1 is the only one so far), so
the previous function keeps working with the newer schema. A schema
rollback is a new forward migration, never an edited one.

Record every incident: time, booths, counts, cause, actions, whether
guests' data was exposed. Personal-data incidents may require notifying
people or authorities; that duty is the operator's and needs legal
advice.

## 7. Monthly review

1. Cost: the provider's invoice against the service's estimate (S36,
   "This month"); adjust `estimated_cost_millicents` if they differ by
   more than 10%.
2. Caps: were any reached? Were they right?
3. Retention: `retention_worker_at` keeps moving; no finished photo older
   than its link exists in storage (`select count(*) from delivery_jobs
   where purged_at is null and link_expires_at < now() - interval '1
   hour'` should be 0); the provider's media list holds nothing older
   than the longest link.
4. Opt-outs and HELP: the inbound webhook time keeps moving; spot-check
   that a test STOP blocks a staging send.
5. Access: booths paired, last seen, and any to revoke; administrator
   token age.
6. Pricing and rules: Twilio's current prices; carrier and registration
   notices.

## 8. Diagnostics

The booth's Settings > Phone delivery > Export diagnostics produces a
redacted text file for support. It never contains numbers, links, tokens
or the credential. Example:

```
Porcelain Photo Booth: phone delivery diagnostics (redacted)
Generated: 2026-11-14T21:04:11.000Z
Service: photos.example.test
Booth: b2000000-0000-4000-8000-000000000001
Paused: false
Ready: true []
Environment: staging
Last checked: 2026-11-14T20:58:02.000Z
Connection: ok
Counts: {delivered: 41, sent: 3, failed: 2, unknown: 1}

Latest requests (no numbers, no links):
2026-11-14T20:51:40.000Z delivered attempts=1 code=- event=a1000000 remote=00000000
2026-11-14T20:47:03.000Z unknown attempts=1 code=PROVIDER_TIMEOUT event=a1000000 remote=00000000
2026-11-14T20:40:19.000Z failed attempts=1 code=RECIPIENT_OPTED_OUT event=a1000000 remote=00000000
```

The backend logs one JSON line per event with codes and ids only; phone
numbers, tokens, links and secrets are redacted before logging
(`_shared/log.ts`, tested in `backend/test/security_test.ts`).
