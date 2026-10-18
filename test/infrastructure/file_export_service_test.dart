// AC-0409: an export that fails (full disk, short or corrupted write,
// failed rename, render failure) saves nothing, leaves no staged file, and
// never touches the originals or an earlier valid output. Repeated exports
// stay within bounded memory.
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/domain/services/export_service.dart';
import 'package:porcelain_photo_booth/domain/value_objects/entity_id.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_fixtures.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/atomic_file_writer.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/file_export_service.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';

import '../rendering/support/pixels.dart';

/// Reads FIX-01's photos from `originals/` on disk, as sessions will.
final class _DiskSource implements RenderSource {
  _DiskSource(this.root, this.assets);

  final Directory root;
  final Map<String, Uint8List> assets;

  @override
  Future<Uint8List> readAsset(String assetId) async => assets[assetId]!;

  @override
  Future<Uint8List> readPhoto(String photoId) async {
    final file = File('${root.path}/originals/$photoId.png');
    if (!file.existsSync()) {
      throw RenderFailure(RenderFailureCode.missingPhoto, detail: photoId);
    }
    return file.readAsBytes();
  }
}

/// File operations with one injected fault.
final class _Faulty extends FileOperations {
  _Faulty({
    this.noSpaceDuringWrite = false,
    this.shortWrite = false,
    this.corruptWrite = false,
    this.renameFails = false,
    this.deleteFails = false,
  });

  final bool noSpaceDuringWrite;
  final bool shortWrite;
  final bool corruptWrite;
  final bool renameFails;
  final bool deleteFails;

  @override
  Future<void> writeAndFlush(File file, Uint8List bytes) async {
    if (noSpaceDuringWrite) {
      // Half the file reaches the disk, then the volume fills up.
      await file.writeAsBytes(
        Uint8List.sublistView(bytes, 0, bytes.length ~/ 2),
      );
      throw FileSystemException(
        'Write failed',
        file.path,
        const OSError('No space left on device', 28),
      );
    }
    if (shortWrite) {
      // A write that silently loses its tail.
      await file.writeAsBytes(
        Uint8List.sublistView(bytes, 0, bytes.length - 100),
        flush: true,
      );
      return;
    }
    if (corruptWrite) {
      final damaged = Uint8List.fromList(bytes);
      damaged[damaged.length ~/ 2] ^= 0xFF;
      await file.writeAsBytes(damaged, flush: true);
      return;
    }
    return super.writeAndFlush(file, bytes);
  }

  @override
  Future<void> rename(File file, String newPath) async {
    if (renameFails) {
      throw FileSystemException(
        'Cannot rename file',
        file.path,
        const OSError('Input/output error', 5),
      );
    }
    return super.rename(file, newPath);
  }

  @override
  Future<void> delete(File file) async {
    if (deleteFails) {
      throw FileSystemException('Cannot delete file', file.path);
    }
    return super.delete(file);
  }
}

/// Every file under [root] (but staging) with its SHA-256.
Map<String, String> _snapshot(Directory root) => {
  for (final entity in root.listSync(recursive: true))
    if (entity is File && !entity.path.contains('/staging/'))
      entity.path.substring(root.path.length): crypto.sha256
          .convert(entity.readAsBytesSync())
          .toString(),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final renderer = DartUiCompositionRenderer();
  final fixture = fix01();
  late Directory root;
  late FileManagedStorage storage;
  late RenderSource source;
  late TemplateRender render;

  FileExportService service([FileOperations? operations]) => FileExportService(
    renderer: renderer,
    storage: storage,
    ids: RandomIdGenerator(),
    operations: operations ?? const FileOperations(),
  );

  Directory staging() => Directory('${root.path}/staging');

  setUp(() async {
    root = await Directory.systemTemp.createTemp('export_test');
    storage = FileManagedStorage(root: () async => root);
    await storage.prepare();
    for (final MapEntry(key: id, value: bytes) in fixture.photos.entries) {
      File('${root.path}/originals/$id.png').writeAsBytesSync(bytes);
    }
    source = _DiskSource(root, fixture.assets);
    render = TemplateRender(
      document: fixture.document,
      photos: fixture.selections,
      source: source,
    );
  });

  tearDown(() => root.delete(recursive: true));

  test('an export is a new, complete, verified file', () async {
    for (final format in OutputFormat.values) {
      final file = await service().export(
        render,
        output: OutputProfile(format: format),
      );
      expect(isEntityId(file.id), isTrue);
      expect(
        file.relativePath,
        'outputs/${file.id}.${format == OutputFormat.jpeg ? 'jpg' : 'png'}',
      );
      final bytes = File('${root.path}/${file.relativePath}').readAsBytesSync();
      expect(bytes.length, file.byteLength);
      expect(crypto.sha256.convert(bytes).toString(), file.sha256);
      final decoded = await decodeRgba(bytes);
      expect((decoded.width, decoded.height), (1200, 1800));
      expect((file.widthPx, file.heightPx), (1200, 1800));
      expect(file.renderVersion, rendererVersion);
      expect(await service().read(file), bytes);
    }
    expect(staging().listSync(), isEmpty);
  });

  test('exporting again never replaces an earlier output', () async {
    final first = await service().export(render);
    final before = _snapshot(root);
    final second = await service().export(render);
    expect(second.id, isNot(first.id));
    expect(second.sha256, first.sha256, reason: 'same inputs, same bytes');
    final after = _snapshot(root);
    for (final MapEntry(:key, :value) in before.entries) {
      expect(after[key], value, reason: key);
    }
    expect(after.length, before.length + 1);
  });

  for (final (name, operations, code) in [
    (
      'the disk fills up mid-write',
      _Faulty(noSpaceDuringWrite: true),
      ExportFailureCode.noSpace,
    ),
    (
      'a write silently loses its tail',
      _Faulty(shortWrite: true),
      ExportFailureCode.verifyFailed,
    ),
    (
      'the written bytes are corrupted',
      _Faulty(corruptWrite: true),
      ExportFailureCode.verifyFailed,
    ),
    (
      'moving the file into place fails',
      _Faulty(renameFails: true),
      ExportFailureCode.commitFailed,
    ),
  ]) {
    test('$name: nothing is saved and nothing else changes', () async {
      await service().export(render); // an earlier valid output
      final before = _snapshot(root);
      await expectLater(
        service(operations).export(render),
        throwsA(
          isA<ExportFailure>().having((failure) => failure.code, 'code', code),
        ),
      );
      expect(_snapshot(root), before);
      expect(staging().listSync(), isEmpty);
    });
  }

  test('a render failure writes nothing', () async {
    await service().export(render);
    final before = _snapshot(root);
    File('${root.path}/originals/photo-b.png')
        .renameSync('${root.path}/photo-b.moved');
    await expectLater(
      service().export(render),
      throwsA(
        isA<RenderFailure>().having(
          (failure) => failure.code,
          'code',
          RenderFailureCode.missingPhoto,
        ),
      ),
    );
    File('${root.path}/photo-b.moved')
        .renameSync('${root.path}/originals/photo-b.png');
    expect(_snapshot(root), before);
    expect(staging().listSync(), isEmpty);
  });

  test(
    'a staged file left by a crash is discarded at the next start',
    () async {
      // Rename fails and the clean-up delete fails too: the app "dies" with
      // a staged copy on disk.
      await expectLater(
        service(_Faulty(renameFails: true, deleteFails: true)).export(render),
        throwsA(isA<ExportFailure>()),
      );
      expect(staging().listSync(), hasLength(1));
      final unrelated = File('${staging().path}/keep.bin')
        ..writeAsBytesSync([1]);
      final before = _snapshot(root);

      await storage.prepare(); // the next start
      expect(staging().listSync().map((e) => e.path), [unrelated.path]);
      expect(_snapshot(root), before);
    },
  );

  test('the writer refuses to replace an existing file', () async {
    final writer = await storage.writer();
    final target = File('${root.path}/outputs/fixed.bin')
      ..writeAsBytesSync([1, 2, 3]);
    await expectLater(
      writer.write(target, Uint8List.fromList([9])),
      throwsA(
        isA<AtomicWriteException>().having(
          (error) => error.reason,
          'reason',
          AtomicWriteFailure.destinationExists,
        ),
      ),
    );
    expect(target.readAsBytesSync(), [1, 2, 3]);
    expect(staging().listSync(), isEmpty);
  });

  test('repeated exports keep memory bounded', () async {
    final exporter = service();
    await exporter.export(render); // warm-up
    final rssBefore = ProcessInfo.currentRss;
    final ids = <String>{};
    for (var i = 0; i < 30; i++) {
      ids.add((await exporter.export(render)).id);
    }
    final growth = ProcessInfo.currentRss - rssBefore;
    // A leaked page buffer per export (8.6 MB) would add over 250 MB.
    expect(growth, lessThan(96 * 1024 * 1024), reason: '$growth bytes');
    expect(ids, hasLength(30));
    expect(staging().listSync(), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
