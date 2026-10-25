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

Future<NewTemplateChoice?> chooseNewTemplate(BuildContext context) =>
    showModalBottomSheet<NewTemplateChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 1180),
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
  final _search = TextEditingController();
  var _nameTouched = false;
  var _collection = 'All';

  @override
  void dispose() {
    _name.dispose();
    _search.dispose();
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
    final query = _search.text.trim().toLowerCase();
    final designs = starterDesigns.where((d) {
      final category = d.blank ? 'Blank pages' : d.collection;
      return (_collection == 'All' || category == _collection) &&
          (query.isEmpty ||
              '${d.name} ${d.description} ${d.category ?? ''} '
                      '${d.tags.allTags.join(' ')}'
                  .toLowerCase()
                  .contains(query));
    }).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.94,
      maxChildSize: 0.98,
      minChildSize: 0.6,
      builder: (context, scroll) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            // Keep every control reachable with a keyboard or large text.
            final scrollEverything =
                constraints.maxHeight < 560 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.5;
            final columns =
                ((constraints.maxWidth - (wide ? 340 : 0) - 48) / 205)
                    .floor()
                    .clamp(1, 4);
            final selection = _SelectionPanel(
              design: _design,
              name: _name,
              showPreview: wide,
              onChanged: () => setState(() => _nameTouched = true),
              onContinue: () =>
                  Navigator.of(context)
                      .pop((design: _design, name: _name.text.trim())),
            );
            final catalog = CustomScrollView(
              controller: scroll,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  'Choose your style',
                                  style: theme.text.headlineLarge,
                                ),
                              ),
                            ),
                            PorcelainIconButton(
                              icon: PorcelainIcons.close,
                              semanticLabel: 'Close design collection',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A beautiful beginning. Make every detail yours.',
                          style: theme.text.bodyMedium.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        PorcelainTextField(
                          key: const ValueKey('design-search'),
                          label: 'Find your design',
                          hint: 'Try wedding, birthday, Easter, Christmas…',
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final category in {
                                'All',
                                for (final design in starterDesigns)
                                  if (!design.blank) design.collection,
                                'Blank pages',
                              })
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(category),
                                    selected: _collection == category,
                                    onSelected: (_) =>
                                        setState(() => _collection = category),
                                    showCheckmark: false,
                                    labelStyle: theme.text.labelMedium.copyWith(
                                      color: _collection == category
                                          ? colors.accentText
                                          : colors.inkMuted,
                                    ),
                                    selectedColor: colors.selected,
                                    backgroundColor: colors.surface,
                                    side: BorderSide(
                                      color: _collection == category
                                          ? colors.primaryEdge
                                          : colors.hairline,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${designs.length} designs · 300 dpi · Fully editable',
                          style: theme.text.bodySmall.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                        if (scrollEverything) ...[
                          const SizedBox(height: 16),
                          selection,
                        ],
                      ],
                    ),
                  ),
                ),
                if (designs.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(32),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Icon(
                            PorcelainIcons.search,
                            size: 32,
                            color: colors.inkMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No designs found',
                            style: theme.text.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try another color, occasion or collection.',
                            style: theme.text.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          PorcelainButton(
                            label: 'Clear filters',
                            variant: PorcelainButtonVariant.quiet,
                            onPressed: () => setState(() {
                              _search.clear();
                              _collection = 'All';
                            }),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    sliver: SliverGrid.builder(
                      itemCount: designs.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent:
                            290 + MediaQuery.textScalerOf(context).scale(50),
                      ),
                      itemBuilder: (context, index) => _StyleCard(
                        design: designs[index],
                        selected: designs[index].id == _design.id,
                        onPressed: () => _pick(designs[index]),
                      ),
                    ),
                  ),
              ],
            );
            if (scrollEverything) return catalog;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: catalog),
                  SizedBox(
                    width: 340,
                    child: SingleChildScrollView(child: selection),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Expanded(child: catalog),
                selection,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({
    required this.design,
    required this.name,
    required this.showPreview,
    required this.onChanged,
    required this.onContinue,
  });
  final StarterDesign design;
  final TextEditingController name;
  final bool showPreview;
  final VoidCallback onChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.raised,
        border: Border(
          top: BorderSide(color: colors.divider),
          left: BorderSide(color: colors.divider),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPreview) ...[
              Text('YOUR SELECTION', style: theme.text.eyebrow),
              const SizedBox(height: 20),
              SizedBox(
                height: 275,
                child: Center(
                  child: RenderedThumbnail(
                    thumbnail: starterThumbnailProvider(design.id),
                    aspectRatio: design.page.widthPx / design.page.heightPx,
                    semanticLabel: 'Selected design: ${design.name}',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(design.name, style: theme.text.headlineSmall),
              const SizedBox(height: 8),
              Text(
                design.description,
                style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Text(
                'Selected: ${design.name}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.text.labelLarge,
              ),
              const SizedBox(height: 12),
            ],
            PorcelainTextField(
              key: const ValueKey('new-template-name'),
              label: 'Template name',
              controller: name,
              maxLength: maxTemplateNameLength,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 16),
            PorcelainButton(
              label: 'Continue',
              icon: PorcelainIcons.chevron,
              variant: PorcelainButtonVariant.primary,
              expand: true,
              disabledReason: 'Give the template a name first.',
              onPressed: name.text.trim().isEmpty ? null : onContinue,
            ),
            if (showPreview) ...[
              const SizedBox(height: 12),
              Text(
                'Edit the artwork, captions and photo layout in the Studio.',
                textAlign: TextAlign.center,
                style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
    final page = design.page;
    final photos = design.photoSlots;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: '${design.name}, ${design.description} $photos photos',
      selected: selected,
      builder: (context, state) => AnimatedContainer(
        duration: PorcelainMotion.of(context).press,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? colors.selected : colors.raised,
          borderRadius: PorcelainRadius.cardAll,
          border: Border.all(
            color: state.focused
                ? colors.focusRing
                : selected
                ? colors.primaryEdge
                : colors.hairline,
            width: selected || state.focused ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadowAmbient,
              blurRadius: state.hovered ? 18 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.inset.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: RenderedThumbnail(
                          thumbnail: starterThumbnailProvider(design.id),
                          aspectRatio: page.widthPx / page.heightPx,
                          semanticLabel: design.name,
                        ),
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primaryTop,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.primaryEdge),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Icon(
                            PorcelainIcons.check,
                            size: 18,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              design.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.text.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              design.blank
                  ? 'Blank canvas'
                  : '${page.widthPx ~/ 300} × ${page.heightPx ~/ 300} in · $photos photos',
              style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
