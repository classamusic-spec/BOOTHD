import 'package:flutter/material.dart';

import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'porcelain_button.dart';
import 'porcelain_text_field.dart';

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

/// Asks for a name in a porcelain sheet: a text field labelled [label]
/// starting at [initialValue], Cancel and [confirmLabel]. Returns the text,
/// or null when cancelled or dismissed. The field's controller belongs to
/// the sheet, so it outlives the closing animation.
Future<String?> showPorcelainNameSheet({
  required BuildContext context,
  required String title,
  required String label,
  required String initialValue,
  required int maxLength,
  String confirmLabel = 'Rename',
  TextCapitalization textCapitalization = TextCapitalization.none,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: PorcelainMotion.of(context).isReduced
        ? AnimationStyle.noAnimation
        : null,
    builder: (_) => _NameSheet(
      title: title,
      label: label,
      initialValue: initialValue,
      maxLength: maxLength,
      confirmLabel: confirmLabel,
      textCapitalization: textCapitalization,
    ),
  );
}

class _NameSheet extends StatefulWidget {
  const _NameSheet({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.maxLength,
    required this.confirmLabel,
    required this.textCapitalization,
  });

  final String title;
  final String label;
  final String initialValue;
  final int maxLength;
  final String confirmLabel;
  final TextCapitalization textCapitalization;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) => PorcelainSheet(
    title: widget.title,
    body: PorcelainTextField(
      label: widget.label,
      controller: _controller,
      maxLength: widget.maxLength,
      autofocus: true,
      textCapitalization: widget.textCapitalization,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _confirm(),
    ),
    actions: [
      PorcelainButton(
        label: 'Cancel',
        variant: PorcelainButtonVariant.quiet,
        onPressed: () => Navigator.of(context).pop(),
      ),
      PorcelainButton(
        label: widget.confirmLabel,
        variant: PorcelainButtonVariant.primary,
        onPressed: _confirm,
      ),
    ],
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
