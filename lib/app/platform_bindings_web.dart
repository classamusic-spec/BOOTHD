import 'dart:io';

import 'package:drift/drift.dart';

import '../domain/services/backup_service.dart';
import '../domain/services/booth_capabilities.dart';
import '../domain/services/camera_service.dart';
import '../domain/services/delivery_api.dart';
import '../domain/services/operator_files.dart';
import '../domain/value_objects/clock.dart';
import '../infrastructure/database/booth_database.dart';
import '../infrastructure/delivery/http_delivery_api.dart';
import '../infrastructure/file_store/blob_file_system.dart';
import '../infrastructure/file_store/managed_storage.dart';
import '../infrastructure/files/managed_gallery_exporter.dart';
import '../infrastructure/web/browser_backup_service.dart';
import '../infrastructure/web/fetch_delivery_send.dart';
import '../infrastructure/web/indexed_db_blob_store.dart';
import '../infrastructure/web/web_database_connection.dart';
import '../infrastructure/web/web_operator_files.dart';
import '../infrastructure/web/web_platform.dart';

/// The browser test build (ADR-0018).
late final BlobFileSystem _files;

/// Opens the browser's file storage and asks the browser to keep it.
Future<void> preparePlatform() async {
  _files = await BlobFileSystem.open(await IndexedDbBlobStore.open());
  await requestPersistentStorage();
}

/// Managed storage's root in the browser's file storage.
Future<Directory> appSupportDirectory() async =>
    _files.directory('/booth').create(recursive: true);

/// There is no device backup to keep the browser's storage out of.
Future<void> Function(Directory root)? platformBackupExclusion() => null;

QueryExecutor openBoothDatabase(FileManagedStorage storage) =>
    openBrowserBoothDatabase();

CameraPermissions platformCameraPermissions() => const WebCameraPermissions();

DeviceStorageInfo platformDeviceStorage() => const WebDeviceStorage();

OperatorFiles platformOperatorFiles() => WebOperatorFiles(_files);

ShareFilesSheet platformShareSheet() => browserShareSheet(_files);

BackupService platformBackupService({
  required BoothDatabase database,
  required FileManagedStorage storage,
  required DeviceStorageInfo space,
  required Clock clock,
}) => const BrowserBackupService();

DeliveryApi platformDeliveryApi() => HttpDeliveryApi(send: fetchDeliverySend);
