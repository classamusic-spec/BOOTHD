import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'porcelain_toast.dart';
import 'pressable.dart';
import 'tactile_surface.dart';

/// The digits typed into a [PinPad] so far. The owner clears it, or
/// [reject]s an entry to shake the dots and start again.
final class PinPadController extends ChangeNotifier {
  String _digits = '';
  int _rejections = 0;

  String get digits => _digits;

  /// Increases with every [reject]; the pad shakes when it changes.
  int get rejections => _rejections;

  void _type(String digit, int length) {
    if (_digits.length >= length) return;
    _digits += digit;
    notifyListeners();
  }

  void _erase() {
    if (_digits.isEmpty) return;
    _digits = _digits.substring(0, _digits.length - 1);
    notifyListeners();
  }

  void clear() {
    if (_digits.isEmpty) return;
    _digits = '';
    notifyListeners();
  }

  /// Clears the entry and shakes the dots (no shake with reduced motion).
  void reject() {
    _digits = '';
    _rejections++;
    notifyListeners();
  }
}

/// Copy for a [PinPad], supplied by the screen (UX-00).
@immutable
final class PinPadLabels {
  const PinPadLabels({
    required this.entered,
    required this.delete,
    required this.deleteUnavailable,
  });

  /// Announces progress, e.g. `(3, 6) => '3 of 6 digits entered'`.
  final String Function(int entered, int length) entered;

  /// The delete key's name, and why it is unavailable with nothing typed.
  final String delete;
  final String deleteUnavailable;
}

/// A tactile numeric keypad with a row of dots (S28): large porcelain keys
/// (at least 64 dp), the hardware keyboard's digits, Backspace and Enter,
/// and a gentle shake when an entry is rejected. [onCompleted] fires when
/// [length] digits are in.
///
/// Disabled pads (a lockout) keep every key and say why when one is
/// pressed; a busy pad shows progress under the dots.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.controller,
    required this.onCompleted,
    required this.labels,
    this.length = 6,
    this.enabled = true,
    this.disabledReason,
    this.busy = false,
    this.autofocus = true,
  });

  final PinPadController controller;
  final ValueChanged<String> onCompleted;
  final PinPadLabels labels;
  final int length;
  final bool enabled;
  final String? disabledReason;
  final bool busy;
  final bool autofocus;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  late final _shake = AnimationController(vsync: this);
  late int _seenRejections = widget.controller.rejections;
  final _focus = FocusNode(debugLabel: 'PinPad');

  bool get _accepting => widget.enabled && !widget.busy;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(PinPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
      _seenRejections = widget.controller.rejections;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _shake.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    final rejections = widget.controller.rejections;
    if (rejections != _seenRejections) {
      _seenRejections = rejections;
      final motion = PorcelainMotion.of(context);
      if (!motion.isReduced) {
        _shake
          ..duration = const Duration(milliseconds: 420)
          ..forward(from: 0);
      }
      HapticFeedback.heavyImpact();
    }
    setState(() {});
  }

  void _type(String digit) {
    if (!_accepting) return;
    final controller = widget.controller;
    controller._type(digit, widget.length);
    if (controller.digits.length == widget.length) {
      widget.onCompleted(controller.digits);
    }
  }

  void _erase() {
    if (_accepting) widget.controller._erase();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final character = event.character;
    if (character != null && RegExp(r'^\d$').hasMatch(character)) {
      _type(character);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _erase();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final entered = widget.controller.digits.length;
    final reason = widget.enabled ? null : widget.disabledReason;

    return Focus(
      focusNode: _focus,
      autofocus: widget.autofocus,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Keys shrink with the space available, never below 64 dp.
          final byWidth = (constraints.maxWidth - 2 * PorcelainSpace.lg) / 3;
          final byHeight = constraints.hasBoundedHeight
              ? (constraints.maxHeight - 120 - 3 * PorcelainSpace.md) / 4
              : 80.0;
          final key = math.max(
            64.0,
            math.min(80.0, math.min(byWidth, byHeight)),
          );

          Widget digit(String value) => _PinKey(
            size: key,
            semanticLabel: value,
            onPressed: _accepting ? () => _type(value) : null,
            disabledReason: reason,
            child: Text(
              value,
              style: theme.text.numeric.copyWith(
                fontSize: 28,
                height: 1,
                color: widget.enabled ? colors.ink : colors.inkDisabled,
              ),
            ),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) => Transform.translate(
                  offset: Offset(
                    math.sin(_shake.value * math.pi * 6) *
                        10 *
                        (1 - _shake.value),
                    0,
                  ),
                  child: child,
                ),
                child: Semantics(
                  liveRegion: true,
                  label: widget.labels.entered(entered, widget.length),
                  child: ExcludeSemantics(
                    child: _Dots(
                      length: widget.length,
                      filled: entered,
                      error: _shake.isAnimating,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: widget.busy
                    ? Center(child: _BusyDots(color: colors.accentIcon))
                    : null,
              ),
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ]) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, value) in row.indexed) ...[
                      if (i > 0) const SizedBox(width: PorcelainSpace.lg),
                      digit(value),
                    ],
                  ],
                ),
                const SizedBox(height: PorcelainSpace.md),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: key),
                  const SizedBox(width: PorcelainSpace.lg),
                  digit('0'),
                  const SizedBox(width: PorcelainSpace.lg),
                  _PinKey(
                    size: key,
                    quiet: true,
                    semanticLabel: widget.labels.delete,
                    onPressed: _accepting && entered > 0 ? _erase : null,
                    disabledReason:
                        reason ??
                        (entered == 0 && !widget.busy
                            ? widget.labels.deleteUnavailable
                            : null),
                    busy: widget.busy,
                    child: Icon(
                      PorcelainIcons.backspace,
                      size: 28,
                      color: _accepting && entered > 0
                          ? colors.inkMuted
                          : colors.inkDisabled,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.length,
    required this.filled,
    required this.error,
  });

  final int length;
  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final motion = PorcelainMotion.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < length; i++) ...[
          if (i > 0) const SizedBox(width: PorcelainSpace.md),
          AnimatedContainer(
            duration: motion.press,
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: i < filled && !error
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colors.primaryTop, colors.primaryBottom],
                    )
                  : null,
              color: error
                  ? colors.dangerSurface
                  : i < filled
                  ? null
                  : colors.inset,
              border: Border.all(
                color: error
                    ? colors.danger
                    : i < filled
                    ? colors.primaryEdge
                    : colors.outline,
                width: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({
    required this.size,
    required this.semanticLabel,
    required this.onPressed,
    required this.child,
    this.disabledReason,
    this.quiet = false,
    this.busy = false,
  });

  final double size;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final String? disabledReason;
  final Widget child;
  final bool quiet;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final motion = PorcelainMotion.of(context);
    final reason = disabledReason;
    return Pressable(
      onPressed: onPressed,
      busy: busy && onPressed == null && reason == null,
      semanticLabel: semanticLabel,
      disabledReason: reason,
      onDisabledTap: reason == null
          ? null
          : () => PorcelainToast.show(
              context,
              reason,
              icon: PorcelainIcons.locked,
            ),
      builder: (context, state) {
        final TactileLook look;
        if (state.pressed) {
          look = TactileLook(
            fillTop: colors.inset,
            fillBottom: colors.inset,
            border: colors.outline,
            inset: 0.7,
            travel: 1,
          );
        } else if (quiet) {
          final clear = colors.canvas.withValues(alpha: 0);
          look = TactileLook(
            fillTop: state.hovered ? colors.selected : clear,
            fillBottom: state.hovered ? colors.selected : clear,
          );
        } else {
          look = TactileLook(
            fillTop: state.enabled ? colors.raised : colors.disabledFill,
            fillBottom: state.enabled
                ? colors.raisedShade
                : colors.disabledFill,
            border: state.enabled ? colors.outline : colors.hairline,
            elevation: state.enabled ? PorcelainDepth.resting : 0,
            highlight: state.enabled ? 1 : 0,
          );
        }
        return TactileSurface(
          shape: TactileShape.circle,
          look: look,
          focused: state.focused,
          duration: state.pressed ? motion.press : motion.release,
          child: SizedBox.square(
            dimension: size,
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

/// Three gently pulsing dots: work in progress without a ticking spinner
/// in the reduced-motion case (shown still).
class _BusyDots extends StatefulWidget {
  const _BusyDots({required this.color});

  final Color color;

  @override
  State<_BusyDots> createState() => _BusyDotsState();
}

class _BusyDotsState extends State<_BusyDots>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PorcelainMotion.of(context).isReduced) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Opacity(
                opacity:
                    0.35 +
                    0.65 *
                        (0.5 +
                            0.5 *
                                math.sin((_pulse.value - i / 3) * 2 * math.pi)),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
