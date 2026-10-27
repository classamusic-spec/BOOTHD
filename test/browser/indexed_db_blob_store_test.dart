@TestOn('browser')
library;

import 'dart:async';
import 'dart:io' as io;
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/infrastructure/web/indexed_db_blob_store.dart';
import 'package:web/web.dart' as web;

void main() {
  late String name;
  late IndexedDbBlobStore store;
  late IndexedDbBlobStore other;
  final now = DateTime.utc(2026, 10, 22);

  setUp(() async {
    name = 'porcelain_test_${DateTime.now().microsecondsSinceEpoch}';
    store = await IndexedDbBlobStore.open(name: name);
    other = await IndexedDbBlobStore.open(name: name);
  });

  tearDown(() async {
    store.close();
    other.close();
    final deleted = Completer<void>();
    final request = web.window.indexedDB.deleteDatabase(name);
    request
      ..onsuccess = ((web.Event _) => deleted.complete()).toJS
      ..onerror = ((web.Event _) => deleted.completeError(
        StateError('cleanup failed'),
      )).toJS;
    await deleted.future;
  });

  test(
    'rename cannot erase a concurrent write from another connection',
    () async {
      await store.write('/photo', Uint8List.fromList([1, 2]), now);
      // The rename is issued first. Its transaction must finish before the
      // later write, which recreates /photo with new bytes. Reading in one
      // transaction then renaming in another loses that later write.
      final move = store.move({'/photo': '/finished'});
      final write = other.write('/photo', Uint8List.fromList([3, 4, 5]), now);
      await Future.wait([move, write]);
      expect(await store.read('/finished'), [1, 2]);
      expect(await store.read('/photo'), [3, 4, 5]);
      final entries = await store.load();
      expect(entries['/photo']!.size, 3);
      expect(entries['/finished']!.size, 2);
    },
  );

  test(
    'multi-file rename snapshots sources before replacing destinations',
    () async {
      await store.write('/a', Uint8List.fromList([1]), now);
      await store.write('/b', Uint8List.fromList([2, 3]), now);
      await store.move({'/a': '/b', '/b': '/a'});
      expect(await other.read('/a'), [2, 3]);
      expect(await other.read('/b'), [1]);
      expect((await other.load())['/a']!.size, 2);
    },
  );

  test(
    'a missing rename source aborts all changes and permits recovery',
    () async {
      await store.write('/original', Uint8List.fromList([7]), now);
      await store.write('/destination', Uint8List.fromList([8, 9]), now);
      await expectLater(
        store.move({'/original': '/destination', '/missing': '/other'}),
        throwsA(isA<io.FileSystemException>()),
      );
      expect(await other.read('/original'), [7]);
      expect(await other.read('/destination'), [8, 9]);
      expect((await other.load()).containsKey('/other'), isFalse);
      await store.move({'/original': '/recovered'});
      expect(await other.read('/recovered'), [7]);
    },
  );
}
