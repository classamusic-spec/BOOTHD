// Host side of `flutter drive` for integration tests. Saves the data a
// device test reports (renders and metrics) under build/device_renders/ so
// it can be compared with host goldens and recorded as evidence.
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp('[:.]'),
      '-',
    );
    final directory = Directory(
      'build/device_renders/${data['platform']}-$stamp',
    )..createSync(recursive: true);
    if (data['renders'] case final Map<String, Object?> renders) {
      for (final MapEntry(key: name, value: encoded) in renders.entries) {
        // Golden file names only: nothing a device reports can write
        // outside the results directory.
        if (encoded is String && RegExp(r'^[a-z0-9_]+\.png$').hasMatch(name)) {
          File('${directory.path}/$name')
              .writeAsBytesSync(base64Decode(encoded));
        }
      }
    }
    final metrics = Map<String, Object?>.of(data)..remove('renders');
    File('${directory.path}/report.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(metrics));
    stdout.writeln('Saved device results to ${directory.path}');
  },
);
