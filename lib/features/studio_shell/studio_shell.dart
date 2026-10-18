import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/access/access_controller.dart';
import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/platform/app_info.dart';
import '../../domain/models/booth_event.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_navigation.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';
import '../../shared/widgets/wordmark.dart';

/// Studio sections in navigation order; matches the router's branches.
const studioDestinations = [
  PorcelainDestination(icon: PorcelainIcons.dashboard, label: 'Dashboard'),
  PorcelainDestination(icon: PorcelainIcons.events, label: 'Events'),
  PorcelainDestination(icon: PorcelainIcons.templates, label: 'Templates'),
  PorcelainDestination(icon: PorcelainIcons.gallery, label: 'Gallery'),
  PorcelainDestination(icon: PorcelainIcons.settings, label: 'Settings'),
  PorcelainDestination(icon: PorcelainIcons.diagnostics, label: 'Diagnostics'),
];

/// The adaptive Studio frame (UX-03): a full sidebar when the window is at
/// least [PorcelainBreakpoints.sidebar] wide, a compact rail otherwise,
/// whichever way the tablet is held. Each section keeps its own navigation
/// stack and scroll position. Lock Studio is always one tap away.
class StudioShell extends ConsumerWidget {
  const StudioShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const lockLabel = 'Lock Studio';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void lock() => ref.read(accessControllerProvider.notifier).lock();
    final extended =
        MediaQuery.sizeOf(context).width >= PorcelainBreakpoints.sidebar;
    return Scaffold(
      body: Row(
        children: [
          PorcelainNavigation(
            destinations: studioDestinations,
            selectedIndex: navigationShell.currentIndex,
            extended: extended,
            onSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            header: PorcelainWordmark(
              title: 'Porcelain',
              subtitle: 'Photo Booth Studio',
              monogram: 'P',
              semanticLabel: '${AppInfo.name} Studio',
              compact: !extended,
            ),
            footer: extended
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BoothStatus(),
                      const SizedBox(height: PorcelainSpace.lg),
                      PorcelainButton(
                        label: lockLabel,
                        icon: PorcelainIcons.lockNow,
                        size: PorcelainButtonSize.compact,
                        expand: true,
                        onPressed: lock,
                      ),
                    ],
                  )
                : Center(
                    child: PorcelainIconButton(
                      icon: PorcelainIcons.lockNow,
                      semanticLabel: lockLabel,
                      onPressed: lock,
                    ),
                  ),
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

/// Honest booth readiness in the sidebar: whether an event is active, and
/// that launch checks still decide.
class _BoothStatus extends ConsumerWidget {
  const _BoothStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final events = ref.watch(eventsProvider).value ?? const <BoothEvent>[];
    final active = events.where((e) => e.status == EventStatus.active).length;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BOOTH', style: theme.text.eyebrow),
          const SizedBox(height: PorcelainSpace.xs),
          StatusBadge(
            label: active == 0 ? 'Not ready' : '$active active',
            tone: active == 0 ? PorcelainTone.neutral : PorcelainTone.success,
          ),
          const SizedBox(height: PorcelainSpace.xs),
          Text(
            active == 0
                ? 'No event is active yet.'
                : 'Run the launch checks to start the booth.',
            style: theme.text.bodyMedium.copyWith(color: theme.colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Shows the selected section with a gentle fade-through when switching
/// (none with reduced motion). Every section stays mounted, so state and
/// scroll positions survive, and only the visible one ticks.
class StudioSectionStack extends StatefulWidget {
  const StudioSectionStack({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<StudioSectionStack> createState() => _StudioSectionStackState();
}

class _StudioSectionStackState extends State<StudioSectionStack>
    with SingleTickerProviderStateMixin {
  late final _entrance = AnimationController(vsync: this, value: 1);
  late final _fade = CurvedAnimation(
    parent: _entrance,
    curve: PorcelainMotion.enter,
  );

  @override
  void didUpdateWidget(StudioSectionStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final motion = PorcelainMotion.of(context);
      if (motion.isReduced) {
        _entrance.value = 1;
      } else {
        _entrance
          ..duration = motion.emphasized
          ..forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Offstage(
            offstage: i != widget.currentIndex,
            child: TickerMode(
              enabled: i == widget.currentIndex,
              child: FadeTransition(
                opacity: i == widget.currentIndex
                    ? _fade
                    : const AlwaysStoppedAnimation(1),
                child: widget.children[i],
              ),
            ),
          ),
      ],
    );
  }
}
