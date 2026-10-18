# Porcelain Photo Booth

Offline-first photo booth for iPadOS and Android tablets, built as one
Flutter/Dart app. Operators design layered print templates in Studio Mode;
guests use a locked, simple Booth Mode with the tablet's built-in camera.

**Status: M02 (Porcelain design system and adaptive Studio shell)
complete on the host, awaiting owner review.** The app opens on the Studio
dashboard with Events, Templates, Gallery, Settings and Diagnostics; actions
that belong to later milestones are disabled and say why. Physical-device
checks from M01 remain BLOCKED until an iPad and an Android tablet are
available. See `docs/IMPLEMENTATION_LOG.md`, `docs/ACCEPTANCE_EVIDENCE.md`
and ADR-0008.

## Start here

1. `START_HERE.md`: the build package, locked decisions and milestone order.
2. `CLAUDE.md`: mandatory engineering rules.
3. `prompts/MILESTONE_PROMPTS.md`: one milestone at a time, each approved
   by the owner.
4. `docs/decisions/`: engineering ADRs and owner change requests
   (CR-001 sets the premium UX bar).

## Toolchain

Flutter **3.47.7** exactly (pinned in `pubspec.yaml`), Android SDK 36 with
NDK 28.2, Java 17+ (21 used). iPadOS work needs a Mac with Xcode 16+
(`docs/IOS_VALIDATION.md`). Full inventory: `docs/TOOLCHAIN_INVENTORY.md`.

## Everyday commands

```sh
tool/check.sh                    # lockfile, format, analyze, tests, licence report
tool/build_android.sh release    # Android APK smoke build (debug-signed)
tool/build_ios.sh release        # unsigned iPadOS build; macOS only, else BLOCKED
tool/toolchain_inventory.sh      # host and toolchain inventory
dart run tool/dependency_licenses.dart   # refresh docs/DEPENDENCY_LICENSES.md
flutter test integration_test/app_launch_test.dart -d <device>  # launch smoke test
flutter test --update-goldens test/rendering/   # only after an intentional render change
flutter test --update-goldens test/goldens/     # only after an intentional UI change (Linux)
```

CI (`.github/workflows/ci.yml`) runs `tool/check.sh` and an Android release
smoke build; the iPadOS build runs on demand on a macOS runner.

## Layout

```text
lib/
  main.dart            entry point
  app/                 composition root: bootstrap, app, router, providers
  core/                cross-cutting code: design system tokens and themes, platform info, routing paths
  domain/              pure Dart: value objects, service contracts, later documents and state machines
  features/<name>/     screens and controllers, one folder per feature
  infrastructure/      plugin and storage adapters (from M01)
  shared/              Porcelain component kit and the guest layout skeleton
test/                  architecture, design system, domain, widget, golden and app tests
integration_test/      device/simulator tests
tool/                  scripts used locally and by CI
docs/                  specifications, ADRs, evidence and logs
prompts/               milestone work orders
```

Import rules between layers are enforced by
`test/architecture/layer_boundaries_test.dart` (ADR-0005). Bundled fonts,
icons and artwork are recorded in `docs/ASSET_PROVENANCE.md`.
