import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';

/// Title block at the top of a Studio page: gold eyebrow, serif title,
/// muted subtitle and the page's actions. Actions sit beside the title when
/// there is room and wrap below it otherwise.
class StudioPageHeader extends StatelessWidget {
  const StudioPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!.toUpperCase(), style: theme.text.eyebrow),
          const SizedBox(height: PorcelainSpace.xs),
        ],
        Semantics(
          header: true,
          child: Text(title, style: theme.text.displaySmall),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: PorcelainSpace.xs),
          Text(
            subtitle!,
            style: theme.text.bodyLarge.copyWith(color: colors.inkMuted),
          ),
        ],
      ],
    );
    if (actions.isEmpty) return titleBlock;
    final actionWrap = Wrap(
      spacing: PorcelainSpace.sm,
      runSpacing: PorcelainSpace.sm,
      children: actions,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: PorcelainSpace.xl),
              actionWrap,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleBlock,
            const SizedBox(height: PorcelainSpace.lg),
            actionWrap,
          ],
        );
      },
    );
  }
}

/// Heading for a group of content within a page.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Padding(
      padding: const EdgeInsets.only(bottom: PorcelainSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: theme.text.headlineSmall),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: PorcelainSpace.xxs),
                  Text(
                    subtitle!,
                    style: theme.text.bodyMedium.copyWith(
                      color: theme.colors.inkMuted,
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
    );
  }
}
