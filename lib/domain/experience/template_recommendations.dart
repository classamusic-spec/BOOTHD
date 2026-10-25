/// Which library templates suit an event's guest experience (EP08):
/// recommendations only. Every template stays selectable; suited ones
/// are listed first and marked.
library;

import '../models/template_revision_summary.dart';
import '../template/template_tags.dart';
import 'experience_configuration.dart';
import 'experience_pack.dart';

abstract final class TemplateRecommendations {
  /// How well [template] suits [pack] (in [config]'s variant): 3 made for
  /// this pack and variant, or linked by the operator; 2 made for the pack
  /// in another variant; 1 sharing one of the pack's template tags; 0 not
  /// recommended (still usable).
  static int score(
    TemplateRevisionSummary template,
    ExperiencePack pack,
    EventExperienceConfiguration config,
  ) {
    if (config.recommendedTemplateIds.contains(template.templateId)) return 3;
    return scoreTags(template.tags, pack, config);
  }

  /// [score] for a design known only by its [tags], such as a starter
  /// design that is not in the library yet.
  static int scoreTags(
    TemplateTags tags,
    ExperiencePack pack,
    EventExperienceConfiguration config,
  ) {
    if (tags.recommendedExperienceIds.contains(pack.packId)) {
      final variant = config.variantId ?? pack.defaultVariantId;
      final drawnFor = tags.optionalPackVariant;
      return drawnFor == null || drawnFor == variant ? 3 : 2;
    }
    return tags.allTags.any(pack.recommendedTemplateTags.contains) ? 1 : 0;
  }

  /// [templates] with the suited ones first (best first), otherwise in
  /// their given order. Nothing is removed.
  static List<TemplateRevisionSummary> order(
    List<TemplateRevisionSummary> templates,
    ExperiencePack pack,
    EventExperienceConfiguration config,
  ) {
    final scored = [
      for (final (index, template) in templates.indexed)
        (score(template, pack, config), index, template),
    ]..sort((a, b) => a.$1 != b.$1 ? b.$1.compareTo(a.$1) : a.$2 - b.$2);
    return [for (final (_, _, template) in scored) template];
  }
}
