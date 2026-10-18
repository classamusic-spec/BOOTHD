# Test and Device Certification Plan

## T-01: Testing layers and ownership
Domain/unit: state machine, event validation, template schema, geometry, rotation/crop, PIN rate limits, retention. Persistence: Drift migrations, file journal atomic rename/startup reconciliation, import corruption/zip traversal/collisions, missing asset, interrupted writes. Rendering: fixtures, layer order, slot clipping, alpha, text wrapping, output dimensions, image orientation/mirroring, exact revision reuse. Widget: operator navigation, empty/error/disabled states, editor gestures and undo, accessible buttons, guest isolation. Integration: offline event -> capture mocked or real -> render -> gallery -> export. Physical-device: real permissions, camera, thermal, orientation and kiosk interaction. Manual: lighting readability, enclosure ergonomics, release deployment.

## T-02: Synthetic test fixture catalog
`FIX-01`: 4x6 template with 2 photo slots, striped source images, transparent flower PNG that crosses both slots and extends outside their boundaries; use pixel samples to verify outside-slot alpha shows and slot crop remains correct.
`FIX-02`: 2x6 with three photo slots + centered text + frame; check 600x1800 render output.
`FIX-03`: 4x6 landscape with 90/270-degree rotated images and custom crop focal points; check photo/preview mapping.
`FIX-04`: opaque PNG vs transparent PNG with anti-aliased edges; check no black/white halo.
`FIX-05`: multiple text sizes, multiline string, font face and licensed packaged fonts; test text measurements across platforms with documented tolerance.
`FIX-06`: intentionally corrupt PNG/unknown layer/unknown version/missing referenced asset/oversized dimensions/zip traversal; reject safely.
`FIX-07`: old DB/templates with v1 schema and migration fixture; ensure no discarded event/session data.
`FIX-08`: session with original + two retakes for slot 1, selected photo mapping; ensure originals untouched and final uses selected file.
`FIX-09`: fake FileStore fault injection at write temp, after rename, before DB commit and before thumbnail; startup reconciliation expectations.
`FIX-10`: fixed deterministic timestamps, IDs and imported image EXIF/mirror flags; assert recovery/state changes independent of wall clock.

Fixtures should be created as owned test graphics/photos with license metadata; do not use personal wedding photos in repository unless consent/provenance is appropriate.

## T-03: Suggested automated commands
```
flutter doctor -v
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test test/rendering/
flutter test test/persistence/
flutter test integration_test/  # if supported for target/environment
flutter build apk --release       # Android release smoke build; signing separately
flutter build ios --release       # macOS/Xcode host and signing required
```
Commands need adaptation to current SDK and exact project setup. Do not assume that `flutter test integration_test/` exercises a physical camera; it may run simulator/mocked integration. Record exit code, device ID and environment. For CI, run format/analyzer/unit/widget/renderer/migrations at each PR. Real camera/soak remains hardware gate.

## T-04: Certified-device matrix template
| Device ID | Make/model | OS | App build | Guest orient | Lens | Live preview | Capture | Render | Export | Kiosk | Soak |
|---|---|---|---|---|---|---|---|---|---|---|---|
| IPAD-01 | TBD | TBD | TBD | Portrait | Front | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED |
| IPAD-01 | TBD | TBD | TBD | Landscape | Front | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED |
| AND-01 | TBD | TBD | TBD | Portrait | Front | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED |
| AND-01 | TBD | TBD | TBD | Landscape | Front | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED | BLOCKED |

Use actual model, memory, camera and OS versions. A passing Android device does not certify other Android cameras. Prefer one recent iPad and one mainstream tablet as first certification, not universal support.

## T-05: Orientation conditions
Test physical booth landscape/portrait both platforms: app cold start, operator switches orientation, guest launch, camera preview mirror and sensor orientation, countdown, capture EXIF, final print page, between-shot rotation policy, state preservation on orientation change, UI safe areas. Record when requested lock is not honored. On iPad, review full-screen Xcode settings; on Android, test Android 16/API 36 large-screen overrides and Android 17/API 37 non-optional adaptive behavior; orientation requested by app may be ignored. Never call orientation “working” based on simulator layout alone.

## T-06: Event soak protocol
1. Wipe synthetic test gallery or reset testing dataset; preserve logs.
2. Launch with airplane mode enabled; continuous supported charger, ventilated kiosk/stand, realistic indoor LED lighting.
3. Run target **100 completed sessions per platform** in 1-, 3-, and 4-shot configurations (can combine using operator script); mix retakes and template selection.
4. Measure completed originals/outputs before and after; verify no dropped/duplicated primary outputs.
5. Run at least one multi-hour powered soak on each certified device; record actual duration (not 'passed' unless performed), peak resident memory, render times, battery/power and thermal notices. No fixed thermal API promises.
6. Interrupt at different points (countdown, capture, after temp save, rendering, finish) and verify recoverable outcomes.
7. Run app restart/reboot tests and inspect gallery/template revision integrity.
8. Log bugs, results, environment and decision to certify/not certify.

## T-07: Performance baseline measurements (tune after first real device)
- Camera ready latency from Start/preview request.
- Capture shutter command to verified image file.
- 4x6 1200x1800 render time p50/p95 with representative layers; image memory/cache usage; no drift over 100 sessions.
- Editor fps and gesture latency with 20+ layers and two large PNGs.
- Gallery first-load, thumbnail scroll and export 100 outputs.
- On-device available storage estimate, low-storage threshold, recovery success.
Do not invent platform-independent numeric guarantees before hardware measurement. Establish production thresholds based on measured certified hardware and documented acceptable user experience.

## T-08: Security/privacy review
- PIN not in plaintext database/logs, rate-limit path tested, operator reentry guarded.
- Guest cannot navigate back to old photos/settings, no OS share sheet from guest routes.
- Request only necessary permissions, device logs sanitized, no network transmission; test airplane mode and inspect network permissions.
- Delete/session retention and backup export verified; clear permission/consent/retention copy.
- Template archives hardened against traversal/zip bombs/corrupt files.
- Restore to new sandbox and verify counts/checksums.

## T-09: Release criteria
Commercial ready only if all release-blocking `AC-*` items have evidence. Hardware gaps can't be checked by mocks. Printer remains excluded and clearly marked not configured. Produce a final release packet containing version, supported devices, signed artifact IDs/checksums, tests, security/privacy summary, known issues, maintenance/backup instructions and go/no-go decision.


## T-10: Required early M01 feasibility evidence (v3.1)
Execute AC-0101..AC-0108 BEFORE M02 visual-polish work. Output artifacts: 1200×1800 still composition, fixture/golden tests with out-of-slot PNG overlay, camera test photos from an actual iPad AND Android device (if available), recorded device metadata, raw timing/memory notes and limitation/ADR summary. If either device is absent, report BLOCKED and explicit instructions; no simulator or mock substitution qualifies for the physical gate. Build and device certification at M11 remains independent and mandatory.

## v3.2 phone delivery certification addition
At M09, perform locally mocked deterministic unit/contract/security tests AND genuine end-to-end verified MMS preview + secure full-quality download testing on certified iPad and Android booths to approved real US recipient phones/carriers. Exercise venue Wi-Fi/hotspot outage, resume, duplicate-submit, webhook tampering, STOP/HELP suppression, TTL expiration, URL revocation, cleanup/provider media retention and spend caps. Run `docs/PHONE_DELIVERY_ACCEPTANCE.md` AC-0901–AC-0922. Include an explicit sender registration/legal-review go/no-go; do not confuse provider accepted/sent with delivered/read. At shifted M11 device certification and M12 release gate also revisit enabled texting states, or ship texting disabled and explicitly label its certification BLOCKED.
