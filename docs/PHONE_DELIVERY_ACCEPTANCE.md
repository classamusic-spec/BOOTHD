# New acceptance checks — Phone delivery / M09

These are mandatory for the *enabled phone-delivery feature* in a commercial release; keep offline booth functional with texting disabled. Record PASS/FAIL/BLOCKED per check. Actual carrier/phone and provider campaign validation cannot be marked PASS from mocked tests.

- [ ] **AC-0901** Event/booth delivery off by default until provider readiness + operator enable; capture/render/gallery remain offline with delivery disabled.
- [ ] **AC-0902** Finished photo saved before phone prompt; `No thanks` exits without intent/upload/send.
- [ ] **AC-0903** Phone validation to E.164, initial supported US-only region, masked UI/logs; input cleared on guest reset.
- [ ] **AC-0904** Separate unchecked documented transactional MMS consent with version/time/event/source; no send without accepted receipt; no marketing enrollment.
- [ ] **AC-0905** Flutter iPad/Android guest screens support portrait/landscape, accessible keypad, offline status, and 7-day expiry disclosure.
- [ ] **AC-0906** Local durable delivery queue survives restart/offline, retries safely on active reconnect within 24h and expires while erasing phone PII; local photos unaffected.
- [ ] **AC-0907** Device pairing authorization, scoped token revocation, backend quotas and per-recipient throttles prevent unauthenticated/abusive dispatch.
- [ ] **AC-0908** Only selected final composition and preview uploaded; checksum/MIME/pixel/size validation and private object store; never raw original captures.
- [ ] **AC-0909** Preview uses limited provider-fetchable GET/HEAD URL, valid HTTPS/MIME, tested carrier-conservative byte budget under 5MB; original remains private.
- [ ] **AC-0910** Guest token cryptographic entropy >=128 bits, hashed storage, 7-day max-default expiry/revoke, non-indexed download page, private short-lived full-quality object access.
- [ ] **AC-0911** Twilio server-side only credentials; US sender campaign/verification and registered consent artifacts confirmed; no live send without approval.
- [ ] **AC-0912** Real MMS received on certified US phone with image preview + private download link; high-res file exact template output dimensions.
- [ ] **AC-0913** Provider status callbacks verified using official signature validation; `accepted/sent/delivered/failed/undelivered` mapped correctly, no false received claims.
- [ ] **AC-0914** STOP opt-out blocks later sends; HELP handling works; signed inbound events processed without duplicate replies.
- [ ] **AC-0915** Double taps and repeated callbacks do not duplicate sends; ambiguous provider timeouts become UNKNOWN/manual review; unsafe blind retries prohibited.
- [ ] **AC-0916** Rate limit, max event spend estimate, unsupported destination, insufficient storage, bad upload, expiring preview URL and provider outage all handled with safe recovery.
- [ ] **AC-0917** Expiry and operator revoke make full-quality download inaccessible; delete hosted media, attempt provider media cleanup, clearly document already-delivered carrier copies cannot be recalled.
- [ ] **AC-0918** Secure webhook regression tests reject tampered/missing signatures; secrets not shipped in app binary, error logs redact phone/token/PII.
- [ ] **AC-0919** Mobile download page works on iPhone and Android with images safe from search indexing and unapproved analytics, and honest expired-link errors.
- [ ] **AC-0920** Live tests log certified booth, carrier, real phone, sanitized Twilio SID, consent proof and actual delivery result; untested carriers/physical devices recorded BLOCKED, never assumed.
- [ ] **AC-0921** Staging/production separation, migration/rollback/deletion jobs, incident documentation, and monthly cost/retention review exist.
- [ ] **AC-0922** No guest is trapped waiting for text; after operator-chosen timeout, booth resets without exposing number or prior guest photos.
