import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../domain/services/operator_secrets.dart';
import '../widgets/pin_pad.dart';
import '../widgets/porcelain_button.dart';
import 'access_copy.dart';
import 'pin_layout.dart';

/// Choose a PIN, then type it again (S01, S28). Refuses guessable PINs
/// before anything is stored; [onCreated] runs once both entries match. If
/// it throws, the flow says the PIN was not saved and starts over.
class CreatePinFlow extends StatefulWidget {
  const CreatePinFlow({super.key, required this.onCreated, this.leading});

  final Future<void> Function(String pin) onCreated;

  /// Shown above the title, e.g. a step indicator.
  final Widget? leading;

  @override
  State<CreatePinFlow> createState() => _CreatePinFlowState();
}

class _CreatePinFlowState extends State<CreatePinFlow> {
  final _pad = PinPadController();
  String? _first;
  String? _message;
  var _saving = false;

  @override
  void dispose() {
    _pad.dispose();
    super.dispose();
  }

  Future<void> _completed(String pin) async {
    final first = _first;
    if (first == null) {
      if (PinPolicy.check(pin) != null) {
        _pad.reject();
        setState(() => _message = AccessCopy.pinTooGuessable);
        return;
      }
      _pad.clear();
      setState(() {
        _first = pin;
        _message = null;
      });
      return;
    }
    if (pin != first) {
      _pad.reject();
      setState(() {
        _first = null;
        _message = AccessCopy.pinMismatch;
      });
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onCreated(pin);
      if (mounted) setState(() => _saving = false);
    } on Exception {
      if (!mounted) return;
      _pad.reject();
      setState(() {
        _first = null;
        _saving = false;
        _message = AccessCopy.pinSaveFailed;
      });
    }
  }

  void _startOver() {
    _pad.clear();
    setState(() {
      _first = null;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final confirming = _first != null;
    final message = _message;
    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?widget.leading,
        Semantics(
          header: true,
          child: Text(
            confirming ? AccessCopy.confirmPinTitle : AccessCopy.choosePinTitle,
            textAlign: TextAlign.center,
            style: theme.text.headlineMedium,
          ),
        ),
        const SizedBox(height: PorcelainSpace.xs),
        Text(
          _saving
              ? AccessCopy.saving
              : confirming
              ? AccessCopy.confirmPinBody
              : AccessCopy.choosePinBody,
          textAlign: TextAlign.center,
          style: theme.text.bodyLarge.copyWith(color: colors.inkMuted),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: message == null
              ? null
              : Center(
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PorcelainIcons.error,
                          size: 20,
                          color: colors.danger,
                          fill: 1,
                        ),
                        const SizedBox(width: PorcelainSpace.xs),
                        Flexible(
                          child: Text(
                            message,
                            style: theme.text.bodyMedium.copyWith(
                              color: colors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
    return PinLayout(
      header: header,
      pad: PinPad(
        controller: _pad,
        labels: AccessCopy.pinPadLabels,
        onCompleted: _completed,
        busy: _saving,
      ),
      footer: SizedBox(
        height: PorcelainSize.buttonCompact,
        child: confirming && !_saving
            ? PorcelainButton(
                label: AccessCopy.startOver,
                icon: PorcelainIcons.retry,
                variant: PorcelainButtonVariant.quiet,
                size: PorcelainButtonSize.compact,
                onPressed: _startOver,
              )
            : null,
      ),
    );
  }
}
