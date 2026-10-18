import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/studio_page.dart';

/// Event lifecycle filters (S03, CR-001 fix 2).
enum EventFilter { active, draft, archived }

/// Events list (S03). Events are stored from M03; until then each filter
/// shows a truthful empty state and creating an event is disabled with its
/// reason.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  static const newEventReason = 'Creating events arrives in M03.';

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  var _filter = EventFilter.active;

  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = switch (_filter) {
      EventFilter.active => (
        PorcelainIcons.active,
        'No active events',
        'Events that have passed their launch checks appear here, ready to '
            'start the booth.',
      ),
      EventFilter.draft => (
        PorcelainIcons.draft,
        'No drafts',
        'Events you are still setting up appear here until they are ready.',
      ),
      EventFilter.archived => (
        PorcelainIcons.archive,
        'Nothing archived',
        'Archived events keep all of their photos. Archiving never deletes '
            'anything.',
      ),
    };

    return StudioPage(
      header: const StudioPageHeader(
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
            onPressed: null,
            disabledReason: EventsScreen.newEventReason,
          ),
        ],
      ),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: PorcelainSegmentedControl<EventFilter>(
            selected: _filter,
            onChanged: (filter) => setState(() => _filter = filter),
            segments: const [
              PorcelainSegment(
                value: EventFilter.active,
                label: 'Active',
                icon: PorcelainIcons.active,
              ),
              PorcelainSegment(
                value: EventFilter.draft,
                label: 'Drafts',
                icon: PorcelainIcons.draft,
              ),
              PorcelainSegment(
                value: EventFilter.archived,
                label: 'Archived',
                icon: PorcelainIcons.archive,
              ),
            ],
          ),
        ),
        EmptyState(
          key: ValueKey(_filter),
          icon: icon,
          title: title,
          message: message,
          footnote: EventsScreen.newEventReason,
        ),
      ],
    );
  }
}
