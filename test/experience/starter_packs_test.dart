// EP04, EP05 (AC-EP03, AC-EP04, AC-EP17): Kid Party Arcade's six and Retro
// Game Quest's eight original starter designs: editable documents that the
// store accepts and renders at print size (starter_designs_test.dart),
// tagged to suit their pack without being limited to it, in every print
// format, using only the app's own artwork and SIL OFL fonts.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/templates/bundled_decorations.dart';
import 'package:porcelain_photo_booth/core/templates/starter_designs.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/domain/repositories/template_store.dart';
import 'package:porcelain_photo_booth/domain/template/page_spec.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';

void main() {
  test('six Kid Party Arcade and eight Retro Game Quest designs', () {
    expect(kidPartyDesigns, hasLength(6));
    expect(retroGameDesigns, hasLength(8));
    for (final design in [...kidPartyDesigns, ...retroGameDesigns]) {
      expect(starterDesigns, contains(design));
    }
    expect({for (final d in kidPartyDesigns) d.category}, {'Kid Party'});
    expect({for (final d in retroGameDesigns) d.category}, {'Retro Game'});
  });

  test('each set covers every print format', () {
    for (final set in [kidPartyDesigns, retroGameDesigns]) {
      expect(
        {for (final d in set) d.page},
        {
          PageSpec.twoBySix,
          PageSpec.fourBySixPortrait,
          PageSpec.fourBySixLandscape,
          PageSpec.fourByFour,
        },
      );
    }
  });

  test('tags recommend the pack and match the photo count', () {
    for (final (set, pack) in [
      (kidPartyDesigns, 'kid-party-arcade'),
      (retroGameDesigns, 'retro-game-quest'),
    ]) {
      for (final design in set) {
        expect(design.tags.recommendedExperienceIds, [pack]);
        expect(design.tags.defaultCaptureCount, design.photoSlots);
        expect(design.photoSlots, inInclusiveRange(1, 4));
        if (design.tags.optionalPackVariant case final variant?) {
          expect(
            ExperienceRegistry.bundled.pack(pack)!.variant(variant),
            isNotNull,
          );
        }
        final overlap = ExperienceRegistry.bundled
            .pack(pack)!
            .recommendedTemplateTags
            .intersection(design.tags.allTags);
        expect(overlap, isNotEmpty, reason: '${design.id} matches its pack');
      }
    }
  });

  test('only bundled decorations and SIL OFL fonts are used', () {
    final decorations = {for (final d in bundledDecorations) d.id};
    for (final design in [...kidPartyDesigns, ...retroGameDesigns]) {
      expect(decorations, containsAll(design.decorations), reason: design.id);
      final document = design.build({
        for (final id in design.decorations)
          id: StoredAsset(
            id: id.codeUnits
                .fold<int>(7, (h, c) => (h * 31 + c) & 0xFFFFFF)
                .toRadixString(16)
                .padLeft(64, '0'),
            asset: const TemplateAsset(
              mediaType: AssetMediaType.png,
              byteLength: 1,
              widthPx: 1,
              heightPx: 1,
            ),
            origin: AssetOrigin.bundled,
            createdAt: DateTime.utc(2026),
          ),
      });
      for (final layer in document.layers.whereType<TextLayer>()) {
        expect(layer.font, isA<BundledFont>(), reason: design.id);
      }
    }
  });

  test('a party design lets confetti cross its photos (not clipped)', () {
    final strip = kidPartyDesigns.firstWhere(
      (d) => d.id == 'kid-confetti-strip',
    );
    final document = strip.build({
      'party_confetti': StoredAsset(
        id: 'c' * 64,
        asset: const TemplateAsset(
          mediaType: AssetMediaType.png,
          byteLength: 1,
          widthPx: 1,
          heightPx: 1,
        ),
        origin: AssetOrigin.bundled,
        createdAt: DateTime.utc(2026),
      ),
    });
    final confetti = document.layers.whereType<ImageLayer>().single;
    for (final slot in document.photoSlots) {
      expect(confetti.zIndex, greaterThan(slot.zIndex));
      final a = confetti.frame;
      final b = slot.frame;
      expect(
        a.x < b.x + b.width &&
            b.x < a.x + a.width &&
            a.y < b.y + b.height &&
            b.y < a.y + a.height,
        isTrue,
      );
    }
  });
}
