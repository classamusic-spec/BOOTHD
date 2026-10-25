import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/access/access_controller.dart';
import '../../core/booth/booth_providers.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/services/operator_auth_service.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/guest/guest_layout.dart';
import '../../shared/operator_access/pin_layout.dart';
import '../../shared/operator_access/unlock_panel.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import 'booth_copy.dart';
import 'booth_event_theme.dart';
import 'booth_photo_reel.dart';

/// The operator's exit from Booth Mode (S28): PIN, then an explicit Exit
/// Booth, in the event's theme ([BoothEventTheme]); once unlocked, the
/// event's photo reel can be looked through without leaving Booth Mode.
/// Reached only through the hidden hold. Left alone for
/// [idleTimeout], it returns to the guest welcome, so a guest who stumbles
/// here is not left on a PIN pad.
class BoothOperatorScreen extends ConsumerStatefulWidget {
  const BoothOperatorScreen({super.key});

  static const idleTimeout = Duration(seconds: 45);

  @override
  ConsumerState<BoothOperatorScreen> createState() =>
      _BoothOperatorScreenState();
}

class _BoothOperatorScreenState extends ConsumerState<BoothOperatorScreen> {
  OperatorProof? _proof;
  Timer? _idle;
  var _exiting = false;
  var _reel = false;

  @override
  void initState() {
    super.initState();
    _resetIdle();
  }

  @override
  void dispose() {
    _idle?.cancel();
    super.dispose();
  }

  void _resetIdle() {
    _idle?.cancel();
    _idle = Timer(BoothOperatorScreen.idleTimeout, _backToGuests);
  }

  void _backToGuests() {
    if (mounted && !_exiting) context.go(RoutePaths.booth);
  }

  Future<void> _exit() async {
    setState(() => _exiting = true);
    _idle?.cancel();
    ref.read(lastGuestProblemProvider.notifier).clear();
    await ref.read(accessControllerProvider.notifier).exitBooth(_proof!);
  }

  @override
  Widget build(BuildContext context) =>
      BoothEventTheme(child: Builder(builder: _screen));

  Widget _screen(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final proof = _proof;
    final eventId = ref.watch(accessControllerProvider).boothEventId;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToGuests();
      },
      child: Listener(
        // Any touch keeps the screen open.
        onPointerDown: (_) => _resetIdle(),
        child: Scaffold(
          body: GuestBackdrop(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(PorcelainSpace.xl),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 2 * PorcelainSpace.xl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: _reel && proof != null
                              ? 860
                              : pinCardWidth(MediaQuery.sizeOf(context)),
                        ),
                        child: PorcelainCard(
                          radius: PorcelainRadius.dialog,
                          padding: const EdgeInsets.symmetric(
                            horizontal: PorcelainSpace.xl,
                            vertical: PorcelainSpace.xxl,
                          ),
                          child: proof != null && _reel && eventId != null
                              ? BoothPhotoReel(
                                  eventId: eventId,
                                  onClose: () => setState(() => _reel = false),
                                )
                              : proof == null
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    UnlockPanel(
                                      subtitle:
                                          'Enter the operator PIN to manage '
                                          'the booth.',
                                      onUnlocked: (proof) {
                                        _resetIdle();
                                        setState(() => _proof = proof);
                                      },
                                    ),
                                    const SizedBox(height: PorcelainSpace.sm),
                                    PorcelainButton(
                                      label: 'Back to the guest screen',
                                      icon: PorcelainIcons.back,
                                      onPressed: _backToGuests,
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      PorcelainIcons.success,
                                      size: 44,
                                      color: colors.success,
                                      fill: 1,
                                    ),
                                    const SizedBox(height: PorcelainSpace.md),
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        'Booth unlocked',
                                        textAlign: TextAlign.center,
                                        style: theme.text.headlineMedium,
                                      ),
                                    ),
                                    const SizedBox(height: PorcelainSpace.xs),
                                    Text(
                                      'Look through the photo reel, exit '
                                      'Booth Mode to open the Studio, or '
                                      'return guests to the welcome screen.',
                                      textAlign: TextAlign.center,
                                      style: theme.text.bodyLarge.copyWith(
                                        color: colors.inkMuted,
                                      ),
                                    ),
                                    if (ref.watch(lastGuestProblemProvider)
                                        case final report?) ...[
                                      const SizedBox(height: PorcelainSpace.lg),
                                      _LastProblem(report: report),
                                    ],
                                    const SizedBox(height: PorcelainSpace.xl),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: PorcelainSpace.sm,
                                      runSpacing: PorcelainSpace.sm,
                                      children: [
                                        PorcelainButton(
                                          label: 'Back to the guest screen',
                                          icon: PorcelainIcons.back,
                                          onPressed: _exiting
                                              ? null
                                              : _backToGuests,
                                          disabledReason: 'Leaving Booth Mode…',
                                        ),
                                        if (eventId != null)
                                          PorcelainButton(
                                            label: 'Photo reel',
                                            icon: PorcelainIcons.gallery,
                                            onPressed: _exiting
                                                ? null
                                                : () => setState(
                                                    () => _reel = true,
                                                  ),
                                            disabledReason:
                                                'Leaving Booth Mode…',
                                          ),
                                        PorcelainButton(
                                          label: 'Exit Booth Mode',
                                          icon: PorcelainIcons.close,
                                          variant:
                                              PorcelainButtonVariant.primary,
                                          busy: _exiting,
                                          busyLabel: 'Leaving Booth Mode…',
                                          onPressed: () => unawaited(_exit()),
                                        ),
                                      ],
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
      ),
    );
  }
}

/// What went wrong for the last guest, for the operator only: guests never
/// see codes (S28, S29 operator recovery).
class _LastProblem extends StatelessWidget {
  const _LastProblem({required this.report});

  final GuestProblemReport report;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.warningSurface,
          borderRadius: PorcelainRadius.controlAll,
          border: Border.all(color: colors.warning),
        ),
        child: Padding(
          padding: const EdgeInsets.all(PorcelainSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PorcelainIcons.warning, color: colors.warning),
              const SizedBox(width: PorcelainSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BoothOperatorCopy.lastProblemTitle,
                      style: theme.text.titleSmall,
                    ),
                    const SizedBox(height: PorcelainSpace.xxs),
                    Text(
                      BoothOperatorCopy.problem(report.problem.kind),
                      style: theme.text.bodyMedium,
                    ),
                    const SizedBox(height: PorcelainSpace.xxs),
                    Text(
                      BoothOperatorCopy.code(
                        report.problem.code,
                        formatTimestamp(report.atUtc.toLocal()),
                      ),
                      style: theme.text.bodySmall.copyWith(color: colors.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
