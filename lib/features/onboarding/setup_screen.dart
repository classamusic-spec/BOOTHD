import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/access/access_controller.dart';
import '../../core/booth/booth_providers.dart';
import '../../core/design_system/appearance.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/design_system/theme_profiles.dart';
import '../../core/di/service_providers.dart';
import '../../domain/models/booth_profile.dart';
import '../../domain/services/operator_auth_service.dart';
import '../../shared/backup/backup_copy.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/formatters/theme_profile_names.dart';
import '../../shared/guest/guest_layout.dart';
import '../../shared/operator_access/create_pin_flow.dart';
import '../../shared/operator_access/pin_layout.dart';
import '../../shared/operator_access/recovery_code_panel.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_text_field.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/theme_profile_card.dart';
import '../../shared/widgets/tone.dart';
import '../../shared/widgets/wordmark.dart';
import 'restore_backup_panel.dart';
import 'welcome_atelier.dart';

enum SetupStep { welcome, privacy, pin, recovery, booth }

/// First-run setup (S01): welcome, how the booth treats data, the operator
/// PIN (typed twice), the recovery code (shown once), then the booth's name
/// and look. Nothing is marked complete until the last step saves, so an
/// interrupted setup starts again cleanly. The camera check joins setup
/// with the production camera service (M06).
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  static const finishFailed =
      "Setup couldn't be saved on this tablet. Check its storage and try "
      'again.';

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  var _step = SetupStep.welcome;
  SetupCredentials? _credentials;
  final _name = TextEditingController(text: BoothProfile.defaultName);
  var _theme = PorcelainThemeProfile.porcelainStudio;
  var _finishing = false;

  /// The welcome step shows the restore panel instead (M10).
  var _restoring = false;

  @override
  void initState() {
    super.initState();
    // After a restore, the restored booth's name (setup runs again for a
    // new PIN and recovery code).
    final restored = ref.read(startupProvider).value?.profile.name;
    if (restored != null && restored.trim().isNotEmpty) _name.text = restored;
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  SetupStep? get _previous => switch (_step) {
    SetupStep.welcome => null,
    SetupStep.privacy => SetupStep.welcome,
    SetupStep.pin => SetupStep.privacy,
    // The PIN is already stored; going back would mean choosing another.
    SetupStep.recovery => null,
    SetupStep.booth => SetupStep.recovery,
  };

  void _go(SetupStep step) => setState(() => _step = step);

  Future<void> _createPin(String pin) async {
    final credentials = await ref.read(operatorAuthServiceProvider).setUp(pin);
    if (!mounted) return;
    setState(() {
      _credentials = credentials;
      _step = SetupStep.recovery;
    });
  }

  String? get _nameProblem {
    final name = _name.text.trim();
    if (name.isEmpty) return 'Give the booth a name.';
    if (name.length > BoothProfile.nameMaxLength) {
      return 'Use at most ${BoothProfile.nameMaxLength} characters.';
    }
    return null;
  }

  Future<void> _finish() async {
    final credentials = _credentials!;
    setState(() => _finishing = true);
    try {
      await ref
          .read(boothSettingsRepositoryProvider)
          .completeSetup(
            boothName: _name.text,
            theme: _theme,
            recoveryVerifier: credentials.recoveryVerifier,
          );
      await ref.read(appearanceProvider.notifier).setProfile(_theme);
    } on Exception {
      if (!mounted) return;
      setState(() => _finishing = false);
      PorcelainToast.show(
        context,
        SetupScreen.finishFailed,
        tone: PorcelainTone.danger,
      );
      return;
    }
    ref.read(accessControllerProvider.notifier).completeSetup();
  }

  /// Wider cards where a step lays out side by side on landscape tablets.
  double _cardWidth(BuildContext context) => switch (_step) {
    SetupStep.pin => pinCardWidth(MediaQuery.sizeOf(context)),
    SetupStep.booth => pinCardWidth(MediaQuery.sizeOf(context)) + 100,
    _ => 640,
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final previous = _previous;
    if (_step == SetupStep.welcome &&
        !_restoring &&
        ref.watch(restoreReportProvider).value == null) {
      return Scaffold(
        body: WelcomeAtelier(
          onBegin: () => _go(SetupStep.privacy),
          onRestore: kIsWeb ? null : () => setState(() => _restoring = true),
        ),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_restoring) {
          setState(() => _restoring = false);
        } else if (previous != null) {
          _go(previous);
        }
      },
      child: Scaffold(
        body: GuestBackdrop(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: PorcelainSpace.xl,
                  vertical: PorcelainSpace.xxl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 2 * PorcelainSpace.xxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _cardWidth(context),
                      ),
                      // The step header sits inside the card, so on any
                      // size or text scale the card, not loose text, is
                      // what meets the backdrop's corner ornament.
                      child: PorcelainCard(
                        padding: const EdgeInsets.all(PorcelainSpace.xxl),
                        radius: PorcelainRadius.dialog,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // A restore is not one of setup's steps.
                            if (!_restoring) ...[
                              Row(
                                children: [
                                  SizedBox(
                                    height: PorcelainSize.buttonCompact,
                                    child: previous == null || _finishing
                                        ? null
                                        : PorcelainButton(
                                            label: 'Back',
                                            icon: PorcelainIcons.back,
                                            variant:
                                                PorcelainButtonVariant.quiet,
                                            size: PorcelainButtonSize.compact,
                                            onPressed: () => _go(previous),
                                          ),
                                  ),
                                  const SizedBox(width: PorcelainSpace.md),
                                  Expanded(child: _Progress(step: _step)),
                                ],
                              ),
                              const SizedBox(height: PorcelainSpace.xl),
                            ],
                            AnimatedSize(
                              duration: PorcelainMotion.of(context).standard,
                              alignment: Alignment.topCenter,
                              child: KeyedSubtree(
                                key: ValueKey(_step),
                                child: _content(theme),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(PorcelainTheme theme) {
    final colors = theme.colors;
    switch (_step) {
      case SetupStep.welcome when _restoring:
        return RestoreBackupPanel(
          onCancel: () => setState(() => _restoring = false),
        );
      case SetupStep.welcome:
        final restored = ref.watch(restoreReportProvider).value;
        return Column(
          children: [
            const PorcelainWordmark(
              title: 'Porcelain',
              subtitle: 'Photo Booth Studio',
              monogram: 'P',
              semanticLabel: 'Porcelain Photo Booth',
            ),
            const SizedBox(height: PorcelainSpace.xxl),
            Semantics(
              header: true,
              child: Text(
                restored == null ? 'Welcome' : 'Backup restored',
                textAlign: TextAlign.center,
                style: theme.text.displaySmall,
              ),
            ),
            const SizedBox(height: PorcelainSpace.sm),
            Text(
              restored == null
                  ? "Let's set this tablet up as your photo booth. It takes a "
                        'couple of minutes and needs no internet connection '
                        'or account.'
                  : '${BackupCopy.contents(restored.counts)} are back, from '
                        'the backup made '
                        '${formatTimestamp(restored.createdAtUtc.toLocal())}. '
                        'Choose a new PIN and recovery code to finish.'
                        '${restored.closedDeliveries == 0 ? '' : ' Texts that were waiting were closed: their numbers are never in a backup.'}',
              textAlign: TextAlign.center,
              style: theme.text.bodyLarge.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: PorcelainSpace.xxl),
            PorcelainButton(
              label: restored == null ? 'Begin setup' : 'Continue',
              icon: PorcelainIcons.start,
              variant: PorcelainButtonVariant.primary,
              size: PorcelainButtonSize.large,
              autofocus: true,
              onPressed: () => _go(SetupStep.privacy),
            ),
            // Restoring needs the tablet app's backup format (ADR-0018).
            if (restored == null && !kIsWeb) ...[
              const SizedBox(height: PorcelainSpace.md),
              PorcelainButton(
                label: 'Restore from a backup',
                icon: PorcelainIcons.restoreBackup,
                variant: PorcelainButtonVariant.quiet,
                onPressed: () => setState(() => _restoring = true),
              ),
            ],
          ],
        );
      case SetupStep.privacy:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                kIsWeb
                    ? 'Everything stays on this device'
                    : 'Everything stays on this tablet',
                style: theme.text.headlineLarge,
              ),
            ),
            const SizedBox(height: PorcelainSpace.xl),
            if (kIsWeb)
              // The web test build (ADR-0018) keeps everything in the
              // browser, which can clear it.
              const _Point(
                icon: PorcelainIcons.storage,
                title: 'Stored in this browser',
                body:
                    "Events, templates and guests' photos are kept in this "
                    "browser's storage on this device. Nothing is uploaded. "
                    "Clearing this site's data, or using a private window, "
                    'deletes them: download photos from the Gallery before '
                    'you do.',
              )
            else
              const _Point(
                icon: PorcelainIcons.storage,
                title: 'Private storage',
                body:
                    "Events, templates and guests' photos are kept in the "
                    "app's private storage on this tablet. Nothing is "
                    'uploaded.',
              ),
            const _Point(
              icon: PorcelainIcons.security,
              title: 'An operator PIN',
              body:
                  'The PIN opens the Studio and is the only way out of Booth '
                  'Mode. Guests never see settings, the gallery or other '
                  "guests' photos.",
            ),
            const _Point(
              icon: PorcelainIcons.archive,
              title: 'You decide what is kept',
              body:
                  'Each event sets how long its photos are kept. Archiving an '
                  'event never deletes anything.',
            ),
            const SizedBox(height: PorcelainSpace.lg),
            Align(
              child: PorcelainButton(
                label: 'Continue',
                icon: PorcelainIcons.chevron,
                variant: PorcelainButtonVariant.primary,
                size: PorcelainButtonSize.large,
                autofocus: true,
                onPressed: () => _go(SetupStep.pin),
              ),
            ),
          ],
        );
      case SetupStep.pin:
        return CreatePinFlow(onCreated: _createPin);
      case SetupStep.recovery:
        return RecoveryCodePanel(
          code: _credentials!.recoveryCode,
          continueLabel: 'Continue',
          onContinue: () => _go(SetupStep.booth),
        );
      case SetupStep.booth:
        final problem = _nameProblem;
        final name = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Name this booth', style: theme.text.headlineLarge),
            ),
            const SizedBox(height: PorcelainSpace.xs),
            Text(
              'The name is for operators, for example on exported photos '
              'and backups. Guests never see it.',
              style: theme.text.bodyLarge.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: PorcelainSpace.xl),
            PorcelainTextField(
              label: 'Booth name',
              controller: _name,
              error: problem,
              maxLength: BoothProfile.nameMaxLength,
              showCounter: true,
              textCapitalization: TextCapitalization.words,
              enabled: !_finishing,
              disabledReason: 'Saving…',
            ),
          ],
        );
        final look = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Look', style: theme.text.titleLarge),
            const SizedBox(height: PorcelainSpace.xxs),
            Text(
              'The theme for the Studio and the guest screens. You can '
              'change it later in Settings.',
              style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: PorcelainSpace.md),
            for (final profile in PorcelainThemeProfile.values)
              Padding(
                padding: const EdgeInsets.only(bottom: PorcelainSpace.sm),
                child: ThemeProfileCard(
                  profile: profile,
                  title: profile.title,
                  description: profile.description,
                  selected: profile == _theme,
                  onPressed: () => setState(() => _theme = profile),
                ),
              ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 760
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: name),
                        const SizedBox(width: PorcelainSpace.xxl),
                        Expanded(child: look),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        name,
                        const SizedBox(height: PorcelainSpace.xxl),
                        look,
                      ],
                    ),
            ),
            const SizedBox(height: PorcelainSpace.lg),
            Align(
              child: PorcelainButton(
                label: 'Finish setup',
                icon: PorcelainIcons.check,
                variant: PorcelainButtonVariant.primary,
                size: PorcelainButtonSize.large,
                busy: _finishing,
                busyLabel: 'Saving…',
                onPressed: problem == null ? () => unawaited(_finish()) : null,
                disabledReason: problem,
              ),
            ),
          ],
        );
    }
  }
}

/// Step dots and "Step 2 of 5".
class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final SetupStep step;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final index = step.index;
    final count = SetupStep.values.length;
    return MergeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: PorcelainSpace.xs),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                  color: i <= index ? colors.accentIcon : colors.hairline,
                ),
              ),
            ),
          ],
          const SizedBox(width: PorcelainSpace.md),
          Text(
            'Step ${index + 1} of $count',
            style: theme.text.labelLarge.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: PorcelainSpace.lg),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.accentIcon, size: PorcelainSize.iconLarge),
            const SizedBox(width: PorcelainSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.text.titleMedium),
                  const SizedBox(height: PorcelainSpace.xxs),
                  Text(
                    body,
                    style: theme.text.bodyMedium.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
