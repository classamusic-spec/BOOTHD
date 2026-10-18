import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../domain/repositories/storage_errors.dart';
import '../../domain/services/booth_capabilities.dart';
import '../../domain/services/managed_storage.dart';

/// Top-level directories of managed storage, under the app's private
/// support directory (never the user-visible Documents folder).
enum ManagedArea {
  database('database'),
  originals('originals'),
  outputs('outputs'),
  templates('templates'),
  assets('assets'),

  /// Files being written; renamed into place only once complete (A-11).
  staging('staging');

  const ManagedArea(this.directoryName);

  final String directoryName;
}

/// Managed storage on the local file system (A-11). Everything lives below
/// one root; callers name areas, never paths.
final class FileManagedStorage implements ManagedStorage {
  FileManagedStorage({required this._root, Random? random})
    : _random = random ?? Random.secure();

  static const databaseFileName = 'porcelain_booth.sqlite';

  final Future<Directory> Function() _root;
  final Random _random;

  Future<Directory> directory(ManagedArea area) async =>
      Directory('${(await _root()).path}/${area.directoryName}');

  /// The booth database file.
  Future<File> databaseFile() async =>
      File('${(await directory(ManagedArea.database)).path}/$databaseFileName');

  @override
  Future<void> prepare() async {
    try {
      for (final area in ManagedArea.values) {
        await (await directory(area)).create(recursive: true);
      }
    } on FileSystemException {
      throw const ManagedStorageException('STORAGE_UNAVAILABLE');
    }
  }

  @override
  Future<CapabilityStatus> probeWrite() async {
    final staging = await directory(ManagedArea.staging);
    final name = List.generate(8, (_) => _random.nextInt(16).toRadixString(16));
    final probe = File('${staging.path}/probe-${name.join()}.tmp');
    final bytes = Uint8List.fromList(
      List.generate(4096, (_) => _random.nextInt(256)),
    );
    try {
      await staging.create(recursive: true);
      await probe.writeAsBytes(bytes, flush: true);
      final readBack = await probe.readAsBytes();
      var same = readBack.length == bytes.length;
      for (var i = 0; same && i < bytes.length; i++) {
        same = readBack[i] == bytes[i];
      }
      return same
          ? const CapabilityReady()
          : const CapabilityProblem('STORAGE_READBACK_MISMATCH');
    } on FileSystemException {
      return const CapabilityProblem('STORAGE_NOT_WRITABLE');
    } finally {
      try {
        if (probe.existsSync()) await probe.delete();
      } on FileSystemException {
        // Left for the staging clean-up (M10); never fails the check twice.
      }
    }
  }
}
