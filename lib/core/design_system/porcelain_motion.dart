import 'package:flutter/widgets.dart';

/// Motion tokens (UX-01: tap 120–180 ms, modal about 200–260 ms).
///
/// Every animated component reads its durations from [PorcelainMotion.of],
/// which returns [reduced] (all zero) when the platform or the operator asks
/// for reduced motion, so nothing moves or slides (CR-001 item 7).
@immutable
final class PorcelainMotion {
  const PorcelainMotion._({
    required this.press,
    required this.release,
    required this.standard,
    required this.emphasized,
    required this.page,
    required this.stagger,
    required this.isReduced,
  });

  static const regular = PorcelainMotion._(
    press: Duration(milliseconds: 140),
    release: Duration(milliseconds: 180),
    standard: Duration(milliseconds: 240),
    emphasized: Duration(milliseconds: 320),
    page: Duration(milliseconds: 280),
    stagger: Duration(milliseconds: 40),
    isReduced: false,
  );

  static const reduced = PorcelainMotion._(
    press: Duration.zero,
    release: Duration.zero,
    standard: Duration.zero,
    emphasized: Duration.zero,
    page: Duration.zero,
    stagger: Duration.zero,
    isReduced: true,
  );

  /// Resolves motion for [context]: reduced when
  /// `MediaQuery.disableAnimations` is set (system setting or the operator's
  /// Appearance choice, applied at the app root).
  static PorcelainMotion of(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? reduced : regular;

  /// Pressing into a tactile control.
  final Duration press;

  /// Springing back after a press.
  final Duration release;

  /// Small state changes: selection, toggles, colour.
  final Duration standard;

  /// Larger entrances: sheets, section changes.
  final Duration emphasized;

  /// Route transitions, and each section of a page entering.
  final Duration page;

  /// Between one section of a page entering and the next.
  final Duration stagger;

  final bool isReduced;

  /// Decelerating entrance.
  static const Curve enter = Cubic(0.2, 0, 0, 1);

  /// Accelerating exit.
  static const Curve exit = Cubic(0.3, 0, 1, 1);

  /// General purpose.
  static const Curve ease = Curves.easeOutCubic;
}
