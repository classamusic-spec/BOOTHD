import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/templates/starter_designs.dart';
import '../../core/templates/template_library.dart';
import '../../core/templates/template_thumbnails.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_text_field.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/rendered_thumbnail.dart';

/// The operator's choice for a new template.
typedef NewTemplateChoice = ({StarterDesign design, String name});

/// "Choose your style" (S06, AC-0501; the reference board's chooser): the
/// finished designs and a blank page in each print format, each rendered
/// as it prints, and a name. Returns null when closed.
Future<NewTemplateChoice?> chooseNewTemplate(BuildContext context) =>
    showModalBottomSheet<NewTemplateChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: PorcelainMotion.of(context).isReduced
          ? AnimationStyle.noAnimation
          : null,
      builder: (context) => const _NewTemplateSheet(),
    );

class _NewTemplateSheet extends StatefulWidget {
  const _NewTemplateSheet();

  @override
  State<_NewTemplateSheet> createState() => _NewTemplateSheetState();
}

class _NewTemplateSheetState extends State<_NewTemplateSheet> {
  var _design = starterDesigns.firstWhere((d) => !d.blank);
  late final _name = TextEditingController(text: _design.name);
  var _nameTouched = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pick(StarterDesign design) => setState(() {
    _design = design;
    if (!_nameTouched) _name.text = design.name;
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final designs = [
      for (final d in starterDesigns)
        if (!d.blank) d,
    ];
    final blanks = [
      for (final d in starterDesigns)
        if (d.blank) d,
    ];
    final name = _name.text.trim();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(
          PorcelainSpace.xxl,
          PorcelainSpace.md,
          PorcelainSpace.xxl,
          PorcelainSpace.xxl,
        ),
        children: [
          Center(
            child: Semantics(
              header: true,
              child: Text(
                'CHOOSE YOUR STYLE',
                style: theme.text.titleLarge.copyWith(
                  letterSpacing: 3,
                  color: colors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: PorcelainSpace.xxs),
          Center(
            child: Text(
              'Pick a design for your photos. Everything in it can be '
              'changed afterwards.',
              textAlign: TextAlign.center,
              style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
            ),
          ),
          const SizedBox(height: PorcelainSpace.xl),
          _StyleGrid(designs: designs, selected: _design, onPick: _pick),
          const SizedBox(height: PorcelainSpace.xl),
          Text(
            'Or start from a blank page',
            style: theme.text.titleMedium.copyWith(color: colors.ink),
          ),
          const SizedBox(height: PorcelainSpace.md),
          _StyleGrid(designs: blanks, selected: _design, onPick: _pick),
          const SizedBox(height: PorcelainSpace.xl),
          PorcelainTextField(
            label: 'Template name',
            controller: _name,
            maxLength: maxTemplateNameLength,
            textCapitalization: TextCapitalization.words,
            error: name.isEmpty ? 'Give the template a name.' : null,
            onChanged: (_) => setState(() => _nameTouched = true),
          ),
          const SizedBox(height: PorcelainSpace.xl),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 280),
              child: PorcelainButton(
                label: 'Continue',
                icon: PorcelainIcons.check,
                variant: PorcelainButtonVariant.primary,
                size: PorcelainButtonSize.large,
                disabledReason: 'Give the template a name first.',
                onPressed: name.isEmpty
                    ? null
                    : () =>
                          Navigator.of(context)
                              .pop((design: _design, name: name)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleGrid extends StatelessWidget {
  const _StyleGrid({
    required this.designs,
    required this.selected,
    required this.onPick,
  });

  final List<StarterDesign> designs;
  final StarterDesign selected;
  final ValueChanged<StarterDesign> onPick;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = (constraints.maxWidth / 190).floor().clamp(2, 6);
      final width =
          (constraints.maxWidth - PorcelainSpace.md * (columns - 1)) / columns;
      return Wrap(
        spacing: PorcelainSpace.md,
        runSpacing: PorcelainSpace.md,
        children: [
          for (final design in designs)
            SizedBox(
              width: width,
              child: _StyleCard(
                design: design,
                selected: design.id == selected.id,
                onPressed: () => onPick(design),
              ),
            ),
        ],
      );
    },
  );
}

/// A design as the board shows it: the print on a porcelain card, its
/// name beneath, a gold edge and check mark when chosen.
class _StyleCard extends ConsumerWidget {
  const _StyleCard({
    required this.design,
    required this.selected,
    required this.onPressed,
  });

  final StarterDesign design;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    final page = design.page;
    final photos = design.photoSlots;
    return Pressable(
      onPressed: onPressed,
      semanticLabel:
          '${design.name}, ${design.description} '
          '${photos == 0 ? '' : '$photos ${photos == 1 ? 'photo' : 'photos'}'}',
      selected: selected,
      builder: (context, state) => AnimatedContainer(
        duration: motion.press,
        padding: const EdgeInsets.all(PorcelainSpace.sm),
        decoration: BoxDecoration(
          color: colors.raised,
          borderRadius: PorcelainRadius.cardAll,
          border: Border.all(
            color: selected
                ? colors.accentIcon
                : state.focused
                ? colors.focusRing
                : colors.hairline,
            width: selected || state.focused ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadowAmbient,
              blurRadius: selected ? 18 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 190,
                  child: Center(
                    child: RenderedThumbnail(
                      thumbnail: starterThumbnailProvider(design.id),
                      aspectRatio: page.widthPx / page.heightPx,
                      semanticLabel: design.name,
                    ),
                  ),
                ),
                const SizedBox(height: PorcelainSpace.sm),
                Text(
                  design.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.labelLarge.copyWith(color: colors.ink),
                ),
                Text(
                  photos == 0
                      ? 'Blank page'
                      : '$photos ${photos == 1 ? 'photo' : 'photos'}',
                  textAlign: TextAlign.center,
                  style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
            if (selected)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colors.primaryTop, colors.primaryBottom],
                    ),
                    border: Border.all(color: colors.primaryEdge),
                  ),
                  child: Icon(
                    PorcelainIcons.check,
                    size: 18,
                    color: colors.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
