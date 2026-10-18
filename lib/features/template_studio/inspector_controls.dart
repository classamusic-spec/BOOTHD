import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/templates/document_colors.dart';
import '../../domain/template/template_assets.dart';
import '../../shared/widgets/porcelain_text_field.dart';
import '../../shared/widgets/pressable.dart';

/// A compact icon control for dense editor rows (48 dp): a toggle when
/// [toggled] is given, otherwise a plain action.
class EditorIconToggle extends StatelessWidget {
  const EditorIconToggle({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.toggled,
    this.activeIcon,
    this.disabledReason,
  });

  final IconData icon;

  /// Shown instead of [icon] while toggled on.
  final IconData? activeIcon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool? toggled;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final motion = PorcelainMotion.of(context);
    final on = toggled ?? false;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      toggled: toggled,
      disabledReason: disabledReason,
      builder: (context, state) => AnimatedContainer(
        duration: motion.press,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: state.pressed
              ? colors.inset
              : on
              ? colors.selected
              : null,
          borderRadius: PorcelainRadius.controlAll,
          border: state.focused
              ? Border.all(color: colors.focusRing, width: 2)
              : null,
        ),
        child: Icon(
          on ? (activeIcon ?? icon) : icon,
          size: PorcelainSize.iconSmall,
          color: !state.enabled
              ? colors.inkDisabled
              : on
              ? colors.accentText
              : colors.inkMuted,
        ),
      ),
    );
  }
}

/// A titled group of inspector fields.
class InspectorSection extends StatelessWidget {
  const InspectorSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Padding(
      padding: const EdgeInsets.only(bottom: PorcelainSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: theme.text.eyebrow.copyWith(
                color: theme.colors.accentText,
              ),
            ),
          ),
          const SizedBox(height: PorcelainSpace.sm),
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: PorcelainSpace.sm),
            child,
          ],
        ],
      ),
    );
  }
}

/// Two fields side by side.
class InspectorPair extends StatelessWidget {
  const InspectorPair(this.first, this.second, {super.key});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: first),
      const SizedBox(width: PorcelainSpace.sm),
      Expanded(child: second),
    ],
  );
}

/// An exact number (S10): shows [value], commits a valid entry on Enter or
/// when focus leaves, and explains an invalid one without changing
/// anything. Follows [value] while not being edited.
class InspectorNumberField extends StatefulWidget {
  const InspectorNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onCommit,
    this.unit,
    this.min,
    this.max,
    this.decimals = 0,
    this.enabled = true,
    this.disabledReason,
  });

  final String label;
  final double value;
  final String? unit;
  final double? min;
  final double? max;
  final int decimals;
  final bool enabled;
  final String? disabledReason;
  final ValueChanged<double> onCommit;

  @override
  State<InspectorNumberField> createState() => _InspectorNumberFieldState();
}

class _InspectorNumberFieldState extends State<InspectorNumberField> {
  late final _text = TextEditingController(text: _format(widget.value));
  var _editing = false;
  String? _error;

  String _format(double value) {
    final fixed = value.toStringAsFixed(widget.decimals);
    // -0 reads oddly.
    return fixed.startsWith('-') && double.parse(fixed) == 0
        ? fixed.substring(1)
        : fixed;
  }

  @override
  void didUpdateWidget(InspectorNumberField old) {
    super.didUpdateWidget(old);
    if (!_editing && _format(widget.value) != _text.text) {
      _text.text = _format(widget.value);
      _error = null;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _commit() {
    final parsed = double.tryParse(_text.text.trim().replaceAll(',', '.'));
    final min = widget.min;
    final max = widget.max;
    String? error;
    if (parsed == null || !parsed.isFinite) {
      error = 'Enter a number.';
    } else if (min != null && parsed < min) {
      error = 'At least ${_format(min)}.';
    } else if (max != null && parsed > max) {
      error = 'At most ${_format(max)}.';
    }
    setState(() => _error = error);
    if (error != null) return;
    if (_format(parsed!) != _format(widget.value)) widget.onCommit(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    return Focus(
      onFocusChange: (focused) {
        _editing = focused;
        if (!focused) _commit();
      },
      child: PorcelainTextField(
        label: unit == null ? widget.label : '${widget.label} ($unit)',
        controller: _text,
        enabled: widget.enabled,
        disabledReason: widget.disabledReason,
        error: _error,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]')),
        ],
        onSubmitted: (_) => _commit(),
      ),
    );
  }
}

/// A slider whose drag is one undo step: [onStart], any number of
/// [onChanged], then [onEnd].
class InspectorSlider extends StatelessWidget {
  const InspectorSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.onStart,
    required this.onChanged,
    required this.onEnd,
    this.enabled = true,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String valueLabel;
  final VoidCallback onStart;
  final ValueChanged<double> onChanged;
  final VoidCallback onEnd;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.text.labelLarge.copyWith(color: colors.ink),
              ),
            ),
            Text(
              valueLabel,
              style: theme.text.numeric.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: colors.accentIcon,
            inactiveTrackColor: colors.inset,
            thumbColor: colors.primaryTop,
            overlayColor: colors.focusRing.withValues(alpha: 0.16),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            label: valueLabel,
            semanticFormatterCallback: (_) => valueLabel,
            onChangeStart: enabled ? (_) => onStart() : null,
            onChanged: enabled ? onChanged : null,
            onChangeEnd: enabled ? (_) => onEnd() : null,
          ),
        ),
      ],
    );
  }
}

/// A template colour (S10): the Porcelain swatches, an exact hex value,
/// and "None" where the colour is optional.
class InspectorColorField extends StatefulWidget {
  const InspectorColorField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowNone = false,
  });

  final String label;
  final ArgbColor? value;
  final ValueChanged<ArgbColor?> onChanged;
  final bool allowNone;

  @override
  State<InspectorColorField> createState() => _InspectorColorFieldState();
}

class _InspectorColorFieldState extends State<InspectorColorField> {
  late final _hex = TextEditingController(text: _format(widget.value));
  var _editing = false;
  String? _error;

  static String _format(ArgbColor? color) {
    if (color == null) return '';
    final value = color.value;
    final alpha = (value >> 24) & 0xFF;
    final rgb = (value & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return alpha == 0xFF
        ? '#${rgb.toUpperCase()}'
        : '#${alpha.toRadixString(16).padLeft(2, '0')}$rgb'.toUpperCase();
  }

  @override
  void didUpdateWidget(InspectorColorField old) {
    super.didUpdateWidget(old);
    if (!_editing && _format(widget.value) != _hex.text) {
      _hex.text = _format(widget.value);
      _error = null;
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _commit() {
    final text = _hex.text.trim().replaceFirst('#', '');
    if (text.isEmpty && widget.allowNone) {
      setState(() => _error = null);
      if (widget.value != null) widget.onChanged(null);
      return;
    }
    final valid = RegExp(r'^([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(text);
    if (!valid) {
      setState(() => _error = 'Use #RRGGBB, or #AARRGGBB with opacity.');
      return;
    }
    setState(() => _error = null);
    final value = int.parse(text.length == 6 ? 'FF$text' : text, radix: 16);
    if (value != widget.value?.value) widget.onChanged(ArgbColor(value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: PorcelainSpace.xxs,
          runSpacing: PorcelainSpace.xxs,
          children: [
            if (widget.allowNone)
              _Swatch(
                label: 'None',
                color: null,
                selected: widget.value == null,
                onPressed: () => widget.onChanged(null),
              ),
            for (final swatch in templateSwatches)
              _Swatch(
                label: swatch.name,
                color: Color(swatch.color.value),
                selected: widget.value == swatch.color,
                onPressed: () => widget.onChanged(swatch.color),
              ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xs),
        Focus(
          onFocusChange: (focused) {
            _editing = focused;
            if (!focused) _commit();
          },
          child: PorcelainTextField(
            label: widget.label,
            controller: _hex,
            hint: widget.allowNone ? 'None' : '#RRGGBB',
            error: _error,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(9),
            ],
            onSubmitted: (_) => _commit(),
          ),
        ),
        if (widget.value case final value?)
          Padding(
            padding: const EdgeInsets.only(top: PorcelainSpace.xxs),
            child: Text(
              (value.value >> 24) == 0xFF
                  ? 'Opaque'
                  : '${((value.value >> 24) / 255 * 100).round()}% opaque',
              style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
            ),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  final String label;

  /// Null draws "none": a crossed-out chip.
  final Color? color;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: selected,
      builder: (context, state) => Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected || state.focused
                ? colors.focusRing
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: colors.outline),
          ),
          child: color == null
              ? Icon(PorcelainIcons.close, size: 16, color: colors.inkMuted)
              : null,
        ),
      ),
    );
  }
}
