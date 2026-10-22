import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/design_system/porcelain_theme_data.dart';
import '../../core/di/service_providers.dart';
import '../../core/gallery/gallery_providers.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/experience/experience_registry.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/services/booth_capabilities.dart';
import '../../shared/formatters/byte_format.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/guest/event_welcome_copy.dart';
import '../../shared/guest/guest_welcome.dart';
import '../../shared/guest/guest_welcome_sample.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/responsive_grid.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/studio_page.dart';
import '../../shared/widgets/tablet_frame.dart';
import '../../shared/widgets/tone.dart';

/// Camera permission and the booth's default lens, checked once per
/// dashboard visit without opening the camera or asking for permission.
final _cameraCheckProvider = FutureProvider.autoDispose<CapabilityStatus>((
  ref,
) async {
  final booth = await ref.watch(boothProfileProvider.future);
  return ref
      .watch(boothCapabilityProbeProvider)
      .camera(booth.defaults.toCaptureSettings());
});

/// Writes, reads back and removes a test file once per dashboard visit.
final _storageCheckProvider = FutureProvider.autoDispose<CapabilityStatus>(
  (ref) => ref.watch(boothCapabilityProbeProvider).storageWrite(),
);

/// Studio dashboard (S02): the next step for the booth, checked facts about
/// its readiness and the way into each section. No invented statistics:
/// counts come from storage, and what cannot be checked yet says so.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const noEventReason =
      'Start Booth needs an active event. Create one and activate it once '
      'its templates and settings are complete.';
  static const draftsOnlyReason =
      'Start Booth needs an active event. Finish a draft and activate it.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider).value ?? const <BoothEvent>[];
    final active = [
      for (final event in events)
        if (event.status == EventStatus.active) event,
    ];
    final drafts = [
      for (final event in events)
        if (event.status == EventStatus.draft) event,
    ];
    final templates = ref.watch(selectableTemplatesProvider).value;
    final storage = ref.watch(_storageCheckProvider);
    final camera = ref.watch(_cameraCheckProvider);
    final free = ref.watch(freeSpaceProvider).value;

    final eventStatus = active.isNotEmpty
        ? '${active.length} active'
        : drafts.isNotEmpty
        ? 'Drafts only'
        : 'None set up';
    final eventDetail = active.isNotEmpty
        ? 'Run the launch checks to start the booth.'
        : drafts.isNotEmpty
        ? 'Activate a draft to launch the booth.'
        : 'Create and activate an event to launch the booth.';

    final (storageStatus, storageDetail, storageTone) = switch (storage) {
      AsyncData(value: CapabilityReady()) => (
        'Writable',
        free == null
            ? 'A test file was written and read back. The tablet did not '
                  'say how much space is free.'
            : 'A test file was written and read back. ${formatBytes(free)} '
                  'free, room for about '
                  '${StorageBudget.sessionsFor(free)} guest sessions.',
        free != null && free < StorageBudget.minimumFreeBytes
            ? PorcelainTone.warning
            : PorcelainTone.success,
      ),
      AsyncData(value: CapabilityProblem(:final code)) => (
        'Not writable',
        'Photos cannot be saved ($code). Restart the tablet; if this '
            'persists, free some space.',
        PorcelainTone.danger,
      ),
      AsyncError() => (
        'Not checked',
        'The storage check could not run.',
        PorcelainTone.warning,
      ),
      _ => ('Checking…', 'Writing a test file.', PorcelainTone.neutral),
    };

    final (cameraStatus, cameraDetail, cameraTone) = switch (camera) {
      AsyncData(value: CapabilityReady()) => (
        'Ready',
        "Camera allowed, and the booth's default lens is on this tablet.",
        PorcelainTone.success,
      ),
      AsyncData(value: CapabilityProblem(:final code)) => switch (code) {
        'CAMERA_PERMISSION_NOT_ASKED' => (
          'Not asked yet',
          'The tablet asks for the camera the first time the launch checks '
              'or the camera test run.',
          PorcelainTone.neutral,
        ),
        'CAMERA_PERMISSION_DENIED' ||
        'CAMERA_PERMISSION_PERMANENTLY_DENIED' => (
          'Not allowed',
          "Allow the camera for this app in the tablet's Settings ($code).",
          PorcelainTone.danger,
        ),
        'CAMERA_PERMISSION_RESTRICTED' => (
          'Blocked',
          "The tablet's device management blocks the camera ($code).",
          PorcelainTone.danger,
        ),
        'CAMERA_NONE' => (
          'No camera',
          'The tablet reports no built-in camera.',
          PorcelainTone.danger,
        ),
        'CAMERA_LENS_UNAVAILABLE' => (
          'Other lens only',
          "The booth's default lens is not on this tablet; events would use "
              'the other one.',
          PorcelainTone.warning,
        ),
        _ => (
          'Problem',
          "The cameras couldn't be listed ($code). Open Diagnostics to test "
              'them.',
          PorcelainTone.warning,
        ),
      },
      AsyncError() => (
        'Not checked',
        'The camera check could not run.',
        PorcelainTone.warning,
      ),
      _ => (
        'Checking…',
        'Asking the tablet about its cameras.',
        PorcelainTone.neutral,
      ),
    };

    return StudioPage(
      header: _Hero(active: active, drafts: drafts),
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
              children: [
                StatusTile(
                  icon: PorcelainIcons.events,
                  title: 'Event',
                  status: eventStatus,
                  detail: eventDetail,
                  tone: active.isNotEmpty
                      ? PorcelainTone.success
                      : PorcelainTone.neutral,
                ),
                StatusTile(
                  icon: PorcelainIcons.camera,
                  title: 'Camera',
                  status: cameraStatus,
                  detail: cameraDetail,
                  tone: cameraTone,
                ),
                StatusTile(
                  icon: PorcelainIcons.storage,
                  title: 'Storage',
                  status: storageStatus,
                  detail: storageDetail,
                  tone: storageTone,
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
                  status: events.isEmpty
                      ? 'No events yet'
                      : '${active.length} active · ${drafts.length} '
                            '${drafts.length == 1 ? 'draft' : 'drafts'}',
                  onPressed: () => context.go(RoutePaths.events),
                ),
                _SectionCard(
                  icon: PorcelainIcons.templates,
                  title: 'Templates',
                  status: switch (templates?.length) {
                    null || 0 => 'No templates yet',
                    1 => '1 template',
                    final count => '$count templates',
                  },
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
  const _Hero({required this.active, required this.drafts});

  final List<BoothEvent> active;
  final List<BoothEvent> drafts;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final next = active.firstOrNull;
    final draft = drafts.firstOrNull;

    final String eyebrow;
    final String title;
    final String body;
    final List<Widget> actions;
    final String? reason;
    if (next != null) {
      final when = [
        if (next.date != null) formatCalendarDate(next.date!),
        if (next.venue != null) next.venue!,
      ].join(' · ');
      eyebrow = 'Next event';
      title = next.title;
      body =
          '${when.isEmpty ? '' : '$when. '}Run its launch checks; when '
          'nothing blocks, Booth Mode is one tap away.';
      reason = null;
      actions = [
        PorcelainButton(
          label: 'Start Booth',
          icon: PorcelainIcons.start,
          variant: PorcelainButtonVariant.primary,
          size: PorcelainButtonSize.large,
          onPressed: () => context.go(RoutePaths.preflight(next.id)),
        ),
        PorcelainButton(
          label: 'Edit event',
          icon: PorcelainIcons.edit,
          size: PorcelainButtonSize.large,
          onPressed: () => context.go(RoutePaths.event(next.id)),
        ),
      ];
    } else if (draft != null) {
      eyebrow = 'Dashboard';
      title = 'Finish “${draft.title}”';
      body =
          'Choose its templates and check its settings, then activate it to '
          'launch the booth.';
      reason = DashboardScreen.draftsOnlyReason;
      actions = [
        PorcelainButton(
          label: 'Open draft',
          icon: PorcelainIcons.edit,
          variant: PorcelainButtonVariant.primary,
          size: PorcelainButtonSize.large,
          onPressed: () => context.go(RoutePaths.event(draft.id)),
        ),
        const PorcelainButton(
          label: 'Start Booth',
          icon: PorcelainIcons.start,
          size: PorcelainButtonSize.large,
          onPressed: null,
          disabledReason: DashboardScreen.draftsOnlyReason,
        ),
      ];
    } else {
      eyebrow = 'Dashboard';
      title = 'Set up your first event';
      body =
          'An event brings together its templates, camera settings and '
          'guest welcome. Once it passes its launch checks, the booth is one '
          'tap away.';
      reason = DashboardScreen.noEventReason;
      actions = [
        PorcelainButton(
          label: 'New event',
          icon: PorcelainIcons.add,
          variant: PorcelainButtonVariant.primary,
          size: PorcelainButtonSize.large,
          onPressed: () => context.go(RoutePaths.newEvent),
        ),
        const PorcelainButton(
          label: 'Start Booth',
          icon: PorcelainIcons.start,
          size: PorcelainButtonSize.large,
          onPressed: null,
          disabledReason: DashboardScreen.noEventReason,
        ),
      ];
    }

    Widget intro({required bool wide}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(eyebrow.toUpperCase(), style: theme.text.eyebrow),
        const SizedBox(height: PorcelainSpace.sm),
        Semantics(
          header: true,
          child: Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: wide ? theme.text.displaySmall : theme.text.headlineLarge,
          ),
        ),
        const SizedBox(height: PorcelainSpace.sm),
        Text(
          body,
          style: theme.text.bodyLarge.copyWith(color: colors.inkMuted),
        ),
      ],
    );
    final buttons = Wrap(
      spacing: PorcelainSpace.sm,
      runSpacing: PorcelainSpace.sm,
      children: [
        ...actions,
        PorcelainButton(
          label: 'Guest preview',
          icon: PorcelainIcons.preview,
          size: PorcelainButtonSize.large,
          onPressed: () => context.push(RoutePaths.guestPreview),
        ),
      ],
    );
    final reasonLine = reason == null
        ? null
        : Row(
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
                  reason,
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
          final preview = _GuestPreview(height: wide ? 300 : 220, event: next);
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
                        buttons,
                        if (reasonLine != null) ...[
                          const SizedBox(height: PorcelainSpace.md),
                          reasonLine,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: PorcelainSpace.xxxl),
                  preview,
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
                      preview,
                    ],
                  ],
                ),
                const SizedBox(height: PorcelainSpace.xl),
                buttons,
                if (reasonLine != null) ...[
                  const SizedBox(height: PorcelainSpace.md),
                  reasonLine,
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A live miniature of the guest welcome: the next event's own, in its
/// guest theme, or the sample before there is one.
class _GuestPreview extends StatelessWidget {
  const _GuestPreview({required this.height, this.event});

  final double height;
  final BoothEvent? event;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final event = this.event;
    final override = event == null
        ? null
        : ExperienceRegistry.legacyAppearance(event.experience);
    Widget frame = TabletFrame(
      logicalSize: const Size(820, 1180),
      semanticLabel: event == null
          ? 'Miniature of the guest welcome screen'
          : 'Miniature of the guest welcome for ${event.title}',
      child: GuestWelcome(
        copy: event == null ? sampleGuestWelcomeCopy : welcomeCopyFor(event),
        onStart: () {},
      ),
    );
    if (override != null) {
      frame = Theme(
        data: porcelainThemeData(override, highContrast: theme.highContrast),
        child: frame,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: height, width: height * 820 / 1180 + 18, child: frame),
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
