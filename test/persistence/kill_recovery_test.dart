// AC-1004: recovery after the app is killed between a file's staged copy,
// its rename and its record. Each case stops a real save at one stage for
// good (the call never returns, as if the process died there) and starts
// again on the same files and database: storage prepared, the database
// opened again, then startup's recovery (photo saves finished or undone,
// the deletion journal, the orphan sweep). Afterwards nothing is staged,
// every record has its intact file, every file in a recorded area has its
// record (camera photos are moved aside, never deleted), and the photos
// saved before the kill are untouched.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/repositories/template_store.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/domain/services/gallery_services.dart';
import 'package:porcelain_photo_booth/domain/value_objects/entity_id.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_fixtures.dart';
import 'package:porcelain_photo_booth/infrastructure/backup/backup_staging.dart';
import 'package:porcelain_photo_booth/infrastructure/composition/dart_ui_composition_renderer.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_gallery_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/database/drift_template_catalog.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/atomic_file_writer.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/file_export_service.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/managed_storage_cleanup.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/original_store.dart';
import 'package:porcelain_photo_booth/infrastructure/templates/drift_asset_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/templates/drift_template_repository.dart';

import '../support/fakes.dart';
import '../support/gallery_seed.dart';
import '../support/seed.dart';
import '../support/test_database.dart';

enum _Stage {
  /// Half the bytes have reached the staged copy.
  duringWrite,

  /// The staged copy is complete and checked, not yet renamed.
  beforeRename,

  /// The file is in place; its record is not written.
  afterRename,
}

/// File operations that stop for good at [stage] of the first write whose
/// staged copy is named [prefix]..., as if the app were killed there.
final class _KillAt extends FileOperations {
  _KillAt(this.stage, this.prefix);

  final _Stage stage;
  final String prefix;

  /// Completes when the kill happened.
  final killed = Completer<void>();

  bool _ours(File file) =>
      !killed.isCompleted && file.uri.pathSegments.last.startsWith(prefix);

  Future<Never> _die() {
    killed.complete();
    return Completer<Never>().future;
  }

  @override
  Future<void> writeAndFlush(File file, Uint8List bytes) async {
    if (stage == _Stage.duringWrite && _ours(file)) {
      await super.writeAndFlush(
        file,
        Uint8List.sublistView(bytes, 0, bytes.length ~/ 2),
      );
      await _die();
    }
    return super.writeAndFlush(file, bytes);
  }

  @override
  Future<void> rename(File file, String newPath) async {
    if (!_ours(file)) return super.rename(file, newPath);
    if (stage == _Stage.beforeRename) await _die();
    await super.rename(file, newPath);
    if (stage == _Stage.afterRename) await _die();
  }
}

/// FIX-01's photos and images, from memory.
final class _MemorySource implements RenderSource {
  _MemorySource(this.fixture);

  final RenderFixture fixture;

  @override
  Future<Uint8List> readAsset(String assetId) async => fixture.assets[assetId]!;

  @override
  Future<Uint8List> readPhoto(String photoId) async => fixture.photos[photoId]!;
}

final _photo = File('test_assets/input_photos/exif_orientation_1_640x480.jpg')
    .readAsBytesSync();

final _context = CaptureContext(
  lens: CameraLens.front,
  sensorOrientationDegrees: 270,
  mirrorPreviewRequested: true,
  mirrorOutputRequested: false,
  capturedAtUtc: DateTime.utc(2026, 11, 14, 21, 5),
  deviceOrientation: CaptureOrientation.portraitUp,
  origin: CaptureOrigin.session,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = fix01();
  late Directory root;
  late File databaseFile;
  late FileManagedStorage storage;
  late BoothDatabase db;
  late List<String> sessions;
  late Map<String, String> savedBefore;
  late OrphanSweepResult swept;
  final opened = <BoothDatabase>[];

  /// Every file in the recorded areas, with its SHA-256.
  Map<String, String> files() => {
    for (final area in ['originals', 'outputs', 'assets', 'templates'])
      if (Directory('${root.path}/$area').existsSync())
        for (final file in Directory(
          '${root.path}/$area',
        ).listSync(recursive: true).whereType<File>())
          file.path.substring(root.path.length + 1): crypto.sha256
              .convert(file.readAsBytesSync())
              .toString(),
  };

  setUp(() async {
    root = Directory.systemTemp.createTempSync('porcelain_kill_');
    databaseFile = File('${root.path}/booth.sqlite');
    storage = FileManagedStorage(root: () async => root);
    await storage.prepare();
    db = fileDatabase(databaseFile);
    opened.add(db);
    await seedEvents(db);
    // Guests photographed before the kill: originals and finished photos
    // on disk with their records.
    sessions = await seedGallery(db, count: 3, filesRoot: root);
    savedBefore = files();
    expect(savedBefore, isNotEmpty);
  });

  tearDown(() async {
    for (final database in opened) {
      await database.close();
    }
    opened.clear();
    root.deleteSync(recursive: true);
  });

  /// The app starts again on the same files and database.
  Future<BoothDatabase> restart() async {
    final again = FileManagedStorage(root: () async => root);
    await again.prepare();
    final database = fileDatabase(databaseFile);
    opened.add(database);
    await OriginalStore(
      database: database,
      root: () async => root,
      writer: again.writer,
      clock: FakeClock(),
    ).reconcile();
    final cleanup = ManagedStorageCleanup(
      database: database,
      root: () async => root,
    );
    await cleanup.run();
    swept = await cleanup.sweepOrphans();
    return database;
  }

  /// Nothing staged or journaled; records and files match one to one, and
  /// every recorded file is intact.
  Future<void> expectConsistent(BoothDatabase database) async {
    expect(Directory('${root.path}/staging').listSync(), isEmpty);
    expect(
      await database.select(database.pendingOriginalCommits).get(),
      isEmpty,
    );
    expect(await database.select(database.pendingFileDeletions).get(), isEmpty);
    final recorded = <String, String>{
      for (final row in await database.select(database.originalPhotos).get())
        row.relativePath: row.sha256,
      for (final row in await database.select(database.sessionOutputs).get())
        row.relativePath: row.sha256,
      for (final row in await database.select(database.assets).get())
        row.relativePath: row.id,
    };
    final manifests = {
      for (final row in await database.select(database.templateRevisions).get())
        row.manifestPath,
    };
    final onDisk = files();
    for (final MapEntry(key: path, value: sha) in recorded.entries) {
      expect(onDisk[path], sha, reason: '$path is intact');
    }
    for (final path in onDisk.keys) {
      if (path.startsWith('originals/.quarantine/')) continue;
      expect(
        recorded.containsKey(path) || manifests.contains(path),
        isTrue,
        reason: '$path has a record',
      );
    }
  }

  /// The photos saved before the kill, byte for byte.
  void expectSavedBeforeUntouched() {
    final now = files();
    for (final MapEntry(key: path, value: sha) in savedBefore.entries) {
      expect(now[path], sha, reason: path);
    }
  }

  List<String> quarantined() {
    final aside = Directory('${root.path}/originals/.quarantine');
    return aside.existsSync() ? [for (final f in aside.listSync()) f.path] : [];
  }

  group('a camera photo', () {
    for (final stage in _Stage.values) {
      test('killed ${stage.name}', () async {
        final kill = _KillAt(stage, 'original-');
        final store = OriginalStore(
          database: db,
          root: () async => root,
          writer: () => storage.writer(operations: kill),
          clock: FakeClock(),
        );
        unawaited(
          store.commit(id: 'cut-off', bytes: _photo, context: _context),
        );
        await kill.killed.future;

        final after = await restart();
        await expectConsistent(after);
        expectSavedBeforeUntouched();
        final ids = [
          for (final row in await after.select(after.originalPhotos).get())
            row.id,
        ];
        if (stage == _Stage.afterRename) {
          // Complete and in place: the journal finishes the save, and the
          // photo is the camera's bytes.
          expect(ids, contains('cut-off'));
          expect(
            File('${root.path}/originals/cut-off.jpg').readAsBytesSync(),
            _photo,
          );
        } else {
          expect(ids, isNot(contains('cut-off')), reason: 'undone');
          expect(
            File('${root.path}/originals/cut-off.jpg').existsSync(),
            isFalse,
          );
        }
        expect(quarantined(), isEmpty);
        expect(swept.removed + swept.quarantined, 0);
      });
    }
  });

  group('a finished photo', () {
    for (final stage in _Stage.values) {
      test('killed ${stage.name}', () async {
        final kill = _KillAt(stage, 'export-');
        final export = FileExportService(
          renderer: DartUiCompositionRenderer(),
          storage: storage,
          ids: RandomIdGenerator(),
          operations: kill,
        );
        unawaited(
          export.export(
            TemplateRender(
              document: fixture.document,
              photos: fixture.selections,
              source: _MemorySource(fixture),
            ),
          ),
        );
        await kill.killed.future;

        final after = await restart();
        await expectConsistent(after);
        expectSavedBeforeUntouched();
        // In place without a record, it is removed; its session (still
        // rendering) is rendered again into a new file (AC-0707).
        expect(swept.removed, stage == _Stage.afterRename ? 1 : 0);
      });
    }
  });

  group('a template image', () {
    for (final stage in _Stage.values) {
      test('killed ${stage.name}', () async {
        final kill = _KillAt(stage, 'asset-');
        final assets = DriftAssetRepository(
          db,
          storage: storage,
          clock: FakeClock(),
          operations: kill,
        );
        unawaited(
          assets.store(
            fixture.assets.values.first,
            name: 'Garland',
            origin: AssetOrigin.imported,
          ),
        );
        await kill.killed.future;

        final after = await restart();
        await expectConsistent(after);
        expectSavedBeforeUntouched();
        expect(await after.select(after.assets).get(), isEmpty);
        expect(swept.removed, stage == _Stage.afterRename ? 1 : 0);
      });
    }
  });

  group('a template revision', () {
    for (final stage in _Stage.values) {
      test('killed ${stage.name}', () async {
        // Its images were stored first.
        final assets = DriftAssetRepository(
          db,
          storage: storage,
          clock: FakeClock(),
        );
        for (final MapEntry(key: id, value: bytes) in fixture.assets.entries) {
          await assets.store(
            bytes,
            name: fixture.document.assets[id]!.name,
            origin: AssetOrigin.imported,
          );
        }
        final revisionsBefore =
            (await db.select(db.templateRevisions).get()).length;
        final kill = _KillAt(stage, 'manifest-');
        final templates = DriftTemplateRepository(
          db,
          storage: storage,
          assets: assets,
          ids: RandomIdGenerator(),
          clock: FakeClock(),
          operations: kill,
        );
        unawaited(
          templates.createTemplate(name: 'Cut off', document: fixture.document),
        );
        await kill.killed.future;

        final after = await restart();
        await expectConsistent(after);
        expectSavedBeforeUntouched();
        expect(
          await after.select(after.templateRevisions).get(),
          hasLength(revisionsBefore),
          reason: 'no revision recorded',
        );
        expect(
          await after.select(after.assets).get(),
          hasLength(fixture.assets.length),
          reason: 'the images stored before are kept',
        );
        expect(swept.removed, stage == _Stage.afterRename ? 1 : 0);
        expect(
          Directory('${root.path}/templates').listSync(),
          isEmpty,
          reason: 'no empty template folder is left',
        );
      });
    }
  });

  test('a deletion killed before its files were removed', () async {
    final gallery = DriftGalleryRepository(
      db,
      clock: FakeClock(),
      templates: DriftTemplateCatalog(db),
    );
    await gallery.deleteSessions([sessions.first]);
    // Killed here: the records and the journal are committed, the files
    // are still on disk.
    expect(await db.select(db.pendingFileDeletions).get(), isNotEmpty);

    final after = await restart();
    await expectConsistent(after);
    expect(quarantined(), isEmpty, reason: 'deleted photos are not kept');
  });

  test('a backup or a restore killed half-way leaves nothing behind', () async {
    // What a kill leaves in staging: a snapshot being cleaned (with
    // SQLite's journal beside it), a half-written archive, a half-copied
    // chosen file. Each name is the backup service's own.
    final staging = Directory('${root.path}/staging');
    for (final name in [
      BackupStaging.snapshot('0123456789abcdef'),
      '${BackupStaging.snapshot('0123456789abcdef')}-journal',
      BackupStaging.archive('0123456789abcdef'),
      BackupStaging.restoreCopy('fedcba9876543210'),
    ]) {
      File('${staging.path}/$name').writeAsBytesSync([1, 2, 3]);
    }
    // Something the booth did not put there is never touched.
    File('${staging.path}/notes.txt').writeAsStringSync('keep');
    final after = await restart();
    expect(
      [for (final f in staging.listSync()) f.uri.pathSegments.last],
      ['notes.txt'],
    );
    File('${staging.path}/notes.txt').deleteSync();
    await expectConsistent(after);
    expectSavedBeforeUntouched();
  });

  group('the startup sweep', () {
    test('moves a camera photo nothing refers to aside, never deletes it, '
        'and removes other unrecorded files', () async {
      File('${root.path}/originals/stray.jpg').writeAsBytesSync(_photo);
      File('${root.path}/outputs/${RandomIdGenerator().newId()}.jpg')
          .writeAsBytesSync([1, 2, 3]);
      Directory('${root.path}/templates/orphan').createSync(recursive: true);
      File('${root.path}/templates/orphan/rev.json').writeAsStringSync('{}');

      final after = await restart();
      expect(swept.quarantined, 1);
      expect(swept.removed, 2);
      final aside = quarantined();
      expect(aside, hasLength(1));
      expect(File(aside.single).readAsBytesSync(), _photo);
      expect(Directory('${root.path}/templates/orphan').existsSync(), isFalse);
      await expectConsistent(after);
      expectSavedBeforeUntouched();
    });

    test('leaves journaled files to the deletion journal', () async {
      final gallery = DriftGalleryRepository(
        db,
        clock: FakeClock(),
        templates: DriftTemplateCatalog(db),
      );
      await gallery.deleteSessions([sessions.last]);
      // Startup's order: the journal first, then the sweep. With the
      // journal stuck (the OS holds the files), the sweep leaves them.
      final again = FileManagedStorage(root: () async => root);
      await again.prepare();
      final database = fileDatabase(databaseFile);
      opened.add(database);
      final stuck = ManagedStorageCleanup(
        database: database,
        root: () async => root,
        delete: (_) async => throw const FileSystemException('busy'),
      );
      await stuck.run();
      final result = await stuck.sweepOrphans();
      expect(result.quarantined, 0, reason: 'deleted, not set aside');
      expect(
        await database.select(database.pendingFileDeletions).get(),
        isNotEmpty,
      );
    });
  });
}
