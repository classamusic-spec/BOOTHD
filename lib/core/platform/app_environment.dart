import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the running binary was compiled.
enum BuildMode { debug, profile, release }

/// Facts about the running build and host platform.
@immutable
final class AppEnvironment {
  const AppEnvironment({required this.platform, required this.buildMode});

  factory AppEnvironment.current() => AppEnvironment(
    platform: defaultTargetPlatform,
    buildMode: kReleaseMode
        ? BuildMode.release
        : kProfileMode
        ? BuildMode.profile
        : BuildMode.debug,
  );

  final TargetPlatform platform;
  final BuildMode buildMode;

  /// Release targets are iPadOS and Android tablets only (ADR-0001).
  String get platformLabel => switch (platform) {
    TargetPlatform.iOS => 'iPadOS',
    TargetPlatform.android => 'Android',
    _ => 'Unsupported (${platform.name})',
  };
}

/// Read through this provider so tests can substitute a fixed environment.
final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => AppEnvironment.current(),
);
