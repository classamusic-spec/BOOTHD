import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/services/backup_service.dart';
import '../domain/services/booth_capabilities.dart';
import '../domain/services/camera_service.dart';
import '../domain/services/delivery_api.dart';
import '../domain/services/operator_files.dart';
import '../domain/value_objects/clock.dart';
import '../infrastructure/backup/file_backup_service.dart';
import '../infrastructure/camera/permission_handler_camera_permissions.dart';
import '../infrastructure/database/booth_database.dart';
import '../infrastructure/database/database_connection.dart';
import '../infrastructure/delivery/http_delivery_api.dart';
import '../infrastructure/device/platform_device_storage.dart';
import '../infrastructure/file_store/managed_storage.dart';
import '../infrastructure/files/managed_gallery_exporter.dart';
import '../infrastructure/files/platform_operator_files.dart';

/// Tablets (iPadOS, Android): nothing to prepare before the app starts.
Future<void> preparePlatform() async {}

/// The app's private support directory.
Future<Directory> appSupportDirectory() => getApplicationSupportDirectory();

/// Keeps managed storage out of the device's own cloud backup.
Future<void> Function(Directory root)? platformBackupExclusion() =>
    const PlatformDeviceStorage().excludeFromBackup;

QueryExecutor openBoothDatabase(FileManagedStorage storage) =>
    openBoothDatabaseFile(storage.databaseFile);

CameraPermissions platformCameraPermissions() =>
    const PermissionHandlerCameraPermissions();

DeviceStorageInfo platformDeviceStorage() => const PlatformDeviceStorage();

OperatorFiles platformOperatorFiles() => PlatformOperatorFiles();

ShareFilesSheet platformShareSheet() => shareFilesWithPlatformSheet;

BackupService platformBackupService({
  required BoothDatabase database,
  required FileManagedStorage storage,
  required DeviceStorageInfo space,
  required Clock clock,
}) => FileBackupService(
  database: database,
  storage: storage,
  space: space,
  clock: clock,
);

DeliveryApi platformDeliveryApi() => HttpDeliveryApi();
