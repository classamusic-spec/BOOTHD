import 'package:meta/meta.dart';

import '../services/camera_service.dart' show CameraLens;
import '../value_objects/appearance.dart';
import '../value_objects/orientation.dart';
import 'booth_event.dart';

/// Settings a new event starts from (S15, S16). Events keep their own copy,
/// so changing these never alters an existing event.
@immutable
final class EventDefaults {
  const EventDefaults({
    this.lens = CameraLens.front,
    this.mirrorPreview = true,
    this.mirrorOutput = false,
    this.orientation = GuestOrientationPreference.portrait,
    this.output = const OutputProfile(),
  });

  final CameraLens lens;
  final bool mirrorPreview;
  final bool mirrorOutput;
  final GuestOrientationPreference orientation;
  final OutputProfile output;

  EventDefaults copyWith({
    CameraLens? lens,
    bool? mirrorPreview,
    bool? mirrorOutput,
    GuestOrientationPreference? orientation,
    OutputProfile? output,
  }) => EventDefaults(
    lens: lens ?? this.lens,
    mirrorPreview: mirrorPreview ?? this.mirrorPreview,
    mirrorOutput: mirrorOutput ?? this.mirrorOutput,
    orientation: orientation ?? this.orientation,
    output: output ?? this.output,
  );

  /// Capture settings for a new event.
  CaptureSettings toCaptureSettings() => CaptureSettings(
    lens: lens,
    mirrorPreview: mirrorPreview,
    mirrorOutput: mirrorOutput,
    orientation: orientation,
  );

  @override
  bool operator ==(Object other) =>
      other is EventDefaults &&
      other.lens == lens &&
      other.mirrorPreview == mirrorPreview &&
      other.mirrorOutput == mirrorOutput &&
      other.orientation == orientation &&
      other.output == output;

  @override
  int get hashCode =>
      Object.hash(lens, mirrorPreview, mirrorOutput, orientation, output);
}

/// This device's booth (A-05 BoothProfile): its name, appearance and the
/// defaults new events start from.
@immutable
final class BoothProfile {
  const BoothProfile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.appearance = const AppearanceSettings(),
    this.defaults = const EventDefaults(),
  });

  static const defaultName = 'Porcelain booth';
  static const nameMaxLength = 40;

  final String id;

  /// Shown to operators only, never to guests.
  final String name;
  final AppearanceSettings appearance;
  final EventDefaults defaults;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is BoothProfile &&
      other.id == id &&
      other.name == name &&
      other.appearance == appearance &&
      other.defaults == defaults &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, name, appearance, defaults, updatedAt);
}

/// The booth's state as stored on the device.
@immutable
final class BoothState {
  const BoothState({
    required this.profile,
    this.setupCompletedAt,
    this.boothEventId,
  });

  final BoothProfile profile;

  /// When first-run setup finished; null until then.
  final DateTime? setupCompletedAt;

  /// The event Booth Mode is running, or null when the Studio is in use.
  /// Stored, so a restart returns guests to the booth, not to the Studio.
  final String? boothEventId;

  bool get setupComplete => setupCompletedAt != null;
}
