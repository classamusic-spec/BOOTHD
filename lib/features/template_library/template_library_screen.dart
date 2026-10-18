import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/routing/route_paths.dart';
import '../../core/templates/template_thumbnails.dart';
import '../../domain/repositories/template_store.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_sheet.dart';
import '../../shared/widgets/porcelain_text_field.dart';
import '../../shared/widgets/rendered_thumbnail.dart';
import '../../shared/widgets/responsive_grid.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/studio_page.dart';
import '../../shared/widgets/tone.dart';
import 'library_actions.dart';

final _libraryProvider = StreamProvider.autoDispose<List<TemplateListing>>(
  (ref) => ref.watch(templateLibraryProvider).watch(),
);

/// Which templates the library shows.
enum LibraryFilter {
  all('All'),
  strips('Strips'),
  fourBySix('4 × 6'),
  square('Square'),
  archived('Archived');

  const LibraryFilter(this.label);

  final String label;

  bool accepts(TemplateListing template) {
    final latest = template.latest;
    if (this == LibraryFilter.archived) return template.archived;
    if (template.archived) return false;
    final w = latest.pageWidthPx;
    final h = latest.pageHeightPx;
    final ratio = w / h;
    return switch (this) {
      LibraryFilter.all || LibraryFilter.archived => true,
      LibraryFilter.strips => ratio < 0.5 || ratio > 2,
      LibraryFilter.fourBySix =>
        (ratio - 2 / 3).abs() < 0.02 || (ratio - 3 / 2).abs() < 0.02,
      LibraryFilter.square => (ratio - 1).abs() < 0.02,
    };
  }
}

/// A page size in words: "2 × 6 strip", "4 × 6 portrait", or pixels for
/// sizes the booth has no name for. Templates are drawn at 300 dpi.
String pageSizeName(int widthPx, int heightPx) {
  String inches(int px) {
    final value = px / 300;
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  final w = inches(widthPx);
  final h = inches(heightPx);
  if (widthPx % 150 != 0 || heightPx % 150 != 0) {
    return '$widthPx × $heightPx px';
  }
  final ratio = widthPx / heightPx;
  final kind = ratio < 0.5 || ratio > 2
      ? 'strip'
      : ratio == 1
      ? 'square'
      : ratio < 1
      ? 'portrait'
      : 'landscape';
  return '$w × $h in $kind';
}

/// Template library (S06): every template drawn as it prints, with its
/// page size, photo count and how many events offer it. New templates
/// start from a design or a blank page; packages import and export
/// through the platform's file picker and share sheet (S12).
class TemplateLibraryScreen extends ConsumerStatefulWidget {
  const TemplateLibraryScreen({super.key});

  @override
  ConsumerState<TemplateLibraryScreen> createState() =>
      _TemplateLibraryScreenState();
}

class _TemplateLibraryScreenState extends ConsumerState<TemplateLibraryScreen> {
  var _filter = LibraryFilter.all;
  final _search = TextEditingController();
  var _importing = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      await LibraryActions.import(context, ref);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(_libraryProvider);
    final query = _search.text.trim().toLowerCase();
    return StudioPage(
      header: StudioPageHeader(
        eyebrow: 'Studio',
        title: 'Templates',
        subtitle:
            'Layered designs with photo slots, transparent artwork and '
            'text, printed at 300 dpi.',
        actions: [
          PorcelainButton(
            label: 'Import',
            icon: PorcelainIcons.import,
            busy: _importing,
            busyLabel: 'Importing',
            onPressed: _import,
          ),
          PorcelainButton(
            label: 'New template',
            icon: PorcelainIcons.add,
            variant: PorcelainButtonVariant.primary,
            onPressed: () => LibraryActions.create(context, ref),
          ),
        ],
      ),
      children: [
        switch (library) {
          AsyncData(:final value) when value.isEmpty => EmptyState(
            icon: PorcelainIcons.templates,
            title: 'No templates yet',
            message:
                'Start from one of the designs, a blank page in any print '
                'size, or a template package from another booth.',
            actions: [
              PorcelainButton(
                label: 'New template',
                icon: PorcelainIcons.add,
                variant: PorcelainButtonVariant.primary,
                onPressed: () => LibraryActions.create(context, ref),
              ),
              PorcelainButton(
                label: 'Import a package',
                icon: PorcelainIcons.import,
                busy: _importing,
                onPressed: _import,
              ),
            ],
          ),
          AsyncData(:final value) => _Templates(
            templates: [
              for (final template in value)
                if (_filter.accepts(template) &&
                    (query.isEmpty ||
                        template.latest.templateName.toLowerCase().contains(
                          query,
                        ) ||
                        (template.category?.toLowerCase().contains(query) ??
                            false)))
                  template,
            ],
            filter: _filter,
            search: _search,
            onFilter: (filter) => setState(() => _filter = filter),
            onSearch: () => setState(() {}),
          ),
          AsyncError() => EmptyState(
            icon: PorcelainIcons.error,
            title: "The library couldn't be read",
            message: 'Its storage did not answer. Try again.',
            tone: PorcelainTone.danger,
            actions: [
              PorcelainButton(
                label: 'Try again',
                icon: PorcelainIcons.retry,
                onPressed: () => ref.invalidate(_libraryProvider),
              ),
            ],
          ),
          _ => const SkeletonList(semanticLabel: 'Loading templates'),
        },
      ],
    );
  }
}

class _Templates extends StatelessWidget {
  const _Templates({
    required this.templates,
    required this.filter,
    required this.search,
    required this.onFilter,
    required this.onSearch,
  });

  final List<TemplateListing> templates;
  final LibraryFilter filter;
  final TextEditingController search;
  final ValueChanged<LibraryFilter> onFilter;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: PorcelainSpace.lg,
          runSpacing: PorcelainSpace.md,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 320,
              child: PorcelainTextField(
                label: 'Search',
                controller: search,
                hint: 'Name or style',
                textInputAction: TextInputAction.search,
                onChanged: (_) => onSearch(),
              ),
            ),
            PorcelainSegmentedControl<LibraryFilter>(
              selected: filter,
              onChanged: onFilter,
              segments: [
                for (final f in LibraryFilter.values)
                  PorcelainSegment(value: f, label: f.label),
              ],
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        if (templates.isEmpty)
          Text(
            filter == LibraryFilter.archived
                ? 'No archived templates.'
                : 'No templates match. Clear the search or choose All.',
            style: theme.text.bodyLarge.copyWith(color: theme.colors.inkMuted),
          )
        else
          ResponsiveGrid(
            minTileWidth: 250,
            children: [
              for (final template in templates)
                TemplateCard(
                  key: ValueKey(template.templateId),
                  template: template,
                ),
            ],
          ),
      ],
    );
  }
}

/// One template in the library: its print, name, size and use.
class TemplateCard extends ConsumerWidget {
  const TemplateCard({super.key, required this.template});

  final TemplateListing template;

  Rect _anchor(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Rect.zero;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _more(BuildContext context, WidgetRef ref) async {
    final archived = template.archived;
    final anchor = _anchor(context);
    final action = await showPorcelainSheet<String>(
      context: context,
      title: template.latest.templateName,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (id, icon, label, subtitle) in [
            (
              'duplicate',
              PorcelainIcons.duplicate,
              'Duplicate',
              'A new template with the same design',
            ),
            ('rename', PorcelainIcons.rename, 'Rename', null),
            (
              'export',
              PorcelainIcons.share,
              'Export package',
              'Send it to another booth as one file',
            ),
            if (archived)
              (
                'restore',
                PorcelainIcons.restore,
                'Restore',
                'Back to the library and events',
              )
            else
              (
                'archive',
                PorcelainIcons.archive,
                'Archive',
                'Events that offer it keep it',
              ),
          ])
            Builder(
              builder: (sheet) => Padding(
                padding: const EdgeInsets.only(bottom: PorcelainSpace.xxs),
                child: PorcelainListRow(
                  icon: icon,
                  title: label,
                  subtitle: subtitle,
                  onPressed: () => Navigator.of(sheet).pop(id),
                ),
              ),
            ),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'duplicate':
        await LibraryActions.duplicate(context, ref, template);
      case 'rename':
        await LibraryActions.rename(context, ref, template);
      case 'export':
        await LibraryActions.export(context, ref, template, anchor: anchor);
      case 'archive':
        await LibraryActions.setArchived(
          context,
          ref,
          template,
          archived: true,
        );
      case 'restore':
        await LibraryActions.setArchived(
          context,
          ref,
          template,
          archived: false,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final latest = template.latest;
    final archived = template.archived;
    final photos = latest.photoSlotCount;
    final events = template.eventCount;
    void open() => unawaited(
      archived
          ? context.push(RoutePaths.templatePreview(latest.templateId))
          : context.push(RoutePaths.templateEditor(latest.templateId)),
    );
    return PorcelainCard(
      padding: const EdgeInsets.all(PorcelainSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: open,
                  child: Container(
                    height: 230,
                    padding: const EdgeInsets.all(PorcelainSpace.md),
                    decoration: BoxDecoration(
                      color: colors.inset,
                      borderRadius: PorcelainRadius.controlAll,
                    ),
                    child: Center(
                      child: RenderedThumbnail(
                        thumbnail: templateThumbnailProvider(latest.revisionId),
                        aspectRatio: latest.pageWidthPx / latest.pageHeightPx,
                        semanticLabel: 'Preview of ${latest.templateName}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: PorcelainSpace.md),
                Text(
                  latest.templateName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.titleLarge,
                ),
                const SizedBox(height: PorcelainSpace.xxs),
                Text(
                  '${pageSizeName(latest.pageWidthPx, latest.pageHeightPx)} · '
                  '${photos == 0 ? 'no photos' : '$photos ${photos == 1 ? 'photo' : 'photos'}'}'
                  '${template.category == null ? '' : ' · ${template.category}'}',
                  style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: PorcelainSpace.sm),
                Wrap(
                  spacing: PorcelainSpace.xs,
                  runSpacing: PorcelainSpace.xs,
                  children: [
                    StatusBadge(
                      label: events == 0
                          ? 'Not in an event'
                          : 'In ${events == 1 ? '1 event' : '$events events'}',
                      tone: events == 0
                          ? PorcelainTone.info
                          : PorcelainTone.success,
                      icon: PorcelainIcons.events,
                    ),
                    if (template.hasDraft)
                      const StatusBadge(
                        label: 'Unsaved changes',
                        tone: PorcelainTone.warning,
                        icon: PorcelainIcons.draft,
                      ),
                    if (archived)
                      const StatusBadge(
                        label: 'Archived',
                        tone: PorcelainTone.info,
                        icon: PorcelainIcons.archive,
                      ),
                    StatusBadge(
                      label: 'Revision ${latest.revisionNumber}',
                      tone: PorcelainTone.info,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: PorcelainSpace.lg),
          Wrap(
            spacing: PorcelainSpace.xs,
            runSpacing: PorcelainSpace.xs,
            children: [
              if (!archived)
                PorcelainButton(
                  label: 'Edit',
                  icon: PorcelainIcons.edit,
                  size: PorcelainButtonSize.compact,
                  semanticHint: latest.templateName,
                  onPressed: open,
                ),
              PorcelainButton(
                label: 'Preview',
                icon: PorcelainIcons.preview,
                size: PorcelainButtonSize.compact,
                variant: archived
                    ? PorcelainButtonVariant.secondary
                    : PorcelainButtonVariant.quiet,
                semanticHint: latest.templateName,
                onPressed: () => unawaited(
                  context.push(RoutePaths.templatePreview(latest.templateId)),
                ),
              ),
              PorcelainButton(
                label: 'More',
                icon: PorcelainIcons.more,
                size: PorcelainButtonSize.compact,
                variant: PorcelainButtonVariant.quiet,
                semanticHint: latest.templateName,
                onPressed: () => _more(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
