import 'package:flutter/painting.dart';

/// Spacing scale on a 4 dp base (UX-01).
abstract final class PorcelainSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double giant = 64;
}

/// Corner radii (UX-01).
abstract final class PorcelainRadius {
  static const double control = 16;
  static const double card = 24;
  static const double dialog = 28;

  static const BorderRadius controlAll = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius dialogAll = BorderRadius.all(
    Radius.circular(dialog),
  );
}

/// Component sizes. Touch targets use Android's 48 dp, which also exceeds
/// Apple's 44 pt (CR-001 item 2).
abstract final class PorcelainSize {
  static const double minTouchTarget = 48;

  /// Guest primary actions are at least 72 dp (UX-01).
  static const double guestPrimaryMinimum = 72;

  /// The round guest Start control.
  static const double guestStartDiameter = 216;

  static const double buttonCompact = 48;
  static const double buttonRegular = 56;
  static const double buttonLarge = 64;

  static const double iconSmall = 20;
  static const double icon = 24;
  static const double iconLarge = 32;

  /// Focus ring: stroke width and gap from the control's edge.
  static const double focusRingWidth = 2;
  static const double focusRingGap = 3;
}

/// Layout breakpoints, applied to the space a layout actually receives
/// (ADR-0004), never to the device's nominal orientation.
abstract final class PorcelainBreakpoints {
  /// Window width from which Studio shows the full sidebar instead of the
  /// compact rail.
  static const double sidebar = 1100;

  /// Content widths.
  static const double medium = 600;
  static const double expanded = 900;

  /// Widest content column; wider windows add margin instead.
  static const double maxContentWidth = 1180;

  static const double sidebarWidth = 280;
  static const double compactRailWidth = 104;
}
