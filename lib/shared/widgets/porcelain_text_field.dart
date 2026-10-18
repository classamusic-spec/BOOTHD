import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'tactile_surface.dart';

/// Labelled text input in an inset porcelain well.
///
/// The label sits above the field (never only as a placeholder), helper and
/// error text sit below, and an error is shown with an icon and words as
/// well as the danger colour.
class PorcelainTextField extends StatefulWidget {
  const PorcelainTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.error,
    this.enabled = true,
    this.disabledReason,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;

  /// Shown instead of [helper]; marks the field invalid.
  final String? error;
  final bool enabled;
  final String? disabledReason;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool autofocus;

  @override
  State<PorcelainTextField> createState() => _PorcelainTextFieldState();
}

class _PorcelainTextFieldState extends State<PorcelainTextField> {
  final _focus = FocusNode();
  var _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focused != _focus.hasFocus) {
        setState(() => _focused = _focus.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    final error = widget.error;
    final enabled = widget.enabled;
    final note = error ?? (enabled ? widget.helper : widget.disabledReason);

    final border = !enabled
        ? colors.hairline
        : error != null
        ? colors.danger
        : _focused
        ? colors.focusRing
        : colors.outline;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: theme.text.labelLarge.copyWith(
              color: enabled ? colors.ink : colors.inkDisabled,
            ),
          ),
          const SizedBox(height: PorcelainSpace.xs),
          TactileSurface(
            duration: motion.standard,
            look: TactileLook(
              fillTop: enabled ? colors.inset : colors.disabledFill,
              fillBottom: enabled ? colors.inset : colors.disabledFill,
              border: border,
              borderWidth: _focused || error != null ? 2 : 1,
              inset: enabled ? 0.55 : 0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PorcelainSpace.md,
                  vertical: PorcelainSpace.sm,
                ),
                child: Center(
                  widthFactor: 1,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    enabled: enabled,
                    autofocus: widget.autofocus,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    inputFormatters: widget.inputFormatters,
                    maxLength: widget.maxLength,
                    style: theme.text.bodyLarge.copyWith(
                      color: enabled ? colors.ink : colors.inkDisabled,
                    ),
                    cursorColor: colors.accentText,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      counterText: '',
                      hintText: widget.hint,
                      hintStyle: theme.text.bodyLarge.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: PorcelainSpace.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (error != null) ...[
                  Icon(
                    PorcelainIcons.error,
                    size: 18,
                    color: colors.danger,
                    fill: 1,
                  ),
                  const SizedBox(width: PorcelainSpace.xs),
                ],
                Expanded(
                  child: Text(
                    note,
                    style: theme.text.bodySmall.copyWith(
                      color: error != null ? colors.danger : colors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
