// EP01: template recommendation tags are suggestions with a stable stored
// form; anything malformed is refused, never half-read.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/template/template_tags.dart';

void main() {
  test('tags are normalised: trimmed, lower case, unique and bounded', () {
    expect(TemplateTags.normalise([' Wedding ', 'wedding', '', 'GOLD']), [
      'wedding',
      'gold',
    ]);
    expect(TemplateTags.normalise(['x' * 33]), isEmpty);
    expect(
      TemplateTags.normalise([for (var i = 0; i < 20; i++) 'tag$i']),
      hasLength(TemplateTags.maxTags),
    );
  });

  test('round-trips through its stored form', () {
    const tags = TemplateTags(
      categoryTags: ['party'],
      recommendedExperienceIds: ['kid-party-arcade'],
      occasionTags: ['birthday'],
      visualStyleTags: ['bright', 'balloons'],
      ageSuitabilityNotes: 'Made for young children',
      defaultCaptureCount: 3,
      optionalPackVariant: 'sunny',
    );
    expect(TemplateTags.fromJson(tags.toJson()), tags);
    expect(tags.allTags, {'party', 'birthday', 'bright', 'balloons'});
    expect(const TemplateTags().isEmpty, isTrue);
    expect(tags.isEmpty, isFalse);
  });

  test('an unknown version or shape is refused', () {
    expect(
      () => TemplateTags.fromJson(const {'schemaVersion': 2}),
      throwsFormatException,
    );
    expect(
      () => TemplateTags.fromJson(const {
        'schemaVersion': 1,
        'categoryTags': 'party',
      }),
      throwsFormatException,
    );
  });
}
