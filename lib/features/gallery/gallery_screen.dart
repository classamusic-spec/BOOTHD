import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/gallery/gallery_providers.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/gallery/gallery_models.dart';
import '../../domain/gallery/gallery_search.dart';
import '../../domain/models/booth_event.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/gallery/gallery_actions.dart';
import '../../shared/gallery/gallery_copy.dart';
import '../../shared/gallery/gallery_thumbnail.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_text_field.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/studio_page.dart';
import '../../shared/widgets/tone.dart';
import 'export_sheet.dart';
import 'session_tile.dart';

/// The operator gallery (S13, P-11): an event at a time, its sessions as a
/// grid of finished photos that loads only what is on screen, filters and
/// search, multi-select export and delete, storage and retention. Studio
/// only: Booth Mode never reaches it (UX-04).
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key, this.eventId});

  /// The event to open on (from a link); otherwise the latest one.
  final String? eventId;

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  String? _eventId;
  var _filter = GalleryFilter.all;
  final _search = TextEditingController();
  var _selecting = false;
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _eventId = widget.eventId;
    _search.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(GalleryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eventId != null && widget.eventId != oldWidget.eventId) {
      _chooseEvent(widget.eventId!);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _chooseEvent(String id) => setState(() {
    _eventId = id;
    _filter = GalleryFilter.all;
    _search.clear();
    _selecting = false;
    _selected.clear();
  });

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(galleryEventsProvider);
    final all = events.value ?? const <GalleryEventSummary>[];
    final event =
        all.where((e) => e.eventId == _eventId).firstOrNull ?? all.firstOrNull;
    final sessions = event == null
        ? null
        : ref.watch(gallerySessionsProvider(event.eventId));
    final list = sessions?.value ?? const <GallerySession>[];
    final search = GallerySearch.parse(_search.text);
    final shown = [
      for (final session in list)
        if (_filter.shows(session) && (search?.matches(session) ?? false))
          session,
    ];

    final page = StudioSliverPage(
      spacing: PorcelainSpace.xl,
      header: StudioPageHeader(
        eyebrow: 'Studio',
        title: GalleryCopy.title,
        subtitle: GalleryCopy.subtitle,
        actions: [
          if (list.isNotEmpty)
            SizedBox(
              width: 260,
              child: PorcelainTextField(
                label: GalleryCopy.searchLabel,
                controller: _search,
                hint: GalleryCopy.searchHint,
                error: search == null ? GalleryCopy.searchNotUnderstood : null,
                textInputAction: TextInputAction.search,
              ),
            ),
          if (_selecting)
            PorcelainButton(
              label: GalleryCopy.cancelSelect,
              onPressed: _endSelecting,
            )
          else
            PorcelainButton(
              label: GalleryCopy.select,
              icon: PorcelainIcons.check,
              onPressed: shown.isEmpty
                  ? null
                  : () => setState(() => _selecting = true),
              disabledReason: shown.isEmpty
                  ? 'There are no sessions to select.'
                  : null,
            ),
        ],
      ),
      slivers: [
        switch (events) {
          AsyncError() => SliverToBoxAdapter(
            child: _LoadProblem(
              onRetry: () => ref.invalidate(galleryEventsProvider),
            ),
          ),
          AsyncData() when all.isEmpty => SliverToBoxAdapter(
            child: EmptyState(
              icon: PorcelainIcons.gallery,
              title: GalleryCopy.noEvents,
              message: GalleryCopy.noEventsMessage,
              footnote: 'Guests never see this gallery.',
              actions: [
                PorcelainButton(
                  label: 'Go to Events',
                  icon: PorcelainIcons.events,
                  onPressed: () => context.go(RoutePaths.events),
                ),
              ],
            ),
          ),
          AsyncData() => SliverToBoxAdapter(
            child: _EventSelector(
              events: all,
              selected: event!.eventId,
              onSelected: _chooseEvent,
            ),
          ),
          _ => const SliverToBoxAdapter(
            child: SkeletonList(semanticLabel: 'Loading the gallery'),
          ),
        },
        if (event != null) ...[
          SliverToBoxAdapter(child: _EventSummary(event: event)),
          if (list.isNotEmpty)
            SliverToBoxAdapter(
              child: _Controls(
                sessions: list,
                filter: _filter,
                onFilter: (filter) => setState(() {
                  _filter = filter;
                  _selected.clear();
                }),
              ),
            ),
          switch (sessions) {
            AsyncError() => SliverToBoxAdapter(
              child: _LoadProblem(
                onRetry: () =>
                    ref.invalidate(gallerySessionsProvider(event.eventId)),
              ),
            ),
            AsyncData() when list.isEmpty => const SliverToBoxAdapter(
              child: EmptyState(
                icon: PorcelainIcons.camera,
                title: GalleryCopy.noSessions,
                message: GalleryCopy.noSessionsMessage,
              ),
            ),
            AsyncData() when shown.isEmpty => SliverToBoxAdapter(
              child: EmptyState(
                icon: PorcelainIcons.search,
                title: GalleryCopy.noMatch,
                message: search == null
                    ? GalleryCopy.searchNotUnderstood
                    : 'Nothing in this list matches. Try another filter or '
                          'search.',
                actions: [
                  PorcelainButton(
                    label: 'Show all',
                    icon: PorcelainIcons.close,
                    onPressed: () => setState(() {
                      _filter = GalleryFilter.all;
                      _search.clear();
                    }),
                  ),
                ],
              ),
            ),
            AsyncData() => SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: GalleryMetrics.tileExtent,
                mainAxisSpacing: GalleryMetrics.tileSpacing,
                crossAxisSpacing: GalleryMetrics.tileSpacing,
                childAspectRatio: GalleryMetrics.tileAspect,
              ),
              itemCount: shown.length,
              itemBuilder: (context, index) {
                final session = shown[index];
                return SessionTile(
                  key: ValueKey(session.id),
                  session: session,
                  selecting: _selecting,
                  selected: _selecting && _selected.contains(session.id),
                  onPressed: _selecting
                      ? () => _toggle(session.id)
                      : () =>
                            context.push(RoutePaths.gallerySession(session.id)),
                  onLongPress: _selecting
                      ? null
                      : () => setState(() {
                          _selecting = true;
                          _selected.add(session.id);
                        }),
                );
              },
            ),
            _ => const SliverToBoxAdapter(
              child: SkeletonList(semanticLabel: 'Loading sessions', rows: 4),
            ),
          },
        ],
      ],
    );
    if (!_selecting) return page;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: page),
        _SelectionBar(
          actions: _selectionActions(shown),
          count: _chosen(shown).length,
        ),
      ],
    );
  }

  void _endSelecting() => setState(() {
    _selecting = false;
    _selected.clear();
  });

  List<String> _chosen(List<GallerySession> shown) => [
    for (final session in shown)
      if (_selected.contains(session.id)) session.id,
  ];

  List<Widget> _selectionActions(List<GallerySession> shown) {
    final selectable = [
      for (final session in shown)
        if (!session.inProgress) session.id,
    ];
    final chosen = _chosen(shown);
    return [
      PorcelainButton(
        label: GalleryCopy.cancelSelect,
        variant: PorcelainButtonVariant.quiet,
        onPressed: _endSelecting,
      ),
      PorcelainButton(
        label: chosen.length == selectable.length && selectable.isNotEmpty
            ? GalleryCopy.clearSelection
            : GalleryCopy.selectAll(selectable.length),
        variant: PorcelainButtonVariant.quiet,
        onPressed: () => setState(() {
          if (chosen.length == selectable.length) {
            _selected.clear();
          } else {
            _selected
              ..clear()
              ..addAll(selectable);
          }
        }),
      ),
      PorcelainButton(
        label: GalleryCopy.export,
        icon: PorcelainIcons.export,
        variant: PorcelainButtonVariant.primary,
        onPressed: chosen.isEmpty
            ? null
            : () => unawaited(
                showGalleryExportSheet(context, sessionIds: chosen),
              ),
        disabledReason: chosen.isEmpty ? GalleryCopy.selectFirst : null,
      ),
      PorcelainButton(
        label: GalleryCopy.deleteConfirm,
        icon: PorcelainIcons.delete,
        variant: PorcelainButtonVariant.danger,
        onPressed: chosen.isEmpty
            ? null
            : () async {
                final deleted = await GalleryActions.deleteSessions(
                  context,
                  ref,
                  chosen,
                );
                if (deleted && mounted) _endSelecting();
              },
        disabledReason: chosen.isEmpty ? GalleryCopy.selectFirst : null,
      ),
    ];
  }
}

/// Select mode's actions, pinned below the grid so they stay in reach
/// however far the operator scrolls.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.actions, required this.count});

  final List<Widget> actions;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.rail,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: SafeArea(
        top: false,
        left: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PorcelainSpace.xl,
            vertical: PorcelainSpace.md,
          ),
          child: Wrap(
            spacing: PorcelainSpace.sm,
            runSpacing: PorcelainSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.end,
            children: [
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: PorcelainSpace.md,
                  ),
                  child: Text(
                    GalleryCopy.selected(count),
                    style: theme.text.titleSmall,
                  ),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadProblem extends StatelessWidget {
  const _LoadProblem({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: PorcelainIcons.error,
    title: GalleryCopy.loadFailed,
    message: GalleryCopy.loadFailedMessage,
    tone: PorcelainTone.danger,
    actions: [
      PorcelainButton(
        label: 'Try again',
        icon: PorcelainIcons.retry,
        onPressed: onRetry,
      ),
    ],
  );
}

/// The events with sessions (and the rest), as a row of cards with their
/// counts and dates.
class _EventSelector extends StatelessWidget {
  const _EventSelector({
    required this.events,
    required this.selected,
    required this.onSelected,
  });

  final List<GalleryEventSummary> events;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    // Three lines of text and padding, growing with the text size.
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return SizedBox(
      height: 40 + 72 * textScale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: PorcelainSpace.md),
        itemBuilder: (context, index) {
          final event = events[index];
          final last = event.lastSessionAtUtc;
          return SizedBox(
            width: 264,
            child: PorcelainCard(
              padding: const EdgeInsets.fromLTRB(
                PorcelainSpace.lg,
                PorcelainSpace.md,
                PorcelainSpace.xxl,
                PorcelainSpace.md,
              ),
              selected: event.eventId == selected,
              semanticLabel:
                  '${event.title}, ${GalleryCopy.sessions(event.sessionCount)}',
              onPressed: () => onSelected(event.eventId),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.title,
                    style: theme.text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: PorcelainSpace.xxs),
                  Text(
                    event.sessionCount == 0
                        ? GalleryCopy.sessions(0)
                        : '${GalleryCopy.sessions(event.sessionCount)} · '
                              '${event.finishedCount} finished',
                    style: theme.text.labelLarge.copyWith(
                      color: colors.accentText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    last == null
                        ? event.status == EventStatus.archived
                              ? 'Archived'
                              : 'No sessions yet'
                        : 'Latest ${formatDay(last.toLocal())}',
                    style: theme.text.bodySmall.copyWith(
                      color: colors.inkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The chosen event: its dates, counts and space, and its retention rule
/// with the sessions past it (offered for deletion, never deleted
/// silently).
class _EventSummary extends ConsumerWidget {
  const _EventSummary({required this.event});

  final GalleryEventSummary event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final usage = ref.watch(storageUsageProvider(event.eventId)).value;
    final first = event.firstSessionAtUtc;
    final last = event.lastSessionAtUtc;
    final days = event.retention.days;
    final due = days == null
        ? const <String>[]
        : ref
                  .watch(
                    pastRetentionProvider((
                      eventId: event.eventId,
                      retention: event.retention,
                    )),
                  )
                  .value ??
              const <String>[];
    return PorcelainCard(
      padding: const EdgeInsets.symmetric(
        horizontal: PorcelainSpace.xl,
        vertical: PorcelainSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: PorcelainSpace.xxl,
            runSpacing: PorcelainSpace.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Fact(
                label: 'When',
                value: first == null || last == null
                    ? '—'
                    : formatSpan(first.toLocal(), last.toLocal()),
              ),
              _Fact(
                label: 'On this tablet',
                value: usage == null
                    ? '…'
                    : '${GalleryCopy.bytes(usage.totalBytes)} · '
                          '${usage.originalCount} camera photos',
              ),
              StatusBadge(
                label: GalleryCopy.keeps(days),
                icon: PorcelainIcons.privacy,
                tone: PorcelainTone.neutral,
              ),
            ],
          ),
          if (days != null && due.isNotEmpty) ...[
            const SizedBox(height: PorcelainSpace.lg),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.warningSurface,
                borderRadius: PorcelainRadius.controlAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(PorcelainSpace.md),
                child: Wrap(
                  spacing: PorcelainSpace.md,
                  runSpacing: PorcelainSpace.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      PorcelainIcons.warning,
                      color: PorcelainTone.warning.foreground(colors),
                    ),
                    Text(
                      GalleryCopy.pastRetention(due.length, days),
                      style: theme.text.bodyMedium,
                    ),
                    PorcelainButton(
                      label: GalleryCopy.reviewRetention,
                      icon: PorcelainIcons.delete,
                      variant: PorcelainButtonVariant.danger,
                      size: PorcelainButtonSize.compact,
                      onPressed: () => GalleryActions.deleteSessions(
                        context,
                        ref,
                        due,
                        title: GalleryCopy.retentionTitle(due.length),
                        body: GalleryCopy.retentionBody(due.length, days),
                        acknowledge: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: theme.text.eyebrow),
          const SizedBox(height: PorcelainSpace.xxs),
          Text(value, style: theme.text.titleMedium),
        ],
      ),
    );
  }
}

/// The status filter, with counts.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.sessions,
    required this.filter,
    required this.onFilter,
  });

  final List<GallerySession> sessions;
  final GalleryFilter filter;
  final ValueChanged<GalleryFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    int count(GalleryFilter f) => sessions.where(f.shows).length;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: PorcelainSegmentedControl<GalleryFilter>(
        selected: filter,
        onChanged: onFilter,
        segments: [
          for (final f in GalleryFilter.values)
            PorcelainSegment(
              value: f,
              label: '${GalleryCopy.filter(f)} · ${count(f)}',
            ),
        ],
      ),
    );
  }
}
