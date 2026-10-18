import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../domain/services/operator_auth_service.dart';
import '../widgets/pin_pad.dart';
import '../widgets/porcelain_button.dart';
import 'access_copy.dart';
import 'countdown.dart';
import 'pin_layout.dart';
import 'recovery_flow.dart';

/// Operator PIN entry (S28): rate-limited checks with a visible countdown,
/// the recovery code for a forgotten or unreadable PIN, and no hint of
/// what lies behind it. [onUnlocked] receives the proof of a successful
/// check.
class UnlockPanel extends ConsumerStatefulWidget {
  const UnlockPanel({super.key, required this.onUnlocked, this.subtitle});

  final ValueChanged<OperatorProof> onUnlocked;

  /// Shown under the title instead of the generic prompt.
  final String? subtitle;

  @override
  ConsumerState<UnlockPanel> createState() => _UnlockPanelState();
}

enum _Mode { loading, pin, unavailable, recovery }

class _UnlockPanelState extends ConsumerState<UnlockPanel> {
  final _pad = PinPadController();
  var _mode = _Mode.loading;
  var _checking = false;
  String? _message;
  late final Countdown _lockout = Countdown(() {
    if (!mounted) return;
    setState(() {
      if (!_lockout.running) _message = null;
    });
  });

  OperatorAuthService get _auth => ref.read(operatorAuthServiceProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_loadStatus());
  }

  @override
  void dispose() {
    _lockout.dispose();
    _pad.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final status = await _auth.pinStatus();
    if (!mounted) return;
    setState(() {
      _mode = status.available ? _Mode.pin : _Mode.unavailable;
    });
    if (status.retryAfter > Duration.zero) _lockFor(status.retryAfter);
  }

  void _lockFor(Duration wait) => setState(() => _lockout.start(wait));

  Future<void> _check(String pin) async {
    setState(() => _checking = true);
    final result = await _auth.verifyPin(pin);
    if (!mounted) return;
    setState(() => _checking = false);
    switch (result) {
      case AccessGranted(:final proof):
        _pad.clear();
        widget.onUnlocked(proof);
      case AccessDenied(:final attemptsBeforeLockout, :final lockout):
        _pad.reject();
        if (lockout > Duration.zero) {
          setState(() => _message = null);
          _lockFor(lockout);
        } else {
          setState(() => _message = AccessCopy.wrongPin(attemptsBeforeLockout));
        }
      case AccessLockedOut(:final retryAfter):
        _pad.reject();
        setState(() => _message = null);
        _lockFor(retryAfter);
      case CredentialUnavailable():
        _pad.clear();
        setState(() => _mode = _Mode.unavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;

    if (_mode == _Mode.recovery) {
      return RecoveryFlow(
        onCancel: () => setState(() => _mode = _Mode.pin),
        onRecovered: widget.onUnlocked,
      );
    }

    final locked = _lockout.running;
    final wait = AccessCopy.formatWait(_lockout.remaining);
    final status = locked
        ? AccessCopy.lockedOut(wait)
        : _checking
        ? AccessCopy.checking
        : _message ?? widget.subtitle ?? AccessCopy.unlockPrompt;
    final isProblem = locked || _message != null;

    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.raised, colors.raisedShade],
            ),
            border: Border.all(color: colors.hairline),
            boxShadow: PorcelainDepth.shadows(colors, 1),
          ),
          child: SizedBox.square(
            dimension: 64,
            child: Icon(
              PorcelainIcons.locked,
              color: colors.accentIcon,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: PorcelainSpace.lg),
        Semantics(
          header: true,
          child: Text(
            _mode == _Mode.unavailable
                ? AccessCopy.pinUnavailableTitle
                : AccessCopy.unlockTitle,
            textAlign: TextAlign.center,
            style: theme.text.headlineMedium,
          ),
        ),
        const SizedBox(height: PorcelainSpace.xs),
        if (_mode == _Mode.unavailable) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              AccessCopy.pinUnavailableBody,
              textAlign: TextAlign.center,
              style: theme.text.bodyLarge.copyWith(color: colors.inkMuted),
            ),
          ),
          const SizedBox(height: PorcelainSpace.xl),
          PorcelainButton(
            label: AccessCopy.useRecoveryCode,
            icon: PorcelainIcons.security,
            variant: PorcelainButtonVariant.primary,
            size: PorcelainButtonSize.large,
            onPressed: () => setState(() => _mode = _Mode.recovery),
          ),
        ] else
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Center(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: theme.text.bodyLarge.copyWith(
                    color: isProblem ? colors.danger : colors.inkMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    if (_mode == _Mode.unavailable) return header;

    return PinLayout(
      header: header,
      pad: PinPad(
        controller: _pad,
        labels: AccessCopy.pinPadLabels,
        onCompleted: _check,
        enabled: !locked && _mode == _Mode.pin,
        disabledReason: _mode == _Mode.loading
            ? AccessCopy.checking
            : AccessCopy.lockedReason(wait),
        busy: _checking || _mode == _Mode.loading,
      ),
      footer: PorcelainButton(
        label: AccessCopy.forgotPin,
        variant: PorcelainButtonVariant.quiet,
        size: PorcelainButtonSize.compact,
        onPressed: _checking
            ? null
            : () => setState(() => _mode = _Mode.recovery),
        disabledReason: AccessCopy.checking,
      ),
    );
  }
}
