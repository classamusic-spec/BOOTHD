// AC-0408 / FIX-06 (zip traversal and bombs): the package reader accepts
// well-formed stored and deflated archives and refuses every hostile or
// broken structure with a specific problem, before using any entry.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/infrastructure/templates/zip_archive.dart';

import 'support/raw_zip.dart';

const _limits = ZipLimits(
  maxArchiveBytes: 4 * 1024 * 1024,
  maxEntries: 8,
  maxEntryBytes: 3 * 1024 * 1024,
  maxTotalBytes: 3 * 1024 * 1024 + 10,
  maxRatio: 100,
);

Matcher _refused(ZipProblem problem) =>
    throwsA(isA<ZipException>().having((e) => e.problem, 'problem', problem));

void main() {
  final hello = utf8.encode('hello, booth');

  test('stored archives round-trip byte for byte, deterministically', () {
    final entries = [
      (name: 'template.json', bytes: Uint8List.fromList(hello)),
      (name: 'assets/a.png', bytes: Uint8List.fromList(List.filled(5000, 7))),
    ];
    final zip = writeZip(entries);
    expect(writeZip(entries), zip);
    final read = readZip(zip, limits: _limits);
    expect(read.names, ['template.json', 'assets/a.png']);
    expect(read.files['template.json'], hello);
    expect(read.files['assets/a.png'], List.filled(5000, 7));
  });

  test('our archives also open in the platform unzip tool', () async {
    final zip = writeZip([
      (name: 'template.json', bytes: Uint8List.fromList(hello)),
    ]);
    final dir = await Directory.systemTemp.createTemp('zip_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/package.zip')..writeAsBytesSync(zip);
    final result = await Process.run('unzip', ['-t', file.path]);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  }, skip: Platform.isLinux || Platform.isMacOS ? false : 'no unzip');

  test('deflated entries (as other tools write them) are read', () {
    final zip = rawZip([
      RawEntry('template.json', hello, method: 8),
      RawEntry('assets/', const []),
    ]);
    final read = readZip(zip, limits: _limits);
    expect(read.files['template.json'], hello);
    expect(read.files.containsKey('assets/'), isFalse);
    expect(read.names, contains('assets/'));
  });

  test('only wanted entries are inflated', () {
    final zip = rawZip([
      RawEntry('template.json', hello),
      RawEntry('__MACOSX/._template.json', [1, 2, 3]),
    ]);
    final read = readZip(
      zip,
      limits: _limits,
      wanted: (name) => !name.startsWith('__MACOSX/'),
    );
    expect(read.files.keys, ['template.json']);
  });

  group('unsafe entry names are refused', () {
    for (final name in [
      '../template.json',
      'assets/../../escape.png',
      '/etc/passwd',
      r'assets\evil.png',
      'C:evil.png',
      'assets//double.png',
      './template.json',
      'tab\there.png',
      'nul\u0000.png',
      '',
    ]) {
      test(jsonEncode(name), () {
        expect(
          () => readZip(rawZip([RawEntry(name, hello)]), limits: _limits),
          _refused(ZipProblem.unsafe),
        );
      });
    }
  });

  test('symbolic links are refused', () {
    final link = RawEntry(
      'assets/link.png',
      utf8.encode('../../outside'),
      madeBy: 3 << 8 | 30,
      externalAttributes: 0xA1FF << 16,
    );
    expect(
      () => readZip(rawZip([link]), limits: _limits),
      _refused(ZipProblem.unsafe),
    );
  });

  test('duplicate names, in any letter case, are refused', () {
    expect(
      () => readZip(
        rawZip([
          RawEntry('template.json', hello),
          RawEntry('Template.JSON', hello),
        ]),
        limits: _limits,
      ),
      _refused(ZipProblem.unsafe),
    );
  });

  test('a local header that names a different file is refused', () {
    expect(
      () => readZip(
        rawZip([RawEntry('template.json', hello, localName: '../evil.json')]),
        limits: _limits,
      ),
      _refused(ZipProblem.unsafe),
    );
  });

  test('entries sharing bytes (a non-recursive bomb) are refused', () {
    final inner = RawEntry('assets/b.png', hello);
    final outerData = inner.local();
    final outer = RawEntry('assets/a.png', outerData);
    final zip = rawZip([
      outer,
      RawEntry(
        'assets/b.png',
        hello,
        writeLocal: false,
        offset: 30 + 'assets/a.png'.length,
      ),
    ]);
    expect(() => readZip(zip, limits: _limits), _refused(ZipProblem.unsafe));
  });

  test(
    'a highly compressed entry (a zip bomb) is refused before inflating',
    () {
      final bomb = RawEntry(
        'assets/a.png',
        Uint8List(3 * 1024 * 1024),
        method: 8,
      );
      expect(
        () => readZip(rawZip([bomb]), limits: _limits),
        _refused(ZipProblem.tooLarge),
      );
    },
  );

  test('inflating more than the declared size stops at once', () {
    final liar = RawEntry(
      'assets/a.png',
      Uint8List(60000),
      method: 8,
      size: 1000,
    );
    expect(
      () => readZip(rawZip([liar]), limits: _limits),
      _refused(ZipProblem.invalid),
    );
  });

  test('size limits: entry, total, count and archive', () {
    final big = Uint8List(3 * 1024 * 1024 + 1);
    expect(
      () => readZip(rawZip([RawEntry('a.bin', big)]), limits: _limits),
      _refused(ZipProblem.tooLarge),
    );
    final half = Uint8List(2 * 1024 * 1024);
    expect(
      () => readZip(
        rawZip([RawEntry('a.bin', half), RawEntry('b.bin', half)]),
        limits: _limits,
      ),
      _refused(ZipProblem.tooLarge),
    );
    expect(
      () => readZip(
        rawZip([for (var i = 0; i < 9; i++) RawEntry('f$i.txt', hello)]),
        limits: _limits,
      ),
      _refused(ZipProblem.tooLarge),
    );
    expect(
      () => readZip(Uint8List(4 * 1024 * 1024 + 1), limits: _limits),
      _refused(ZipProblem.tooLarge),
    );
  });

  test('encryption, other compression methods, ZIP64 and split archives '
      'are unsupported', () {
    for (final zip in [
      rawZip([RawEntry('template.json', hello, flags: 0x0801)]),
      rawZip([RawEntry('template.json', hello, method: 12)]),
      rawZip([RawEntry('template.json', hello)], zip64Locator: true),
      rawZip([RawEntry('template.json', hello, size: 0xFFFFFFFF)]),
      rawZip([RawEntry('template.json', hello)], disk: 1),
    ]) {
      expect(
        () => readZip(zip, limits: _limits),
        _refused(ZipProblem.unsupported),
      );
    }
  });

  test('damage is found: CRC, sizes, truncation, trailing data, garbage', () {
    final good = rawZip([RawEntry('template.json', hello)]);
    for (final zip in [
      rawZip([RawEntry('template.json', hello, crc: 1234)]),
      rawZip([RawEntry('template.json', hello, size: hello.length + 1)]),
      Uint8List.sublistView(good, 0, good.length - 5),
      rawZip([RawEntry('template.json', hello)], trailing: [0, 1, 2]),
      Uint8List.fromList(utf8.encode('this is not a zip file at all, sorry')),
      Uint8List(0),
      rawZip([RawEntry('template.json', hello)], entryCountOverride: 2),
    ]) {
      expect(() => readZip(zip, limits: _limits), _refused(ZipProblem.invalid));
    }
  });

  test('non-UTF-8 entry names are refused', () {
    final latin1Name = RawEntry('café.png', hello, flags: 0);
    expect(
      () => readZip(rawZip([latin1Name]), limits: _limits),
      _refused(ZipProblem.invalid),
    );
  });
}
