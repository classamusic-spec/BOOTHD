// EP08: template recommendations rank, never filter.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/domain/experience/template_recommendations.dart';
import 'package:porcelain_photo_booth/domain/models/template_revision_summary.dart';
import 'package:porcelain_photo_booth/domain/template/template_tags.dart';

TemplateRevisionSummary _template(
  String id, [
  TemplateTags tags = const TemplateTags(),
]) => TemplateRevisionSummary(
  revisionId: 'r-$id',
  templateId: id,
  templateName: id,
  revisionNumber: 1,
  pageWidthPx: 1200,
  pageHeightPx: 1800,
  photoSlotCount: 2,
  tags: tags,
);

void main() {
  final quest = ExperienceRegistry.bundled.pack('retro-game-quest')!;
  const handheld = EventExperienceConfiguration(packId: 'retro-game-quest');
  final plain = _template('plain');
  final tagged = _template(
    'tagged',
    const TemplateTags(categoryTags: ['pixel']),
  );
  final arcade = _template(
    'arcade',
    const TemplateTags(
      recommendedExperienceIds: ['retro-game-quest'],
      optionalPackVariant: 'arcade',
    ),
  );
  final made = _template(
    'made',
    const TemplateTags(recommendedExperienceIds: ['retro-game-quest']),
  );

  test('made for the pack and variant, then the pack, then a shared tag', () {
    expect(TemplateRecommendations.score(made, quest, handheld), 3);
    expect(TemplateRecommendations.score(arcade, quest, handheld), 2);
    expect(
      TemplateRecommendations.score(
        arcade,
        quest,
        handheld.copyWith(variantId: 'arcade'),
      ),
      3,
    );
    expect(TemplateRecommendations.score(tagged, quest, handheld), 1);
    expect(TemplateRecommendations.score(plain, quest, handheld), 0);
  });

  test('a template the operator linked counts as made for the event', () {
    expect(
      TemplateRecommendations.score(
        plain,
        quest,
        handheld.copyWith(recommendedTemplateIds: ['plain']),
      ),
      3,
    );
  });

  test('ordering keeps every template, suited first, otherwise stable', () {
    final ordered = TemplateRecommendations.order(
      [plain, tagged, arcade, made],
      quest,
      handheld,
    );
    expect(ordered, [made, arcade, tagged, plain]);
    final none = TemplateRecommendations.order(
      [plain, _template('other')],
      quest,
      handheld,
    );
    expect([for (final t in none) t.templateId], ['plain', 'other']);
  });
}
