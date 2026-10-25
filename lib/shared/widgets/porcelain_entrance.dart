import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_motion.dart';

/// Brings a page's sections in when the page first appears (UX-P1): each
/// [EntranceItem] or [EntranceSliver] below fades in and rises a little, a
/// beat after the one before. Nothing moves with reduced motion.
///
/// The widget tree is the same before, during and after the entrance, so
/// no state is lost, and every section is in the semantics tree and can be
/// tapped throughout.
class PorcelainEntrance extends StatefulWidget {
  const PorcelainEntrance({super.key, required this.child});

  final Widget child;

  /// How many sections enter one after another; later ones enter with the
  /// last of these.
  static const staggered = 5;

  @override
  State<PorcelainEntrance> createState() => _PorcelainEntranceState();
}

class _PorcelainEntranceState extends State<PorcelainEntrance>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = PorcelainMotion.of(context);
    if (motion.isReduced) {
      _controller.value = 1;
    } else {
      _controller
        ..duration = _total(motion)
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _EntranceScope(animation: _controller, child: widget.child);
}

Duration _total(PorcelainMotion motion) =>
    motion.page + motion.stagger * (PorcelainEntrance.staggered - 1);

class _EntranceScope extends InheritedWidget {
  const _EntranceScope({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_EntranceScope oldWidget) =>
      animation != oldWidget.animation;
}

/// The progress of the [index]th section of the nearest [PorcelainEntrance]
/// (complete outside one).
mixin _EntranceProgress<T extends StatefulWidget> on State<T> {
  int get index;

  Animation<double>? _parent;
  late Animation<double> progress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parent =
        context
            .dependOnInheritedWidgetOfExactType<_EntranceScope>()
            ?.animation ??
        kAlwaysCompleteAnimation;
    if (parent != _parent) {
      _parent = parent;
      _drive();
    }
  }

  void _drive() {
    // Fractions of the regular timing; with reduced motion the entrance is
    // already complete, wherever each section's interval lies.
    const motion = PorcelainMotion.regular;
    final total = _total(motion).inMicroseconds;
    final step = index.clamp(0, PorcelainEntrance.staggered - 1);
    final start = (motion.stagger * step).inMicroseconds / total;
    final end = start + motion.page.inMicroseconds / total;
    progress = _parent!.drive(
      CurveTween(
        curve: Interval(
          start,
          end.clamp(start, 1),
          curve: PorcelainMotion.enter,
        ),
      ),
    );
  }
}

/// One section of a [PorcelainEntrance], the [index]th to enter.
class EntranceItem extends StatefulWidget {
  const EntranceItem({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  /// How far a section rises as it enters.
  static const rise = 16.0;

  @override
  State<EntranceItem> createState() => _EntranceItemState();
}

class _EntranceItemState extends State<EntranceItem>
    with _EntranceProgress<EntranceItem> {
  @override
  int get index => widget.index;

  @override
  void didUpdateWidget(EntranceItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _drive();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: progress,
    alwaysIncludeSemantics: true,
    child: _Rise(progress: progress, child: widget.child),
  );
}

class _Rise extends AnimatedWidget {
  const _Rise({required Animation<double> progress, required this.child})
    : super(listenable: progress);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Transform.translate(
      offset: Offset(0, (1 - t) * EntranceItem.rise),
      child: child,
    );
  }
}

/// A sliver section of a [PorcelainEntrance], the [index]th to enter: it
/// fades in.
class EntranceSliver extends StatefulWidget {
  const EntranceSliver({super.key, required this.index, required this.sliver});

  final int index;
  final Widget sliver;

  @override
  State<EntranceSliver> createState() => _EntranceSliverState();
}

class _EntranceSliverState extends State<EntranceSliver>
    with _EntranceProgress<EntranceSliver> {
  @override
  int get index => widget.index;

  @override
  void didUpdateWidget(EntranceSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _drive();
  }

  @override
  Widget build(BuildContext context) => SliverFadeTransition(
    opacity: progress,
    alwaysIncludeSemantics: true,
    sliver: widget.sliver,
  );
}
