import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_motion.dart';

/// Interaction state handed to a [Pressable] builder.
@immutable
final class PressState {
  const PressState({
    required this.enabled,
    required this.pressed,
    required this.hovered,
    required this.focused,
  });

  final bool enabled;
  final bool pressed;
  final bool hovered;

  /// Keyboard focus is showing (not merely holding focus after a touch).
  final bool focused;
}

/// Forces the look of an interaction state on the enabled [Pressable]s
/// below it, so the component gallery and state goldens can show pressed,
/// hovered and focused looks side by side. Behaviour is unchanged.
class PressStatePreview extends InheritedWidget {
  const PressStatePreview({
    super.key,
    this.pressed = false,
    this.hovered = false,
    this.focused = false,
    required super.child,
  });

  final bool pressed;
  final bool hovered;
  final bool focused;

  static PressStatePreview? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PressStatePreview>();

  @override
  bool updateShouldNotify(PressStatePreview old) =>
      old.pressed != pressed ||
      old.hovered != hovered ||
      old.focused != focused;
}

/// Touch, pointer, keyboard and accessibility behaviour shared by every
/// Porcelain control; the look comes from [builder].
///
/// A control is disabled when [onPressed] is null. A disabled control is
/// still honest about why: [disabledReason] becomes its accessibility hint,
/// and tapping it calls [onDisabledTap] (typically showing the reason).
/// A [busy] control ignores presses while its work runs; it is not dead.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.semanticLabel,
    this.semanticHint,
    this.disabledReason,
    this.onDisabledTap,
    this.busy = false,
    this.selected,
    this.toggled,
    this.inMutuallyExclusiveGroup = false,
    this.autofocus = false,
    this.focusNode,
  });

  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, PressState state) builder;

  /// Replaces the children's semantics when given; otherwise the children's
  /// text is merged into one accessible control.
  final String? semanticLabel;
  final String? semanticHint;
  final String? disabledReason;
  final VoidCallback? onDisabledTap;
  final bool busy;
  final bool? selected;
  final bool? toggled;
  final bool inMutuallyExclusiveGroup;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _pressed = false;
  var _hovered = false;
  var _focused = false;
  Timer? _release;
  final _pressWatch = Stopwatch();
  FocusNode? _ownFocusNode;

  FocusNode get _focusNode =>
      widget.focusNode ??
      (_ownFocusNode ??= FocusNode(debugLabel: 'Pressable'));

  bool get _enabled => widget.onPressed != null;

  @override
  void didUpdateWidget(Pressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && (_pressed || _hovered || _focused)) {
      _release?.cancel();
      _pressed = _hovered = _focused = false;
    }
  }

  @override
  void dispose() {
    _release?.cancel();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _down() {
    if (!_enabled) return;
    _release?.cancel();
    _pressWatch
      ..reset()
      ..start();
    setState(() => _pressed = true);
  }

  /// Keeps the pressed look on screen for at least one press animation, so
  /// even a quick tap is visibly acknowledged.
  void _up() {
    if (!_pressed) return;
    final remaining = PorcelainMotion.of(context).press - _pressWatch.elapsed;
    if (remaining <= Duration.zero) {
      setState(() => _pressed = false);
      return;
    }
    _release = Timer(remaining, () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  void _activate() {
    final onPressed = widget.onPressed;
    if (onPressed == null) return;
    _down();
    _up();
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _enabled ? PressStatePreview.maybeOf(context) : null;
    final state = PressState(
      enabled: _enabled,
      pressed: _pressed || (preview?.pressed ?? false),
      hovered: _hovered || (preview?.hovered ?? false),
      focused: _focused || (preview?.focused ?? false),
    );
    Widget result = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTapDown: (_) => _down(),
      onTapUp: (_) => _up(),
      onTapCancel: _up,
      onTap: _enabled ? widget.onPressed : widget.onDisabledTap,
      child: widget.builder(context, state),
    );
    result = FocusableActionDetector(
      enabled: _enabled,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (_) => setState(() {}),
      mouseCursor: _enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      child: result,
    );
    final hint = _enabled
        ? widget.semanticHint
        : widget.disabledReason ?? widget.semanticHint;
    result = Semantics(
      container: true,
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      toggled: widget.toggled,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
      label: widget.semanticLabel,
      hint: hint,
      // Disabled controls leave focus semantics unset rather than false.
      focusable: _enabled ? true : null,
      focused: _enabled ? _focusNode.hasFocus : null,
      onFocus: _enabled ? _focusNode.requestFocus : null,
      onTap: widget.onPressed,
      excludeSemantics: widget.semanticLabel != null,
      child: result,
    );
    return widget.semanticLabel == null
        ? MergeSemantics(child: result)
        : result;
  }
}
