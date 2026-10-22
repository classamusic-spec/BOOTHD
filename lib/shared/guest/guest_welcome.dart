import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/experience/guest_cues.dart';
import '../../core/experience/guest_experience.dart';
import '../../domain/experience/experience_catalog.dart';
import '../../domain/experience/experience_pack.dart';
import 'guest_button.dart';
import 'guest_layout.dart';
import 'guest_start_button.dart';
import 'guest_welcome_sample.dart';

/// Words on the guest welcome screen (S20). Supplied by the caller, so the
/// event can personalise them and they can be localised.
@immutable
final class GuestWelcomeCopy {
  const GuestWelcomeCopy({
    required this.wordmark,
    required this.wordmarkSubtitle,
    required this.title,
    required this.steps,
    required this.startLabel,
    this.eyebrow,
    this.subtitle,
    this.startPrompt,
    this.startHint,
    this.privacyNote,
  });

  /// The booth's name over its spaced subtitle ("Porcelain", "Photo booth").
  final String wordmark;
  final String wordmarkSubtitle;

  /// A small line above the title, such as the event and its date.
  final String? eyebrow;
  final String title;
  final String? subtitle;

  /// The step guide, in order: photo booth, pose, smile, enjoy. Never
  /// promises a print (CR-001 fix 8).
  final List<String> steps;
  final String startLabel;

  /// The small line on the Start button above its label ("Tap to").
  final String? startPrompt;
  final String? startHint;
  final String? privacyNote;
}

/// The guest welcome screen (S20, CR-002): the booth's wordmark, a warm
/// title, the pearl Start button, an optional preview of the event's own
/// template and a quiet step guide, in portrait or landscape depending on
/// the space available. It has exactly one control (AC-0210).
class GuestWelcome extends StatelessWidget {
  const GuestWelcome({
    super.key,
    required this.copy,
    required this.onStart,
    this.preview,
  });

  final GuestWelcomeCopy copy;
  final VoidCallback onStart;

  /// What a finished print looks like, e.g. the event's template; shown
  /// beside the title when there is room.
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = GuestScale.forSize(constraints.biggest);
        return GuestLayout(
          header: _Wordmark(copy: copy, scale: scale),
          message: _Message(copy: copy, scale: scale),
          action: _StartAction(copy: copy, scale: scale, onStart: onStart),
          preview: preview == null
              ? null
              : _TiltedPrint(scale: scale, child: preview!),
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepGuide(steps: copy.steps, scale: scale),
              if (copy.privacyNote != null) ...[
                SizedBox(height: scale(PorcelainSpace.lg)),
                _PrivacyNote(text: copy.privacyNote!, scale: scale),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.copy, required this.scale});

  final GuestWelcomeCopy copy;
  final GuestScale scale;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return Semantics(
      label: '${copy.wordmark} ${copy.wordmarkSubtitle}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              copy.wordmark.toUpperCase(),
              textAlign: TextAlign.center,
              style: scale.text(
                theme.text.guestTitle.copyWith(
                  fontSize: 44,
                  height: 1,
                  letterSpacing: 4,
                  color: colors.guestAccentText,
                ),
              ),
            ),
            SizedBox(height: scale(PorcelainSpace.xs)),
            Text(
              copy.wordmarkSubtitle.toUpperCase(),
              textAlign: TextAlign.center,
              style: scale.text(
                theme.text.guestLabel.copyWith(
                  fontSize: 15,
                  letterSpacing: 6,
                  color: colors.guestAccentText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.copy, required this.scale});

  final GuestWelcomeCopy copy;
  final GuestScale scale;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final eyebrow = copy.eyebrow;
    final subtitle = copy.subtitle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow.toUpperCase(),
            textAlign: TextAlign.center,
            style: scale.text(
              theme.text.guestLabel.copyWith(
                fontSize: 16,
                color: colors.guestAccentText,
                letterSpacing: 3,
              ),
            ),
          ),
          SizedBox(height: scale(PorcelainSpace.sm)),
        ],
        // A narrow measure breaks the title into a classic block of two or
        // three lines.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: scale(500)),
          child: Semantics(
            header: true,
            child: Text(
              copy.title,
              textAlign: TextAlign.center,
              style: scale.text(
                theme.text.guestTitle.copyWith(color: colors.guestAccentText),
              ),
            ),
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: scale(PorcelainSpace.md)),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: scale(560)),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: scale.text(theme.text.guestBody),
            ),
          ),
        ],
      ],
    );
  }
}

/// The preview as a print lying on the table: a little turned, with a
/// white border and a soft shadow.
class _TiltedPrint extends StatelessWidget {
  const _TiltedPrint({required this.scale, required this.child});

  final GuestScale scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    return Transform.rotate(
      angle: -0.09,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: [
            BoxShadow(
              color: colors.shadowKey,
              blurRadius: scale(24),
              offset: Offset(scale(4), scale(12)),
            ),
          ],
        ),
        child: Padding(padding: EdgeInsets.all(scale(10)), child: child),
      ),
    );
  }
}

/// Photo booth, pose, smile, enjoy: what happens, at a glance. Words and
/// icons only; nothing here can be tapped.
class _StepGuide extends StatelessWidget {
  const _StepGuide({required this.steps, required this.scale});

  final List<String> steps;
  final GuestScale scale;

  static const _icons = [
    PorcelainIcons.camera,
    PorcelainIcons.pose,
    PorcelainIcons.smile,
    PorcelainIcons.enjoy,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: scale(PorcelainSpace.sm),
      children: [
        for (final (i, step) in steps.indexed) ...[
          if (i > 0)
            Container(
              width: 1,
              height: scale(40),
              margin: EdgeInsets.symmetric(
                horizontal: scale(PorcelainSpace.lg),
              ),
              color: colors.divider,
            ),
          MergeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _icons[i % _icons.length],
                  size: scale(30),
                  color: colors.accentIcon,
                ),
                SizedBox(height: scale(PorcelainSpace.xxs)),
                Text(
                  step.toUpperCase(),
                  style: scale.text(
                    theme.text.guestCaption.copyWith(
                      fontSize: 14,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: colors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text, required this.scale});

  final String text;
  final GuestScale scale;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return MergeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PorcelainIcons.privacy, size: scale(18), color: colors.inkMuted),
          SizedBox(width: scale(PorcelainSpace.xs)),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: scale.text(theme.text.guestCaption),
            ),
          ),
        ],
      ),
    );
  }
}

/// The guest's Start (EP06): the pearl shutter of the porcelain family,
/// or the pack's own hero button. Pack words replace the standard "Start"
/// only where the event kept the standard welcome.
class _StartAction extends StatelessWidget {
  const _StartAction({
    required this.copy,
    required this.scale,
    required this.onStart,
  });

  final GuestWelcomeCopy copy;
  final GuestScale scale;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final experience = GuestExperience.experienceOf(context);
    final label = copy.startLabel == sampleGuestWelcomeCopy.startLabel
        ? experience.copy[GuestCopyKey.start]
        : copy.startLabel;
    void start() {
      GuestCueScope.play(context, SoundCue.press);
      onStart();
    }

    if (experience.buttonStyle == GuestButtonStyle.porcelain) {
      return GuestStartButton(
        label: label,
        prompt: copy.startPrompt,
        semanticHint: copy.startHint,
        onPressed: start,
        scale: scale.factor,
      );
    }
    return GuestButton(
      label: label,
      icon: PorcelainIcons.camera,
      size: GuestButtonSize.hero,
      semanticHint: copy.startHint,
      onPressed: onStart,
    );
  }
}
