import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/templates/template_thumbnails.dart';
import '../../domain/experience/experience_pack.dart';
import '../../shared/guest/guest_button.dart';
import '../../shared/guest/guest_layout.dart';
import '../../shared/guest/guest_words.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/tactile_surface.dart';
import 'booth_copy.dart';
import 'guest_parts.dart';

/// S21 Template choice (CR-002): the event's templates as cards drawn by
/// the print renderer, one selected (gold edge and a check), and a large
/// Continue. Nothing here edits anything.
class GuestTemplateChoice extends StatefulWidget {
  const GuestTemplateChoice({
    super.key,
    required this.templates,
    required this.initial,
    required this.onChosen,
  });

  /// Revision IDs, in the event's order.
  final List<String> templates;

  /// Selected at first: the event's default.
  final String? initial;
  final ValueChanged<String> onChosen;

  @override
  State<GuestTemplateChoice> createState() => _GuestTemplateChoiceState();
}

class _GuestTemplateChoiceState extends State<GuestTemplateChoice> {
  late String _selected = widget.templates.contains(widget.initial)
      ? widget.initial!
      : widget.templates.first;

  @override
  Widget build(BuildContext context) {
    return GuestBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = GuestScale.forSize(constraints.biggest);
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final count = widget.templates.length;
            final columns = landscape
                ? math.min(count, 4)
                : (count <= 2 ? 2 : 3);
            final side = scale(
              landscape
                  ? PorcelainSpace.giant + PorcelainSpace.xl
                  : PorcelainSpace.giant,
            );
            return Padding(
              padding: EdgeInsets.fromLTRB(
                side,
                scale(PorcelainSpace.xxl),
                side,
                scale(PorcelainSpace.xl),
              ),
              child: Column(
                children: [
                  GuestHeading(
                    title: context.guestCopy[GuestCopyKey.chooseTitle],
                    subtitle: BoothCopy.chooseSubtitle,
                    caps: true,
                    scale: scale,
                  ),
                  SizedBox(height: scale(PorcelainSpace.xl)),
                  Expanded(
                    child: _Cards(
                      templates: widget.templates,
                      columns: columns,
                      selected: _selected,
                      scale: scale,
                      onSelect: (id) => setState(() => _selected = id),
                    ),
                  ),
                  SizedBox(height: scale(PorcelainSpace.xl)),
                  SizedBox(
                    width: math.min(
                      constraints.maxWidth - 2 * side,
                      scale(520),
                    ),
                    child: GuestButton(
                      label: BoothCopy.continueLabel,
                      size: GuestButtonSize.large,
                      caps: true,
                      expand: true,
                      onPressed: () => widget.onChosen(_selected),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The cards in rows of [columns], as large as the space allows (at most
/// 300 dp wide at full scale), scrolling only if they cannot fit.
class _Cards extends StatelessWidget {
  const _Cards({
    required this.templates,
    required this.columns,
    required this.selected,
    required this.scale,
    required this.onSelect,
  });

  final List<String> templates;
  final int columns;
  final String selected;
  final GuestScale scale;
  final ValueChanged<String> onSelect;

  /// Picture area: three wide, four tall.
  static const _pictureAspect = 3 / 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, area) {
        final gap = scale(PorcelainSpace.lg);
        final rows = (templates.length / columns).ceil();
        final label = scale(64);
        var width = math.min(
          (area.maxWidth - gap * (columns - 1)) / columns,
          scale(300),
        );
        // Shrink to fit the height rather than scroll, down to a floor.
        final fitHeight = (area.maxHeight - gap * (rows - 1)) / rows;
        final fitWidth = (fitHeight - label) * _pictureAspect;
        width = math.max(math.min(width, fitWidth), scale(150));
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: area.maxHeight),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final id in templates)
                    SizedBox(
                      width: width,
                      child: _TemplateCard(
                        revisionId: id,
                        selected: id == selected,
                        scale: scale,
                        labelHeight: label,
                        onSelect: () => onSelect(id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({
    required this.revisionId,
    required this.selected,
    required this.scale,
    required this.labelHeight,
    required this.onSelect,
  });

  final String revisionId;
  final bool selected;
  final GuestScale scale;
  final double labelHeight;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    final name = ref.watch(templateSummaryProvider(revisionId)).value;
    final picture = ref.watch(templateThumbnailProvider(revisionId)).value;
    final title = name?.templateName ?? '';
    final radius = scale(20);
    return Pressable(
      onPressed: onSelect,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      semanticLabel: title,
      builder: (context, state) => Stack(
        clipBehavior: Clip.none,
        children: [
          TactileSurface(
            look: TactileLook(
              fillTop: selected ? colors.surface : colors.raised,
              fillBottom: colors.raisedShade,
              border: selected || state.focused
                  ? colors.primaryEdge
                  : colors.hairline,
              borderWidth: selected ? 2.5 : 1,
              elevation: selected || state.hovered
                  ? PorcelainDepth.lifted
                  : PorcelainDepth.raised,
              inset: state.pressed ? 0.4 : 0,
              highlight: 1,
              travel: state.pressed ? 1 : 0,
            ),
            radius: radius,
            focused: state.focused,
            duration: state.pressed ? motion.press : motion.standard,
            child: Padding(
              padding: EdgeInsets.all(scale(PorcelainSpace.sm)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: _Cards._pictureAspect,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.inset,
                        borderRadius: BorderRadius.circular(
                          radius - scale(PorcelainSpace.sm),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(scale(PorcelainSpace.md)),
                        // Blank paper while it draws; never an error mark
                        // on a guest screen.
                        child: picture == null
                            ? const SizedBox.expand()
                            : Image.memory(
                                picture,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                                gaplessPlayback: true,
                                excludeFromSemantics: true,
                              ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: labelHeight - scale(PorcelainSpace.sm),
                    child: Center(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: scale.text(
                          theme.text.guestLabel.copyWith(
                            fontSize: 19,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: colors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: -scale(10),
              right: -scale(10),
              child: ExcludeSemantics(
                child: Container(
                  width: scale(40),
                  height: scale(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colors.primaryTop, colors.primaryBottom],
                    ),
                    border: Border.all(color: colors.primaryEdge, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadowKey,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    PorcelainIcons.check,
                    size: scale(24),
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
