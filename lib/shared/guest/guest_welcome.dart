import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'guest_layout.dart';
import 'guest_start_button.dart';

/// Words on the guest welcome screen (S20). Supplied by the caller, so the
/// event can personalise them (M03) and they can be localised.
@immutable
final class GuestWelcomeCopy {
  const GuestWelcomeCopy({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.startLabel,
    this.startHint,
    this.privacyNote,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  /// Short numbered steps. Never promise a print (CR-001 fix 8).
  final List<String> steps;
  final String startLabel;
  final String? startHint;
  final String? privacyNote;
}

/// The guest welcome screen skeleton (S20): greeting, numbered steps, the
/// round Start control and an optional quiet privacy line, in portrait or
/// landscape depending on the space available. It has exactly one control.
class GuestWelcome extends StatelessWidget {
  const GuestWelcome({super.key, required this.copy, required this.onStart});

  final GuestWelcomeCopy copy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = GuestScale.forSize(constraints.biggest);
        final landscape = constraints.maxWidth > constraints.maxHeight;
        return GuestLayout(
          message: _Message(copy: copy, scale: scale, centred: !landscape),
          action: GuestStartButton(
            label: copy.startLabel,
            semanticHint: copy.startHint,
            onPressed: onStart,
            scale: scale.factor,
          ),
          footer: copy.privacyNote == null
              ? null
              : _PrivacyNote(text: copy.privacyNote!, scale: scale),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.copy,
    required this.scale,
    required this.centred,
  });

  final GuestWelcomeCopy copy;
  final GuestScale scale;
  final bool centred;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final align = centred ? TextAlign.center : TextAlign.start;
    final cross = centred
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          copy.eyebrow.toUpperCase(),
          textAlign: align,
          style: scale.text(
            theme.text.guestLabel.copyWith(
              color: colors.guestAccentText,
              letterSpacing: 4,
            ),
          ),
        ),
        SizedBox(height: scale(PorcelainSpace.md)),
        Semantics(
          header: true,
          child: Text(
            copy.title,
            textAlign: align,
            style: scale.text(theme.text.guestDisplay),
          ),
        ),
        SizedBox(height: scale(PorcelainSpace.lg)),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: scale(640)),
          child: Text(
            copy.subtitle,
            textAlign: align,
            style: scale.text(theme.text.guestBody),
          ),
        ),
        SizedBox(height: scale(PorcelainSpace.xxl)),
        // A row under a centred portrait message; a list beside the Start
        // control in landscape, where the column is narrower.
        if (centred)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: scale(PorcelainSpace.xxl),
            runSpacing: scale(PorcelainSpace.md),
            children: [
              for (var i = 0; i < copy.steps.length; i++)
                _Step(number: i + 1, label: copy.steps[i], scale: scale),
            ],
          )
        else
          for (var i = 0; i < copy.steps.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == copy.steps.length - 1
                    ? 0
                    : scale(PorcelainSpace.sm),
              ),
              child: _Step(number: i + 1, label: copy.steps[i], scale: scale),
            ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.label, required this.scale});

  final int number;
  final String label;
  final GuestScale scale;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final ring = scale(44);
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ring,
            height: ring,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.raised,
              border: Border.all(color: colors.accentIcon, width: 1.5),
            ),
            child: Text(
              '$number',
              style: scale.text(
                theme.text.headlineSmall.copyWith(
                  height: 1,
                  color: colors.guestAccentText,
                ),
              ),
            ),
          ),
          SizedBox(width: scale(PorcelainSpace.sm)),
          Text(label, style: scale.text(theme.text.guestLabel)),
        ],
      ),
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
        children: [
          Icon(PorcelainIcons.privacy, size: scale(20), color: colors.inkMuted),
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
