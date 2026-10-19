# Phone delivery: prerequisites inventory (M09)

What live phone delivery needs, and what exists today. Inspected
2026-10-19 from this repository and its build host. Nothing below was
assumed: an item is READY only when it exists and was checked.

| # | Prerequisite | Needed for | Status | Notes |
| --- | --- | --- | --- | --- |
| 1 | Operator-controlled domain with HTTPS (for example `photos.<operator-domain>`) | Download links in texts, Twilio's preview fetch, webhooks | BLOCKED | No domain is configured. Never `example.com`. The default Supabase domain cannot serve the download page as HTML; a custom domain or proxy is needed (setup guide) |
| 2 | Supabase projects (staging and production) or an equivalent Postgres + private storage + functions host | The backend | BLOCKED | No project exists. The backend runs locally against Postgres 16 for tests only |
| 3 | Scheduler calling the worker every minute (Supabase `pg_cron` + `pg_net`, or any scheduler) | Dispatch retries, reconciliation, retention | BLOCKED | Depends on 2 |
| 4 | Twilio business account (paid), Messaging Service, MMS-capable US sender | Sending | BLOCKED | No account or credentials were provided |
| 5 | US A2P 10DLC brand and campaign registration (long code) or toll-free verification | Lawful US sending | BLOCKED | Requires the operator's business details, the exact consent screen (exportable from the app), privacy and terms URLs and sample messages |
| 6 | Public privacy policy and terms URLs on the operator's domain | Consent screen, registration, download page | BLOCKED | A draft for legal review is in `docs/delivery/PRIVACY_AND_RETENTION_DRAFT.md` |
| 7 | Legal review: consent wording, minors, retention, texting rules | Enabling sends | BLOCKED | No review has happened; the consent text is marked as a draft |
| 8 | STOP/HELP configured on the Messaging Service (Advanced Opt-Out or default handling) with the operator's HELP text | Compliance, no duplicate replies | BLOCKED | Depends on 4 |
| 9 | Physical iPad and Android tablet running the booth | Device evidence (AC-0905, AC-0912, AC-0920) | BLOCKED | No tablets attached to this host |
| 10 | Approved test phones on certified US carriers (for example AT&T, T-Mobile, Verizon) | Real MMS receipt evidence (AC-0912, AC-0919, AC-0920) | BLOCKED | None available |
| 11 | Venue-like network (Wi-Fi with and without a captive portal, a hotspot) | Offline and resume evidence on devices | BLOCKED | Depends on 9 |
| 12 | Administrator token and backend secrets in a secret store | Operating the backend | BLOCKED | Generated per environment at deployment (setup guide) |
| 13 | Current Twilio pricing check before launch | Cost estimates (PD-08) | BLOCKED | Figures in the cost calculator are the spec's October 2026 numbers and must be re-checked |

## What is ready (built and tested here)

| Item | Evidence |
| --- | --- |
| Backend code, schema, contract and tests | `backend/` (`tool/test.sh`: format, lint, type check, tests against a real Postgres) |
| Booth app delivery client, queue, consent and screens | `lib/` (M09 sections), `test/` (M09 tests), goldens |
| Setup, operations, cost, incident and privacy drafts | `docs/delivery/` |
| Device and carrier test procedure | `docs/device_tests/M09_DEVICE_PROCEDURE.md` |

## Go / no-go for live sending

Live sending may be switched on for a tenant only when 1 to 8 and 12 are
READY, the administrator has recorded the registration reference and the
legal review in the backend (the server refuses to send otherwise), and a
staging run on approved test phones (10) has passed. Until then the
feature ships disabled: the booth hides texting and works as before.
