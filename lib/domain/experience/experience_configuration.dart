/// An event's guest experience (EP01): the pack it uses and what the
/// operator changed. Stored with the event; resolved into a
/// [ResolvedExperience] that each guest session freezes when it starts.
library;

import 'package:meta/meta.dart';

import 'experience_catalog.dart';

const _unset = Object();

@immutable
final class EventExperienceConfiguration {
  const EventExperienceConfiguration({
    this.packId = 'porcelain-classic',
    this.packVersion = 1,
    this.variantId,
    this.accentColor,
    this.getReadyText,
    this.finishText,
    this.countdownPresetId,
    this.soundEnabled,
    this.soundVolume = 70,
    this.animation,
    this.celebrationEnabled = true,
    this.cameraStage = CameraStageMode.cameraFocused,
    this.recommendedTemplateIds = const [],
    this.childrenMayBeGuests = false,
    this.revision = 1,
  });

  static const currentSchemaVersion = 1;
  static const maxGetReadyLength = 40;
  static const maxFinishLength = 80;

  final String packId;
  final int packVersion;

  /// Null uses the pack's default variant.
  final String? variantId;

  /// Replaces the pack's accent (0xAARRGGBB), when the pack allows it and
  /// the guest text on it stays readable.
  final int? accentColor;
  final String? getReadyText;
  final String? finishText;

  /// Null uses the pack's (or variant's) countdown.
  final String? countdownPresetId;

  /// Null follows the pack's default.
  final bool? soundEnabled;

  /// 0 to 100.
  final int soundVolume;

  /// Null follows the pack's default.
  final AnimationIntensity? animation;
  final bool celebrationEnabled;

  /// Camera-focused unless the operator asks for the live template: the
  /// live template's cost on tablets is unproven until the device run
  /// (ADR-0017).
  final CameraStageMode cameraStage;

  /// Template library ids the operator linked as suggestions.
  final List<String> recommendedTemplateIds;

  /// Texting screens ask for a parent or guardian (EP plan 4.7).
  final bool childrenMayBeGuests;

  /// Increases on every saved change to the experience. Bookkeeping: not
  /// part of equality, so an unchanged experience compares equal.
  final int revision;

  /// The pack's defaults for everything the operator can change, keeping
  /// the pack and the links to templates.
  EventExperienceConfiguration resetToPackDefaults() =>
      EventExperienceConfiguration(
        packId: packId,
        packVersion: packVersion,
        recommendedTemplateIds: recommendedTemplateIds,
        childrenMayBeGuests: childrenMayBeGuests,
        revision: revision,
      );

  EventExperienceConfiguration copyWith({
    String? packId,
    int? packVersion,
    Object? variantId = _unset,
    Object? accentColor = _unset,
    Object? getReadyText = _unset,
    Object? finishText = _unset,
    Object? countdownPresetId = _unset,
    Object? soundEnabled = _unset,
    int? soundVolume,
    Object? animation = _unset,
    bool? celebrationEnabled,
    CameraStageMode? cameraStage,
    List<String>? recommendedTemplateIds,
    bool? childrenMayBeGuests,
    int? revision,
  }) => EventExperienceConfiguration(
    packId: packId ?? this.packId,
    packVersion: packVersion ?? this.packVersion,
    variantId: identical(variantId, _unset)
        ? this.variantId
        : variantId as String?,
    accentColor: identical(accentColor, _unset)
        ? this.accentColor
        : accentColor as int?,
    getReadyText: identical(getReadyText, _unset)
        ? this.getReadyText
        : getReadyText as String?,
    finishText: identical(finishText, _unset)
        ? this.finishText
        : finishText as String?,
    countdownPresetId: identical(countdownPresetId, _unset)
        ? this.countdownPresetId
        : countdownPresetId as String?,
    soundEnabled: identical(soundEnabled, _unset)
        ? this.soundEnabled
        : soundEnabled as bool?,
    soundVolume: soundVolume ?? this.soundVolume,
    animation: identical(animation, _unset)
        ? this.animation
        : animation as AnimationIntensity?,
    celebrationEnabled: celebrationEnabled ?? this.celebrationEnabled,
    cameraStage: cameraStage ?? this.cameraStage,
    recommendedTemplateIds:
        recommendedTemplateIds ?? this.recommendedTemplateIds,
    childrenMayBeGuests: childrenMayBeGuests ?? this.childrenMayBeGuests,
    revision: revision ?? this.revision,
  );

  /// Another pack, keeping the event-level choices that are not the
  /// pack's (camera stage, template links, children) and nothing that
  /// belonged to the old pack's look.
  EventExperienceConfiguration switchPack(String packId, int packVersion) =>
      EventExperienceConfiguration(
        packId: packId,
        packVersion: packVersion,
        getReadyText: getReadyText,
        finishText: finishText,
        soundVolume: soundVolume,
        celebrationEnabled: celebrationEnabled,
        cameraStage: cameraStage,
        recommendedTemplateIds: recommendedTemplateIds,
        childrenMayBeGuests: childrenMayBeGuests,
        revision: revision,
      );

  Map<String, Object?> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'packId': packId,
    'packVersion': packVersion,
    'variantId': ?variantId,
    'accentColor': ?accentColor,
    'getReadyText': ?getReadyText,
    'finishText': ?finishText,
    'countdownPresetId': ?countdownPresetId,
    'soundEnabled': ?soundEnabled,
    'soundVolume': soundVolume,
    'animation': ?animation?.name,
    'celebrationEnabled': celebrationEnabled,
    'cameraStage': cameraStage.name,
    'recommendedTemplateIds': recommendedTemplateIds,
    'childrenMayBeGuests': childrenMayBeGuests,
    'revision': revision,
  };

  /// Reads [toJson]'s output. Throws [FormatException] for a version or
  /// shape this app does not read.
  static EventExperienceConfiguration fromJson(Map<String, Object?> json) {
    try {
      if (json['schemaVersion'] != currentSchemaVersion) {
        throw FormatException(
          'Unknown experience configuration version ${json['schemaVersion']}',
        );
      }
      return EventExperienceConfiguration(
        packId: json['packId']! as String,
        packVersion: json['packVersion']! as int,
        variantId: json['variantId'] as String?,
        accentColor: json['accentColor'] as int?,
        getReadyText: json['getReadyText'] as String?,
        finishText: json['finishText'] as String?,
        countdownPresetId: json['countdownPresetId'] as String?,
        soundEnabled: json['soundEnabled'] as bool?,
        soundVolume: json['soundVolume']! as int,
        animation: switch (json['animation']) {
          final String name => AnimationIntensity.values.byName(name),
          _ => null,
        },
        celebrationEnabled: json['celebrationEnabled']! as bool,
        cameraStage: CameraStageMode.values.byName(
          json['cameraStage']! as String,
        ),
        recommendedTemplateIds: [
          for (final id in json['recommendedTemplateIds']! as List<Object?>)
            id! as String,
        ],
        childrenMayBeGuests: json['childrenMayBeGuests']! as bool,
        revision: json['revision']! as int,
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        'Unreadable experience configuration: ${error.runtimeType}',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is EventExperienceConfiguration &&
      other.packId == packId &&
      other.packVersion == packVersion &&
      other.variantId == variantId &&
      other.accentColor == accentColor &&
      other.getReadyText == getReadyText &&
      other.finishText == finishText &&
      other.countdownPresetId == countdownPresetId &&
      other.soundEnabled == soundEnabled &&
      other.soundVolume == soundVolume &&
      other.animation == animation &&
      other.celebrationEnabled == celebrationEnabled &&
      other.cameraStage == cameraStage &&
      _sameStrings(other.recommendedTemplateIds, recommendedTemplateIds) &&
      other.childrenMayBeGuests == childrenMayBeGuests;

  @override
  int get hashCode => Object.hash(
    packId,
    packVersion,
    variantId,
    accentColor,
    getReadyText,
    finishText,
    countdownPresetId,
    soundEnabled,
    soundVolume,
    animation,
    celebrationEnabled,
    cameraStage,
    Object.hashAll(recommendedTemplateIds),
    childrenMayBeGuests,
  );
}

bool _sameStrings(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
