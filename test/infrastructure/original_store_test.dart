import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/infrastructure/file_store/original_store.dart';

Uint8List _fixture(String name) =>
    File('test_assets/input_photos/$name').readAsBytesSync();

final _context = CaptureContext(
  lens: CameraLens.front,
  sensorOrientationDegrees: 270,
  mirrorPreviewRequested: true,
  mirrorOutputRequested: false,
  capturedAtUtc: DateTime.utc(2026, 10, 18, 9, 30),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late OriginalStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('porcelain_originals_');
    store = OriginalStore(root: () async => root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  List<String> files() =>
      root
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path.substring(root.path.length + 1))
          .toList()
        ..sort();

  test('commits a validated original with its metadata', () async {
    final bytes = _fixture('exif_orientation_6_640x480.jpg');
    final still = await store.commit(
      id: 'shot-1',
      bytes: bytes,
      context: _context,
    );

    expect(files(), ['originals/shot-1.jpg', 'originals/shot-1.json']);
    expect(File('${root.path}/originals/shot-1.jpg').readAsBytesSync(), bytes);
    expect(still.relativePath, 'originals/shot-1.jpg');
    // The platform decoder applies EXIF orientation 6: 640x480 becomes
    // 480x640, and the raw tag is kept for the record (ADR-0007).
    expect((still.widthPx, still.heightPx), (480, 640));
    expect(still.exifOrientation, 6);
    expect(still.byteLength, bytes.length);
    expect(still.sha256, crypto.sha256.convert(bytes).toString());
    expect(still.lens, CameraLens.front);
    expect(still.mirrorPreviewRequested, isTrue);
    expect(still.mirrorOutputRequested, isFalse);
  });

  test(
    'rejects corrupt and truncated images and leaves nothing behind',
    () async {
      final jpeg = _fixture('exif_orientation_1_640x480.jpg');
      for (final bad in [
        Uint8List.fromList(List.filled(256, 1)),
        Uint8List.sublistView(jpeg, 0, jpeg.length ~/ 2),
      ]) {
        await expectLater(
          store.commit(id: 'bad', bytes: bad, context: _context),
          throwsA(isA<OriginalCommitException>()),
        );
      }
      expect(files(), isEmpty);
    },
  );

  test('never overwrites an existing original', () async {
    final first = _fixture('exif_orientation_1_640x480.jpg');
    await store.commit(id: 'same', bytes: first, context: _context);
    await expectLater(
      store.commit(
        id: 'same',
        bytes: _fixture('exif_orientation_6_640x480.jpg'),
        context: _context,
      ),
      throwsA(isA<OriginalCommitException>()),
    );
    expect(File('${root.path}/originals/same.jpg').readAsBytesSync(), first);
  });

  test('refuses ids that could escape the store', () async {
    for (final id in ['../escape', 'a/b', '', 'x' * 65]) {
      await expectLater(
        store.commit(
          id: id,
          bytes: _fixture('exif_orientation_1_640x480.jpg'),
          context: _context,
        ),
        throwsA(isA<OriginalCommitException>()),
      );
    }
    expect(files(), isEmpty);
  });

  test('a new store on the same root lists and reads committed originals '
      '(app restart)', () async {
    await store.commit(
      id: 'b',
      bytes: _fixture('exif_orientation_6_640x480.jpg'),
      context: _context,
    );
    await store.commit(
      id: 'a',
      bytes: _fixture('exif_orientation_1_640x480.jpg'),
      context: CaptureContext(
        lens: CameraLens.back,
        sensorOrientationDegrees: 90,
        mirrorPreviewRequested: false,
        mirrorOutputRequested: false,
        capturedAtUtc: DateTime.utc(2026, 10, 18, 9),
      ),
    );

    final reopened = OriginalStore(root: () async => root);
    final listed = await reopened.listCommitted();
    expect(listed.map((s) => s.id), ['a', 'b']); // oldest first
    expect(
      await reopened.read(listed.last),
      _fixture('exif_orientation_6_640x480.jpg'),
    );
  });

  test('an altered file is no longer listed or readable', () async {
    final still = await store.commit(
      id: 'c',
      bytes: _fixture('exif_orientation_1_640x480.jpg'),
      context: _context,
    );
    final file = File('${root.path}/${still.relativePath}');
    final altered = file.readAsBytesSync()..[100] ^= 0xFF;
    file.writeAsBytesSync(altered);

    expect(await store.listCommitted(), isEmpty);
    await expectLater(
      store.read(still),
      throwsA(isA<OriginalCommitException>()),
    );
  });
}
