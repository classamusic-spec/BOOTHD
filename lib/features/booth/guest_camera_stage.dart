import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/design_system/porcelain_colors.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/experience/live_template.dart';
import '../../domain/experience/experience_pack.dart';
import '../../domain/session/countdown_state.dart';
import '../../shared/guest/guest_countdown.dart';
import '../../shared/guest/guest_layout.dart';
import '../../shared/guest/guest_words.dart';
import '../../shared/widgets/porcelain_spinner.dart';
import 'booth_copy.dart';
import 'guest_parts.dart';

/// What the camera screen is doing (S22 to S24).
enum CameraStep {
  /// Opening the camera before a countdown (S22).
  preparing,

  /// Counting down (S23).
  countdown,

  /// The photo is being taken and saved (S24).
  capturing,

  /// A photo was saved; the next follows shortly (S24).
  saved,
}

/// One mark in the shot progress.
@immutable
final class ShotMark {
  const ShotMark.upcoming() : photo = null, current = false;
  const ShotMark.current() : photo = null, current = true;
  const ShotMark.done(Future<Uint8List> this.photo) : current = false;

  /// The saved photo, once this shot is taken.
  final Future<Uint8List>? photo;

  /// The shot being taken now.
  final bool current;
}

/// S22 to S24 (CR-002): the live picture in a porcelain frame with a
/// plaque below it, which shows the countdown numeral, then "Snap!" with a
/// soft flash, then a check while the next photo comes up; the progress
/// of the session's photos, with each saved photo's thumbnail, beside or
/// below it. Portrait or landscape from the space the screen actually has.
///
/// No controls: guests only pose. The photo is shown as saved only once
/// the original is durably stored.
class GuestCameraStage extends StatelessWidget {
  const GuestCameraStage({
    super.key,
    required this.step,
    required this.secondsLeft,
    required this.shotNumber,
    required this.shotCount,
    required this.retaking,
    required this.marks,
    required this.preview,
    required this.previewAspect,
    required this.mirroredPhotos,
    required this.flashKey,
    this.countdownSeconds = 3,
    this.liveTemplate,
  });

  final CameraStep step;
  final int secondsLeft;

  /// 1-based.
  final int shotNumber;
  final int shotCount;

  /// The shot is being taken again (a per-photo retake).
  final bool retaking;
  final List<ShotMark> marks;

  /// The live picture, or null while the camera opens.
  final Widget? preview;

  /// Long side over short side of the live picture.
  final double previewAspect;

  /// Thumbnails show photos as the finished photo will.
  final bool mirroredPhotos;

  /// Changes with every photo taken, so the flash plays each time.
  final Object flashKey;

  /// The full countdown, so the pack's countdown can show its progress.
  final int countdownSeconds;

  /// Full Template mode (EP06): the session's template around the live
  /// picture. Null shows the camera-focused stage.
  final LiveTemplate? liveTemplate;

  String _shotLabelIn(BuildContext context) => retaking
      ? BoothCopy.retaking(shotNumber)
      : context.guestCopy.shotProgress(shotNumber, shotCount);

  @override
  Widget build(BuildContext context) {
    return GuestBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = GuestScale.forSize(constraints.biggest);
            final landscape = constraints.maxWidth > constraints.maxHeight;
            return landscape
                ? _landscape(context, constraints, scale)
                : _portrait(context, constraints, scale);
          },
        ),
      ),
    );
  }

  /// Heading on top, the picture with its plaque, the progress below.
  Widget _portrait(
    BuildContext context,
    BoxConstraints constraints,
    GuestScale scale,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: scale(PorcelainSpace.huge),
        vertical: scale(PorcelainSpace.xl),
      ),
      child: Column(
        children: [
          GuestHeading(
            eyebrow: _shotLabelIn(context),
            title: step == CameraStep.saved
                ? context.guestCopy[GuestCopyKey.lovely]
                : context.guestCopy[GuestCopyKey.getReady],
            scale: scale,
          ),
          SizedBox(height: scale(PorcelainSpace.lg)),
          Expanded(
            child: _Picture(
              stage: this,
              scale: scale,
              portrait: true,
              plaqueHeight: scale(230),
            ),
          ),
          SizedBox(height: scale(PorcelainSpace.lg)),
          _Progress(
            marks: marks,
            scale: scale,
            vertical: false,
            mirrored: mirroredPhotos,
            label: _shotLabelIn(context),
          ),
        ],
      ),
    );
  }

  /// The progress at the side, the picture with its plaque in the middle
  /// (the plaque says "Get ready!" before the countdown).
  Widget _landscape(
    BuildContext context,
    BoxConstraints constraints,
    GuestScale scale,
  ) {
    final theme = context.porcelain;
    final side = scale(140);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: scale(PorcelainSpace.xxl),
        vertical: scale(PorcelainSpace.xl),
      ),
      child: Row(
        children: [
          SizedBox(
            width: side,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Progress(
                  marks: marks,
                  scale: scale,
                  vertical: true,
                  mirrored: mirroredPhotos,
                  label: _shotLabelIn(context),
                ),
                SizedBox(height: scale(PorcelainSpace.sm)),
                ExcludeSemantics(
                  child: Text(
                    _shotLabelIn(context),
                    textAlign: TextAlign.center,
                    style: scale.text(theme.text.guestCaption),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: scale(PorcelainSpace.xl)),
          Expanded(
            child: _Picture(
              stage: this,
              scale: scale,
              portrait: false,
              plaqueHeight: scale(200),
            ),
          ),
          SizedBox(width: scale(PorcelainSpace.xl) + side),
        ],
      ),
    );
  }
}

/// The viewfinder at the picture's own shape, as large as fits, with the
/// plaque overlapping its lower edge.
class _Picture extends StatelessWidget {
  const _Picture({
    required this.stage,
    required this.scale,
    required this.portrait,
    required this.plaqueHeight,
  });

  final GuestCameraStage stage;
  final GuestScale scale;
  final bool portrait;
  final double plaqueHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, area) {
        final overlap = plaqueHeight * 0.3;
        // The live picture stands the way the screen does; in Full
        // Template mode the stage takes the template's page shape.
        final live = stage.liveTemplate;
        final shape = live != null && stage.preview != null
            ? live.scene.widthPx / live.scene.heightPx
            : portrait
            ? 1 / stage.previewAspect
            : stage.previewAspect;
        final maxHeight = math.max(
          0.0,
          area.maxHeight - (plaqueHeight - overlap),
        );
        // The viewfinder's rim surrounds the picture: the picture, not
        // the frame, keeps the shape (a template page shows no gap).
        final rim = 2 * scale(10);
        var width = area.maxWidth;
        var height = (width - rim) / shape + rim;
        if (height > maxHeight) {
          height = maxHeight;
          width = (height - rim) * shape + rim;
        }
        final plaqueWidth = math.min(
          math.max(width * 0.84, scale(320)),
          math.min(area.maxWidth, scale(560)),
        );
        return Center(
          child: SizedBox(
            width: math.max(width, plaqueWidth),
            height: height + plaqueHeight - overlap,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 0,
                  width: width,
                  height: height,
                  child: GuestViewfinder(
                    scale: scale,
                    child: _Live(stage: stage, portrait: portrait),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  width: plaqueWidth,
                  height: plaqueHeight,
                  child: GuestPlaque(
                    width: plaqueWidth,
                    height: plaqueHeight,
                    child: _PlaqueContent(
                      stage: stage,
                      height: plaqueHeight,
                      showTitle: !portrait,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The live picture (or a quiet wait while the camera opens) and the
/// flash when a photo is taken.
class _Live extends StatelessWidget {
  const _Live({required this.stage, required this.portrait});

  final GuestCameraStage stage;
  final bool portrait;

  @override
  Widget build(BuildContext context) {
    final preview = stage.preview;
    final live = stage.liveTemplate;
    final flash =
        stage.step == CameraStep.capturing &&
        !PorcelainMotion.of(context).isReduced;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (preview != null && live != null)
          Center(
            child: LiveTemplateStage(
              template: live,
              preview: preview,
              previewAspect: portrait
                  ? 1 / stage.previewAspect
                  : stage.previewAspect,
            ),
          )
        else if (preview != null)
          // Centred, so the picture keeps its own shape: never stretched.
          Center(child: preview)
        else
          const Center(
            child: PorcelainSpinner(color: PorcelainViewfinder.ink, size: 40),
          ),
        if (flash) _Flash(key: ValueKey(stage.flashKey)),
      ],
    );
  }
}

/// A soft white flash that fades out once.
class _Flash extends StatelessWidget {
  const _Flash({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 0),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, opacity, _) => ColoredBox(
          color: PorcelainViewfinder.ink.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _PlaqueContent extends StatelessWidget {
  const _PlaqueContent({
    required this.stage,
    required this.height,
    required this.showTitle,
  });

  final GuestCameraStage stage;
  final double height;

  /// Landscape has no heading above the picture: the plaque says it.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    final unit = height / 230;
    final message = theme.text.guestBody.copyWith(fontSize: 24 * unit);
    final serif = theme.text.guestTitle.copyWith(
      fontSize: 56 * unit,
      color: colors.guestAccentText,
    );

    final Widget content = switch (stage.step) {
      CameraStep.preparing => Column(
        key: const ValueKey('preparing'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitle)
            Text(context.guestCopy[GuestCopyKey.getReady], style: serif),
          if (stage.preview == null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PorcelainSpinner(
                  color: colors.guestAccentText,
                  size: 26 * unit,
                ),
                SizedBox(width: 12 * unit),
                Flexible(child: Text(BoothCopy.openingCamera, style: message)),
              ],
            )
          else
            Text(context.guestCopy[GuestCopyKey.lookHere], style: message),
        ],
      ),
      CameraStep.countdown => Semantics(
        key: const ValueKey('countdown'),
        liveRegion: true,
        label: BoothCopy.countdownLabel(stage.secondsLeft),
        // The pack's countdown (EP03, EP06): drawn from the controller's
        // state only; it cannot move the photo.
        child: GuestCountdown(
          size: 190 * unit,
          state: CountdownState(
            remaining: stage.secondsLeft,
            total: math.max(stage.countdownSeconds, stage.secondsLeft),
            shot: stage.shotNumber - 1,
            shotCount: stage.shotCount,
          ),
        ),
      ),
      CameraStep.capturing => Column(
        key: const ValueKey('capturing'),
        mainAxisSize: MainAxisSize.min,
        children: [
          GuestEmblem(
            scale: GuestScale(unit),
            icon: PorcelainIcons.camera,
            size: 96,
          ),
          SizedBox(height: 10 * unit),
          Text(
            context.guestCopy[GuestCopyKey.snap],
            style: serif.copyWith(fontSize: 44 * unit),
          ),
        ],
      ),
      CameraStep.saved => Column(
        key: const ValueKey('saved'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitle)
            Text(context.guestCopy[GuestCopyKey.lovely], style: serif),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PorcelainIcons.success,
                size: 32 * unit,
                color: colors.guestAccentText,
                fill: 1,
              ),
              SizedBox(width: 10 * unit),
              Flexible(
                child: Text(
                  context.guestCopy[GuestCopyKey.nextPhotoSoon],
                  style: message,
                ),
              ),
            ],
          ),
        ],
      ),
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24 * unit),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: AnimatedSwitcher(duration: motion.standard, child: content),
      ),
    );
  }
}

/// The session's photos as marks: saved ones show their thumbnail, the
/// current one a gold ring, later ones their number. Read as one line.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.marks,
    required this.scale,
    required this.vertical,
    required this.mirrored,
    required this.label,
  });

  final List<ShotMark> marks;
  final GuestScale scale;
  final bool vertical;
  final bool mirrored;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Flex(
          direction: vertical ? Axis.vertical : Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, mark) in marks.indexed)
              Padding(
                padding: EdgeInsets.all(scale(PorcelainSpace.xs)),
                child: _Mark(
                  mark: mark,
                  number: i + 1,
                  scale: scale,
                  mirrored: mirrored,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({
    required this.mark,
    required this.number,
    required this.scale,
    required this.mirrored,
  });

  final ShotMark mark;
  final int number;
  final GuestScale scale;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final size = scale(72);
    final photo = mark.photo;
    if (photo != null) {
      return GuestPrint(
        scale: scale,
        border: 4,
        child: SizedBox.square(
          dimension: size - scale(8),
          child: GuestPhoto(bytes: photo, mirrored: mirrored),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.inset,
        borderRadius: BorderRadius.circular(scale(14)),
        border: Border.all(
          color: mark.current ? colors.primaryEdge : colors.hairline,
          width: mark.current ? 3 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: scale.text(
          theme.text.guestLabel.copyWith(
            fontSize: 26,
            color: mark.current ? colors.guestAccentText : colors.inkMuted,
          ),
        ),
      ),
    );
  }
}
