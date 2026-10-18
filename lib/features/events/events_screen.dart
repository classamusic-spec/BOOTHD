import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/models/booth_event.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_text_field.dart';
import '../../shared/widgets/responsive_grid.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/studio_page.dart';
import '../../shared/widgets/tone.dart';
import 'event_actions.dart';
import 'event_copy.dart';

/// Event lifecycle filters (S03, CR-001 fix 2).
enum EventFilter {
  active(EventStatus.active),
  draft(EventStatus.draft),
  archived(EventStatus.archived);

  const EventFilter(this.status);

  final EventStatus status;
}

/// Events list (S03): Active, Drafts and Archived with counts, a search,
/// and a card per event with what can be done to it.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  var _filter = EventFilter.active;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(BoothEvent event) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return event.title.toLowerCase().contains(query) ||
        (event.venue?.toLowerCase().contains(query) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final all = events.value ?? const <BoothEvent>[];
    int count(EventFilter filter) =>
        all.where((event) => event.status == filter.status).length;

    return StudioPage(
      header: StudioPageHeader(
        eyebrow: 'Studio',
        title: 'Events',
        subtitle:
            'Each event holds its templates, camera settings and guest '
            'welcome.',
        actions: [
          PorcelainButton(
            label: 'New event',
            icon: PorcelainIcons.add,
            variant: PorcelainButtonVariant.primary,
            onPressed: () => context.go(RoutePaths.newEvent),
          ),
        ],
      ),
      children: [
        Wrap(
          spacing: PorcelainSpace.lg,
          runSpacing: PorcelainSpace.md,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            PorcelainSegmentedControl<EventFilter>(
              selected: _filter,
              onChanged: (filter) => setState(() => _filter = filter),
              segments: [
                PorcelainSegment(
                  value: EventFilter.active,
                  label: 'Active · ${count(EventFilter.active)}',
                  icon: PorcelainIcons.active,
                ),
                PorcelainSegment(
                  value: EventFilter.draft,
                  label: 'Drafts · ${count(EventFilter.draft)}',
                  icon: PorcelainIcons.draft,
                ),
                PorcelainSegment(
                  value: EventFilter.archived,
                  label: 'Archived · ${count(EventFilter.archived)}',
                  icon: PorcelainIcons.archive,
                ),
              ],
            ),
            if (all.isNotEmpty)
              SizedBox(
                width: 320,
                child: PorcelainTextField(
                  label: 'Search events',
                  controller: _search,
                  hint: 'Title or venue',
                  textInputAction: TextInputAction.search,
                ),
              ),
          ],
        ),
        switch (events) {
          AsyncData() => _list(all),
          AsyncError() => EmptyState(
            icon: PorcelainIcons.error,
            title: "Events couldn't be loaded",
            message: 'The booth storage could not be read. Try again.',
            tone: PorcelainTone.danger,
            actions: [
              PorcelainButton(
                label: 'Try again',
                icon: PorcelainIcons.retry,
                onPressed: () => ref.invalidate(eventsProvider),
              ),
            ],
          ),
          _ => const SkeletonList(semanticLabel: 'Loading events'),
        },
      ],
    );
  }

  Widget _list(List<BoothEvent> all) {
    final shown = [
      for (final event in all)
        if (event.status == _filter.status && _matches(event)) event,
    ];
    if (shown.isEmpty) {
      if (_search.text.trim().isNotEmpty &&
          all.any((event) => event.status == _filter.status)) {
        return EmptyState(
          key: ValueKey('search-$_filter'),
          icon: PorcelainIcons.search,
          title: 'No matching events',
          message: 'Nothing in this list matches “${_search.text.trim()}”.',
          actions: [
            PorcelainButton(
              label: 'Clear search',
              icon: PorcelainIcons.close,
              onPressed: _search.clear,
            ),
          ],
        );
      }
      final (icon, title, message) = switch (_filter) {
        EventFilter.active => (
          PorcelainIcons.active,
          'No active events',
          'Activate a draft once its templates and settings are complete; '
              'active events can start the booth.',
        ),
        EventFilter.draft => (
          PorcelainIcons.draft,
          'No drafts',
          'Events you are still setting up appear here until they are '
              'ready.',
        ),
        EventFilter.archived => (
          PorcelainIcons.archive,
          'Nothing archived',
          'Archived events keep all of their photos. Archiving never '
              'deletes anything.',
        ),
      };
      return EmptyState(
        key: ValueKey(_filter),
        icon: icon,
        title: title,
        message: message,
        actions: [
          if (_filter != EventFilter.archived)
            PorcelainButton(
              label: 'New event',
              icon: PorcelainIcons.add,
              onPressed: () => context.go(RoutePaths.newEvent),
            ),
        ],
      );
    }
    return ResponsiveGrid(
      minTileWidth: 340,
      maxColumns: 3,
      children: [for (final event in shown) EventCard(event: event)],
    );
  }
}

/// One event in the list: status, when and where, what it uses, and its
/// actions. Opening it is an explicit button, so no control nests inside
/// another.
class EventCard extends ConsumerWidget {
  const EventCard({super.key, required this.event});

  final BoothEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final date = event.date;
    final place = [
      if (date != null) formatCalendarDateShort(date),
      if (event.venue != null) event.venue!,
    ].join(' · ');
    final archived = event.status == EventStatus.archived;

    return PorcelainCard(
      padding: const EdgeInsets.all(PorcelainSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(
                      label: EventCopy.status(event.status),
                      tone: EventCopy.statusTone(event.status),
                      icon: EventCopy.statusIcon(event.status),
                    ),
                    const Spacer(),
                    if (event.guest.themeOverride != null)
                      Icon(
                        PorcelainIcons.appearance,
                        size: PorcelainSize.iconSmall,
                        color: colors.accentIcon,
                        semanticLabel: 'Own guest theme',
                      ),
                  ],
                ),
                const SizedBox(height: PorcelainSpace.md),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.titleLarge,
                ),
                const SizedBox(height: PorcelainSpace.xxs),
                Text(
                  place.isEmpty ? 'No date or venue yet' : place,
                  style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
                ),
                const SizedBox(height: PorcelainSpace.sm),
                Text(
                  EventCopy.summary(event),
                  style: theme.text.bodyMedium.copyWith(color: colors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: PorcelainSpace.lg),
          Wrap(
            spacing: PorcelainSpace.xs,
            runSpacing: PorcelainSpace.xs,
            children: [
              PorcelainButton(
                label: archived ? 'View' : 'Edit',
                icon: archived ? PorcelainIcons.preview : PorcelainIcons.edit,
                size: PorcelainButtonSize.compact,
                semanticHint: event.title,
                onPressed: () => context.go(RoutePaths.event(event.id)),
              ),
              if (event.status == EventStatus.active)
                PorcelainButton(
                  label: 'Launch checks',
                  icon: PorcelainIcons.preflight,
                  size: PorcelainButtonSize.compact,
                  semanticHint: event.title,
                  onPressed: () => context.go(RoutePaths.preflight(event.id)),
                ),
              if (archived)
                PorcelainButton(
                  label: 'Reopen',
                  icon: PorcelainIcons.restore,
                  size: PorcelainButtonSize.compact,
                  semanticHint: event.title,
                  onPressed: () => EventActions.reopen(context, ref, event),
                ),
              PorcelainButton(
                label: 'Duplicate',
                icon: PorcelainIcons.duplicate,
                variant: PorcelainButtonVariant.quiet,
                size: PorcelainButtonSize.compact,
                semanticHint: event.title,
                onPressed: () => EventActions.duplicate(context, ref, event),
              ),
              if (!archived)
                PorcelainButton(
                  label: 'Archive',
                  icon: PorcelainIcons.archive,
                  variant: PorcelainButtonVariant.quiet,
                  size: PorcelainButtonSize.compact,
                  semanticHint: event.title,
                  onPressed: () => EventActions.archive(context, ref, event),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
