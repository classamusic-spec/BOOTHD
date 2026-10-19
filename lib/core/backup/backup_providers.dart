import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/backup/backup_manifest.dart';
import '../../domain/services/backup_service.dart';
import '../di/service_providers.dart';

/// How big a backup of [BackupContents] would be, and whether it fits
/// (Settings > Backup, M10).
final backupEstimateProvider = FutureProvider.autoDispose
    .family<BackupEstimate, BackupContents>(
      (ref, contents) => ref.watch(backupServiceProvider).estimate(contents),
    );
