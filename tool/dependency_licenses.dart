// Generates docs/DEPENDENCY_LICENSES.md from the resolved dependency graph
// (pubspec.lock, via `flutter pub deps --json`) and each package's LICENSE.
//
//   dart run tool/dependency_licenses.dart          rewrite the report
//   dart run tool/dependency_licenses.dart --check  exit 1 if it is stale
//
// The report separates the runtime dependency graph (treated as shipped)
// from development tooling, so the release licence audit (AC-1204) starts
// from facts. The licence column is a text heuristic; anything unrecognised
// is flagged for manual review rather than guessed.
import 'dart:convert';
import 'dart:io';

const _reportPath = 'docs/DEPENDENCY_LICENSES.md';

Future<void> main(List<String> args) async {
  final report = _render(await _resolvedPackages());
  final file = File(_reportPath);

  if (args.contains('--check')) {
    if (!file.existsSync() || file.readAsStringSync() != report) {
      stderr.writeln(
        '$_reportPath does not match pubspec.lock. '
        'Run: dart run tool/dependency_licenses.dart',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('$_reportPath matches pubspec.lock.');
    return;
  }

  file.writeAsStringSync(report);
  stdout.writeln('Wrote $_reportPath');
}

final class _Package {
  _Package({
    required this.name,
    required this.version,
    required this.source,
    required this.ships,
    required this.direct,
    required this.license,
  });

  final String name;
  final String version;
  final String source;
  final bool ships;
  final bool direct;
  final String license;
}

Future<List<_Package>> _resolvedPackages() async {
  final result = await Process.run('flutter', [
    'pub',
    'deps',
    '--json',
  ], runInShell: true);
  if (result.exitCode != 0) {
    throw StateError('flutter pub deps failed: ${result.stderr}');
  }
  final output = result.stdout as String;
  final json =
      jsonDecode(output.substring(output.indexOf('{'))) as Map<String, Object?>;
  final packages = [
    for (final entry in json['packages']! as List<Object?>)
      entry! as Map<String, Object?>,
  ];
  final byName = {for (final p in packages) p['name']! as String: p};
  final root = packages.firstWhere((p) => p['kind'] == 'root');
  final mainDeps = _strings(root['directDependencies']);

  // Everything reachable from non-dev direct dependencies is treated as
  // shipped in the app.
  final shipped = <String>{};
  final pending = [...mainDeps];
  while (pending.isNotEmpty) {
    final name = pending.removeLast();
    if (shipped.add(name)) {
      pending.addAll(_strings(byName[name]!['dependencies']));
    }
  }

  final roots = _packageRoots();
  // package:flutter lives at <sdk>/packages/flutter.
  final sdkRoot = roots['flutter']!.parent.parent;
  return [
    for (final p in packages)
      if (p['kind'] != 'root')
        _Package(
          name: p['name']! as String,
          version: p['version']! as String,
          source: p['source']! as String,
          ships: shipped.contains(p['name']),
          direct: p['kind'] == 'direct' || p['kind'] == 'dev',
          license: _license(p['name']! as String, roots[p['name']], sdkRoot),
        ),
  ]..sort((a, b) => a.name.compareTo(b.name));
}

List<String> _strings(Object? list) => [
  for (final item in (list as List<Object?>?) ?? const []) item! as String,
];

Map<String, Directory> _packageRoots() {
  final config = jsonDecode(
    File('.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final configDir = Directory('.dart_tool').absolute.uri;
  return {
    for (final entry
        in (config['packages']! as List<Object?>).cast<Map<String, Object?>>())
      entry['name']! as String: Directory.fromUri(
        configDir.resolve(entry['rootUri']! as String),
      ),
  };
}

String _license(String name, Directory? root, Directory sdkRoot) {
  if (name == 'sky_engine') {
    return 'Multiple (Flutter engine with bundled third-party notices)';
  }
  if (root == null) return 'UNKNOWN: package root not found';

  // Flutter SDK packages without their own LICENSE use the SDK's licence.
  final candidates = [
    root,
    if (root.absolute.path.startsWith(sdkRoot.absolute.path)) sdkRoot,
  ];
  for (final dir in candidates) {
    for (final fileName in [
      'LICENSE',
      'LICENSE.md',
      'LICENSE.txt',
      'COPYING',
    ]) {
      final file = File('${dir.path}/$fileName');
      if (file.existsSync()) return _classify(file.readAsStringSync());
    }
  }
  return 'UNKNOWN: no LICENSE file (manual review)';
}

String _classify(String text) {
  final t = text.replaceAll(RegExp(r'\s+'), ' ');
  if (t.contains('Apache License') && t.contains('Version 2.0')) {
    return 'Apache-2.0';
  }
  if (t.contains('Permission is hereby granted, free of charge')) return 'MIT';
  if (t.contains('Redistribution and use in source and binary forms')) {
    return t.contains('Neither the name') ||
            t.contains('names of its contributors')
        ? 'BSD-3-Clause'
        : 'BSD-2-Clause';
  }
  if (t.contains('Mozilla Public License') && t.contains('2.0')) {
    return 'MPL-2.0';
  }
  return 'UNKNOWN (manual review)';
}

String _render(List<_Package> packages) {
  String table(Iterable<_Package> rows) => [
    '| Package | Version | Source | Direct | Licence (detected) |',
    '| --- | --- | --- | --- | --- |',
    for (final p in rows)
      '| ${p.name} | ${p.version} | ${p.source} | '
          '${p.direct ? 'yes' : ''} | ${p.license} |',
  ].join('\n');

  final shipped = packages.where((p) => p.ships);
  final tooling = packages.where((p) => !p.ships);
  final review = packages.where((p) => p.license.startsWith('UNKNOWN'));
  return '''
# Dependency licences

Generated by `dart run tool/dependency_licenses.dart` from `pubspec.lock`.
Do not edit by hand; `tool/check.sh` and CI fail when this file is stale.

Licence names come from a text heuristic over each package's LICENSE file and
are a starting point for the release audit (AC-1204), not a legal opinion.
SDK packages report version 0.0.0 and are pinned by the Flutter SDK version.

## Runtime dependency graph: treat as shipped (${shipped.length})

Everything reachable from the app's non-dev dependencies. Deliberately
conservative: release compilation drops unused code, but the licence audit
covers this whole set.

${table(shipped)}

## Development and test tooling only (${tooling.length})

${table(tooling)}

## Needs manual review (${review.length})

${review.isEmpty ? 'None.' : review.map((p) => '- ${p.name} ${p.version}: ${p.license}').join('\n')}
''';
}
