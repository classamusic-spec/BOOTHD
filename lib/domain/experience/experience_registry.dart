/// Validates Experience Packs and resolves an event's configuration into
/// what its guest sessions use (EP01, ADR-0017). Anything unknown, unread
/// or unreadable is reported as an [ExperienceProblem]; the booth then
/// falls back to Porcelain Classic or the pack's own default, never to a
/// broken screen.
library;

import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../value_objects/appearance.dart';
import 'bundled_packs.dart';
import 'experience_catalog.dart';
import 'experience_configuration.dart';
import 'experience_pack.dart';

enum ExperienceProblemCode {
  unknownPack('EXPERIENCE_UNKNOWN_PACK'),
  unsupportedPackVersion('EXPERIENCE_PACK_VERSION_UNSUPPORTED'),
  unknownVariant('EXPERIENCE_UNKNOWN_VARIANT'),
  unknownPreset('EXPERIENCE_UNKNOWN_PRESET'),
  unknownAsset('EXPERIENCE_UNKNOWN_ASSET'),
  unknownFont('EXPERIENCE_UNKNOWN_FONT'),
  invalidPack('EXPERIENCE_INVALID_PACK'),
  missingOrientation('EXPERIENCE_ORIENTATION_MISSING'),
  unreadableColors('EXPERIENCE_COLORS_UNREADABLE'),
  invalidText('EXPERIENCE_TEXT_INVALID'),
  notCustomizable('EXPERIENCE_SETTING_NOT_CUSTOMIZABLE'),
  invalidSetting('EXPERIENCE_SETTING_INVALID');

  const ExperienceProblemCode(this.diagnostic);

  final String diagnostic;
}

@immutable
final class ExperienceProblem {
  const ExperienceProblem(this.code, this.detail);

  final ExperienceProblemCode code;

  /// The id or field concerned (never guest data).
  final String detail;

  @override
  bool operator ==(Object other) =>
      other is ExperienceProblem &&
      other.code == code &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(code, detail);

  @override
  String toString() => '${code.diagnostic}($detail)';
}

/// WCAG relative luminance of an opaque 0xAARRGGBB colour.
double relativeLuminance(int argb) {
  double channel(int shift) {
    final value = ((argb >> shift) & 0xFF) / 255;
    return value <= 0.04045
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
}

/// WCAG contrast ratio of two opaque colours (1 to 21).
double contrastRatio(int a, int b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

/// Text pairs on guest screens and the contrast each needs (WCAG AA for
/// normal text; guest text is large, so this is a floor).
const _textPairs = [
  (PaletteRole.ink, PaletteRole.backdrop),
  (PaletteRole.ink, PaletteRole.panel),
  (PaletteRole.inkMuted, PaletteRole.panel),
  (PaletteRole.onAccent, PaletteRole.accent),
];
const minimumTextContrast = 4.5;

/// The experience a guest session runs with, complete and self-contained:
/// stored with the session (its snapshot), so changing the event or
/// updating the app's packs never changes a session already started.
@immutable
final class ResolvedExperience {
  const ResolvedExperience({
    required this.packId,
    required this.packVersion,
    required this.variantId,
    required this.displayName,
    required this.themeFamily,
    required this.palette,
    required this.typography,
    required this.layoutPresetId,
    required this.buttonStyle,
    required this.copy,
    required this.countdownPresetId,
    required this.transitionPresetIds,
    required this.shutterEffectPresetId,
    required this.sounds,
    required this.soundEnabled,
    required this.soundVolume,
    required this.celebrationPresetId,
    required this.decorations,
    required this.animation,
    required this.cameraStage,
    required this.minTouchTarget,
    required this.childrenMayBeGuests,
    required this.configurationRevision,
    this.problems = const [],
  });

  static const currentSchemaVersion = 1;

  final String packId;
  final int packVersion;
  final String variantId;
  final String displayName;
  final String themeFamily;
  final GuestPalette palette;
  final GuestTypography typography;
  final String layoutPresetId;
  final GuestButtonStyle buttonStyle;
  final GuestCopy copy;
  final String countdownPresetId;
  final List<String> transitionPresetIds;
  final String shutterEffectPresetId;
  final Map<SoundCue, String> sounds;
  final bool soundEnabled;
  final int soundVolume;

  /// `none` when the event turned celebrations off.
  final String celebrationPresetId;
  final List<String> decorations;
  final AnimationIntensity animation;
  final CameraStageMode cameraStage;
  final double minTouchTarget;
  final bool childrenMayBeGuests;
  final int configurationRevision;

  /// What was ignored or replaced while resolving; empty when everything
  /// the event asked for is in use. Not stored with a session.
  final List<ExperienceProblem> problems;

  Map<String, Object?> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'packId': packId,
    'packVersion': packVersion,
    'variantId': variantId,
    'displayName': displayName,
    'themeFamily': themeFamily,
    'palette': palette.toJson(),
    'typography': typography.toJson(),
    'layoutPresetId': layoutPresetId,
    'buttonStyle': buttonStyle.name,
    'copy': copy.toJson(),
    'countdownPresetId': countdownPresetId,
    'transitionPresetIds': transitionPresetIds,
    'shutterEffectPresetId': shutterEffectPresetId,
    'sounds': {
      for (final MapEntry(:key, :value) in sounds.entries) key.name: value,
    },
    'soundEnabled': soundEnabled,
    'soundVolume': soundVolume,
    'celebrationPresetId': celebrationPresetId,
    'decorations': decorations,
    'animation': animation.name,
    'cameraStage': cameraStage.name,
    'minTouchTarget': minTouchTarget,
    'childrenMayBeGuests': childrenMayBeGuests,
    'configurationRevision': configurationRevision,
  };

  /// Reads a stored snapshot. Throws [FormatException] for one this
  /// version cannot read; the caller then resolves the event afresh.
  static ResolvedExperience fromJson(Map<String, Object?> json) {
    try {
      if (json['schemaVersion'] != currentSchemaVersion) {
        throw const FormatException('Unknown experience snapshot version');
      }
      List<String> strings(Object? value) => [
        for (final item in value! as List<Object?>) item! as String,
      ];
      final sounds = json['sounds']! as Map<String, Object?>;
      return ResolvedExperience(
        packId: json['packId']! as String,
        packVersion: json['packVersion']! as int,
        variantId: json['variantId']! as String,
        displayName: json['displayName']! as String,
        themeFamily: json['themeFamily']! as String,
        palette: GuestPalette.fromJson(
          json['palette']! as Map<String, Object?>,
        ),
        typography: GuestTypography.fromJson(
          json['typography']! as Map<String, Object?>,
        ),
        layoutPresetId: json['layoutPresetId']! as String,
        buttonStyle: GuestButtonStyle.values.byName(
          json['buttonStyle']! as String,
        ),
        copy: GuestCopy.fromJson(json['copy']! as Map<String, Object?>),
        countdownPresetId: json['countdownPresetId']! as String,
        transitionPresetIds: strings(json['transitionPresetIds']),
        shutterEffectPresetId: json['shutterEffectPresetId']! as String,
        sounds: {
          for (final MapEntry(:key, :value) in sounds.entries)
            SoundCue.values.byName(key): value! as String,
        },
        soundEnabled: json['soundEnabled']! as bool,
        soundVolume: json['soundVolume']! as int,
        celebrationPresetId: json['celebrationPresetId']! as String,
        decorations: strings(json['decorations']),
        animation: AnimationIntensity.values.byName(
          json['animation']! as String,
        ),
        cameraStage: CameraStageMode.values.byName(
          json['cameraStage']! as String,
        ),
        minTouchTarget: (json['minTouchTarget']! as num).toDouble(),
        childrenMayBeGuests: json['childrenMayBeGuests']! as bool,
        configurationRevision: json['configurationRevision']! as int,
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException(
        'Unreadable experience snapshot: ${error.runtimeType}',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ResolvedExperience && _sameJson(other.toJson(), toJson());

  @override
  int get hashCode => Object.hash(packId, packVersion, variantId, copy);
}

bool _sameJson(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_sameJson(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameJson(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// The packs this app can show, each validated.
final class ExperienceRegistry {
  ExperienceRegistry(Iterable<ExperiencePack> packs) {
    for (final pack in packs) {
      final problems = validatePack(pack);
      if (problems.isEmpty) {
        _packs[pack.packId] = pack;
      } else {
        _rejected[pack.packId] = problems;
      }
    }
    if (!_packs.containsKey(fallbackPackId)) {
      throw StateError('The fallback pack $fallbackPackId is not valid');
    }
  }

  /// The bundled packs.
  static final bundled = ExperienceRegistry(bundledPacks);

  static const fallbackPackId = 'porcelain-classic';

  /// Packs made for children: choosing one turns on "Guests may be
  /// children" (EP00 decision 4.7). The operator can turn it off.
  static const childrenPackIds = {'kid-party-arcade'};

  final _packs = <String, ExperiencePack>{};
  final _rejected = <String, List<ExperienceProblem>>{};

  List<ExperiencePack> get packs => List.unmodifiable(_packs.values);

  /// Packs left out because they failed validation, with why.
  Map<String, List<ExperienceProblem>> get rejected =>
      Map.unmodifiable(_rejected);

  ExperiencePack? pack(String packId) => _packs[packId];

  ExperiencePack get fallback => _packs[fallbackPackId]!;

  /// Everything wrong with [pack]; empty when it can be shown.
  static List<ExperienceProblem> validatePack(ExperiencePack pack) {
    final problems = <ExperienceProblem>[];
    void need(bool ok, ExperienceProblemCode code, String detail) {
      if (!ok) problems.add(ExperienceProblem(code, detail));
    }

    need(
      pack.schemaVersion == ExperiencePack.currentSchemaVersion,
      ExperienceProblemCode.invalidPack,
      'schemaVersion',
    );
    need(
      RegExp(r'^[a-z][a-z0-9-]{2,39}$').hasMatch(pack.packId),
      ExperienceProblemCode.invalidPack,
      'packId',
    );
    need(pack.packVersion >= 1, ExperienceProblemCode.invalidPack, 'version');
    need(
      pack.displayName.trim().isNotEmpty && pack.displayName.length <= 40,
      ExperienceProblemCode.invalidPack,
      'displayName',
    );
    need(
      pack.variants.isNotEmpty &&
          pack.variants.map((v) => v.id).toSet().length == pack.variants.length,
      ExperienceProblemCode.invalidPack,
      'variants',
    );
    need(
      pack.variant(pack.defaultVariantId) != null,
      ExperienceProblemCode.unknownVariant,
      pack.defaultVariantId,
    );
    need(
      ExperienceOrientation.values.every(pack.orientations.contains),
      ExperienceProblemCode.missingOrientation,
      pack.packId,
    );
    need(
      pack.accessibility.minTouchTarget >= 72,
      ExperienceProblemCode.invalidPack,
      'minTouchTarget',
    );
    for (final font in [pack.typography.display, pack.typography.body]) {
      need(
        ExperienceCatalog.fonts.contains(font),
        ExperienceProblemCode.unknownFont,
        font,
      );
    }
    void preset(Set<String> catalog, String id) =>
        need(catalog.contains(id), ExperienceProblemCode.unknownPreset, id);
    preset(ExperienceCatalog.layouts, pack.layoutPresetId);
    preset(ExperienceCatalog.countdowns, pack.countdownPresetId);
    preset(ExperienceCatalog.shutters, pack.shutterEffectPresetId);
    preset(ExperienceCatalog.celebrations, pack.celebrationPresetId);
    for (final id in pack.transitionPresetIds) {
      preset(ExperienceCatalog.transitions, id);
    }
    for (final cue in SoundCue.values) {
      final sound = pack.sounds[cue];
      need(
        sound != null && ExperienceCatalog.sounds.contains(sound),
        ExperienceProblemCode.unknownAsset,
        sound ?? cue.name,
      );
    }
    for (final id in pack.decorations) {
      need(
        ExperienceCatalog.decorations.contains(id),
        ExperienceProblemCode.unknownAsset,
        id,
      );
    }
    _checkCopy(pack.copy, problems);
    for (final variant in pack.variants) {
      if (variant.countdownPresetId case final id?) {
        preset(ExperienceCatalog.countdowns, id);
      }
      if (variant.layoutPresetId case final id?) {
        preset(ExperienceCatalog.layouts, id);
      }
      for (final id in variant.decorations ?? const <String>[]) {
        need(
          ExperienceCatalog.decorations.contains(id),
          ExperienceProblemCode.unknownAsset,
          id,
        );
      }
      final palette = pack.palette.withOverrides(variant.palette);
      _checkPalette(palette, '${pack.packId}/${variant.id}', problems);
      _checkCopy(pack.copy.withOverrides(variant.copy), problems);
    }
    return problems;
  }

  static void _checkCopy(GuestCopy copy, List<ExperienceProblem> problems) {
    for (final key in GuestCopyKey.values) {
      final text = copy[key];
      if (text.length > key.maxLength || text.contains(RegExp(r'[\n\r]'))) {
        problems.add(
          ExperienceProblem(ExperienceProblemCode.invalidText, key.name),
        );
      }
    }
    if (!copy[GuestCopyKey.shotProgress].contains('{n}') ||
        !copy[GuestCopyKey.shotProgress].contains('{total}')) {
      problems.add(
        const ExperienceProblem(
          ExperienceProblemCode.invalidText,
          'shotProgress',
        ),
      );
    }
  }

  static void _checkPalette(
    GuestPalette palette,
    String where,
    List<ExperienceProblem> problems,
  ) {
    for (final role in PaletteRole.values) {
      if ((palette[role] >> 24) != 0xFF) {
        problems.add(
          ExperienceProblem(
            ExperienceProblemCode.unreadableColors,
            '$where:${role.name} not opaque',
          ),
        );
      }
    }
    for (final (text, ground) in _textPairs) {
      if (contrastRatio(palette[text], palette[ground]) < minimumTextContrast) {
        problems.add(
          ExperienceProblem(
            ExperienceProblemCode.unreadableColors,
            '$where:${text.name}/${ground.name}',
          ),
        );
      }
    }
  }

  /// Problems with an operator's [config], for the Experience settings
  /// (empty when everything will be used as chosen).
  List<ExperienceProblem> validateConfiguration(
    EventExperienceConfiguration config,
  ) => resolve(config).problems;

  /// What guests see for [config]. Unknown packs or versions newer than
  /// this app fall back to Porcelain Classic; unknown variants, presets or
  /// unreadable colours fall back to the pack's own; every replacement is
  /// listed in [ResolvedExperience.problems].
  ResolvedExperience resolve(EventExperienceConfiguration config) {
    final problems = <ExperienceProblem>[];
    var pack = _packs[config.packId];
    var effective = config;
    if (pack == null) {
      problems.add(
        ExperienceProblem(ExperienceProblemCode.unknownPack, config.packId),
      );
      pack = fallback;
      effective = config.switchPack(pack.packId, pack.packVersion);
    } else if (config.packVersion > pack.packVersion) {
      problems.add(
        ExperienceProblem(
          ExperienceProblemCode.unsupportedPackVersion,
          '${config.packId}@${config.packVersion}',
        ),
      );
      pack = fallback;
      effective = config.switchPack(pack.packId, pack.packVersion);
    }
    bool allowed(ExperienceSetting setting, bool changed) {
      if (!changed) return false;
      if (pack!.customizable.contains(setting)) return true;
      problems.add(
        ExperienceProblem(ExperienceProblemCode.notCustomizable, setting.name),
      );
      return false;
    }

    var variant = pack.defaultVariant;
    if (allowed(ExperienceSetting.variant, effective.variantId != null)) {
      final chosen = pack.variant(effective.variantId);
      if (chosen == null) {
        problems.add(
          ExperienceProblem(
            ExperienceProblemCode.unknownVariant,
            effective.variantId!,
          ),
        );
      } else {
        variant = chosen;
      }
    }

    var palette = pack.palette.withOverrides(variant.palette);
    if (allowed(ExperienceSetting.accentColor, effective.accentColor != null)) {
      final accent = effective.accentColor!;
      final readable =
          (accent >> 24) == 0xFF &&
          contrastRatio(palette[PaletteRole.onAccent], accent) >=
              minimumTextContrast;
      if (readable) {
        palette = palette.withOverrides({PaletteRole.accent: accent});
      } else {
        problems.add(
          const ExperienceProblem(
            ExperienceProblemCode.unreadableColors,
            'accentColor',
          ),
        );
      }
    }

    var copy = pack.copy.withOverrides(variant.copy);
    String? text(String? value, int max, String field) {
      if (value == null) return null;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.length > max || trimmed.contains(RegExp(r'[\n\r]'))) {
        problems.add(
          ExperienceProblem(ExperienceProblemCode.invalidText, field),
        );
        return null;
      }
      return trimmed;
    }

    if (allowed(
      ExperienceSetting.getReadyText,
      effective.getReadyText != null,
    )) {
      if (text(
            effective.getReadyText,
            EventExperienceConfiguration.maxGetReadyLength,
            'getReadyText',
          )
          case final ready?) {
        copy = copy.withOverrides({GuestCopyKey.getReady: ready});
      }
    }
    if (allowed(ExperienceSetting.finishText, effective.finishText != null)) {
      if (text(
            effective.finishText,
            EventExperienceConfiguration.maxFinishLength,
            'finishText',
          )
          case final finish?) {
        copy = copy.withOverrides({GuestCopyKey.readyTitle: finish});
      }
    }

    var countdown = variant.countdownPresetId ?? pack.countdownPresetId;
    if (allowed(
      ExperienceSetting.countdown,
      effective.countdownPresetId != null,
    )) {
      final chosen = effective.countdownPresetId!;
      if (ExperienceCatalog.countdowns.contains(chosen)) {
        countdown = chosen;
      } else {
        problems.add(
          ExperienceProblem(ExperienceProblemCode.unknownPreset, chosen),
        );
      }
    }

    var volume = effective.soundVolume;
    if (volume < 0 || volume > 100) {
      problems.add(
        const ExperienceProblem(
          ExperienceProblemCode.invalidSetting,
          'soundVolume',
        ),
      );
      volume = volume.clamp(0, 100);
    }

    return ResolvedExperience(
      packId: pack.packId,
      packVersion: pack.packVersion,
      variantId: variant.id,
      displayName: pack.variants.length > 1
          ? '${pack.displayName} · ${variant.name}'
          : pack.displayName,
      themeFamily: pack.themeFamily,
      palette: palette,
      typography: pack.typography,
      layoutPresetId: variant.layoutPresetId ?? pack.layoutPresetId,
      buttonStyle: variant.buttonStyle ?? pack.buttonStyle,
      copy: copy,
      countdownPresetId: countdown,
      transitionPresetIds: pack.transitionPresetIds,
      shutterEffectPresetId: pack.shutterEffectPresetId,
      sounds: pack.sounds,
      soundEnabled: effective.soundEnabled ?? pack.accessibility.sound,
      soundVolume: volume,
      celebrationPresetId: effective.celebrationEnabled
          ? pack.celebrationPresetId
          : 'none',
      decorations: variant.decorations ?? pack.decorations,
      animation: effective.animation ?? pack.accessibility.animation,
      cameraStage: effective.cameraStage,
      minTouchTarget: pack.accessibility.minTouchTarget,
      childrenMayBeGuests: effective.childrenMayBeGuests,
      configurationRevision: effective.revision,
      problems: List.unmodifiable(problems),
    );
  }

  /// The experience an event gets when it has none of its own: the pack
  /// matching how the booth (or the event's former theme) looks, so guests
  /// see exactly what they saw before packs existed.
  static EventExperienceConfiguration forAppearance(
    PorcelainThemeProfile profile,
  ) => switch (profile) {
    PorcelainThemeProfile.porcelainStudio =>
      const EventExperienceConfiguration(),
    PorcelainThemeProfile.lightOak => const EventExperienceConfiguration(
      packId: 'vintage-oak',
    ),
    PorcelainThemeProfile.darkroomWalnut => const EventExperienceConfiguration(
      variantId: 'darkroom',
    ),
  };

  /// The original appearance whose screens show [config] until the guest
  /// screens read packs directly (EP06): the inverse of [forAppearance].
  /// Null for a pack that has no such appearance; those screens keep the
  /// booth's.
  static PorcelainThemeProfile? legacyAppearance(
    EventExperienceConfiguration config,
  ) => switch ((config.packId, config.variantId)) {
    ('porcelain-classic', 'darkroom') => PorcelainThemeProfile.darkroomWalnut,
    ('porcelain-classic', null || 'ivory') =>
      PorcelainThemeProfile.porcelainStudio,
    ('vintage-oak', _) => PorcelainThemeProfile.lightOak,
    _ => null,
  };
}
