import 'package:flutter/widgets.dart';

import '../../../core/design_system/porcelain_metrics.dart';
import '../../../core/design_system/porcelain_theme.dart';
import '../../../domain/models/booth_event.dart';
import '../../../domain/models/template_revision_summary.dart';
import '../../../shared/widgets/porcelain_card.dart';

/// What every editor tab receives (S04).
@immutable
final class EditorTabContext {
  const EditorTabContext({
    required this.event,
    required this.onChanged,
    required this.library,
    this.readOnlyReason,
  });

  final BoothEvent event;
  final ValueChanged<BoothEvent> onChanged;

  /// Template summaries by revision ID, for the event's templates and every
  /// selectable one.
  final Map<String, TemplateRevisionSummary> library;

  /// Set when the event cannot be edited (archived); every control is
  /// disabled with this reason.
  final String? readOnlyReason;

  bool get readOnly => readOnlyReason != null;

  /// [change] applied to the event, or null when read-only (which disables
  /// the control).
  ValueChanged<T>? edit<T>(BoothEvent Function(T value) change) =>
      readOnly ? null : (value) => onChanged(change(value));
}

/// A titled group of settings in a porcelain card.
class EditorCard extends StatelessWidget {
  const EditorCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return PorcelainCard(
      padding: const EdgeInsets.all(PorcelainSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(title, style: theme.text.titleLarge),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: PorcelainSpace.xxs),
                      Text(
                        subtitle!,
                        style: theme.text.bodyMedium.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: PorcelainSpace.md),
                trailing!,
              ],
            ],
          ),
          for (final child in children) ...[
            const SizedBox(height: PorcelainSpace.lg),
            child,
          ],
        ],
      ),
    );
  }
}

/// A setting: its name and explanation beside the control when there is
/// room, above it otherwise.
class EditorSetting extends StatelessWidget {
  const EditorSetting({
    super.key,
    required this.title,
    required this.control,
    this.description,
    this.stacked = false,
  });

  final String title;
  final String? description;
  final Widget control;

  /// The control under its label at every width: for controls that wrap,
  /// such as a row of swatches.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: theme.text.titleSmall),
        if (description != null) ...[
          const SizedBox(height: 2),
          Text(
            description!,
            style: theme.text.bodyMedium.copyWith(color: theme.colors.inkMuted),
          ),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label,
              const SizedBox(height: PorcelainSpace.sm),
              control,
            ],
          );
        }
        if (constraints.maxWidth >= 620) {
          return Row(
            children: [
              Expanded(child: label),
              const SizedBox(width: PorcelainSpace.lg),
              control,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            const SizedBox(height: PorcelainSpace.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: control,
            ),
          ],
        );
      },
    );
  }
}

/// A quiet line of explanation, e.g. what a later milestone adds.
class EditorNote extends StatelessWidget {
  const EditorNote({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colors.accentIcon),
          const SizedBox(width: PorcelainSpace.xs),
          Expanded(
            child: Text(
              text,
              style: theme.text.bodyMedium.copyWith(
                color: theme.colors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `4 × 6 in portrait · 1200 × 1800 px` for a template page at 300 DPI.
String pageSizeLabel(TemplateRevisionSummary template) {
  String inches(int px) {
    final value = px / 300;
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  final w = template.pageWidthPx;
  final h = template.pageHeightPx;
  final shape = w == h
      ? 'square'
      : w > h
      ? 'landscape'
      : 'portrait';
  return '${inches(w)} × ${inches(h)} in $shape · $w × $h px';
}
