import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/kiosk_lock.dart';
import '../di/service_providers.dart';

/// The kiosk lock as the tablet reports it (Settings > Kiosk lock, M10).
/// Invalidate it to read again.
final kioskLockProvider = FutureProvider.autoDispose<KioskLock>(
  (ref) => ref.watch(kioskLockInfoProvider).current(),
);
