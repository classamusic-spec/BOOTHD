import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/access/access_controller.dart';
import '../core/design_system/porcelain_icons.dart';
import '../core/design_system/porcelain_metrics.dart';
import '../core/design_system/porcelain_theme.dart';
import '../domain/repositories/storage_errors.dart';
import '../shared/guest/guest_layout.dart';
import '../shared/widgets/porcelain_button.dart';
import '../shared/widgets/porcelain_card.dart';
import '../shared/widgets/porcelain_spinner.dart';
import '../shared/widgets/wordmark.dart';

/// Shown while storage opens: usually for a moment only.
class StartingScreen extends StatelessWidget {
  const StartingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    return Scaffold(
      body: GuestBackdrop(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PorcelainWordmark(
                title: 'Porcelain',
                subtitle: 'Photo Booth Studio',
                monogram: 'P',
                semanticLabel: 'Porcelain Photo Booth is starting',
              ),
              const SizedBox(height: PorcelainSpace.xxl),
              PorcelainSpinner(color: colors.accentIcon, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// Startup failed (A-14): plain words, a diagnostic code and what to do,
/// never an exception, path or stored value. Shown before any PIN check,
/// so it reveals nothing about the booth's contents.
class StartupProblemScreen extends ConsumerWidget {
  const StartupProblemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final failure = ref.watch(accessControllerProvider).failure;
    final (code, title, body, canRetry) = switch (failure) {
      StoredDataTooNewException() => (
        'STORAGE_SCHEMA_NEWER',
        'This booth needs a newer app',
        'Its data was saved by a newer version of Porcelain Photo Booth. '
            'Install that version (or newer) to open it. Nothing has been '
            'changed.',
        false,
      ),
      StoredDataUnsupportedException() => (
        'STORAGE_SCHEMA_UNSUPPORTED',
        "This booth's data can't be opened",
        'It was saved in a format this version cannot read. Nothing has '
            'been changed. Contact support with the code below.',
        false,
      ),
      ManagedStorageException(:final code) => (
        code,
        "The tablet's storage isn't available",
        'The app could not prepare its private storage. Free some space or '
            'restart the tablet, then try again.',
        true,
      ),
      _ => (
        'STORAGE_OPEN_FAILED',
        "The booth couldn't start",
        'Its storage could not be opened. Restart the tablet and try again. '
            'If this keeps happening, contact support with the code below.',
        true,
      ),
    };
    return Scaffold(
      body: GuestBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(PorcelainSpace.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: PorcelainCard(
                  radius: PorcelainRadius.dialog,
                  padding: const EdgeInsets.all(PorcelainSpace.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PorcelainIcons.warning,
                        size: 44,
                        color: colors.warning,
                      ),
                      const SizedBox(height: PorcelainSpace.md),
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: theme.text.headlineLarge,
                        ),
                      ),
                      const SizedBox(height: PorcelainSpace.sm),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: theme.text.bodyLarge.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: PorcelainSpace.lg),
                      SelectableText(
                        'Code: $code',
                        style: theme.text.labelLarge.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                      if (canRetry) ...[
                        const SizedBox(height: PorcelainSpace.xl),
                        PorcelainButton(
                          label: 'Try again',
                          icon: PorcelainIcons.retry,
                          variant: PorcelainButtonVariant.primary,
                          onPressed: () => ref
                              .read(accessControllerProvider.notifier)
                              .retryStartup(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
