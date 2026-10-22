/// Recommendation metadata on a template (EP01, used from EP08): what it
/// suits, never what it is restricted to. Any template can be used with
/// any experience.
library;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
final class TemplateTags {
  const TemplateTags({
    this.categoryTags = const [],
    this.recommendedExperienceIds = const [],
    this.occasionTags = const [],
    this.visualStyleTags = const [],
    this.ageSuitabilityNotes,
    this.defaultCaptureCount,
    this.optionalPackVariant,
  });

  static const currentSchemaVersion = 1;
  static const maxTags = 12;
  static const maxTagLength = 32;

  final List<String> categoryTags;
  final List<String> recommendedExperienceIds;
  final List<String> occasionTags;
  final List<String> visualStyleTags;

  /// Free note for operators, e.g. "Made for young children".
  final String? ageSuitabilityNotes;

  /// Photos the design is made for; the template's slot count decides.
  final int? defaultCaptureCount;

  /// A pack variant the design was drawn for (e.g. `arcade`).
  final String? optionalPackVariant;

  /// Every tag, for matching against a pack's recommended tags.
  Set<String> get allTags => {
    ...categoryTags,
    ...occasionTags,
    ...visualStyleTags,
  };

  bool get isEmpty =>
      categoryTags.isEmpty &&
      recommendedExperienceIds.isEmpty &&
      occasionTags.isEmpty &&
      visualStyleTags.isEmpty &&
      ageSuitabilityNotes == null &&
      defaultCaptureCount == null &&
      optionalPackVariant == null;

  /// Tags in canonical form: lower case, trimmed, unique, bounded.
  static List<String> normalise(Iterable<String> tags) {
    final seen = <String>{};
    for (final tag in tags) {
      final clean = tag.trim().toLowerCase();
      if (clean.isEmpty || clean.length > maxTagLength) continue;
      seen.add(clean);
      if (seen.length == maxTags) break;
    }
    return List.unmodifiable(seen);
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'categoryTags': categoryTags,
    'recommendedExperienceIds': recommendedExperienceIds,
    'occasionTags': occasionTags,
    'visualStyleTags': visualStyleTags,
    'ageSuitabilityNotes': ?ageSuitabilityNotes,
    'defaultCaptureCount': ?defaultCaptureCount,
    'optionalPackVariant': ?optionalPackVariant,
  };

  static TemplateTags fromJson(Map<String, Object?> json) {
    try {
      if (json['schemaVersion'] != currentSchemaVersion) {
        throw const FormatException('Unknown template tags version');
      }
      List<String> list(String key) => normalise([
        for (final item in json[key]! as List<Object?>) item! as String,
      ]);
      return TemplateTags(
        categoryTags: list('categoryTags'),
        recommendedExperienceIds: list('recommendedExperienceIds'),
        occasionTags: list('occasionTags'),
        visualStyleTags: list('visualStyleTags'),
        ageSuitabilityNotes: json['ageSuitabilityNotes'] as String?,
        defaultCaptureCount: json['defaultCaptureCount'] as int?,
        optionalPackVariant: json['optionalPackVariant'] as String?,
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Unreadable template tags: ${error.runtimeType}');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TemplateTags &&
      const ListEquality<String>().equals(other.categoryTags, categoryTags) &&
      const ListEquality<String>().equals(
        other.recommendedExperienceIds,
        recommendedExperienceIds,
      ) &&
      const ListEquality<String>().equals(other.occasionTags, occasionTags) &&
      const ListEquality<String>().equals(
        other.visualStyleTags,
        visualStyleTags,
      ) &&
      other.ageSuitabilityNotes == ageSuitabilityNotes &&
      other.defaultCaptureCount == defaultCaptureCount &&
      other.optionalPackVariant == optionalPackVariant;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(categoryTags),
    Object.hashAll(recommendedExperienceIds),
    Object.hashAll(occasionTags),
    Object.hashAll(visualStyleTags),
    ageSuitabilityNotes,
    defaultCaptureCount,
    optionalPackVariant,
  );
}
