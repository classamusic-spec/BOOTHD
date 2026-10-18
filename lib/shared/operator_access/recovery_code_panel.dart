import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../widgets/porcelain_button.dart';
import '../widgets/porcelain_switch.dart';
import '../widgets/tactile_surface.dart';
import 'access_copy.dart';

/// Shows a new recovery code once (S01), and continues only after the
/// operator confirms it is written down.
class RecoveryCodePanel extends StatefulWidget {
  const RecoveryCodePanel({
    super.key,
    required this.code,
    required this.continueLabel,
    required this.onContinue,
    this.leading,
  });

  final String code;
  final String continueLabel;
  final VoidCallback onContinue;
  final Widget? leading;

  @override
  State<RecoveryCodePanel> createState() => _RecoveryCodePanelState();
}

class _RecoveryCodePanelState extends State<RecoveryCodePanel> {
  var _stored = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final groups = widget.code.split('-');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?widget.leading,
        Semantics(
          header: true,
          child: Text(
            AccessCopy.recoveryCodeTitle,
            textAlign: TextAlign.center,
            style: theme.text.headlineMedium,
          ),
        ),
        const SizedBox(height: PorcelainSpace.xs),
        Text(
          AccessCopy.recoveryCodeBody,
          textAlign: TextAlign.center,
          style: theme.text.bodyLarge.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: PorcelainSpace.xl),
        Semantics(
          label: AccessCopy.recoveryCodeLabel,
          // Read character by character, group by group.
          value: groups.map((group) => group.split('').join(' ')).join(', '),
          child: ExcludeSemantics(
            child: TactileSurface(
              duration: Duration.zero,
              look: TactileLook(
                fillTop: colors.inset,
                fillBottom: colors.inset,
                border: colors.outline,
                inset: 0.5,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PorcelainSpace.lg,
                  vertical: PorcelainSpace.xl,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: PorcelainSpace.lg,
                  runSpacing: PorcelainSpace.sm,
                  children: [
                    for (final group in groups)
                      Text(
                        group,
                        style: theme.text.numeric.copyWith(
                          fontSize: 30,
                          height: 1.2,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: PorcelainSpace.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(PorcelainIcons.warning, size: 20, color: colors.warning),
            const SizedBox(width: PorcelainSpace.xs),
            Expanded(
              child: Text(
                AccessCopy.recoveryCodeWarning,
                style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.lg),
        PorcelainSwitchRow(
          title: AccessCopy.recoveryCodeStored,
          subtitle: AccessCopy.recoveryCodeStoredSubtitle,
          value: _stored,
          onChanged: (value) => setState(() => _stored = value),
        ),
        const SizedBox(height: PorcelainSpace.xl),
        Align(
          child: PorcelainButton(
            label: widget.continueLabel,
            icon: PorcelainIcons.check,
            variant: PorcelainButtonVariant.primary,
            size: PorcelainButtonSize.large,
            onPressed: _stored ? widget.onContinue : null,
            disabledReason: AccessCopy.confirmStoredReason,
          ),
        ),
      ],
    );
  }
}
