// AC-1007 permission audit, on the sources the release builds come from:
// the booth asks for the camera and, for optional texting, the network;
// nothing else, and it never starts or stops a kiosk lock. The merged
// Android manifest (with plugins' and libraries' entries) is audited from
// the built APK by tool/audit_permissions.sh, in CI and the evidence.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _matches(RegExp pattern, String text) =>
    pattern.allMatches(text).map((match) => match.group(1)!).toSet();

void main() {
  test('Android: only the network is declared here, and what plugins add '
      'for audio, shared storage and network state is removed', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(
      _matches(
        RegExp(r'<uses-permission\s+android:name="([^"]+)"\s*/>'),
        manifest,
      ),
      {'android.permission.INTERNET'},
    );
    expect(
      _matches(
        RegExp(
          r'<uses-permission\s+android:name="([^"]+)"\s+tools:node="remove"',
        ),
        manifest,
      ),
      {
        'android.permission.RECORD_AUDIO',
        'android.permission.WRITE_EXTERNAL_STORAGE',
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.ACCESS_NETWORK_STATE',
      },
    );
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, isNot(contains('usesCleartextTraffic="true"')));
    expect(manifest, isNot(contains('requestLegacyExternalStorage')));
    expect(manifest, isNot(contains('android:lockTaskMode')));
  });

  test('iPadOS: the camera is the only protected resource the app asks '
      'for, App Transport Security stays at its defaults and nothing runs '
      'in the background', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(_matches(RegExp(r'<key>(NS\w+UsageDescription)</key>'), plist), {
      'NSCameraUsageDescription',
    });
    expect(plist, isNot(contains('NSAppTransportSecurity')));
    expect(plist, isNot(contains('UIBackgroundModes')));
    expect(plist, isNot(contains('UIFileSharingEnabled')));
  });

  test('the native code only reads the kiosk lock: nothing starts or stops '
      'one (AC-1002)', () {
    final native =
        [
          ...Directory('android/app/src/main').listSync(recursive: true),
          ...Directory('ios/Runner').listSync(recursive: true),
        ].whereType<File>().where(
          (file) => file.path.endsWith('.kt') || file.path.endsWith('.swift'),
        );
    expect(native, isNotEmpty);
    for (final file in native) {
      final code = file.readAsStringSync();
      for (final call in [
        'startLockTask',
        'stopLockTask',
        'setLockTaskPackages',
        'requestGuidedAccessSession',
      ]) {
        expect(code, isNot(contains(call)), reason: '${file.path}: $call');
      }
    }
  });
}
