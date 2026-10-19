import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/kiosk/kiosk_providers.dart';
import '../../core/platform/app_environment.dart';
import '../../domain/services/kiosk_lock.dart';
import '../widgets/page_header.dart';
import '../widgets/porcelain_button.dart';
import '../widgets/porcelain_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/tone.dart';
import 'kiosk_copy.dart';

/// The kiosk lock (M10, AC-1002), in Settings > Kiosk lock and from the
/// launch checks: whether the tablet reports it is locked to the booth app,
/// and the tablet's own two ways to lock it. The booth reads the lock; it
/// never turns one on or off, and never says it can
/// (docs/KIOSK_DEPLOYMENT.md).
class KioskGuide extends ConsumerWidget {
  const KioskGuide({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final platform = ref.watch(appEnvironmentProvider).platform;
    final lock = ref.watch(kioskLockProvider);
    final ipad = platform == TargetPlatform.iOS;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Lock this tablet to the booth',
          subtitle:
              "The tablet's own kiosk lock keeps guests inside the booth app. "
              'The booth checks whether it is on; only the tablet can turn '
              'it on or off.',
        ),
        PorcelainCard(
          child: _Status(
            lock: lock.value,
            platform: platform,
            checking: lock.isLoading,
            onCheck: () => ref.invalidate(kioskLockProvider),
          ),
        ),
        const SizedBox(height: PorcelainSpace.xxl),
        SectionHeader(
          title: ipad ? 'Two ways on iPad' : 'Two ways on Android',
          subtitle:
              'Choose one for each tablet and test it before guests '
              'arrive.',
        ),
        for (final (i, method) in KioskCopy.methods(platform).indexed) ...[
          if (i > 0) const SizedBox(height: PorcelainSpace.md),
          PorcelainCard(child: _Method(method: method)),
        ],
        const SizedBox(height: PorcelainSpace.md),
        Text(
          'To test a lock, try the Home gesture, the app switcher and '
          'notifications: the booth must stay in front. With or without '
          'one, Booth Mode shows guests only its own screens and its exit '
          'needs the PIN.',
          style: theme.text.bodySmall.copyWith(color: theme.colors.inkMuted),
        ),
      ],
    );
  }
}

/// What the tablet reports now, and a way to ask again.
class _Status extends StatelessWidget {
  const _Status({
    required this.lock,
    required this.platform,
    required this.checking,
    required this.onCheck,
  });

  /// Null until the tablet first answers.
  final KioskLock? lock;
  final TargetPlatform platform;
  final bool checking;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final lock = this.lock;
    final tone = switch (lock) {
      null => PorcelainTone.neutral,
      KioskLock(locked: true) => PorcelainTone.success,
      KioskLock.none => PorcelainTone.warning,
      _ => PorcelainTone.neutral,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(PorcelainIcons.kiosk, color: colors.accentIcon),
              ),
              const SizedBox(width: PorcelainSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: PorcelainSpace.sm,
                      runSpacing: PorcelainSpace.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          lock == null
                              ? 'Checking the tablet…'
                              : KioskCopy.state(lock),
                          style: theme.text.titleMedium,
                        ),
                        if (lock != null)
                          StatusBadge(label: KioskCopy.badge(lock), tone: tone),
                      ],
                    ),
                    if (lock != null) ...[
                      const SizedBox(height: PorcelainSpace.xxs),
                      Text(
                        KioskCopy.explain(lock),
                        style: theme.text.bodyMedium.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                      if (!lock.locked)
                        Text(
                          KioskCopy.turnOn(platform),
                          style: theme.text.bodyMedium,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PorcelainSpace.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: PorcelainButton(
            label: 'Check again',
            icon: PorcelainIcons.retry,
            busy: checking,
            busyLabel: 'Checking…',
            onPressed: checking ? null : onCheck,
          ),
        ),
      ],
    );
  }
}

/// One of the tablet's ways to lock itself, step by step.
class _Method extends StatelessWidget {
  const _Method({required this.method});

  final KioskMethod method;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final muted = theme.text.bodySmall.copyWith(color: colors.inkMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(method.title, style: theme.text.titleMedium),
        ),
        const SizedBox(height: PorcelainSpace.xxs),
        Text(method.goodFor, style: muted),
        const SizedBox(height: PorcelainSpace.md),
        for (final (i, step) in method.steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: PorcelainSpace.sm),
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.inset,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.hairline),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: theme.text.labelMedium.copyWith(
                        color: colors.accentText,
                      ),
                    ),
                  ),
                  const SizedBox(width: PorcelainSpace.sm),
                  Expanded(child: Text(step, style: theme.text.bodyMedium)),
                ],
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(PorcelainIcons.info, size: 18, color: colors.inkMuted),
            const SizedBox(width: PorcelainSpace.xs),
            Expanded(child: Text(method.note, style: muted)),
          ],
        ),
      ],
    );
  }
}
