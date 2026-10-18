# Porcelain Photo Booth

Offline-first photo booth for iPadOS and Android tablets, built as one
Flutter/Dart app. Operators design layered print templates in Studio Mode;
guests use a locked, simple Booth Mode with the tablet's built-in camera.

**Status: M04 (production template model, renderer and template store)
complete on the host, awaiting owner review.** Templates are versioned JSON
documents with photo slots, transparent artwork, text, shapes and
backgrounds; one painter renders previews and 300 dpi print files (2x6,
4x6 portrait or landscape, 4x4) as PNG with transparency or JPEG flattened
on purpose, saved atomically. Templates and their assets are stored by
content, revisions never change, and `.porcelain-template` packages are
checked strictly before anything is stored. Launch checks now render every
template of an event for real. The template library screen, editor and
file picker come in M05; the camera and sessions in M06. Physical-device
checks remain BLOCKED until an iPad and an Android tablet are available.
See `docs/IMPLEMENTATION_LOG.md`, `docs/ACCEPTANCE_EVIDENCE.md` and
ADR-0010.

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
tool/check.sh                    # lockfile, generated code, format, analyze, tests, licences
dart run build_runner build      # regenerate Drift code after editing the schema
dart run drift_dev make-migrations   # schema dump and migration-test schemas (bump the version first)
tool/build_android.sh release    # Android APK smoke build (debug-signed)
tool/build_ios.sh release        # unsigned iPadOS build; macOS only, else BLOCKED
tool/toolchain_inventory.sh      # host and toolchain inventory
dart run tool/dependency_licenses.dart   # refresh docs/DEPENDENCY_LICENSES.md
flutter test integration_test/app_launch_test.dart -d <device>  # launch smoke test
flutter drive --profile -d <device> --driver=test_driver/integration_test.dart \
  --target=integration_test/render_lab_test.dart   # render lab on a device (M04 procedure)
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
  core/                cross-cutting code: design system, routing, access, the composition painter
  domain/              pure Dart: value objects, service contracts, template documents and scenes
  features/<name>/     screens and controllers, one folder per feature
  infrastructure/      plugin, database (Drift), secure storage, files, codecs, renderer and template store
  shared/              Porcelain component kit and the guest layout skeleton
test/                  architecture, design system, domain, rendering, persistence, migration, widget, golden and app tests
test_assets/           committed render goldens, template fixtures and input photos
drift_schemas/         one JSON dump per database schema version (migration tests)
integration_test/      device/simulator tests
tool/                  scripts used locally and by CI
docs/                  specifications, ADRs, evidence and logs
prompts/               milestone work orders
```

Import rules between layers are enforced by
`test/architecture/layer_boundaries_test.dart` (ADR-0005). Bundled fonts,
icons and artwork are recorded in `docs/ASSET_PROVENANCE.md`.
