// Host side of `flutter drive` for integration tests. Saves the data a
// device test reports (renders and metrics) under build/m01_device/ so it
// can be compared with host goldens and recorded as evidence.
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
    final directory = Directory('build/m01_device/${data['platform']}-$stamp')
      ..createSync(recursive: true);
    for (final (key, file) in [
      ('exportPngBase64', 'fix01_export.png'),
      ('workspacePngBase64', 'fix01_workspace.png'),
    ]) {
      if (data[key] case final String encoded) {
        File('${directory.path}/$file').writeAsBytesSync(base64Decode(encoded));
      }
    }
    final metrics = Map<String, Object?>.of(data)
      ..removeWhere((key, _) => key.endsWith('Base64'));
    File('${directory.path}/report.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(metrics));
    stdout.writeln('Saved device results to ${directory.path}');
  },
);
