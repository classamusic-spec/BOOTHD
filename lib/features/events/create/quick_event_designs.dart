/// The new-event flow's choices (UX-P1, CR-003): the occasion that picks a
/// fitting look, and the photo designs a new event can start with, in the
/// order that suits the chosen look. Recommendations only: every design
/// stays available.
library;

import 'package:flutter/widgets.dart';

import '../../../core/design_system/porcelain_icons.dart';
import '../../../core/templates/starter_designs.dart';
import '../../../domain/experience/experience_configuration.dart';
import '../../../domain/experience/experience_pack.dart';
import '../../../domain/experience/template_recommendations.dart';
import '../../../domain/models/event_rules.dart';
import '../../../domain/models/template_revision_summary.dart';
import '../../../domain/template/template_tags.dart';

/// What the event celebrates. Choosing one picks the guest experience that
/// suits it; nothing about it is stored, and the look can still be
/// changed.
enum QuickOccasion {
  wedding('Wedding', PorcelainIcons.wedding, 'porcelain-classic'),
  birthday('Birthday', PorcelainIcons.birthday, 'disco-nights'),
  kidsParty('Kids party', PorcelainIcons.kidsParty, 'kid-party-arcade'),
  gala('Gala night', PorcelainIcons.gala, 'midnight-gala'),
  garden('Garden party', PorcelainIcons.garden, 'storybook-garden'),
  retro('Retro night', PorcelainIcons.retro, 'retro-film'),
  gameNight('Game night', PorcelainIcons.gameNight, 'retro-game-quest'),
  rustic('Rustic celebration', PorcelainIcons.rustic, 'vintage-oak');

  const QuickOccasion(this.label, this.icon, this.packId);

  final String label;
  final IconData icon;

  /// The guest experience the occasion starts with.
  final String packId;

  /// A placeholder for the event's name, without any real names.
  String get titleHint => switch (this) {
    wedding => 'e.g. Our wedding day',
    birthday => 'e.g. 30th birthday party',
    kidsParty => 'e.g. 7th birthday party',
    gala => 'e.g. Spring gala',
    garden => 'e.g. Summer garden party',
    retro => 'e.g. 80s night',
    gameNight => 'e.g. Game night',
    rustic => 'e.g. Harvest celebration',
  };
}

/// A photo design a new event can start with.
sealed class QuickDesign {
  const QuickDesign();

  /// Unique among the choices on screen.
  String get key;
  String get name;
  int get photoSlots;

  /// Page width over height.
  double get aspectRatio;
  TemplateTags get tags;
}

/// A template already in the library: its newest revision.
final class LibraryDesign extends QuickDesign {
  const LibraryDesign(this.template);

  final TemplateRevisionSummary template;

  @override
  String get key => 'library:${template.revisionId}';

  @override
  String get name => template.templateName;

  @override
  int get photoSlots => template.photoSlotCount;

  @override
  double get aspectRatio => template.pageWidthPx / template.pageHeightPx;

  @override
  TemplateTags get tags => template.tags;
}

/// A ready-made design: added to the library, as revision 1 of a new
/// template named after it, when the event is created.
final class StarterChoice extends QuickDesign {
  StarterChoice(this.design);

  final StarterDesign design;

  @override
  String get key => 'starter:${design.id}';

  @override
  String get name => design.name;

  @override
  late final int photoSlots = design.photoSlots;

  @override
  double get aspectRatio => design.page.width / design.page.height;

  @override
  TemplateTags get tags => design.tags;
}

/// The designs a new event can start with: the [library]'s templates,
/// then the ready-made designs, each best suited to [pack] first. Blank
/// pages, a ready-made design the library already has under its own name
/// and designs whose photo count an event cannot take are left out.
List<QuickDesign> quickDesigns({
  required List<TemplateRevisionSummary> library,
  required List<StarterDesign> starters,
  required ExperiencePack pack,
  required EventExperienceConfiguration config,
}) {
  final candidates = <QuickDesign>[
    for (final template in library)
      if (!template.templateArchived) LibraryDesign(template),
    for (final design in starters)
      if (!design.blank && !_inLibrary(design, library)) StarterChoice(design),
  ];
  final scored =
      [
        for (final (index, design) in candidates.indexed)
          if (EventLimits.shotCount.contains(design.photoSlots))
            (quickDesignScore(design, pack, config), index, design),
      ]..sort((a, b) {
        final group =
            (a.$3 is StarterChoice ? 1 : 0) - (b.$3 is StarterChoice ? 1 : 0);
        if (group != 0) return group;
        return a.$1 != b.$1 ? b.$1.compareTo(a.$1) : a.$2 - b.$2;
      });
  return [for (final (_, _, design) in scored) design];
}

/// How well [design] suits [pack]: see [TemplateRecommendations.score].
int quickDesignScore(
  QuickDesign design,
  ExperiencePack pack,
  EventExperienceConfiguration config,
) => switch (design) {
  LibraryDesign(:final template) => TemplateRecommendations.score(
    template,
    pack,
    config,
  ),
  StarterChoice() => TemplateRecommendations.scoreTags(
    design.tags,
    pack,
    config,
  ),
};

/// Whether the library already holds [design]: an unarchived template with
/// its name, page and photo count, most likely made from it.
bool _inLibrary(StarterDesign design, List<TemplateRevisionSummary> library) {
  final aspect = design.page.width / design.page.height;
  return library.any(
    (template) =>
        !template.templateArchived &&
        template.templateName.trim().toLowerCase() ==
            design.name.toLowerCase() &&
        (template.pageWidthPx / template.pageHeightPx - aspect).abs() < 0.01 &&
        template.photoSlotCount == design.photoSlots,
  );
}
