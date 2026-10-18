import 'package:flutter/material.dart';

import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';

/// Opens a modal porcelain sheet with a serif [title], a [body] and an
/// optional row of [actions]. It rises from the bottom (instantly with
/// reduced motion) and is at most 720 dp wide, so landscape tablets get a
/// centred sheet rather than a full-width slab.
Future<T?> showPorcelainSheet<T>({
  required BuildContext context,
  required String title,
  required Widget body,
  List<Widget> Function(BuildContext sheetContext)? actions,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: PorcelainMotion.of(context).isReduced
        ? AnimationStyle.noAnimation
        : null,
    builder: (sheetContext) => PorcelainSheet(
      title: title,
      body: body,
      actions: actions?.call(sheetContext) ?? const [],
    ),
  );
}

/// The content layout of a Porcelain sheet.
class PorcelainSheet extends StatelessWidget {
  const PorcelainSheet({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        PorcelainSpace.xxl,
        0,
        PorcelainSpace.xxl,
        PorcelainSpace.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.text.headlineMedium),
          ),
          const SizedBox(height: PorcelainSpace.md),
          DefaultTextStyle.merge(style: theme.text.bodyLarge, child: body),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: PorcelainSpace.xl),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: PorcelainSpace.sm,
                runSpacing: PorcelainSpace.sm,
                children: actions,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
