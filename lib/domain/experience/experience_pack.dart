/// The Experience Pack document (EP01, ADR-0017): a versioned, declarative
/// description of how the guest screens look, read, count down, sound and
/// celebrate. Shared by every pack: the guest flow, camera, template
/// rendering, delivery and storage, which no pack can change.
library;

import 'package:meta/meta.dart';

import 'experience_catalog.dart';

/// Colour roles of the guest screens. Values are 0xAARRGGBB.
enum PaletteRole {
  /// The screen behind everything.
  backdrop,

  /// A second backdrop tone for gradients and bands.
  backdropAccent,

  /// Cards and panels guests read from.
  panel,

  /// Panel borders and bevels.
  panelEdge,

  /// Text and icons on the backdrop and panels.
  ink,

  /// Secondary text.
  inkMuted,

  /// The main action colour.
  accent,

  /// Text and icons on [accent].
  onAccent,

  /// The bevel and pressed edge of [accent] controls.
  accentEdge,

  /// The light catching raised controls.
  highlight,

  /// Decoration colours (never text).
  decorationA,
  decorationB,
}

/// A guest palette: every role, as ARGB.
@immutable
final class GuestPalette {
  GuestPalette(Map<PaletteRole, int> colors)
    : colors = Map.unmodifiable(colors) {
    for (final role in PaletteRole.values) {
      if (!colors.containsKey(role)) {
        throw ArgumentError.value(role, 'colors', 'missing palette role');
      }
    }
  }

  final Map<PaletteRole, int> colors;

  int operator [](PaletteRole role) => colors[role]!;

  GuestPalette withOverrides(Map<PaletteRole, int> overrides) =>
      GuestPalette({...colors, ...overrides});

  Map<String, Object?> toJson() => {
    for (final MapEntry(:key, :value) in colors.entries) key.name: _hex(value),
  };

  static GuestPalette fromJson(Map<String, Object?> json) => GuestPalette({
    for (final role in PaletteRole.values)
      role: _parseHex(json[role.name], role.name),
  });

  @override
  bool operator ==(Object other) =>
      other is GuestPalette &&
      PaletteRole.values.every((role) => other[role] == this[role]);

  @override
  int get hashCode =>
      Object.hashAll([for (final role in PaletteRole.values) this[role]]);
}

String _hex(int argb) =>
    '#${argb.toUnsigned(32).toRadixString(16).padLeft(8, '0').toUpperCase()}';

int _parseHex(Object? value, String name) {
  if (value is! String || !RegExp(r'^#[0-9A-Fa-f]{8}$').hasMatch(value)) {
    throw FormatException('Colour $name must be #AARRGGBB');
  }
  return int.parse(value.substring(1), radix: 16);
}

/// Words guests read that a pack may change. `{n}` and `{total}` in
/// [shotProgress] are filled in by the guest screens.
enum GuestCopyKey {
  start(24),
  chooseTitle(40),
  getReady(40),
  lookHere(40),
  countdownLead(24),
  countdownGo(16),
  snap(24),
  lovely(24),
  nextPhotoSoon(40),
  shotProgress(32),
  reviewTitle(40),
  keepThese(24),
  keepIt(24),
  retake(24),
  retakeAll(24),
  creatingTitle(40),
  readyTitle(48),
  savedMessage(80),
  textMyPhotos(24),
  nextGuest(24);

  const GuestCopyKey(this.maxLength);

  final int maxLength;
}

/// Guest words, complete for every [GuestCopyKey].
@immutable
final class GuestCopy {
  GuestCopy(Map<GuestCopyKey, String> words) : words = Map.unmodifiable(words) {
    for (final key in GuestCopyKey.values) {
      final text = words[key];
      if (text == null || text.trim().isEmpty) {
        throw ArgumentError.value(key, 'words', 'missing guest copy');
      }
    }
  }

  final Map<GuestCopyKey, String> words;

  String operator [](GuestCopyKey key) => words[key]!;

  /// "Photo 2 of 3", in this copy's words.
  String shotProgress(int number, int total) => this[GuestCopyKey.shotProgress]
      .replaceAll('{n}', '$number')
      .replaceAll('{total}', '$total');

  GuestCopy withOverrides(Map<GuestCopyKey, String> overrides) =>
      GuestCopy({...words, ...overrides});

  Map<String, Object?> toJson() => {
    for (final MapEntry(:key, :value) in words.entries) key.name: value,
  };

  static GuestCopy fromJson(Map<String, Object?> json) => GuestCopy({
    for (final key in GuestCopyKey.values)
      key: switch (json[key.name]) {
        final String text => text,
        _ => throw FormatException('Missing copy ${key.name}'),
      },
  });

  @override
  bool operator ==(Object other) =>
      other is GuestCopy &&
      GuestCopyKey.values.every((key) => other[key] == this[key]);

  @override
  int get hashCode =>
      Object.hashAll([for (final key in GuestCopyKey.values) this[key]]);
}

/// Display and body faces, from [ExperienceCatalog.fonts].
@immutable
final class GuestTypography {
  const GuestTypography({required this.display, this.body = 'inter'});

  final String display;
  final String body;

  Map<String, Object?> toJson() => {'display': display, 'body': body};

  static GuestTypography fromJson(Map<String, Object?> json) => GuestTypography(
    display: json['display']! as String,
    body: json['body']! as String,
  );

  @override
  bool operator ==(Object other) =>
      other is GuestTypography &&
      other.display == display &&
      other.body == body;

  @override
  int get hashCode => Object.hash(display, body);
}

/// What a pack turns on unless the event says otherwise.
@immutable
final class AccessibilityDefaults {
  const AccessibilityDefaults({
    this.animation = AnimationIntensity.gentle,
    this.sound = false,
    this.minTouchTarget = 72,
  });

  final AnimationIntensity animation;
  final bool sound;

  /// Logical points; never below 72 for guest primary actions.
  final double minTouchTarget;

  Map<String, Object?> toJson() => {
    'animation': animation.name,
    'sound': sound,
    'minTouchTarget': minTouchTarget,
  };

  static AccessibilityDefaults fromJson(Map<String, Object?> json) =>
      AccessibilityDefaults(
        animation: AnimationIntensity.values.byName(
          json['animation']! as String,
        ),
        sound: json['sound']! as bool,
        minTouchTarget: (json['minTouchTarget']! as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      other is AccessibilityDefaults &&
      other.animation == animation &&
      other.sound == sound &&
      other.minTouchTarget == minTouchTarget;

  @override
  int get hashCode => Object.hash(animation, sound, minTouchTarget);
}

/// A variant within a pack family: what it changes from the pack.
@immutable
final class PackVariant {
  const PackVariant({
    required this.id,
    required this.name,
    this.description = '',
    this.palette = const {},
    this.copy = const {},
    this.buttonStyle,
    this.countdownPresetId,
    this.layoutPresetId,
    this.decorations,
  });

  final String id;
  final String name;
  final String description;
  final Map<PaletteRole, int> palette;
  final Map<GuestCopyKey, String> copy;
  final GuestButtonStyle? buttonStyle;
  final String? countdownPresetId;
  final String? layoutPresetId;
  final List<String>? decorations;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'palette': {
      for (final MapEntry(:key, :value) in palette.entries)
        key.name: _hex(value),
    },
    'copy': {
      for (final MapEntry(:key, :value) in copy.entries) key.name: value,
    },
    'buttonStyle': ?buttonStyle?.name,
    'countdownPresetId': ?countdownPresetId,
    'layoutPresetId': ?layoutPresetId,
    'decorations': ?decorations,
  };

  static PackVariant fromJson(Map<String, Object?> json) {
    final palette = json['palette']! as Map<String, Object?>;
    final copy = json['copy']! as Map<String, Object?>;
    return PackVariant(
      id: json['id']! as String,
      name: json['name']! as String,
      description: json['description']! as String,
      palette: {
        for (final MapEntry(:key, :value) in palette.entries)
          PaletteRole.values.byName(key): _parseHex(value, key),
      },
      copy: {
        for (final MapEntry(:key, :value) in copy.entries)
          GuestCopyKey.values.byName(key): value! as String,
      },
      buttonStyle: switch (json['buttonStyle']) {
        final String name => GuestButtonStyle.values.byName(name),
        _ => null,
      },
      countdownPresetId: json['countdownPresetId'] as String?,
      layoutPresetId: json['layoutPresetId'] as String?,
      decorations: switch (json['decorations']) {
        final List<Object?> list => [for (final id in list) id! as String],
        _ => null,
      },
    );
  }
}

/// One Experience Pack (EP01): everything is a choice among predefined
/// presets and bundled assets.
@immutable
final class ExperiencePack {
  const ExperiencePack({
    this.schemaVersion = currentSchemaVersion,
    required this.packId,
    required this.packVersion,
    required this.displayName,
    required this.description,
    required this.themeFamily,
    required this.variants,
    required this.defaultVariantId,
    required this.palette,
    required this.typography,
    required this.layoutPresetId,
    required this.buttonStyle,
    required this.copy,
    required this.countdownPresetId,
    required this.transitionPresetIds,
    required this.shutterEffectPresetId,
    required this.sounds,
    required this.celebrationPresetId,
    required this.decorations,
    this.orientations = const {
      ExperienceOrientation.portrait,
      ExperienceOrientation.landscape,
    },
    this.accessibility = const AccessibilityDefaults(),
    this.recommendedTemplateTags = const {},
    this.customizable = const {...ExperienceSetting.values},
  });

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final String packId;
  final int packVersion;
  final String displayName;
  final String description;

  /// Variants of one family share it (e.g. `retro-game`).
  final String themeFamily;
  final List<PackVariant> variants;
  final String defaultVariantId;
  final GuestPalette palette;
  final GuestTypography typography;
  final String layoutPresetId;
  final GuestButtonStyle buttonStyle;
  final GuestCopy copy;
  final String countdownPresetId;
  final List<String> transitionPresetIds;
  final String shutterEffectPresetId;
  final Map<SoundCue, String> sounds;
  final String celebrationPresetId;
  final List<String> decorations;
  final Set<ExperienceOrientation> orientations;
  final AccessibilityDefaults accessibility;
  final Set<String> recommendedTemplateTags;
  final Set<ExperienceSetting> customizable;

  PackVariant? variant(String? id) {
    for (final variant in variants) {
      if (variant.id == id) return variant;
    }
    return null;
  }

  PackVariant get defaultVariant => variant(defaultVariantId)!;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'packId': packId,
    'packVersion': packVersion,
    'displayName': displayName,
    'description': description,
    'themeFamily': themeFamily,
    'variants': [for (final variant in variants) variant.toJson()],
    'defaultVariantId': defaultVariantId,
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
    'celebrationPresetId': celebrationPresetId,
    'decorations': decorations,
    'orientations': [for (final o in orientations) o.name],
    'accessibility': accessibility.toJson(),
    'recommendedTemplateTags': recommendedTemplateTags.toList()..sort(),
    'customizable': [for (final s in customizable) s.name],
  };

  /// Reads a manifest. Throws [FormatException] for anything this version
  /// cannot read; [ExperienceValidation] then checks what it names.
  static ExperiencePack fromJson(Map<String, Object?> json) {
    try {
      final version = json['schemaVersion'];
      if (version != currentSchemaVersion) {
        throw FormatException('Unknown pack schema version $version');
      }
      List<String> strings(Object? value) => [
        for (final item in value! as List<Object?>) item! as String,
      ];
      final sounds = json['sounds']! as Map<String, Object?>;
      return ExperiencePack(
        packId: json['packId']! as String,
        packVersion: json['packVersion']! as int,
        displayName: json['displayName']! as String,
        description: json['description']! as String,
        themeFamily: json['themeFamily']! as String,
        variants: [
          for (final variant in json['variants']! as List<Object?>)
            PackVariant.fromJson(variant! as Map<String, Object?>),
        ],
        defaultVariantId: json['defaultVariantId']! as String,
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
        celebrationPresetId: json['celebrationPresetId']! as String,
        decorations: strings(json['decorations']),
        orientations: {
          for (final name in strings(json['orientations']))
            ExperienceOrientation.values.byName(name),
        },
        accessibility: AccessibilityDefaults.fromJson(
          json['accessibility']! as Map<String, Object?>,
        ),
        recommendedTemplateTags: strings(json['recommendedTemplateTags'])
            .toSet(),
        customizable: {
          for (final name in strings(json['customizable']))
            ExperienceSetting.values.byName(name),
        },
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Unreadable pack manifest: ${error.runtimeType}');
    }
  }
}
