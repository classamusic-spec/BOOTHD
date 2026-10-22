import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../domain/experience/experience_pack.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/session/session_shots.dart';
import '../../shared/guest/guest_button.dart';
import '../../shared/guest/guest_layout.dart';
import '../../shared/guest/guest_words.dart';
import 'booth_copy.dart';
import 'guest_parts.dart';

/// S25 Review (CR-001 fix 10, CR-002): the photos as they will be used,
/// each a small print; under each, Retake while the event's policy allows
/// and how many retakes are left; Keep these, and with a whole-session
/// policy Retake all after a confirmation. A retake is always a new photo:
/// the earlier one is kept in storage (AC-0703).
class GuestReview extends StatefulWidget {
  const GuestReview({
    super.key,
    required this.shots,
    required this.photo,
    required this.aspect,
    required this.mirrored,
    required this.onRetake,
    required this.onRetakeAll,
    required this.onKeep,
  });

  final SessionShots shots;

  /// The bytes of an original, by id.
  final Future<Uint8List> Function(String originalId) photo;

  /// Width over height of an original, when known.
  final double? Function(String originalId) aspect;

  /// Photos are shown as the finished photo uses them.
  final bool mirrored;
  final ValueChanged<int> onRetake;
  final VoidCallback onRetakeAll;
  final VoidCallback onKeep;

  @override
  State<GuestReview> createState() => _GuestReviewState();
}

class _GuestReviewState extends State<GuestReview> {
  var _confirming = false;

  @override
  Widget build(BuildContext context) {
    final shots = widget.shots;
    final policy = shots.plan.capture.retakePolicy;
    final one = shots.shotCount == 1;
    return GuestBackdrop(
      child: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = GuestScale.forSize(constraints.biggest);
                  final landscape =
                      constraints.maxWidth > constraints.maxHeight;
                  final heading = GuestHeading(
                    title: one
                        ? BoothCopy.reviewTitleOne
                        : context.guestCopy[GuestCopyKey.reviewTitle],
                    scale: scale,
                  );
                  final photos = _Photos(
                    review: widget,
                    scale: scale,
                    perShot: policy == RetakePolicy.perShot,
                  );
                  final actions = _Actions(
                    shots: shots,
                    scale: scale,
                    one: one,
                    vertical: landscape,
                    onKeep: widget.onKeep,
                    onRetakeAll: policy == RetakePolicy.wholeSession
                        ? () => setState(() => _confirming = true)
                        : null,
                  );
                  if (landscape) {
                    // Wider on the right, clear of the garland there.
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        scale(PorcelainSpace.huge),
                        scale(PorcelainSpace.xl),
                        scale(PorcelainSpace.giant + PorcelainSpace.xxl),
                        scale(PorcelainSpace.xl),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 7, child: photos),
                          SizedBox(width: scale(PorcelainSpace.xxl)),
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  heading,
                                  SizedBox(height: scale(PorcelainSpace.xxl)),
                                  actions,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: scale(PorcelainSpace.huge),
                      vertical: scale(PorcelainSpace.xl),
                    ),
                    child: Column(
                      children: [
                        heading,
                        SizedBox(height: scale(PorcelainSpace.xl)),
                        Expanded(child: photos),
                        SizedBox(height: scale(PorcelainSpace.xl)),
                        actions,
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (_confirming)
            Positioned.fill(
              child: _ConfirmRetakeAll(
                roundsLeft: shots.roundsLeft,
                onCancel: () => setState(() => _confirming = false),
                onConfirm: () {
                  setState(() => _confirming = false);
                  widget.onRetakeAll();
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// The photos in one row (or two rows of two), each a small print turned
/// a little, with its retake control under it.
class _Photos extends StatelessWidget {
  const _Photos({
    required this.review,
    required this.scale,
    required this.perShot,
  });

  final GuestReview review;
  final GuestScale scale;
  final bool perShot;

  static const _angles = [-0.045, 0.02, -0.025, 0.04];

  @override
  Widget build(BuildContext context) {
    final shots = review.shots;
    final count = shots.shotCount;
    // The photos' usual shape: the first one's, or a portrait 3:4.
    final first = shots.selected(0);
    final aspect =
        (first == null ? null : review.aspect(first.originalId)) ?? 3 / 4;
    return LayoutBuilder(
      builder: (context, area) {
        final gap = scale(PorcelainSpace.xl);
        // Retake (a guest button, not scaled), its gaps and its caption.
        final controls = perShot
            ? GuestButtonSize.regular.height + scale(PorcelainSpace.md * 2 + 32)
            : scale(36);
        // As many columns as make the photos largest.
        var columns = 1;
        var best = 0.0;
        for (var c = 1; c <= count; c++) {
          final rows = (count / c).ceil();
          final width = (area.maxWidth - gap * (c - 1)) / c;
          final height = (area.maxHeight - gap * (rows - 1)) / rows - controls;
          final size = math.min(width, height * aspect);
          if (size > best + 1) {
            best = size;
            columns = c;
          }
        }
        final rows = (count / columns).ceil();
        final cellWidth = (area.maxWidth - gap * (columns - 1)) / columns;
        final cellHeight = math.max(
          (area.maxHeight - gap * (rows - 1)) / rows,
          scale(140) + controls,
        );
        return Center(
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var shot = 0; shot < count; shot++)
                  SizedBox(
                    width: cellWidth,
                    height: cellHeight,
                    child: _ReviewPhoto(
                      review: review,
                      shot: shot,
                      angle: _angles[shot % _angles.length],
                      scale: scale,
                      perShot: perShot,
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

class _ReviewPhoto extends StatelessWidget {
  const _ReviewPhoto({
    required this.review,
    required this.shot,
    required this.angle,
    required this.scale,
    required this.perShot,
  });

  final GuestReview review;
  final int shot;
  final double angle;
  final GuestScale scale;
  final bool perShot;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final shots = review.shots;
    final selected = shots.selected(shot);
    final border = scale(10);
    final aspect =
        (selected == null ? null : review.aspect(selected.originalId)) ?? 3 / 4;
    final left = shots.retakesLeft(shot);
    final number = shot + 1;
    // The controls take what they need (a pack's button face may be
    // deeper than another's); the print fills the rest of the cell.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: LayoutBuilder(
            builder: (context, box) {
              var width = box.maxWidth * 0.9;
              var height = (width - 2 * border) / aspect + 2 * border;
              if (height > box.maxHeight) {
                height = box.maxHeight;
                width = (height - 2 * border) * aspect + 2 * border;
              }
              return Semantics(
                label: BoothCopy.photoNumber(number),
                image: true,
                child: GuestPrint(
                  scale: scale,
                  angle: angle,
                  child: SizedBox(
                    width: math.max(0, width - 2 * border),
                    height: math.max(0, height - 2 * border),
                    child: selected == null
                        ? const SizedBox.shrink()
                        : GuestPhoto(
                            bytes: review.photo(selected.originalId),
                            mirrored: review.mirrored,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: scale(PorcelainSpace.md)),
        if (perShot) ...[
          if (shots.canRetake(shot))
            GuestButton(
              label: context.guestCopy[GuestCopyKey.retake],
              icon: PorcelainIcons.retake,
              size: GuestButtonSize.regular,
              caps: true,
              semanticHint: BoothCopy.photoNumber(number),
              onPressed: () => review.onRetake(shot),
              emphasis: GuestButtonEmphasis.secondary,
            ),
          // Clear of the button's shadow, which reaches below its bounds.
          SizedBox(height: scale(PorcelainSpace.md)),
          Text(
            left > 0 ? BoothCopy.retakesLeft(left) : BoothCopy.noRetakesLeft,
            textAlign: TextAlign.center,
            style: scale.text(theme.text.guestCaption),
          ),
        ],
      ],
    );
  }
}

/// Keep these (primary), and Retake all for a whole-session policy.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.shots,
    required this.scale,
    required this.one,
    required this.vertical,
    required this.onKeep,
    required this.onRetakeAll,
  });

  final SessionShots shots;
  final GuestScale scale;
  final bool one;
  final bool vertical;
  final VoidCallback onKeep;

  /// Null when the policy has no whole-set retakes.
  final VoidCallback? onRetakeAll;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final onRetakeAll = this.onRetakeAll;
    final keep = GuestButton(
      label: one
          ? context.guestCopy[GuestCopyKey.keepIt]
          : context.guestCopy[GuestCopyKey.keepThese],
      icon: PorcelainIcons.check,
      size: GuestButtonSize.large,
      caps: true,
      expand: vertical,
      onPressed: onKeep,
    );
    final Widget? retakeAll = onRetakeAll == null
        ? null
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (shots.canRetakeAll)
                GuestButton(
                  label: context.guestCopy[GuestCopyKey.retakeAll],
                  icon: PorcelainIcons.retake,
                  size: GuestButtonSize.large,
                  caps: true,
                  expand: vertical,
                  onPressed: onRetakeAll,
                  emphasis: GuestButtonEmphasis.secondary,
                ),
              SizedBox(height: scale(PorcelainSpace.md)),
              Text(
                shots.roundsLeft > 0
                    ? BoothCopy.retakesLeft(shots.roundsLeft)
                    : BoothCopy.noRetakesLeft,
                style: scale.text(theme.text.guestCaption),
              ),
            ],
          );
    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          keep,
          if (retakeAll != null) ...[
            SizedBox(height: scale(PorcelainSpace.lg)),
            retakeAll,
          ],
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.start,
      spacing: scale(PorcelainSpace.xl),
      runSpacing: scale(PorcelainSpace.md),
      children: [?retakeAll, keep],
    );
  }
}

/// The guest confirms before the whole set is taken again (CR-001 fix
/// 10). Part of the review screen, so it disappears with it.
class _ConfirmRetakeAll extends StatelessWidget {
  const _ConfirmRetakeAll({
    required this.roundsLeft,
    required this.onCancel,
    required this.onConfirm,
  });

  final int roundsLeft;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motion.standard,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: ColoredBox(
        color: colors.scrim,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = GuestScale.forSize(constraints.biggest);
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(scale(PorcelainSpace.xl)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: scale(700)),
                  child: Semantics(
                    scopesRoute: true,
                    namesRoute: true,
                    explicitChildNodes: true,
                    label: BoothCopy.confirmRetakeTitle,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: PorcelainRadius.dialogAll,
                        border: Border.all(color: colors.primaryEdge),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadowKey,
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: scale(PorcelainSpace.xl),
                          vertical: scale(PorcelainSpace.xxl),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GuestHeading(
                              title: BoothCopy.confirmRetakeTitle,
                              scale: scale,
                            ),
                            SizedBox(height: scale(PorcelainSpace.md)),
                            Text(
                              BoothCopy.confirmRetakeBody,
                              textAlign: TextAlign.center,
                              style: scale.text(theme.text.guestBody),
                            ),
                            SizedBox(height: scale(PorcelainSpace.xs)),
                            Text(
                              BoothCopy.retakesLeft(roundsLeft),
                              textAlign: TextAlign.center,
                              style: scale.text(theme.text.guestCaption),
                            ),
                            SizedBox(height: scale(PorcelainSpace.xxl)),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: scale(PorcelainSpace.lg),
                              runSpacing: scale(PorcelainSpace.md),
                              children: [
                                GuestButton(
                                  label: BoothCopy.cancel,
                                  size: GuestButtonSize.large,
                                  caps: true,
                                  onPressed: onCancel,
                                  emphasis: GuestButtonEmphasis.secondary,
                                ),
                                GuestButton(
                                  label:
                                      context.guestCopy[GuestCopyKey.retakeAll],
                                  icon: PorcelainIcons.retake,
                                  size: GuestButtonSize.large,
                                  caps: true,
                                  onPressed: onConfirm,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
