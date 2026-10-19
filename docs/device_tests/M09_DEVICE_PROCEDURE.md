# M09 device procedure: texting a photo on real tablets, senders and phones

For the owner or a tester with a physical iPad (plus a Mac with Xcode), a
physical Android tablet, a deployed **staging** delivery backend, a
registered Twilio sender and approved test phones on US carriers.
Simulators, emulators, the host test suite, the local backend and the
stand-in provider do not count for any step here. Record every result in
`docs/ACCEPTANCE_EVIDENCE.md` (M09) with: tablet model and OS version,
app commit and build mode, orientation, backend commit and environment,
Twilio Messaging Service (SID with the middle masked), carrier and phone
model for each test phone, date and time, and the screenshots named
below. Until this is done the live rows of AC-0901..AC-0922 stay
BLOCKED.

**Never** test against production, never text a number that is not on the
staging approved list, and never mark a step PASS from the host tests.

**Exit gate (M09):** one explicitly consenting guest on either certified
tablet receives the preview MMS with a working full-quality link, while
sessions without consent, offline and failed stay safe, accessible and
truthful.

## 0. Setup

- Every prerequisite in `docs/delivery/PREREQUISITES.md` READY for
  staging (1 to 8, 10, 12), recorded with evidence.
- Backend deployed to staging per `docs/delivery/SETUP_AND_CREDENTIALS.md`
  sections 1 to 10; `GET /healthz` answers; the scheduler runs every
  minute.
- Approved test phones (at least AT&T, T-Mobile and Verizon, one iPhone
  and one Android phone) added with
  `POST /v1/admin/tenants/<id>/test-recipients`.
- Tablets: profile builds of the commit under test (M07 procedure
  section 0), an event with a 4×6 portrait template and one with a
  landscape template, each with texting on (Event > Texting).
- Pair each tablet: Studio > Settings > Phone delivery, the staging
  address and a fresh pairing code. Record the status row ("Ready",
  "staging service (test numbers only)").

## 1. Readiness and diagnostics (AC-0901, AC-0907, AC-0916)

1. Settings > Phone delivery: Check now, Test an upload ("Upload works.
   Nothing was stored or sent."), and record the service checks row
   (status reports, sending worker, clean-up times).
2. Turn the tenant's `sendingEnabled` off. Check now: "Not ready: Sending
   is switched off at the service." Finish a guest session: no "Text my
   photos". Turn it back on.
3. Pause texting on the tablet: the event's Texting tab shows "Paused";
   guests are not offered texting. Resume.
4. Export diagnostics; confirm the file contains no number, link or
   token (search for `+1`, `/p/`, `credential`).

## 2. One guest, end to end (AC-0902 to AC-0905, AC-0908 to AC-0910, AC-0912, AC-0913)

On each tablet, in portrait and in landscape:

1. Run a guest session to S30. Screenshot S30. The photo is saved before
   anything else (Gallery shows it).
2. Text my photos. Screenshot S31 empty: the box is unchecked and Send my
   photos is disabled. Type an approved test number with the on-screen
   keypad (and once with a hardware keyboard if available). Check the
   box. Screenshot. Send my photos; S31 confirmation shows the full
   number once. Send.
3. S32: record the words shown and the time to "Text request sent".
   Tap Done; the welcome screen shows nothing of the last guest.
4. On the phone: record the arrival time, that the preview image shows,
   the message text (brand, event, link, expiry, STOP/HELP), and any
   carrier transcoding (image size as received).
5. Open the link on the phone: the page loads over HTTPS, shows the
   photo, Download saves the full file. Compare the downloaded file with
   the booth's finished photo (exported from the gallery): same pixel
   size (1200 × 1800 for 4×6 at 300 dpi) and the same SHA-256.
6. Studio > Gallery > the session > Texts: Submitted, Sent, then
   Delivered (if the carrier reports it); the history has times; the
   number shows as •••-•••-NNNN only.
7. Repeat with VoiceOver (iPad) and TalkBack (Android) on: every key, the
   consent box (read with its state) and the buttons are announced.

## 3. No consent, No thanks and reset (AC-0902, AC-0903, AC-0922)

1. Type a number, leave the box unchecked: Send my photos stays disabled.
   No thanks: the welcome returns. In the backend, no job was created
   (`select count(*) from delivery_jobs` unchanged).
2. Type part of a number and walk away: after the event's finish time
   the booth resets; start a new session and confirm the keypad is empty
   and the box unchecked.
3. Rotate the tablet mid-entry: the number and the box keep their state
   within that session.

## 4. Offline and recovery (AC-0906, AC-0911, AC-0916)

1. Turn Wi-Fi off. Finish a session: S30 shows the offline note. Send a
   text: S32 says "Waiting for a connection". The session's Texts shows
   Queued locally.
2. Force-quit the app; reopen it with Wi-Fi still off: the request is
   still queued. Turn Wi-Fi on with the app open: it is handed over and
   the text arrives. Record the delay.
3. Join a captive-portal Wi-Fi without signing in: the booth reports no
   connection and keeps the request; nothing is lost.
4. With Wi-Fi off, wait past 24 hours (or set the tablet clock forward,
   noting it): the request expires; the number is gone (it cannot be
   shown or sent); the photo is still in the gallery.
5. Event with "Take requests while offline" off: with Wi-Fi off, guests
   are not offered texting.

## 5. Opt-out, help and limits (AC-0914, AC-0916)

1. Reply STOP from a test phone. Record the single confirmation reply.
   Send another text to that number from the booth: it fails with "This
   number opted out of our texts"; nothing arrives.
2. Reply START; a later text arrives.
3. Reply HELP: exactly one reply with the operator's HELP text.
4. Send four texts to one number within an hour: the fourth is refused
   ("Texting is paused for now").
5. Try a landline or VoIP number on the approved list (if available):
   record the provider's failure and the booth's words.

## 6. Unknown, duplicate taps and repeated callbacks (AC-0915)

1. Double-tap Send on the confirmation as fast as possible: one job, one
   text.
2. If Twilio's test tooling or a firewall rule can delay the provider
   call past the service's timeout, record that the job becomes Unknown
   and is reconciled or left for the operator; resolve with Close it.
   Otherwise record BLOCKED with the reason (covered on the host by
   `backend/test/dispatch_test.ts`).
3. Replay a status callback from Twilio's console (or the logs): the
   status does not change backwards and no second text is sent.

## 7. Links: expiry, revocation, deletion (AC-0910, AC-0917, AC-0919)

1. Open a link on an iPhone (Safari) and an Android phone (Chrome).
   Record that the page is readable and Download works.
2. Turn link off (S35) on a delivered text: the link shows that it is no
   longer available; the hosted file is gone (storage console); the
   provider's media for that message is deleted (Twilio console). The
   picture already on the phone remains, as documented.
3. Delete a session with a text in the gallery: its link stops working
   (when the tablet is online; if offline, after it reconnects).
4. Event with 1-day links: the link works on day 1 and shows the expired
   page after it.
5. Check the page's response headers (`curl -I`): `X-Robots-Tag: noindex`,
   `Referrer-Policy: no-referrer`, a Content-Security-Policy, no cookies.

## 8. Secrets in the binaries (AC-0911, AC-0918)

1. On the release IPA and APK: `strings` and an unzip search for
   `twilio`, `AC[0-9a-f]{32}`, `SK[0-9a-f]{32}`, `sb_secret`,
   `service_role`, `-----BEGIN`. Record that none is present (the host
   scan in the evidence covers the APK built in CI only).
2. Device logs (Console.app / `adb logcat`) during a full send: no number,
   link, token or credential appears.

## 9. What to record as BLOCKED

Anything not run, with the reason: no second carrier, no iPhone, captive
portal unavailable, delays not reproducible. Never infer one carrier or
phone from another.
