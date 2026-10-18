import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/routing/route_paths.dart';
import '../../shared/guest/guest_welcome.dart';
import '../../shared/guest/guest_welcome_sample.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/responsive_grid.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/studio_page.dart';
import '../../shared/widgets/tablet_frame.dart';

/// Studio dashboard (S02): launch hero, booth readiness and the way into
/// each section. Shows only what the app can verify; Start Booth stays
/// disabled, with its reason, until events and launch checks exist (M03).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const startBoothReason =
      'Start Booth unlocks when an event passes its launch checks. '
      'Events arrive in M03.';

  @override
  Widget build(BuildContext context) {
    return StudioPage(
      header: const _Hero(),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'Booth readiness',
              subtitle: 'Checked facts only. Nothing here is assumed.',
            ),
            ResponsiveGrid(
              minTileWidth: 180,
              maxColumns: 3,
              children: const [
                StatusTile(
                  icon: PorcelainIcons.events,
                  title: 'Event',
                  status: 'None set up',
                  detail: 'Create and check an event to launch the booth.',
                ),
                StatusTile(
                  icon: PorcelainIcons.camera,
                  title: 'Camera',
                  status: 'Not checked',
                  detail: 'Camera tests arrive with the camera service (M06).',
                ),
                StatusTile(
                  icon: PorcelainIcons.storage,
                  title: 'Storage',
                  status: 'Not checked',
                  detail:
                      'Free space is checked by the launch checklist (M03).',
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(title: 'Studio'),
            ResponsiveGrid(
              minTileWidth: 200,
              children: [
                _SectionCard(
                  icon: PorcelainIcons.events,
                  title: 'Events',
                  status: 'No events yet',
                  onPressed: () => context.go(RoutePaths.events),
                ),
                _SectionCard(
                  icon: PorcelainIcons.templates,
                  title: 'Templates',
                  status: 'Page formats and designs',
                  onPressed: () => context.go(RoutePaths.templates),
                ),
                _SectionCard(
                  icon: PorcelainIcons.gallery,
                  title: 'Gallery',
                  status: 'No sessions yet',
                  onPressed: () => context.go(RoutePaths.gallery),
                ),
                _SectionCard(
                  icon: PorcelainIcons.settings,
                  title: 'Settings',
                  status: 'Appearance and device',
                  onPressed: () => context.go(RoutePaths.settings),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    Widget intro({required bool wide}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('DASHBOARD', style: theme.text.eyebrow),
        const SizedBox(height: PorcelainSpace.sm),
        Semantics(
          header: true,
          child: Text(
            'Set up your first event',
            style: wide ? theme.text.displaySmall : theme.text.headlineLarge,
          ),
        ),
        const SizedBox(height: PorcelainSpace.sm),
        Text(
          'An event brings together its templates, camera settings and '
          'guest welcome. Once it passes its launch checks, the booth is '
          'one tap away.',
          style: theme.text.bodyLarge.copyWith(color: colors.inkMuted),
        ),
      ],
    );
    final actions = Wrap(
      spacing: PorcelainSpace.sm,
      runSpacing: PorcelainSpace.sm,
      children: [
        const PorcelainButton(
          label: 'Start Booth',
          icon: PorcelainIcons.start,
          variant: PorcelainButtonVariant.primary,
          size: PorcelainButtonSize.large,
          onPressed: null,
          disabledReason: DashboardScreen.startBoothReason,
        ),
        PorcelainButton(
          label: 'Guest preview',
          icon: PorcelainIcons.preview,
          size: PorcelainButtonSize.large,
          onPressed: () => context.push(RoutePaths.guestPreview),
        ),
      ],
    );
    final reason = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          PorcelainIcons.locked,
          size: PorcelainSize.iconSmall,
          color: colors.accentIcon,
        ),
        const SizedBox(width: PorcelainSpace.xs),
        Expanded(
          child: Text(
            DashboardScreen.startBoothReason,
            style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
          ),
        ),
      ],
    );

    return PorcelainCard(
      padding: EdgeInsets.zero,
      radius: PorcelainRadius.dialog,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          if (wide) {
            return Padding(
              padding: const EdgeInsets.all(PorcelainSpace.xxxl),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        intro(wide: true),
                        const SizedBox(height: PorcelainSpace.xl),
                        actions,
                        const SizedBox(height: PorcelainSpace.md),
                        reason,
                      ],
                    ),
                  ),
                  const SizedBox(width: PorcelainSpace.xxxl),
                  const _GuestPreview(height: 300),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(PorcelainSpace.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: intro(wide: false)),
                    if (constraints.maxWidth >= 480) ...[
                      const SizedBox(width: PorcelainSpace.xl),
                      const _GuestPreview(height: 220),
                    ],
                  ],
                ),
                const SizedBox(height: PorcelainSpace.xl),
                actions,
                const SizedBox(height: PorcelainSpace.md),
                reason,
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A live miniature of the guest welcome screen in the current theme.
class _GuestPreview extends StatelessWidget {
  const _GuestPreview({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: height * 820 / 1180 + 18,
          child: TabletFrame(
            logicalSize: const Size(820, 1180),
            semanticLabel: 'Miniature of the guest welcome screen',
            child: GuestWelcome(copy: sampleGuestWelcomeCopy, onStart: () {}),
          ),
        ),
        const SizedBox(height: PorcelainSpace.lg),
        Text(
          'What guests see',
          style: theme.text.labelMedium.copyWith(color: theme.colors.inkMuted),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return PorcelainCard(
      onPressed: onPressed,
      padding: const EdgeInsets.all(PorcelainSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.raised, colors.selected],
                  ),
                  border: Border.all(color: colors.hairline),
                  boxShadow: PorcelainDepth.shadows(colors, 0.8),
                ),
                child: SizedBox.square(
                  dimension: 48,
                  child: Icon(icon, color: colors.accentIcon, weight: 300),
                ),
              ),
              const Spacer(),
              Icon(PorcelainIcons.chevron, color: colors.inkMuted),
            ],
          ),
          const SizedBox(height: PorcelainSpace.lg),
          Text(title, style: theme.text.titleMedium),
          const SizedBox(height: PorcelainSpace.xxs),
          Text(
            status,
            style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}
