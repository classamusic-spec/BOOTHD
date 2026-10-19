import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../domain/session/guest_flow.dart';
import '../../shared/widgets/porcelain_button.dart';
import 'booth_copy.dart';
import 'guest_parts.dart';

/// S26 Rendering: a warm wait while the finished photo is made and saved.
/// Nothing claims it is saved yet (AC-0705), and there is nothing to
/// cancel: the photos are already safe.
class GuestRendering extends StatelessWidget {
  const GuestRendering({super.key});

  @override
  Widget build(BuildContext context) => const GuestNotice(
    title: BoothCopy.creatingTitle,
    body: BoothCopy.creatingBody,
    busy: true,
  );
}

/// After the booth left the foreground or the camera stopped: nothing
/// happens until the guest taps Continue, so no photo is ever taken late
/// (AC-0702).
class GuestPaused extends StatelessWidget {
  const GuestPaused({
    super.key,
    required this.photosSoFar,
    required this.onContinue,
  });

  /// Some photos of this session are already saved.
  final bool photosSoFar;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => GuestNotice(
    icon: PorcelainIcons.paused,
    title: BoothCopy.pausedTitle,
    body: photosSoFar
        ? '${BoothCopy.pausedSafe} ${BoothCopy.pausedBody}'
        : BoothCopy.pausedBody,
    actions: [
      PorcelainButton(
        label: BoothCopy.continueLabel,
        variant: PorcelainButtonVariant.primary,
        size: PorcelainButtonSize.guest,
        caps: true,
        onPressed: onContinue,
      ),
    ],
  );
}

/// S29 Guest-safe problem: plain words by kind, never a code; Try again
/// when the guest can, and always a way back to the start. Photos already
/// taken stay in storage either way.
class GuestProblemNotice extends StatelessWidget {
  const GuestProblemNotice({
    super.key,
    required this.problem,
    required this.photosSoFar,
    required this.onRetry,
    required this.onStartOver,
  });

  final GuestProblem problem;
  final bool photosSoFar;
  final VoidCallback onRetry;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    final (title, body) = BoothCopy.problem(problem.kind, photos: photosSoFar);
    return GuestNotice(
      icon: switch (problem.kind) {
        GuestProblemKind.camera ||
        GuestProblemKind.capture => PorcelainIcons.camera,
        GuestProblemKind.render => PorcelainIcons.image,
        GuestProblemKind.storage => PorcelainIcons.storage,
        GuestProblemKind.setup => PorcelainIcons.info,
      },
      title: title,
      body: body,
      actions: problem.recoverable
          ? [
              PorcelainButton(
                label: BoothCopy.startOver,
                size: PorcelainButtonSize.guest,
                caps: true,
                onPressed: onStartOver,
              ),
              PorcelainButton(
                label: BoothCopy.tryAgain,
                icon: PorcelainIcons.retry,
                variant: PorcelainButtonVariant.primary,
                size: PorcelainButtonSize.guest,
                caps: true,
                onPressed: onRetry,
              ),
            ]
          : [
              PorcelainButton(
                label: BoothCopy.done,
                variant: PorcelainButtonVariant.primary,
                size: PorcelainButtonSize.guest,
                caps: true,
                onPressed: onStartOver,
              ),
            ],
    );
  }
}
