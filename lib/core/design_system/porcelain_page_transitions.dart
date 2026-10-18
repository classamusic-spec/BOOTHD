import 'package:flutter/material.dart';

import 'porcelain_motion.dart';

/// Route transition: the incoming page fades in while rising 16 dp; the
/// outgoing page fades back slightly. With reduced motion the page simply
/// appears (CR-001 item 7).
final class PorcelainPageTransitionsBuilder extends PageTransitionsBuilder {
  const PorcelainPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (PorcelainMotion.of(context).isReduced) return child;
    final enter = CurvedAnimation(
      parent: animation,
      curve: PorcelainMotion.enter,
      reverseCurve: PorcelainMotion.exit,
    );
    final behind = CurvedAnimation(
      parent: secondaryAnimation,
      curve: PorcelainMotion.ease,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.92).animate(behind),
      child: FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(enter),
          child: child,
        ),
      ),
    );
  }
}
