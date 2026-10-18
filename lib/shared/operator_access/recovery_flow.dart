import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../domain/services/operator_auth_service.dart';
import '../../domain/services/operator_secrets.dart';
import '../widgets/porcelain_button.dart';
import '../widgets/porcelain_text_field.dart';
import 'access_copy.dart';
import 'countdown.dart';
import 'create_pin_flow.dart';
import 'recovery_code_panel.dart';

/// Resetting a forgotten PIN (P-14): recovery code, new PIN, then a new
/// recovery code (the used one stops working). Rate-limited like the PIN.
class RecoveryFlow extends ConsumerStatefulWidget {
  const RecoveryFlow({
    super.key,
    required this.onCancel,
    required this.onRecovered,
  });

  final VoidCallback onCancel;
  final ValueChanged<OperatorProof> onRecovered;

  @override
  ConsumerState<RecoveryFlow> createState() => _RecoveryFlowState();
}

enum _Step { code, newPin, newCode }

class _RecoveryFlowState extends ConsumerState<RecoveryFlow> {
  final _code = TextEditingController();
  var _step = _Step.code;
  var _checking = false;
  var _unavailable = false;
  String? _error;
  OperatorProof? _proof;
  String? _newCode;
  late final Countdown _lockout = Countdown(() {
    if (!mounted) return;
    setState(() {
      if (!_lockout.running) _error = null;
    });
  });

  OperatorAuthService get _auth => ref.read(operatorAuthServiceProvider);

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _lockout.dispose();
    _code.dispose();
    super.dispose();
  }

  void _lockFor(Duration wait) => setState(() => _lockout.start(wait));

  Future<void> _checkCode() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    final result = await _auth.verifyRecoveryCode(_code.text);
    if (!mounted) return;
    setState(() => _checking = false);
    switch (result) {
      case AccessGranted(:final proof):
        _code.clear();
        setState(() {
          _proof = proof;
          _step = _Step.newPin;
        });
      case AccessDenied(:final attemptsBeforeLockout, :final lockout):
        if (lockout > Duration.zero) {
          _lockFor(lockout);
        } else {
          setState(() => _error = AccessCopy.wrongCode(attemptsBeforeLockout));
        }
      case AccessLockedOut(:final retryAfter):
        _lockFor(retryAfter);
      case CredentialUnavailable():
        setState(() => _unavailable = true);
    }
  }

  Future<void> _setPin(String pin) async {
    final proof = _proof!;
    await _auth.replacePin(proof, pin);
    final code = await _auth.replaceRecoveryCode(proof);
    if (!mounted) return;
    setState(() {
      _newCode = code;
      _step = _Step.newCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    switch (_step) {
      case _Step.newPin:
        return CreatePinFlow(onCreated: _setPin);
      case _Step.newCode:
        return RecoveryCodePanel(
          code: _newCode!,
          continueLabel: AccessCopy.recoveryDone,
          onContinue: () => widget.onRecovered(_proof!),
        );
      case _Step.code:
        break;
    }

    if (_unavailable) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PorcelainIcons.warning, size: 40, color: colors.warning),
          const SizedBox(height: PorcelainSpace.md),
          Semantics(
            header: true,
            child: Text(
              AccessCopy.noRecoveryCodeTitle,
              textAlign: TextAlign.center,
              style: theme.text.headlineMedium,
            ),
          ),
          const SizedBox(height: PorcelainSpace.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              AccessCopy.noRecoveryCodeBody,
              textAlign: TextAlign.center,
              style: theme.text.bodyLarge.copyWith(color: colors.inkMuted),
            ),
          ),
          const SizedBox(height: PorcelainSpace.xl),
          PorcelainButton(
            label: AccessCopy.backToPin,
            icon: PorcelainIcons.back,
            onPressed: widget.onCancel,
          ),
        ],
      );
    }

    final locked = _lockout.running;
    final complete = RecoveryCodes.normalise(_code.text) != null;
    final error = locked
        ? AccessCopy.lockedOut(AccessCopy.formatWait(_lockout.remaining))
        : _error;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              AccessCopy.recoveryTitle,
              textAlign: TextAlign.center,
              style: theme.text.headlineMedium,
            ),
          ),
          const SizedBox(height: PorcelainSpace.xs),
          Text(
            AccessCopy.recoveryBody,
            textAlign: TextAlign.center,
            style: theme.text.bodyLarge.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: PorcelainSpace.xl),
          PorcelainTextField(
            label: AccessCopy.recoveryField,
            controller: _code,
            hint: AccessCopy.recoveryHint,
            error: error,
            enabled: !locked && !_checking,
            disabledReason: error,
            autofocus: true,
            maxLength: 19,
            textCapitalization: TextCapitalization.characters,
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9A-Za-z -]')),
            ],
            onSubmitted: (_) {
              if (complete && !locked && !_checking) unawaited(_checkCode());
            },
          ),
          const SizedBox(height: PorcelainSpace.xl),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: PorcelainSpace.sm,
            runSpacing: PorcelainSpace.sm,
            children: [
              PorcelainButton(
                label: AccessCopy.backToPin,
                icon: PorcelainIcons.back,
                onPressed: _checking ? null : widget.onCancel,
                disabledReason: AccessCopy.checking,
              ),
              PorcelainButton(
                label: AccessCopy.checkCode,
                icon: PorcelainIcons.check,
                variant: PorcelainButtonVariant.primary,
                busy: _checking,
                busyLabel: AccessCopy.checking,
                onPressed: complete && !locked ? _checkCode : null,
                disabledReason: locked ? error : AccessCopy.recoveryIncomplete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
