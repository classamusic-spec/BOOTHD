# iPadOS validation path (macOS required)

iPadOS builds, simulators, signing and device runs need a Mac with Xcode.
None of these were possible on the Linux host used for M00, so every iPadOS
check is BLOCKED until someone runs this procedure and records the results in
`docs/ACCEPTANCE_EVIDENCE.md`.

## Option A: CI (unsigned build only)

GitHub → Actions → **CI** → **Run workflow**, tick **ios**. The `ios` job
runs `tool/build_ios.sh release` (unsigned) on a macOS runner. A green job
proves the project compiles for iPadOS. It proves nothing about launch,
camera or signing.

## Option B: an owner Mac (needed for simulator, device and signing)

1. **Prerequisites.** macOS that runs Xcode 16 or newer (Flutter 3.47.7
   requires 15+, recommends 16; App Store submission may require the latest
   Xcode, so check Apple's current rule at M12). Install Xcode, open it once,
   then `sudo xcodebuild -runFirstLaunch`. Install CocoaPods 1.16.2 or newer
   if `flutter doctor` asks for it.
2. **Flutter 3.47.7 exactly** (the version pinned in `pubspec.yaml`), e.g.
   with FVM: `fvm install 3.47.7 && fvm use 3.47.7`.
3. **Record the inventory:** `mkdir -p docs/device_tests && tool/toolchain_inventory.sh > docs/device_tests/mac-inventory-$(date +%F).txt`
4. **Static checks:** `tool/check.sh` (must pass, as on Linux).
5. **Unsigned build:** `tool/build_ios.sh release`; record the exit code.
   Since M01 the app has plugins (`camera`, `path_provider`, and since M06
   `permission_handler`). Flutter
   3.47.7 integrates them with Swift Package Manager, so the first Mac
   build may add that wiring to `ios/Runner.xcodeproj`; commit the change.
6. **Simulator launch (AC-0004):** boot an iPad simulator
   (`open -a Simulator`, choose an iPad), then
   `flutter test integration_test -d <simulator-id>`. Repeat in portrait and
   landscape. Simulators never satisfy DEVICE gates.
7. **Physical iPad (M01 onward):** in Xcode open `ios/Runner.xcworkspace`,
   set the owner's Team under Signing & Capabilities, replace the
   placeholder bundle ID (ADR-0001), connect the iPad, enable Developer Mode,
   then `flutter run -d <ipad-id>` and
   `flutter test integration_test -d <ipad-id>`. Record model, iPadOS
   version, build mode and results.

## Camera permission builds (M06, ADR-0012)

`permission_handler` decides at build time which permissions exist. With
Swift Package Manager it finds `NSCameraUsageDescription` in
`ios/Runner/Info.plist` only when the build starts in the project
directory: `flutter run`, `flutter build ios`, `flutter build ipa` and
`xcodebuild` from the repository qualify. **A build or archive started
from Xcode.app compiles the camera permission out, and the booth then
reads camera access as refused on every iPad.** Archive with
`flutter build ipa`, or before using Xcode.app run once:

```sh
launchctl setenv PERMISSION_HANDLER_INFO_PLIST "$PWD/ios/Runner/Info.plist"
rm -rf ~/Library/Developer/Xcode/DerivedData
```

If a build ever falls back to CocoaPods (a generated `ios/Podfile`), add
`'PERMISSION_CAMERA=1'` to `GCC_PREPROCESSOR_DEFINITIONS` in the
Podfile's `post_install` block (see the plugin's README) and commit it.
To confirm a build, delete the app, install it and open Diagnostics >
Camera test > Allow camera: the system prompt must appear (M06 device
procedure, step 1). `PERMISSION_HANDLER_VERBOSE=1` makes the command-line
build log which permissions were enabled.

## What to record

For each step: date, Mac model, macOS, Xcode and Flutter versions, command,
exit code, device or simulator model and OS, orientation, result and
evidence path, mapped to the AC ID (format in `docs/ACCEPTANCE_EVIDENCE.md`).
