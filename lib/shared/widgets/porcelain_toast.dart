import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'tactile_surface.dart';
import 'tone.dart';

/// Brief, non-blocking messages, above everything (sheets included) and
/// never in the way: taps pass through a toast to whatever is beneath it.
/// Announced to screen readers; a new toast replaces the current one.
abstract final class PorcelainToast {
  static const displayDuration = Duration(seconds: 4);

  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    PorcelainTone tone = PorcelainTone.info,
    IconData? icon,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final previous = _current;
    if (previous != null && previous.mounted) previous.remove();
    final reduced = PorcelainMotion.of(context).isReduced;
    // The caller's theme, which may differ from the overlay's: Booth Mode
    // wears the event's.
    final theme = Theme.of(context);
    final width = math.min(560.0, MediaQuery.sizeOf(context).width - 48);
    late final OverlayEntry entry;
    void done() {
      if (identical(_current, entry)) _current = null;
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => Theme(
        data: theme,
        child: _ToastPresenter(
          width: width,
          reduceMotion: reduced,
          onDone: done,
          onDisposed: () {
            if (identical(_current, entry)) _current = null;
          },
          child: PorcelainToastCard(message: message, tone: tone, icon: icon),
        ),
      ),
    );
    _current = entry;
    overlay.insert(entry);
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }
}

/// Fades a toast in near the bottom, holds it for
/// [PorcelainToast.displayDuration], fades it out and removes it. The hold
/// timer is cancelled if the overlay goes away first.
class _ToastPresenter extends StatefulWidget {
  const _ToastPresenter({
    required this.width,
    required this.reduceMotion,
    required this.onDone,
    required this.onDisposed,
    required this.child,
  });

  final double width;
  final bool reduceMotion;
  final VoidCallback onDone;
  final VoidCallback onDisposed;
  final Widget child;

  @override
  State<_ToastPresenter> createState() => _ToastPresenterState();
}

class _ToastPresenterState extends State<_ToastPresenter>
    with SingleTickerProviderStateMixin {
  late final _fade = AnimationController(
    vsync: this,
    duration: widget.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200),
  );
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    _fade.forward();
    _hold = Timer(PorcelainToast.displayDuration, () {
      if (!mounted) return;
      _fade.reverse().whenComplete(() {
        if (mounted) widget.onDone();
      });
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _fade.dispose();
    widget.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    return Positioned(
      left: PorcelainSpace.xl,
      right: PorcelainSpace.xl,
      bottom: PorcelainSpace.xl + padding.bottom,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SizedBox(width: widget.width, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// The visual of a toast; public so the component gallery can show it.
class PorcelainToastCard extends StatelessWidget {
  const PorcelainToastCard({
    super.key,
    required this.message,
    this.tone = PorcelainTone.info,
    this.icon,
  });

  final String message;
  final PorcelainTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return TactileSurface(
      duration: Duration.zero,
      radius: PorcelainRadius.control,
      look: TactileLook(
        fillTop: colors.raised,
        fillBottom: colors.surface,
        border: colors.hairline,
        elevation: PorcelainDepth.overlay,
        highlight: 1,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PorcelainSpace.lg,
          vertical: PorcelainSpace.md,
        ),
        child: Row(
          children: [
            Icon(
              icon ?? tone.icon,
              color: tone.foreground(colors),
              size: PorcelainSize.icon,
              fill: 1,
            ),
            const SizedBox(width: PorcelainSpace.sm),
            Expanded(child: Text(message, style: theme.text.bodyLarge)),
          ],
        ),
      ),
    );
  }
}
