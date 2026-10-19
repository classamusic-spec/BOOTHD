# Phone delivery: privacy and retention (DRAFT for legal review)

**Status: a draft written by the developers to describe what the software
does. It is not legal advice and has not been reviewed by a lawyer. The
operator must have it reviewed (prerequisite 7), publish the reviewed
privacy notice and terms on their own domain, and record the review in
the backend before any text is sent.** The facts below match the code in
this repository at M09; if the code changes, this draft must change too.

## 1. What texting is

An optional service at a staffed photo booth. After a guest's photo is
finished and saved at the booth, the guest may type their US mobile
number and check a box to receive one text message (MMS) with a small
preview of their photo and a private link to download the full-quality
photo. Guests who do not opt in lose nothing: their photo is saved at the
booth as usual.

## 2. The consent the guest gives

Shown next to an unchecked box (version `pd-consent-1`; the exact text
for an event is in Event > Texting > What guests agree to):

> I agree to receive one photo-delivery text from <brand> at the number
> I entered. The text includes a photo preview and a private download
> link. Message and data rates may apply. Reply STOP to opt out or HELP
> for help. Your download link expires after 7 days.

The text comes from `lib/domain/delivery/consent.dart`; the number of
days follows the event's link setting. It covers one transactional
message about the guest's own photo. There is no marketing, no list and
no follow-up message. The guest confirms the number on a second screen
before anything is sent.

Recorded as proof, for each request: the consent text's version and
SHA-256 fingerprint, the time it was accepted, the event, the session, the
screen (S31), the locale, and a keyed one-way digest of the number (not
the number). Stored by the delivery backend in an append-only table.

## 3. What is collected, where, and for how long

| Data | Where | Kept until | Who can see it |
| --- | --- | --- | --- |
| Phone number (full) | Booth: platform secure storage, for a request not yet handed over | Handed over, ended, 24 hours after consent, or its session deleted, whichever is first | Nobody through the app; the booth shows only the last four digits |
| Phone number (encrypted) | Backend database (AES-256-GCM) | The text is submitted, fails, expires or is canceled | Nobody; decrypted only to submit to the provider |
| Last four digits | Booth and backend | With the request record (booth: until the session is deleted; backend: 90 days) | Operators |
| Keyed digest of the number | Backend | Consent receipts and opt-outs: as long as legally required (to be decided by the review); rate counting: 1 day | Nobody can reverse it without the key |
| Finished photo (full quality) | Booth gallery; backend private storage | Booth: the event's retention rule. Backend: until the link expires (7 days by default) or is turned off | Whoever holds the link, during its life |
| Preview image | Backend private storage; Twilio; carriers; the guest's phone | Backend: with the link. Twilio: deleted by the service when the link ends. Carrier and phone: outside our control | Twilio fetches it once through a 60-minute address |
| Delivery status and history | Booth; backend | Booth: with the session. Backend: 90 days, without the number | Operators |
| Opt-out (STOP) | Backend, as a keyed digest | Until START, kept as long as the law requires | Nobody can reverse it |
| Network addresses | Backend, as a keyed hash that changes daily | 1 day (rate limits) | Nobody can reverse it |

The download page sets no cookies, loads no analytics or third-party
content, is excluded from search indexing and sends no referrer.

## 4. Who processes it

- The operator (the booth's business): controller.
- The delivery backend's host (for example Supabase) and Twilio (the
  messaging provider): processors under the operator's agreements with
  them. Carriers deliver the message under their own terms.
- The booth app's developers receive nothing: the app has no analytics
  and sends delivery data only to the operator's own backend.

## 5. What cannot be undone

- A text already delivered stays on the guest's phone and may be kept by
  carriers. Turning the link off or deleting the session stops the link
  from working and deletes the hosted copy; it cannot recall the message
  or the preview.
- Anyone the guest forwards the link to can open it until it expires.

## 6. Guests' choices and requests

- Not opting in: the default.
- STOP to the sender's number: no further texts from that sender.
- Asking the operator to delete their photo: the operator deletes the
  session in the booth's gallery, which also turns off the link and
  deletes the hosted copy (once the booth is online).
- Requests about consent records and opt-outs go to the operator's
  support contact shown on the consent screen and the download page.

## 7. Points for the legal review

1. The consent wording, including whether it needs a line such as
   "consent is not a condition of purchase", and the privacy and terms
   links shown beside it.
2. Minors at events (school, family events): whether texting must be off,
   or need a guardian's consent.
3. How long consent receipts and opt-outs must be kept, and whether the
   90-day status records are appropriate.
4. US state privacy laws applicable to the operator; whether the privacy
   notice must list categories, purposes and rights in a particular form.
5. The sender registration (A2P 10DLC or toll-free): the use case
   description, sample message and opt-in description must match this
   flow exactly (Event > Texting > Export consent proof).
6. Photo likeness and event hosts: whether hosts must inform guests that
   photos may be texted.
7. Incident handling and notification duties (OPERATIONS.md section 6).
