# Toolchain and host inventory

Recorded for M00 (AC-0002) on 2026-10-17 UTC. Regenerate the raw data with
`tool/toolchain_inventory.sh`. Upgrades follow ADR-0001.

## Development host used for M00

| Item | Value |
| --- | --- |
| Host | Claude Code cloud session: Ubuntu 24.04.5 LTS, Linux 6.18.44 (Firecracker VM), x86_64, 4 vCPU, 15 GB RAM |
| Virtualisation | No `/dev/kvm`: Android emulators cannot run on this host |
| macOS / Xcode | **Not available (Linux host).** iPadOS build, simulator and signing checks are BLOCKED here |
| Physical devices | **None attached.** No iPad, no Android tablet |
| Network | Egress through the session proxy. Maven Central intermittently returned HTTP 429; Gradle was pointed at Google's public Maven Central mirror by a container-local init script (`~/.gradle/init.d`, not in the repository) |

## Pinned toolchain

| Component | Version | Source |
| --- | --- | --- |
| Flutter | 3.47.7 stable (framework abaf9c5237, engine deb287481e, 2026-10-08) | storage.googleapis.com release archive, SHA-256 verified |
| Dart | 3.13.5 | bundled with Flutter |
| DevTools | 2.60.0 | bundled with Flutter |
| Java (host) | OpenJDK 21.0.12.1 (Ubuntu) | system package; CI uses Temurin 21 |
| Gradle | 9.3.1 (wrapper) | Flutter 3.47.7 template |
| Android Gradle Plugin | 9.1.0 | Flutter 3.47.7 template |
| Kotlin Gradle Plugin | 2.4.0 | Flutter 3.47.7 template |
| Android compileSdk / targetSdk / minSdk | 37 / 36 / 24 (compileSdk was 36 until M06; ADR-0012) | Flutter 3.47.7 defaults, compileSdk raised for `permission_handler_android` 14 |
| Android build-tools | 36.0.0 | sdkmanager |
| Android platform | android-36 (r02); android-37.0 (r02) since M06, installed by `tool/build_android.sh` | sdkmanager |
| Android NDK | 28.2.13676358 (r28c) | sdkmanager (Flutter default `ndkVersion`) |
| Android platform-tools | 37.0.1 | sdkmanager |
| Android platform 35, CMake 3.22.1 | auto-installed by AGP during the first M01 build (plugins compile against API 35; JNI-based `path_provider_android` builds native code) | AGP |
| Android command-line tools | 23.0.0 ("Android CLI" 1.0.16625370; `sdkmanager` is now a deprecated wrapper) | dl.google.com |
| iOS deployment target | 15.0 | Flutter 3.47.7 template |
| Xcode required by Flutter 3.47.7 | 15 or newer (16 recommended); CocoaPods 1.10+ (1.16.2 recommended) | `flutter_tools` source |

Note: AGP 9.1.0 warns that the SDK metadata written by command-line tools 23
uses XML version 4 while it understands up to 3. The build succeeds; revisit
when AGP is upgraded.

## Plugin compatibility

Dry runs against Flutter 3.47.7 on 2026-10-17; `camera`, `path_provider` and
`crypto` 3.0.7 were added in M01 (2026-10-18) at the versions below:

| Package | Resolves to | Milestone that adds it |
| --- | --- | --- |
| camera | 0.12.1, with camera_android_camerax 0.7.5+1 (minSdk 23) and camera_avfoundation 0.10.3+1 (iOS 13.0+) | added M01 |
| drift | 2.35.2 | M03 |
| path_provider | 2.1.6 (path_provider_android 2.3.1 uses JNI) | added M01 |
| flutter_secure_storage | 11.2.0 | M03 |

## Signing

| Platform | State |
| --- | --- |
| Android | Debug keystore only; release builds are signed with the debug key (template default). Release keystore and Play signing: M12 |
| iPadOS | No Apple Developer team, certificate or provisioning profile on this host. BLOCKED until a Mac with the owner's team is available |
| Identifiers | Placeholders `com.example.porcelainPhotoBooth` / `com.example.porcelain_photo_booth` (ADR-0001) |

## Devices and emulators

`flutter devices` lists only "Linux (desktop)", which is not a target
platform. `flutter emulators` finds no AVD images, and none can run without
KVM. No iOS simulators (Linux host).

## flutter doctor -v (2026-10-17)

```text
[✓] Flutter (Channel stable, 3.47.7, on Ubuntu 24.04.5 LTS 6.18.44-fc-v139, locale en_US) [626ms]
    • Flutter version 3.47.7 on channel stable at /opt/flutter
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision abaf9c5237 (9 days ago), 2026-10-08 09:51:21 -0700
    • Engine revision deb287481e
    • Dart version 3.13.5
    • DevTools version 2.60.0
    • Feature flags: enable-web, enable-linux-desktop, enable-macos-desktop, enable-windows-desktop, enable-android, enable-ios, no-cli-animations, enable-native-assets, enable-record-use, enable-swift-package-manager, omit-legacy-version-file, enable-lldb-debugging, enable-uiscene-migration

[✓] Android toolchain - develop for Android devices (Android SDK version 36.0.0) [187ms]
    • Android SDK at /opt/android-sdk
    • Emulator version unknown
    • Platform android-36, build-tools 36.0.0
    • ANDROID_HOME = /opt/android-sdk
    • ANDROID_SDK_ROOT = /opt/android-sdk
    • Java binary at: /usr/lib/jvm/java-21-openjdk-amd64/bin/java
      This JDK is specified by the JAVA_HOME environment variable.
      To manually set the JDK path, use: `flutter config --jdk-dir="path/to/jdk"`.
    • Java version OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
    • All Android licenses accepted.

[✗] Chrome - develop for the web (Cannot find Chrome executable at google-chrome) [78ms]
    ! Cannot find Chrome. Try setting CHROME_EXECUTABLE to a Chrome executable.

[✗] Linux toolchain - develop for Linux desktop [461ms]
    • Ubuntu clang version 18.1.3 (1ubuntu1)
    • cmake version 3.28.3
    • ninja version 1.11.1
    • pkg-config version 1.8.1
    ✗ GTK 3.0 development libraries are required for Linux development.
      They are likely available from your distribution (e.g.: apt install libgtk-3-dev)
    ! Unable to access driver information using 'eglinfo'.
      It is likely available from your distribution (e.g.: apt install mesa-utils)

[✓] Connected device (1 available) [184ms]
    • Linux (desktop) • linux • linux-x64 • Ubuntu 24.04.5 LTS 6.18.44-fc-v139

[✓] Network resources [658ms]
    • All expected network resources are available.

! Doctor found issues in 2 categories.
```

Chrome and the Linux desktop toolchain are not project targets; their
failures are expected and irrelevant.
