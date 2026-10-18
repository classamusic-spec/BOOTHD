import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/platform/app_info.dart';
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
/// stack and scroll position.
class StudioShell extends StatelessWidget {
  const StudioShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
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
            footer: extended ? const _BoothStatus() : null,
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

/// Honest booth readiness in the sidebar: nothing can launch yet.
class _BoothStatus extends StatelessWidget {
  const _BoothStatus();

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BOOTH', style: theme.text.eyebrow),
          const SizedBox(height: PorcelainSpace.xs),
          const StatusBadge(label: 'Not ready', tone: PorcelainTone.neutral),
          const SizedBox(height: PorcelainSpace.xs),
          Text(
            'No event is set up to launch yet.',
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
