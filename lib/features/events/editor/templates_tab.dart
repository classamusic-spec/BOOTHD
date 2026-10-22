import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/booth/booth_providers.dart';
import '../../../core/design_system/porcelain_icons.dart';
import '../../../core/design_system/porcelain_metrics.dart';
import '../../../core/design_system/porcelain_theme.dart';
import '../../../core/templates/template_thumbnails.dart';
import '../../../domain/experience/experience_registry.dart';
import '../../../domain/experience/template_recommendations.dart';
import '../../../domain/models/event_rules.dart';
import '../../../domain/models/template_revision_summary.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/porcelain_button.dart';
import '../../../shared/widgets/porcelain_switch.dart';
import '../../../shared/widgets/rendered_thumbnail.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tone.dart';
import '../event_copy.dart';
import 'editor_parts.dart';

/// The templates guests may use, their order and the default (S04
/// Templates). Events reference immutable template revisions.
class TemplatesTab extends ConsumerWidget {
  const TemplatesTab({super.key, required this.tab});

  final EditorTabContext tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final event = tab.event;
    final selection = event.templates;
    final reason = tab.readOnlyReason;
    final selectable = ref.watch(selectableTemplatesProvider);
    final count = selection.revisionIds.length;
    final full = count >= EventLimits.maxTemplates;
    final pack =
        ExperienceRegistry.bundled.pack(event.experience.packId) ??
        ExperienceRegistry.bundled.fallback;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorCard(
          title: 'Templates for this event',
          subtitle:
              'Guests get the default unless they may choose. Each template '
              'needs one photo slot per photo in a session.',
          children: [
            if (count == 0)
              Text(
                'No templates chosen yet. Add one from the library below.',
                style: theme.text.bodyLarge.copyWith(
                  color: theme.colors.inkMuted,
                ),
              )
            else
              for (final (index, id) in selection.revisionIds.indexed)
                _ChosenTemplate(
                  template: tab.library[id],
                  isDefault: id == selection.defaultRevisionId,
                  shotCount: event.capture.shotCount,
                  canMoveUp: index > 0,
                  canMoveDown: index < count - 1,
                  readOnlyReason: reason,
                  onMakeDefault: tab.edit<void>(
                    (_) => event.copyWith(templates: selection.withDefault(id)),
                  ),
                  onMoveUp: tab.edit<void>(
                    (_) => event.copyWith(
                      templates: selection.move(index, index - 1),
                    ),
                  ),
                  onMoveDown: tab.edit<void>(
                    (_) => event.copyWith(
                      templates: selection.move(index, index + 1),
                    ),
                  ),
                  onRemove: tab.edit<void>(
                    (_) => event.copyWith(templates: selection.remove(id)),
                  ),
                ),
            PorcelainSwitchRow(
              title: 'Guests choose a template',
              subtitle: 'Shows the allowed templates before the photos.',
              value: event.guest.guestChoosesTemplate && count > 1,
              onChanged: count > 1
                  ? tab.edit(
                      (value) => event.copyWith(
                        guest: event.guest.copyWith(
                          guestChoosesTemplate: value,
                        ),
                      ),
                    )
                  : null,
              disabledReason:
                  reason ?? 'Add a second template to let guests choose.',
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        EditorCard(
          title: 'Add from the library',
          subtitle:
              'The latest version of each template. Designs that suit '
              '${pack.displayName} come first; any template can be used.',
          children: [
            switch (selectable) {
              AsyncData(:final value) when value.isEmpty => const EmptyState(
                icon: PorcelainIcons.templates,
                title: 'The template library is empty',
                message:
                    'Design one in Templates, or import a template package '
                    'there. Until then this event can be saved as a draft.',
              ),
              AsyncData(:final value) => Column(
                children: [
                  for (final template in TemplateRecommendations.order(
                    value,
                    pack,
                    event.experience,
                  ))
                    if (!selection.revisionIds.contains(template.revisionId))
                      _LibraryTemplate(
                        template: template,
                        suits:
                            TemplateRecommendations.score(
                                  template,
                                  pack,
                                  event.experience,
                                ) >
                                0
                            ? pack.displayName
                            : null,
                        shotCount: event.capture.shotCount,
                        onAdd: full || tab.readOnly
                            ? null
                            : () => tab.onChanged(
                                event.copyWith(
                                  templates: selection.add(template.revisionId),
                                ),
                              ),
                        disabledReason:
                            reason ??
                            'An event can offer at most '
                                '${EventLimits.maxTemplates} templates.',
                      ),
                ],
              ),
              AsyncError() => const EmptyState(
                icon: PorcelainIcons.error,
                title: "The library couldn't be read",
                message: 'Close the event and open it again.',
                tone: PorcelainTone.danger,
              ),
              _ => const SkeletonList(semanticLabel: 'Loading templates'),
            },
          ],
        ),
      ],
    );
  }
}

class _ChosenTemplate extends StatelessWidget {
  const _ChosenTemplate({
    required this.template,
    required this.isDefault,
    required this.shotCount,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.readOnlyReason,
    required this.onMakeDefault,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  /// Null when the revision is no longer in the library.
  final TemplateRevisionSummary? template;
  final bool isDefault;
  final int shotCount;
  final bool canMoveUp;
  final bool canMoveDown;
  final String? readOnlyReason;
  final ValueChanged<void>? onMakeDefault;
  final ValueChanged<void>? onMoveUp;
  final ValueChanged<void>? onMoveDown;
  final ValueChanged<void>? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final template = this.template;
    final name = template?.templateName ?? 'Missing template';
    final mismatch = template != null && template.photoSlotCount != shotCount;
    VoidCallback? call(ValueChanged<void>? action) =>
        action == null ? null : () => action(null);

    return Padding(
      padding: const EdgeInsets.only(bottom: PorcelainSpace.sm),
      child: Row(
        children: [
          SizedBox(
            width: _PageShape.width,
            child: template == null
                ? Icon(PorcelainIcons.warning, color: colors.danger)
                : _PageShape(template: template),
          ),
          const SizedBox(width: PorcelainSpace.md),
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: PorcelainSpace.xs,
                    runSpacing: PorcelainSpace.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(name, style: theme.text.titleSmall),
                      if (isDefault)
                        const StatusBadge(
                          label: 'Default',
                          tone: PorcelainTone.success,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template == null
                        ? 'No longer in the library. Remove it and choose '
                              'another.'
                        : '${pageSizeLabel(template)} · '
                              '${EventCopy.photoSlots(template.photoSlotCount)}',
                    style: theme.text.bodyMedium.copyWith(
                      color: template == null ? colors.danger : colors.inkMuted,
                    ),
                  ),
                  if (mismatch)
                    Text(
                      'Needs ${EventCopy.photos(template.photoSlotCount)} per '
                      'session; this event takes $shotCount.',
                      style: theme.text.bodyMedium.copyWith(
                        color: colors.warning,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: PorcelainSpace.sm),
          Wrap(
            spacing: PorcelainSpace.xxs,
            children: [
              if (!isDefault)
                PorcelainButton(
                  label: 'Make default',
                  variant: PorcelainButtonVariant.quiet,
                  size: PorcelainButtonSize.compact,
                  onPressed: call(onMakeDefault),
                  disabledReason: readOnlyReason,
                ),
              PorcelainIconButton(
                icon: PorcelainIcons.moveUp,
                semanticLabel: 'Move $name up',
                onPressed: canMoveUp ? call(onMoveUp) : null,
                disabledReason: readOnlyReason ?? 'Already first.',
              ),
              PorcelainIconButton(
                icon: PorcelainIcons.moveDown,
                semanticLabel: 'Move $name down',
                onPressed: canMoveDown ? call(onMoveDown) : null,
                disabledReason: readOnlyReason ?? 'Already last.',
              ),
              PorcelainIconButton(
                icon: PorcelainIcons.close,
                semanticLabel: 'Remove $name',
                onPressed: call(onRemove),
                disabledReason: readOnlyReason,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LibraryTemplate extends StatelessWidget {
  const _LibraryTemplate({
    required this.template,
    required this.suits,
    required this.shotCount,
    required this.onAdd,
    required this.disabledReason,
  });

  final TemplateRevisionSummary template;

  /// The experience this design suits, when it is recommended.
  final String? suits;
  final int shotCount;
  final VoidCallback? onAdd;
  final String disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final fits = template.photoSlotCount == shotCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: PorcelainSpace.sm),
      child: Row(
        children: [
          SizedBox(
            width: _PageShape.width,
            child: _PageShape(template: template),
          ),
          const SizedBox(width: PorcelainSpace.md),
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.templateName, style: theme.text.titleSmall),
                  if (suits case final pack?) ...[
                    const SizedBox(height: PorcelainSpace.xxs),
                    StatusBadge(
                      label: 'Suits $pack',
                      icon: PorcelainIcons.suggested,
                      tone: PorcelainTone.info,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '${pageSizeLabel(template)} · '
                    '${EventCopy.photoSlots(template.photoSlotCount)}'
                    '${fits ? '' : ' (this event takes $shotCount)'}',
                    style: theme.text.bodyMedium.copyWith(
                      color: fits ? colors.inkMuted : colors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: PorcelainSpace.sm),
          PorcelainButton(
            label: 'Add',
            icon: PorcelainIcons.add,
            size: PorcelainButtonSize.compact,
            onPressed: onAdd,
            disabledReason: disabledReason,
          ),
        ],
      ),
    );
  }
}

/// The template drawn as it prints, above its photo-slot count.
class _PageShape extends StatelessWidget {
  const _PageShape({required this.template});

  /// The space a page of any shape is fitted into.
  static const width = 56.0;
  static const pageHeight = 52.0;

  final TemplateRevisionSummary template;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final aspect = template.pageWidthPx / template.pageHeightPx;
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: pageHeight,
            child: Center(
              child: SizedBox(
                // Landscape pages fit the width instead.
                height: math.min(pageHeight, width / aspect),
                child: RenderedThumbnail(
                  thumbnail: templateThumbnailProvider(template.revisionId),
                  aspectRatio: aspect,
                  semanticLabel: template.templateName,
                ),
              ),
            ),
          ),
          const SizedBox(height: PorcelainSpace.xxs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PorcelainIcons.camera,
                size: 14,
                color: theme.colors.accentIcon,
              ),
              const SizedBox(width: 2),
              Text(
                '${template.photoSlotCount}',
                style: theme.text.labelMedium.copyWith(
                  color: theme.colors.inkMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
