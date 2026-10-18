import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'porcelain_card.dart';
import 'tactile_surface.dart';
import 'tone.dart';

/// A small status pill: tone icon plus words (never colour alone).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = PorcelainTone.neutral,
    this.icon,
  });

  final String label;
  final PorcelainTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final foreground = tone.foreground(colors);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.surfaceColor(colors),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? tone.icon, size: 16, color: foreground, fill: 1),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.text.labelMedium.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One fact on the dashboard status strip: what is checked, its state in
/// words and what to do about it. Shows only states the app can verify.
class StatusTile extends StatelessWidget {
  const StatusTile({
    super.key,
    required this.icon,
    required this.title,
    required this.status,
    required this.detail,
    this.tone = PorcelainTone.neutral,
  });

  final IconData icon;
  final String title;
  final String status;
  final String detail;
  final PorcelainTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return MergeSemantics(
      child: PorcelainCard(
        padding: const EdgeInsets.all(PorcelainSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 40,
                  child: TactileSurface(
                    duration: Duration.zero,
                    shape: TactileShape.circle,
                    look: TactileLook(
                      fillTop: colors.inset,
                      fillBottom: colors.inset,
                      inset: 0.5,
                    ),
                    child: Center(
                      child: Icon(icon, size: 20, color: colors.accentIcon),
                    ),
                  ),
                ),
                const SizedBox(width: PorcelainSpace.sm),
                Expanded(child: Text(title, style: theme.text.titleSmall)),
              ],
            ),
            const SizedBox(height: PorcelainSpace.md),
            StatusBadge(label: status, tone: tone),
            const SizedBox(height: PorcelainSpace.sm),
            Text(
              detail,
              style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
