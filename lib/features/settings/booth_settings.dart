import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/access/access_controller.dart';
import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/models/booth_profile.dart';
import '../../domain/services/operator_auth_service.dart';
import '../../domain/value_objects/orientation.dart';
import '../../shared/operator_access/create_pin_flow.dart';
import '../../shared/operator_access/recovery_code_panel.dart';
import '../../shared/operator_access/unlock_panel.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_sheet.dart';
import '../../shared/widgets/porcelain_text_field.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/tone.dart';

/// Booth identity, the default guest orientation for new events, and
/// operator security: change the PIN, replace the recovery code, lock the
/// Studio (S01, S28, P-14), and the way to the kiosk lock (M10).
class BoothSettings extends ConsumerWidget {
  const BoothSettings({super.key});

  static const saveFailed =
      "That change couldn't be saved on the tablet. Try again.";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(boothProfileProvider);
    return switch (profile) {
      AsyncData(:final value) => _Body(profile: value),
      AsyncError() => const PorcelainCard(
        child: PorcelainListRow(
          icon: PorcelainIcons.error,
          title: "Booth settings couldn't be read",
          subtitle: 'Close Settings and open them again.',
        ),
      ),
      _ => const SkeletonList(semanticLabel: 'Loading booth settings'),
    };
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.profile});

  final BoothProfile profile;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final _name = TextEditingController(text: widget.profile.name);
  var _savingName = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _nameProblem {
    final name = _name.text.trim();
    if (name.isEmpty) return 'Give the booth a name.';
    if (name.length > BoothProfile.nameMaxLength) {
      return 'Use at most ${BoothProfile.nameMaxLength} characters.';
    }
    return null;
  }

  Future<void> _saveName() async {
    setState(() => _savingName = true);
    try {
      await ref.read(boothSettingsRepositoryProvider).renameBooth(_name.text);
      if (mounted) {
        PorcelainToast.show(
          context,
          'Booth name saved.',
          tone: PorcelainTone.success,
        );
      }
    } on Exception {
      if (mounted) {
        PorcelainToast.show(
          context,
          BoothSettings.saveFailed,
          tone: PorcelainTone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _saveOrientation(GuestOrientationPreference orientation) async {
    try {
      await ref
          .read(boothSettingsRepositoryProvider)
          .saveEventDefaults(
            widget.profile.defaults.copyWith(orientation: orientation),
          );
    } on Exception {
      if (mounted) {
        PorcelainToast.show(
          context,
          BoothSettings.saveFailed,
          tone: PorcelainTone.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final problem = _nameProblem;
    final changed = _name.text.trim() != profile.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Booth',
          subtitle: 'For operators. Guests never see the booth name.',
        ),
        PorcelainCard(
          padding: const EdgeInsets.all(PorcelainSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PorcelainTextField(
                label: 'Booth name',
                controller: _name,
                error: problem,
                maxLength: BoothProfile.nameMaxLength,
                showCounter: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: PorcelainSpace.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: PorcelainButton(
                  label: 'Save name',
                  icon: PorcelainIcons.check,
                  busy: _savingName,
                  busyLabel: 'Saving…',
                  onPressed: changed && problem == null ? _saveName : null,
                  disabledReason: problem ?? 'The name has not changed.',
                ),
              ),
              const SizedBox(height: PorcelainSpace.xl),
              Text(
                'Guest orientation for new events',
                style: context.porcelain.text.titleSmall,
              ),
              const SizedBox(height: PorcelainSpace.xs),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: PorcelainSegmentedControl<GuestOrientationPreference>(
                  selected: profile.defaults.orientation,
                  onChanged: _saveOrientation,
                  segments: const [
                    PorcelainSegment(
                      value: GuestOrientationPreference.portrait,
                      label: 'Portrait',
                      icon: PorcelainIcons.portrait,
                    ),
                    PorcelainSegment(
                      value: GuestOrientationPreference.landscape,
                      label: 'Landscape',
                      icon: PorcelainIcons.landscape,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PorcelainSpace.xs),
              const _Note(
                'A starting point for new events; each event keeps its own. '
                'Guest screens always fit the window the tablet gives them.',
              ),
            ],
          ),
        ),
        const SizedBox(height: PorcelainSpace.xxxl),
        const SectionHeader(
          title: 'Operator access',
          subtitle:
              'The PIN opens the Studio and is the only way out of Booth '
              'Mode.',
        ),
        PorcelainCard(
          child: Column(
            children: [
              PorcelainListRow(
                icon: PorcelainIcons.security,
                title: 'Change PIN',
                subtitle: 'Needs the current PIN.',
                onPressed: () => _changePin(context),
              ),
              PorcelainListRow(
                icon: PorcelainIcons.licence,
                title: 'New recovery code',
                subtitle:
                    'Replaces the code written down at setup; the old one '
                    'stops working.',
                onPressed: () => _newRecoveryCode(context),
              ),
              PorcelainListRow(
                icon: PorcelainIcons.lockNow,
                title: 'Lock the Studio now',
                subtitle: 'The PIN is needed to come back in.',
                onPressed: () =>
                    ref.read(accessControllerProvider.notifier).lock(),
              ),
              PorcelainListRow(
                icon: PorcelainIcons.kiosk,
                title: 'Kiosk lock',
                subtitle:
                    "Keep guests inside the booth app with the tablet's own "
                    'lock.',
                onPressed: () =>
                    context.go(RoutePaths.settingsSection('kiosk')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _changePin(BuildContext context) async {
    final changed = await showPorcelainSheet<bool>(
      context: context,
      title: 'Change the operator PIN',
      body: const _ChangePinFlow(),
    );
    if (changed == true && context.mounted) {
      PorcelainToast.show(
        context,
        'The new PIN is in use.',
        tone: PorcelainTone.success,
      );
    }
  }

  Future<void> _newRecoveryCode(BuildContext context) async {
    await showPorcelainSheet<void>(
      context: context,
      title: 'Create a new recovery code',
      body: const _NewRecoveryCodeFlow(),
    );
  }
}

/// Current PIN, then the new PIN twice.
class _ChangePinFlow extends ConsumerStatefulWidget {
  const _ChangePinFlow();

  @override
  ConsumerState<_ChangePinFlow> createState() => _ChangePinFlowState();
}

class _ChangePinFlowState extends ConsumerState<_ChangePinFlow> {
  OperatorProof? _proof;

  @override
  Widget build(BuildContext context) {
    final proof = _proof;
    if (proof == null) {
      return UnlockPanel(
        subtitle: 'First, the current PIN.',
        onUnlocked: (proof) => setState(() => _proof = proof),
      );
    }
    return CreatePinFlow(
      onCreated: (pin) async {
        await ref.read(operatorAuthServiceProvider).replacePin(proof, pin);
        if (context.mounted) Navigator.of(context).pop(true);
      },
    );
  }
}

/// Current PIN, then the new code, shown once.
class _NewRecoveryCodeFlow extends ConsumerStatefulWidget {
  const _NewRecoveryCodeFlow();

  @override
  ConsumerState<_NewRecoveryCodeFlow> createState() =>
      _NewRecoveryCodeFlowState();
}

class _NewRecoveryCodeFlowState extends ConsumerState<_NewRecoveryCodeFlow> {
  String? _code;

  Future<void> _create(OperatorProof proof) async {
    try {
      final code = await ref
          .read(operatorAuthServiceProvider)
          .replaceRecoveryCode(proof);
      if (mounted) setState(() => _code = code);
    } on Exception {
      if (!mounted) return;
      Navigator.of(context).pop();
      PorcelainToast.show(
        context,
        BoothSettings.saveFailed,
        tone: PorcelainTone.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _code;
    if (code == null) {
      return UnlockPanel(
        subtitle: 'First, the current PIN.',
        onUnlocked: (proof) => unawaited(_create(proof)),
      );
    }
    return RecoveryCodePanel(
      code: code,
      continueLabel: 'Done',
      onContinue: () => Navigator.of(context).pop(),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Text(
      text,
      style: theme.text.bodyMedium.copyWith(color: theme.colors.inkMuted),
    );
  }
}
