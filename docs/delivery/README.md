# Phone delivery documents (M09)

Optional texting of a finished photo: one MMS with a preview and a
private, expiring link to the full-quality file. Off unless an operator
sets it up; the booth works the same without it.

**Status:** built and tested on the host only (the booth app with a
stand-in service, the backend against a real Postgres and a stand-in
provider). Not deployed; no sender registered; no real text sent. Live
use waits on `PREREQUISITES.md`.

| Document | For | What |
| --- | --- | --- |
| [PREREQUISITES.md](PREREQUISITES.md) | Owner | What live sending needs, what exists, go/no-go |
| [SETUP_AND_CREDENTIALS.md](SETUP_AND_CREDENTIALS.md) | Administrator | Environments, secrets, deployment, domain, scheduler, Twilio, tenants, booths, rotation |
| [OPERATIONS.md](OPERATIONS.md) | Operator, administrator | Sample message, cost calculator, caps, on/off switches, statuses, incidents, rollback, monthly review, diagnostics |
| [PRIVACY_AND_RETENTION_DRAFT.md](PRIVACY_AND_RETENTION_DRAFT.md) | Legal review | What is collected, where, for how long; consent; what cannot be undone |
| [THREAT_MODEL.md](THREAT_MODEL.md) | Reviewers | Assets, actors, boundaries, threats and mitigations, residual risks |
| [../decisions/ADR-0015-phone-delivery.md](../decisions/ADR-0015-phone-delivery.md) | Developers | The design and why |
| [../device_tests/M09_DEVICE_PROCEDURE.md](../device_tests/M09_DEVICE_PROCEDURE.md) | Testers | Real tablets, sender and phones |
| [../../backend/README.md](../../backend/README.md) | Developers | The backend's layout, checks and dependencies |
| [../../backend/openapi/delivery-v1.yaml](../../backend/openapi/delivery-v1.yaml) | Developers | The API contract |

Checks on the host:

```sh
tool/check.sh                 # the app (includes the M09 tests and goldens)
backend/tool/test.sh          # the backend
tool/delivery_contract.sh     # the app's HTTP client against the backend
```
