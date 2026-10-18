# ADR-0006: Test layers, CI and evidence rules

- Status: Accepted (M00, 2026-10-17)
- Related: TEST_AND_DEVICE_PLAN T-01..T-10; CLAUDE.md "Tests/builds"

## Test layers

| Layer | Location | Runs where | Arrives |
| --- | --- | --- | --- |
| Architecture fitness (import rules) | `test/architecture/` | every `flutter test` | M00 |
| Domain unit tests (pure Dart) | `test/domain/` | every `flutter test` | M00 |
| Widget, layout and accessibility tests | `test/widgets/`, `test/app/` | every `flutter test` | M00 |
| Renderer geometry and golden tests | `test/rendering/` | every `flutter test`; cross-platform comparison on devices | M01/M04 |
| Persistence and migration tests | `test/persistence/` | every `flutter test` | M03 |
| Integration tests | `integration_test/` | emulator, simulator or device only | M00 (launch smoke) |
| Physical-device certification | `docs/device_tests/` | real iPad and Android tablet | M01, M06, M11 |

- Layout tests run at named portrait and landscape tablet viewports
  (`test/support/tablet_viewports.dart`) and at 200% text scale; they become
  the golden-screenshot sizes once certified devices are chosen.
- Accessibility uses Flutter's guideline matchers (`textContrastGuideline`,
  `androidTapTargetGuideline`, `iOSTapTargetGuideline`,
  `labeledTapTargetGuideline`); CR-001 makes them mandatory for every screen.
- Golden tolerance is measured in M01 across platforms and written down; it
  is never widened just to pass.

## Local and CI checks

- `tool/check.sh` is the single local and CI entry point: lockfile-enforced
  `pub get`, format check, analyze, tests, licence-report freshness.
- `.github/workflows/ci.yml`: `checks` and an Android release smoke build on
  Ubuntu for pushes to `main` and `claude/**` and for pull requests; an
  unsigned iPadOS build on macOS only on manual dispatch (`ios: true`).
- Toolchain is pinned to Flutter 3.47.7 in `pubspec.yaml` and CI.

## Evidence rules

- Every acceptance result goes in `docs/ACCEPTANCE_EVIDENCE.md` with AC ID,
  status (PASS, FAIL, BLOCKED, N/A with reason), command, exit code, host
  and device details.
- CI, simulators, emulators and mocks never satisfy DEVICE gates.
- A check that could not run is BLOCKED with the reason and the exact steps
  for the owner, never PASS.
