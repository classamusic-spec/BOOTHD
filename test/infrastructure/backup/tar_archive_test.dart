// The backup archive codec (AC-1006): what the writer makes, the reader
// reads back byte for byte with the same checksums, and standard tar can
// list it; anything the writer would never make (links, parent paths,
// names outside the root, bad checksums, archives cut short, sizes over
// the limits) is refused before anything is written.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/infrastructure/backup/tar_archive.dart';

const _limits = TarLimits(
  root: 'porcelain-backup',
  maxEntries: 100,
  maxEntryBytes: 4 * 1024 * 1024,
  maxTotalBytes: 16 * 1024 * 1024,
);

final _when = DateTime.utc(2026, 10, 19, 12);

Future<File> _archive(
  Directory dir,
  void Function(TarWriter writer) entries, {
  Future<void> Function(TarWriter writer)? more,
}) async {
  final file = File('${dir.path}/backup.tar');
  final sink = file.openWrite();
  final writer = TarWriter(sink);
  entries(writer);
  await more?.call(writer);
  await writer.close();
  await sink.close();
  return file;
}

/// A ustar header for [name] with [type], checksummed, for hostile cases.
Uint8List _header(String name, {int type = 0x30, int size = 0}) {
  final header = Uint8List(512);
  header.setRange(0, name.length, utf8.encode(name));
  void octal(int at, int width, int value) {
    final text = '${value.toRadixString(8).padLeft(width - 1, '0')}\u0000';
    header.setRange(at, at + width, ascii.encode(text));
  }

  octal(100, 8, 420);
  octal(108, 8, 0);
  octal(116, 8, 0);
  octal(124, 12, size);
  octal(136, 12, 0);
  header.fillRange(148, 156, 0x20);
  header[156] = type;
  header.setRange(257, 263, ascii.encode('ustar\u0000'));
  header.setRange(263, 265, ascii.encode('00'));
  final sum = header.fold<int>(0, (total, byte) => total + byte);
  header.setRange(
    148,
    155,
    ascii.encode('${sum.toRadixString(8).padLeft(6, '0')}\u0000'),
  );
  header[155] = 0x20;
  return header;
}

Future<File> _raw(Directory dir, List<Uint8List> blocks) async {
  final file = File('${dir.path}/hostile.tar');
  await file.writeAsBytes([
    for (final block in blocks) ...block,
    ...Uint8List(1024),
  ]);
  return file;
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tar-test');
    addTearDown(() => dir.delete(recursive: true));
  });

  test('files written are read back byte for byte, with their checksums, '
      'and extracted below the target only', () async {
    final photo = Uint8List.fromList(List.generate(70000, (i) => i % 251));
    final source = File('${dir.path}/photo.jpg')..writeAsBytesSync(photo);
    final long =
        'porcelain-backup/files/originals/'
        '${'a' * 60}/${'b' * 60}/photo-with-a-long-name.jpg';
    late String written;
    final archive = await _archive(
      dir,
      (writer) => writer
        ..addDirectory('porcelain-backup', modified: _when)
        ..addBytes(
          'porcelain-backup/README.txt',
          Uint8List.fromList(utf8.encode('hello')),
          modified: _when,
        ),
      more: (writer) async {
        written = await writer.addFile(long, source, modified: _when);
      },
    );
    expect(archive.lengthSync() % 512, 0);
    expect(written, crypto.sha256.convert(photo).toString());

    final target = await Directory('${dir.path}/out').create();
    final entries = await readTar(archive, limits: _limits, extractTo: target);
    expect(entries.map((entry) => entry.name), [
      'porcelain-backup',
      'porcelain-backup/README.txt',
      long,
    ]);
    expect(entries.last.sha256, written);
    expect(File('${target.path}/$long').readAsBytesSync(), photo);
    expect(
      File('${target.path}/porcelain-backup/README.txt').readAsStringSync(),
      'hello',
    );
  });

  test('standard tar lists what the writer made', () async {
    final archive = await _archive(
      dir,
      (writer) => writer.addBytes(
        'porcelain-backup/manifest.json',
        Uint8List.fromList(utf8.encode('{}')),
        modified: _when,
      ),
    );
    final listed = await Process.run('tar', ['-tf', archive.path]);
    expect(listed.exitCode, 0, reason: '${listed.stderr}');
    expect('${listed.stdout}'.trim(), 'porcelain-backup/manifest.json');
  }, skip: Platform.isLinux || Platform.isMacOS ? false : 'needs tar');

  for (final (why, name, type) in [
    ('a parent path', 'porcelain-backup/../../escape.txt', 0x30),
    ('an absolute path', '/etc/passwd', 0x30),
    ('a name outside the root', 'other/file.txt', 0x30),
    ('a symbolic link', 'porcelain-backup/link', 0x32),
    ('a hard link', 'porcelain-backup/hard', 0x31),
    ('a device', 'porcelain-backup/dev', 0x33),
    ('a pax header', 'porcelain-backup/pax', 0x78),
  ]) {
    test('$why is refused before anything is written', () async {
      final archive = await _raw(dir, [_header(name, type: type)]);
      final target = await Directory('${dir.path}/out').create();
      await expectLater(
        readTar(archive, limits: _limits, extractTo: target),
        throwsA(
          isA<TarException>().having(
            (error) => error.problem,
            'problem',
            TarProblem.unsafe,
          ),
        ),
      );
      expect(target.listSync(recursive: true), isEmpty);
    });
  }

  test('a duplicate name is refused', () async {
    final block = Uint8List(512);
    final archive = await _raw(dir, [
      _header('porcelain-backup/a.txt', size: 3),
      block,
      _header('porcelain-backup/a.txt', size: 3),
      block,
    ]);
    await expectLater(
      readTar(archive, limits: _limits),
      throwsA(isA<TarException>()),
    );
  });

  test('a changed header, a cut-short archive and a missing end are '
      'refused', () async {
    final good = await _archive(
      dir,
      (writer) => writer.addBytes(
        'porcelain-backup/a.bin',
        Uint8List(5000),
        modified: _when,
      ),
    );
    final bytes = good.readAsBytesSync();

    final tampered = File('${dir.path}/tampered.tar')
      ..writeAsBytesSync(Uint8List.fromList(bytes)..[20] ^= 0x01);
    await expectLater(
      readTar(tampered, limits: _limits),
      throwsA(isA<TarException>()),
    );

    final short = File('${dir.path}/short.tar')
      ..writeAsBytesSync(bytes.sublist(0, 2048));
    await expectLater(
      readTar(short, limits: _limits),
      throwsA(isA<TarException>()),
    );

    final noEnd = File('${dir.path}/noend.tar')
      ..writeAsBytesSync(bytes.sublist(0, bytes.length - 1024));
    await expectLater(
      readTar(noEnd, limits: _limits),
      throwsA(isA<TarException>()),
    );
  });

  test('entries over the size and count limits are refused before they '
      'are read', () async {
    final archive = await _raw(dir, [
      _header('porcelain-backup/huge.bin', size: 8 * 1024 * 1024),
    ]);
    await expectLater(
      readTar(archive, limits: _limits),
      throwsA(
        isA<TarException>().having(
          (error) => error.problem,
          'problem',
          TarProblem.tooLarge,
        ),
      ),
    );
  });
}
