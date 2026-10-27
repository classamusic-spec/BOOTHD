import 'dart:async';
import 'dart:io' as io;
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../file_store/blob_file_system.dart';

/// [BlobStore] in the browser's IndexedDB (ADR-0018): an `entries` store
/// (path to folder or file size and time) and a `contents` store (path to
/// bytes). Each change is one read-write transaction over both stores, so
/// a write or rename either happens completely or not at all; the browser
/// commits the transaction before [write] returns.
final class IndexedDbBlobStore implements BlobStore {
  IndexedDbBlobStore._(this._db);

  static const _name = 'porcelain_booth_files';
  static const _entries = 'entries';
  static const _contents = 'contents';

  final web.IDBDatabase _db;

  /// Opens (or creates) the store.
  static Future<IndexedDbBlobStore> open({String name = _name}) async {
    final request = web.window.indexedDB.open(name, 1);
    request.onupgradeneeded = ((web.Event _) {
      final db = request.result! as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_entries)) {
        db.createObjectStore(_entries);
      }
      if (!db.objectStoreNames.contains(_contents)) {
        db.createObjectStore(_contents);
      }
    }).toJS;
    final db = await _result(request);
    return IndexedDbBlobStore._(db! as web.IDBDatabase);
  }

  /// Releases the connection, including before removing an isolated test store.
  void close() => _db.close();

  static Future<JSAny?> _result(web.IDBRequest request) {
    final done = Completer<JSAny?>();
    request
      ..onsuccess = ((web.Event _) => done.complete(request.result)).toJS
      ..onerror = ((web.Event _) {
        done.completeError(_failure(request.error, ''));
      }).toJS;
    return done.future;
  }

  static io.FileSystemException _failure(
    web.DOMException? error,
    String path,
  ) => io.FileSystemException(
    error?.name == 'QuotaExceededError'
        ? 'QuotaExceeded: the browser storage is full'
        : 'Browser storage failed: ${error?.name ?? 'unknown'}',
    path,
  );

  /// Runs [issue] in one read-write transaction and waits for the browser
  /// to commit it. Every request is issued before the first await, so the
  /// transaction never closes early.
  Future<void> _change(String path, void Function(web.IDBTransaction) issue) {
    final transaction = _db.transaction(
      [_entries.toJS, _contents.toJS].toJS,
      'readwrite',
    );
    final done = Completer<void>();
    transaction
      ..oncomplete = ((web.Event _) => done.complete()).toJS
      ..onabort = ((web.Event _) {
        if (!done.isCompleted) {
          done.completeError(_failure(transaction.error, path));
        }
      }).toJS
      ..onerror = ((web.Event _) {
        if (!done.isCompleted) {
          done.completeError(_failure(transaction.error, path));
        }
      }).toJS;
    try {
      issue(transaction);
    } on Object catch (error, stack) {
      // Return the same failed future the caller awaits. Rethrowing here
      // would leave the later abort event rejecting an orphaned future.
      if (!done.isCompleted) done.completeError(error, stack);
      transaction.abort();
    }
    return done.future;
  }

  static JSAny _fileEntry(int size, DateTime modified) =>
      {'d': false, 's': size, 'm': modified.millisecondsSinceEpoch}.jsify()!;

  static final JSAny _folderEntry = {'d': true, 's': 0, 'm': 0}.jsify()!;

  @override
  Future<Map<String, BlobEntry>> load() async {
    final transaction = _db.transaction(_entries.toJS, 'readonly');
    final store = transaction.objectStore(_entries);
    final keys = _result(store.getAllKeys());
    final values = _result(store.getAll());
    final keyList = ((await keys)! as JSArray<JSAny?>).toDart;
    final valueList = ((await values)! as JSArray<JSAny?>).toDart;
    return {
      for (var i = 0; i < keyList.length; i++)
        (keyList[i]! as JSString).toDart: _entryOf(valueList[i]),
    };
  }

  static BlobEntry _entryOf(JSAny? value) {
    final map = (value.dartify() as Map?) ?? const {};
    if (map['d'] == true) return const BlobEntry.directory();
    return BlobEntry.file(
      (map['s'] as num? ?? 0).toInt(),
      DateTime.fromMillisecondsSinceEpoch((map['m'] as num? ?? 0).toInt()),
    );
  }

  @override
  Future<Uint8List> read(String path) async {
    final transaction = _db.transaction(_contents.toJS, 'readonly');
    final value = await _result(
      transaction.objectStore(_contents).get(path.toJS),
    );
    if (value == null) {
      throw io.FileSystemException('Cannot open file', path);
    }
    return (value as JSUint8Array).toDart;
  }

  @override
  Future<void> write(String path, Uint8List bytes, DateTime modified) =>
      _change(path, (transaction) {
        transaction.objectStore(_contents).put(bytes.toJS, path.toJS);
        transaction
            .objectStore(_entries)
            .put(_fileEntry(bytes.length, modified), path.toJS);
      });

  @override
  Future<void> makeDirectories(Iterable<String> paths) {
    final all = paths.toList();
    return _change(all.isEmpty ? '' : all.first, (transaction) {
      final entries = transaction.objectStore(_entries);
      for (final path in all) {
        entries.put(_folderEntry, path.toJS);
      }
    });
  }

  @override
  Future<void> move(Map<String, String> moves) {
    if (moves.isEmpty) return Future.value();
    // Read and write under the SAME read-write transaction. IndexedDB
    // serializes it against other writers, so a concurrent update cannot
    // be replaced with bytes read before that update committed.
    return _change(moves.keys.first, (transaction) {
      final entryStore = transaction.objectStore(_entries);
      final contentStore = transaction.objectStore(_contents);
      final entries = <String, JSAny?>{};
      final contents = <String, JSAny?>{};
      var remaining = moves.length * 2;

      void readCompleted() {
        if (--remaining != 0) return;
        if (entries.values.any((entry) => entry == null)) {
          transaction.abort();
          return;
        }
        // Issue writes from a request callback while the transaction is
        // still active. Snapshot all sources first, including for swaps.
        try {
          for (final from in moves.keys) {
            entryStore.delete(from.toJS);
            contentStore.delete(from.toJS);
          }
          for (final MapEntry(key: from, value: to) in moves.entries) {
            entryStore.put(entries[from]!, to.toJS);
            if (contents[from] case final bytes?) {
              contentStore.put(bytes, to.toJS);
            }
          }
        } on Object {
          transaction.abort();
        }
      }

      for (final from in moves.keys) {
        final entry = entryStore.get(from.toJS);
        entry.onsuccess = ((web.Event _) {
          entries[from] = entry.result;
          readCompleted();
        }).toJS;
        final content = contentStore.get(from.toJS);
        content.onsuccess = ((web.Event _) {
          contents[from] = content.result;
          readCompleted();
        }).toJS;
      }
    });
  }

  @override
  Future<void> remove(Iterable<String> paths) {
    final all = paths.toList();
    return _change(all.isEmpty ? '' : all.first, (transaction) {
      final entries = transaction.objectStore(_entries);
      final contents = transaction.objectStore(_contents);
      for (final path in all) {
        entries.delete(path.toJS);
        contents.delete(path.toJS);
      }
    });
  }
}
