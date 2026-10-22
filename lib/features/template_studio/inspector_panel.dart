import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/composition/scene_painter.dart';
import '../../core/composition/template_fonts.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/templates/document_colors.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/template/document_scene.dart';
import '../../domain/template/editing/editor_geometry.dart';
import '../../domain/template/editing/layer_copy.dart';
import '../../domain/template/geometry.dart';
import '../../domain/template/page_spec.dart';
import '../../domain/template/template_assets.dart';
import '../../domain/template/template_document.dart';
import '../../domain/template/template_layers.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_stepper.dart';
import '../../shared/widgets/porcelain_switch.dart';
import '../../shared/widgets/porcelain_text_field.dart';
import 'editor_canvas.dart';
import 'editor_controller.dart';
import 'inspector_controls.dart';
import 'layers_panel.dart';

/// Chooses a stored image for the template (the asset browser).
typedef ImageChooser = Future<StoredAsset?> Function(BuildContext context);

/// The inspector (S10, AC-0503): exact position, size, rotation, pivot and
/// opacity in document units, and each layer type's own properties. Every
/// change is one undo step; sliders are one step per drag.
class InspectorPanel extends StatelessWidget {
  const InspectorPanel({
    super.key,
    required this.controller,
    required this.onRefused,
    required this.chooseImage,
  });

  final TemplateEditorController controller;
  final ValueChanged<Object> onRefused;
  final ImageChooser chooseImage;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selected = controller.selectedLayers;
        final ctx = _Inspect(controller, onRefused, chooseImage);
        final Widget body = switch (selected) {
          [] => _PageInspector(ctx),
          [final BackgroundLayer layer] => KeyedSubtree(
            key: ValueKey(layer.id),
            child: _BackgroundInspector(ctx, layer, standalone: true),
          ),
          [final FramedLayer layer] => KeyedSubtree(
            key: ValueKey(layer.id),
            child: _LayerInspector(ctx, layer),
          ),
          _ => _MultiInspector(ctx, selected),
        };
        return ListView(
          padding: const EdgeInsets.all(PorcelainSpace.lg),
          children: [body],
        );
      },
    );
  }
}

/// What every inspector section needs.
final class _Inspect {
  const _Inspect(this.controller, this.onRefused, this.chooseImage);

  final TemplateEditorController controller;
  final ValueChanged<Object> onRefused;
  final ImageChooser chooseImage;

  PageSpec get page => controller.document.page;

  void run(VoidCallback edit) {
    try {
      edit();
    } on Exception catch (error) {
      onRefused(error);
    }
  }

  void update(String id, TemplateLayer Function(TemplateLayer layer) change) =>
      run(() => controller.updateLayer(id, change));

  /// A slider drag as one undo step.
  ({VoidCallback start, ValueChanged<double> change, VoidCallback end}) drag(
    String id,
    TemplateLayer Function(TemplateLayer layer, double value) change,
  ) => (
    start: controller.beginGesture,
    change: (value) =>
        run(() => controller.updateLayerInGesture(id, (l) => change(l, value))),
    end: controller.endGesture,
  );

  /// Print pixels per displayed length unit.
  double get unitScale => controller.pageUnits
      ? page.dpi * (page.unit == LengthUnit.inch ? 1 : 1 / 25.4)
      : 1;

  String get unit => controller.pageUnits ? page.unit.code : 'px';
  int get decimals =>
      controller.pageUnits ? (page.unit == LengthUnit.inch ? 3 : 1) : 1;
}

const _lockedReason = 'Unlock the layer to change it.';

class _PageInspector extends StatelessWidget {
  const _PageInspector(this.i);

  final _Inspect i;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final controller = i.controller;
    final document = controller.document;
    final page = document.page;
    final background = document.background;
    String size(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectorSection(
          title: 'Page',
          children: [
            Text(
              '${size(page.width)} × ${size(page.height)} ${page.unit.code} · '
              '${page.widthPx} × ${page.heightPx} px at ${page.dpi} dpi',
              style: theme.text.bodyLarge.copyWith(color: theme.colors.ink),
            ),
            Text(
              '${document.photoSlotCount} '
              '${document.photoSlotCount == 1 ? 'photo' : 'photos'} · '
              '${document.layers.length} '
              '${document.layers.length == 1 ? 'layer' : 'layers'}. '
              'Tap a layer to change it.',
              style: theme.text.bodyMedium.copyWith(
                color: theme.colors.inkMuted,
              ),
            ),
          ],
        ),
        if (background != null)
          _BackgroundInspector(i, background, standalone: false)
        else
          InspectorSection(
            title: 'Background',
            children: [
              Text(
                'The page is transparent; prints come out on white.',
                style: theme.text.bodyMedium.copyWith(
                  color: theme.colors.inkMuted,
                ),
              ),
              PorcelainButton(
                label: 'Add a background colour',
                icon: PorcelainIcons.background,
                onPressed: () => i.run(
                  () => controller.setBackground(
                    const SolidFill(DocumentPalette.ivory),
                  ),
                ),
              ),
            ],
          ),
        InspectorSection(
          title: 'Guides',
          children: [
            PorcelainSwitchRow(
              title: 'Snap to guides',
              subtitle: 'Edges and centres of the page and other layers',
              icon: PorcelainIcons.snap,
              value: controller.snapping,
              onChanged: (v) => controller.snapping = v,
            ),
            PorcelainSwitchRow(
              title: 'Grid',
              subtitle: 'Every eighth of an inch; snaps too',
              icon: PorcelainIcons.grid,
              value: controller.showGrid,
              onChanged: (v) => controller.showGrid = v,
            ),
            PorcelainSwitchRow(
              title: 'Print-safe margin',
              subtitle: 'Keep words and faces inside the dashed line',
              icon: PorcelainIcons.safeArea,
              value: controller.showSafeArea,
              onChanged: (v) => controller.showSafeArea = v,
            ),
          ],
        ),
      ],
    );
  }
}

class _BackgroundInspector extends StatelessWidget {
  const _BackgroundInspector(this.i, this.layer, {required this.standalone});

  final _Inspect i;
  final BackgroundLayer layer;

  /// Selected on its own (rather than shown with the page).
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final controller = i.controller;
    final fill = layer.fill;
    final locked = layer.locked;
    final kind = switch (fill) {
      SolidFill() => 0,
      LinearGradientFill() => 1,
      ImageFill() => 2,
    };
    void setFill(BackgroundFill next, {StoredAsset? image}) =>
        i.run(() => controller.setBackground(next, image: image));

    Future<void> chooseImage() async {
      final image = await i.chooseImage(context);
      if (image == null) return;
      try {
        await controller.setBackground(ImageFill(image.id), image: image);
      } on Exception catch (error) {
        i.onRefused(error);
      }
    }

    final (from, to) = switch (fill) {
      LinearGradientFill(:final stops) => (stops.first.color, stops.last.color),
      SolidFill(:final color) => (color, color),
      ImageFill() => (
        DocumentPalette.champagnePaper,
        DocumentPalette.champagneDeep,
      ),
    };
    return InspectorSection(
      title: 'Background',
      children: [
        if (locked)
          Text(
            _lockedReason,
            style: theme.text.bodyMedium.copyWith(color: theme.colors.inkMuted),
          ),
        PorcelainSegmentedControl<int>(
          selected: kind,
          disabledReason: locked ? _lockedReason : null,
          onChanged: locked
              ? null
              : (value) {
                  switch (value) {
                    case 0:
                      setFill(SolidFill(from));
                    case 1:
                      setFill(
                        LinearGradientFill(
                          angleDegrees: 180,
                          stops: [GradientStop(0, from), GradientStop(1, to)],
                        ),
                      );
                    default:
                      chooseImage();
                  }
                },
          segments: const [
            PorcelainSegment(value: 0, label: 'Colour'),
            PorcelainSegment(value: 1, label: 'Gradient'),
            PorcelainSegment(value: 2, label: 'Image'),
          ],
        ),
        if (!locked)
          switch (fill) {
            SolidFill(:final color) => InspectorColorField(
              label: 'Colour',
              value: color,
              onChanged: (c) => setFill(SolidFill(c!)),
            ),
            LinearGradientFill(:final angleDegrees, :final stops) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InspectorColorField(
                  label: 'From',
                  value: stops.first.color,
                  onChanged: (c) => setFill(
                    LinearGradientFill(
                      angleDegrees: angleDegrees,
                      stops: [GradientStop(0, c!), ...stops.skip(1)],
                    ),
                  ),
                ),
                const SizedBox(height: PorcelainSpace.sm),
                InspectorColorField(
                  label: 'To',
                  value: stops.last.color,
                  onChanged: (c) => setFill(
                    LinearGradientFill(
                      angleDegrees: angleDegrees,
                      stops: [
                        ...stops.take(stops.length - 1),
                        GradientStop(1, c!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: PorcelainSpace.sm),
                _GradientAngle(i: i, layer: layer, fill: fill),
              ],
            ),
            ImageFill(:final fit, :final assetId) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PorcelainSegmentedControl<ImageFit>(
                  selected: fit,
                  onChanged: (f) => setFill(ImageFill(assetId, fit: f)),
                  segments: const [
                    PorcelainSegment(value: ImageFit.cover, label: 'Fill'),
                    PorcelainSegment(value: ImageFit.contain, label: 'Fit'),
                    PorcelainSegment(value: ImageFit.fill, label: 'Stretch'),
                  ],
                ),
                const SizedBox(height: PorcelainSpace.sm),
                PorcelainButton(
                  label: 'Choose another image',
                  icon: PorcelainIcons.image,
                  onPressed: chooseImage,
                ),
              ],
            ),
          },
      ],
    );
  }
}

class _GradientAngle extends StatelessWidget {
  const _GradientAngle({
    required this.i,
    required this.layer,
    required this.fill,
  });

  final _Inspect i;
  final BackgroundLayer layer;
  final LinearGradientFill fill;

  @override
  Widget build(BuildContext context) {
    final drag = i.drag(
      layer.id,
      (l, v) => (l as BackgroundLayer).copyWith(
        fill: LinearGradientFill(
          angleDegrees: v.roundToDouble(),
          stops: fill.stops,
        ),
      ),
    );
    return InspectorSlider(
      label: 'Direction',
      value: fill.angleDegrees % 360,
      min: 0,
      max: 359,
      valueLabel: '${(fill.angleDegrees % 360).round()}°',
      onStart: drag.start,
      onChanged: drag.change,
      onEnd: drag.end,
    );
  }
}

class _MultiInspector extends StatelessWidget {
  const _MultiInspector(this.i, this.layers);

  final _Inspect i;
  final List<TemplateLayer> layers;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final controller = i.controller;
    return InspectorSection(
      title: '${layers.length} layers selected',
      children: [
        for (final layer in layers)
          Text(
            '· ${layerLabel(layer)}',
            style: theme.text.bodyMedium.copyWith(color: theme.colors.ink),
          ),
        Wrap(
          spacing: PorcelainSpace.xs,
          runSpacing: PorcelainSpace.xs,
          children: [
            PorcelainButton(
              label: 'Duplicate',
              icon: PorcelainIcons.duplicate,
              size: PorcelainButtonSize.compact,
              onPressed: () => i.run(controller.duplicateSelected),
            ),
            PorcelainButton(
              label: 'Delete',
              icon: PorcelainIcons.delete,
              variant: PorcelainButtonVariant.danger,
              size: PorcelainButtonSize.compact,
              onPressed: () => i.run(controller.deleteSelected),
            ),
            PorcelainButton(
              label: 'Select none',
              variant: PorcelainButtonVariant.quiet,
              size: PorcelainButtonSize.compact,
              onPressed: () => controller.select(null),
            ),
          ],
        ),
        Text(
          'Drag any of them on the canvas to move them together.',
          style: theme.text.bodySmall.copyWith(color: theme.colors.inkMuted),
        ),
      ],
    );
  }
}

class _LayerInspector extends StatelessWidget {
  const _LayerInspector(this.i, this.layer);

  final _Inspect i;
  final FramedLayer layer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LayerHeader(i, layer),
        _TransformSection(i, layer),
        switch (layer) {
          PhotoSlotLayer() => _SlotSection(i, layer as PhotoSlotLayer),
          ImageLayer() => _ImageSection(i, layer as ImageLayer),
          TextLayer() => _TextSection(i, layer as TextLayer),
          ShapeLayer() => _ShapeSection(i, layer as ShapeLayer),
        },
      ],
    );
  }
}

class _LayerHeader extends StatelessWidget {
  const _LayerHeader(this.i, this.layer);

  final _Inspect i;
  final FramedLayer layer;

  @override
  Widget build(BuildContext context) {
    final controller = i.controller;
    final locked = layer.locked;
    final id = layer.id;
    return InspectorSection(
      title: layerKind(layer),
      children: [
        _NameField(i: i, layer: layer),
        Wrap(
          spacing: PorcelainSpace.xxs,
          runSpacing: PorcelainSpace.xxs,
          children: [
            EditorIconToggle(
              icon: PorcelainIcons.unlocked,
              activeIcon: PorcelainIcons.locked,
              toggled: locked,
              semanticLabel: locked ? 'Unlock' : 'Lock',
              onPressed: () =>
                  i.run(() => controller.setLocked(id, locked: !locked)),
            ),
            EditorIconToggle(
              icon: PorcelainIcons.visible,
              activeIcon: PorcelainIcons.hidden,
              toggled: !layer.visible,
              semanticLabel: layer.visible ? 'Hide' : 'Show',
              onPressed: () => i.run(
                () => controller.setVisible(id, visible: !layer.visible),
              ),
            ),
            EditorIconToggle(
              icon: PorcelainIcons.duplicate,
              semanticLabel: 'Duplicate',
              onPressed: () => i.run(controller.duplicateSelected),
            ),
            EditorIconToggle(
              icon: PorcelainIcons.bringToFront,
              semanticLabel: 'Bring to front',
              onPressed: () => i.run(() => controller.bringToFront(id)),
            ),
            EditorIconToggle(
              icon: PorcelainIcons.bringForward,
              semanticLabel: 'Bring forward',
              onPressed: () => i.run(() => controller.bringForward(id)),
            ),
            EditorIconToggle(
              icon: PorcelainIcons.sendBackward,
              semanticLabel: 'Send backward',
              onPressed: () => i.run(() => controller.sendBackward(id)),
            ),
            EditorIconToggle(
              icon: PorcelainIcons.sendToBack,
              semanticLabel: 'Send to back',
              onPressed: () => i.run(() => controller.sendToBack(id)),
            ),
            EditorIconToggle(
              icon: PorcelainIcons.delete,
              semanticLabel: 'Delete',
              disabledReason: locked ? 'Unlock the layer to delete it.' : null,
              onPressed: locked ? null : () => i.run(controller.deleteSelected),
            ),
          ],
        ),
      ],
    );
  }
}

class _NameField extends StatefulWidget {
  const _NameField({required this.i, required this.layer});

  final _Inspect i;
  final FramedLayer layer;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final _text = TextEditingController(text: widget.layer.name);
  var _editing = false;

  @override
  void didUpdateWidget(_NameField old) {
    super.didUpdateWidget(old);
    if (!_editing && widget.layer.name != _text.text) {
      _text.text = widget.layer.name;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _commit() {
    if (_text.text.trim() == widget.layer.name) return;
    widget.i.run(
      () => widget.i.controller.renameLayer(widget.layer.id, _text.text),
    );
  }

  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (focused) {
      _editing = focused;
      if (!focused) _commit();
    },
    child: PorcelainTextField(
      label: 'Name',
      controller: _text,
      hint: layerKind(widget.layer),
      maxLength: GeometryLimits.maxNameLength,
      onSubmitted: (_) => _commit(),
    ),
  );
}

class _TransformSection extends StatelessWidget {
  const _TransformSection(this.i, this.layer);

  final _Inspect i;
  final FramedLayer layer;

  @override
  Widget build(BuildContext context) {
    final controller = i.controller;
    final page = i.page;
    final geometry = LayerGeometry.of(layer, page);
    final rect = geometry.rect;
    final scale = i.unitScale;
    final locked = layer.locked;
    final reason = locked ? _lockedReason : null;

    void setRect({double? x, double? y, double? w, double? h}) => i.update(
      layer.id,
      (l) => copyLayer(
        l,
        frame: geometry
            .withRect(
              PixelRect(
                left: x == null ? rect.left : x * scale,
                top: y == null ? rect.top : y * scale,
                width: w == null ? rect.width : w * scale,
                height: h == null ? rect.height : h * scale,
              ),
            )
            .frameOn(page),
      ),
    );

    Widget field(
      String label,
      double px,
      void Function(double) commit, {
      double? min,
    }) => InspectorNumberField(
      label: label,
      unit: i.unit,
      value: px / scale,
      decimals: i.decimals,
      min: min,
      enabled: !locked,
      disabledReason: reason,
      onCommit: commit,
    );

    final opacity = i.drag(layer.id, (l, v) => copyLayer(l, opacity: v));
    return InspectorSection(
      title: 'Position and size',
      children: [
        PorcelainSegmentedControl<bool>(
          selected: controller.pageUnits,
          onChanged: (v) => controller.pageUnits = v,
          segments: [
            const PorcelainSegment(value: false, label: 'Print pixels'),
            PorcelainSegment(
              value: true,
              label: page.unit == LengthUnit.inch ? 'Inches' : 'Millimetres',
            ),
          ],
        ),
        InspectorPair(
          field('X', rect.left, (v) => setRect(x: v)),
          field('Y', rect.top, (v) => setRect(y: v)),
        ),
        InspectorPair(
          field('Width', rect.width, (v) => setRect(w: v), min: 1 / scale),
          field('Height', rect.height, (v) => setRect(h: v), min: 1 / scale),
        ),
        InspectorNumberField(
          label: 'Rotation',
          unit: '°',
          value: normalizeDegrees(layer.rotationDegrees),
          decimals: 1,
          min: -360,
          max: 360,
          enabled: !locked,
          disabledReason: reason,
          onCommit: (v) => i.update(
            layer.id,
            (l) => copyLayer(l, rotationDegrees: normalizeDegrees(v)),
          ),
        ),
        _PivotPicker(
          value: layer.pivot,
          enabled: !locked,
          onChanged: (fraction) => i.update(layer.id, (l) {
            final moved = LayerGeometry.of(
              l as FramedLayer,
              page,
            ).withPivot(fraction);
            return copyLayer(l, pivot: fraction, frame: moved.frameOn(page));
          }),
        ),
        InspectorSlider(
          label: 'Opacity',
          value: layer.opacity,
          min: 0,
          max: 1,
          enabled: !locked,
          valueLabel: '${(layer.opacity * 100).round()}%',
          onStart: opacity.start,
          onChanged: opacity.change,
          onEnd: opacity.end,
        ),
      ],
    );
  }
}

/// The rotation anchor: one of nine points of the frame.
class _PivotPicker extends StatelessWidget {
  const _PivotPicker({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final NormalizedPoint value;
  final bool enabled;
  final ValueChanged<NormalizedPoint> onChanged;

  static const _names = ['top', 'middle', 'bottom'];
  static const _sides = ['left', 'centre', 'right'];

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Turns about',
            style: theme.text.labelLarge.copyWith(color: colors.ink),
          ),
        ),
        SizedBox(
          width: 3 * 48,
          height: 3 * 48,
          child: GridView.count(
            crossAxisCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var row = 0; row < 3; row++)
                for (var column = 0; column < 3; column++)
                  _pivotDot(context, row, column),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pivotDot(BuildContext context, int row, int column) {
    final point = NormalizedPoint(column / 2, row / 2);
    final selected =
        (value.x - point.x).abs() < 1e-6 && (value.y - point.y).abs() < 1e-6;
    final name = row == 1 && column == 1
        ? 'centre'
        : '${_names[row]} ${_sides[column]}';
    return EditorIconToggle(
      icon: selected ? PorcelainIcons.ellipse : PorcelainIcons.remove,
      toggled: selected,
      semanticLabel: 'Turn about the $name',
      // Like a radio button, the chosen point stays a working control.
      onPressed: enabled
          ? () {
              if (!selected) onChanged(point);
            }
          : null,
      disabledReason: enabled ? null : _lockedReason,
    );
  }
}

class _SlotSection extends StatelessWidget {
  const _SlotSection(this.i, this.layer);

  final _Inspect i;
  final PhotoSlotLayer layer;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final controller = i.controller;
    final locked = layer.locked;
    final reason = locked ? _lockedReason : null;
    final clip = layer.clip;
    final shape = switch (clip) {
      RectClip() => 0,
      RoundedRectClip() => 1,
      EllipseClip() => 2,
      MaskClip() => 3,
    };
    final radius = i.drag(
      layer.id,
      (l, v) => (l as PhotoSlotLayer).copyWith(clip: RoundedRectClip(v)),
    );
    final border = layer.border;
    final borderWidth = i.drag(
      layer.id,
      (l, v) => (l as PhotoSlotLayer).copyWith(
        border: v < 0.25
            ? null
            : Stroke(
                widthPt: (v * 4).roundToDouble() / 4,
                color: border?.color ?? DocumentPalette.white,
              ),
      ),
    );
    final focalX = i.drag(
      layer.id,
      (l, v) => (l as PhotoSlotLayer).copyWith(
        focal: NormalizedPoint(v, layer.focal.y),
      ),
    );
    final focalY = i.drag(
      layer.id,
      (l, v) => (l as PhotoSlotLayer).copyWith(
        focal: NormalizedPoint(layer.focal.x, v),
      ),
    );
    return InspectorSection(
      title: 'Photo',
      children: [
        PorcelainStepper(
          label: 'Taken as photo',
          value: layer.slotIndex + 1,
          min: 1,
          max: controller.document.photoSlotCount,
          disabledReason: reason,
          decreaseLabel: 'Take it earlier',
          increaseLabel: 'Take it later',
          minimumReason: 'This is the first photo taken.',
          maximumReason: 'This is the last photo taken.',
          onChanged: locked
              ? null
              : (n) => i.run(() => controller.renumberSlot(layer.id, n - 1)),
        ),
        PorcelainSegmentedControl<int>(
          selected: shape,
          disabledReason: reason,
          onChanged: locked
              ? null
              : (s) => i.update(
                  layer.id,
                  (l) => (l as PhotoSlotLayer).copyWith(
                    clip: switch (s) {
                      0 => const RectClip(),
                      1 => const RoundedRectClip(0.08),
                      2 => const EllipseClip(),
                      _ => clip,
                    },
                  ),
                ),
          segments: [
            const PorcelainSegment(value: 0, label: 'Square'),
            const PorcelainSegment(value: 1, label: 'Rounded'),
            const PorcelainSegment(value: 2, label: 'Oval'),
            if (clip is MaskClip)
              const PorcelainSegment(value: 3, label: 'Mask'),
          ],
        ),
        if (clip case RoundedRectClip(:final cornerRadius))
          InspectorSlider(
            label: 'Corner roundness',
            value: cornerRadius,
            min: 0,
            max: 0.5,
            enabled: !locked,
            valueLabel: '${(cornerRadius * 200).round()}%',
            onStart: radius.start,
            onChanged: radius.change,
            onEnd: radius.end,
          ),
        PorcelainSegmentedControl<PhotoFit>(
          selected: layer.fit,
          disabledReason: reason,
          onChanged: locked
              ? null
              : (f) => i.update(
                  layer.id,
                  (l) => (l as PhotoSlotLayer).copyWith(fit: f),
                ),
          segments: const [
            PorcelainSegment(value: PhotoFit.cover, label: 'Fill the slot'),
            PorcelainSegment(value: PhotoFit.contain, label: 'Whole photo'),
          ],
        ),
        if (layer.fit == PhotoFit.cover) ...[
          InspectorSlider(
            label: 'Keep in view: across',
            value: layer.focal.x,
            min: 0,
            max: 1,
            enabled: !locked,
            valueLabel: '${(layer.focal.x * 100).round()}%',
            onStart: focalX.start,
            onChanged: focalX.change,
            onEnd: focalX.end,
          ),
          InspectorSlider(
            label: 'Keep in view: down',
            value: layer.focal.y,
            min: 0,
            max: 1,
            enabled: !locked,
            valueLabel: '${(layer.focal.y * 100).round()}%',
            onStart: focalY.start,
            onChanged: focalY.change,
            onEnd: focalY.end,
          ),
        ],
        InspectorSlider(
          label: 'Border',
          value: border?.widthPt ?? 0,
          min: 0,
          max: 12,
          enabled: !locked,
          valueLabel: border == null ? 'None' : '${border.widthPt} pt',
          onStart: borderWidth.start,
          onChanged: borderWidth.change,
          onEnd: borderWidth.end,
        ),
        if (border != null && !locked)
          InspectorColorField(
            label: 'Border colour',
            value: border.color,
            onChanged: (c) => i.update(
              layer.id,
              (l) => (l as PhotoSlotLayer).copyWith(
                border: Stroke(widthPt: border.widthPt, color: c!),
              ),
            ),
          ),
        Text(
          'Guests\' photos are cut to this shape only. Artwork above it is '
          'never cut.',
          style: theme.text.bodySmall.copyWith(color: theme.colors.inkMuted),
        ),
      ],
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection(this.i, this.layer);

  final _Inspect i;
  final ImageLayer layer;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final controller = i.controller;
    final asset = controller.document.assets[layer.assetId];
    final locked = layer.locked;
    final reason = locked ? _lockedReason : null;
    final crop = layer.crop;
    final missing = controller.missingAssets.contains(layer.assetId);

    void setCrop({double? left, double? top, double? right, double? bottom}) {
      final l = (left ?? crop.x * 100) / 100;
      final t = (top ?? crop.y * 100) / 100;
      final r = (right ?? (1 - crop.x - crop.width) * 100) / 100;
      final b = (bottom ?? (1 - crop.y - crop.height) * 100) / 100;
      if (l + r >= 0.99 || t + b >= 0.99) {
        i.onRefused(
          const FormatException('Leave at least 1% of the image showing.'),
        );
        return;
      }
      i.update(
        layer.id,
        (layer) => (layer as ImageLayer).copyWith(
          crop: NormalizedRect(x: l, y: t, width: 1 - l - r, height: 1 - t - b),
        ),
      );
    }

    Widget cropField(String label, double percent, void Function(double) set) =>
        InspectorNumberField(
          label: label,
          unit: '%',
          value: percent,
          decimals: 1,
          min: 0,
          max: 98,
          enabled: !locked,
          disabledReason: reason,
          onCommit: set,
        );

    return InspectorSection(
      title: 'Image',
      children: [
        if (asset != null)
          Text(
            '${asset.name ?? 'Image'} · ${asset.widthPx} × ${asset.heightPx} px',
            style: theme.text.bodyMedium.copyWith(color: theme.colors.ink),
          ),
        if (missing)
          Text(
            "This image's file is missing or changed on this device; it "
            'shows hatched and the template cannot be printed until it is '
            'replaced.',
            style: theme.text.bodyMedium.copyWith(color: theme.colors.danger),
          ),
        PorcelainSegmentedControl<ImageFit>(
          selected: layer.fit,
          disabledReason: reason,
          onChanged: locked
              ? null
              : (f) => i.update(
                  layer.id,
                  (l) => (l as ImageLayer).copyWith(fit: f),
                ),
          segments: const [
            PorcelainSegment(value: ImageFit.fill, label: 'Stretch'),
            PorcelainSegment(value: ImageFit.contain, label: 'Fit'),
            PorcelainSegment(value: ImageFit.cover, label: 'Fill'),
          ],
        ),
        Text(
          'Crop, as a share of the image',
          style: theme.text.labelLarge.copyWith(color: theme.colors.ink),
        ),
        InspectorPair(
          cropField('Left', crop.x * 100, (v) => setCrop(left: v)),
          cropField(
            'Right',
            (1 - crop.x - crop.width) * 100,
            (v) => setCrop(right: v),
          ),
        ),
        InspectorPair(
          cropField('Top', crop.y * 100, (v) => setCrop(top: v)),
          cropField(
            'Bottom',
            (1 - crop.y - crop.height) * 100,
            (v) => setCrop(bottom: v),
          ),
        ),
      ],
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection(this.i, this.layer);

  final _Inspect i;
  final TextLayer layer;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final locked = layer.locked;
    final reason = locked ? _lockedReason : null;
    final font = layer.font;
    final bundled = font is BundledFont ? font : null;
    final lineHeight = i.drag(
      layer.id,
      (l, v) =>
          (l as TextLayer).copyWith(lineHeight: (v * 20).roundToDouble() / 20),
    );
    final overflow = _overflows(i.controller, layer);
    return InspectorSection(
      title: 'Text',
      children: [
        _TextContentField(i: i, layer: layer),
        if (overflow)
          Text(
            'The words are taller than their box and will spill out. Make '
            'the box taller or the text smaller.',
            style: theme.text.bodyMedium.copyWith(color: theme.colors.warning),
          ),
        if (bundled != null) ...[
          for (final row in const [
            [
              PorcelainSegment(
                value: BundledFontFamily.cormorantGaramond,
                label: 'Cormorant',
              ),
              PorcelainSegment(value: BundledFontFamily.inter, label: 'Inter'),
              PorcelainSegment(
                value: BundledFontFamily.courierPrime,
                label: 'Courier',
              ),
            ],
            [
              PorcelainSegment(
                value: BundledFontFamily.fredoka,
                label: 'Fredoka',
              ),
              PorcelainSegment(
                value: BundledFontFamily.pixelifySans,
                label: 'Pixel',
              ),
              PorcelainSegment(
                value: BundledFontFamily.poiretOne,
                label: 'Poiret',
              ),
              PorcelainSegment(
                value: BundledFontFamily.monoton,
                label: 'Monoton',
              ),
            ],
          ])
            PorcelainSegmentedControl<BundledFontFamily>(
              selected: bundled.family,
              disabledReason: reason,
              onChanged: locked
                  ? null
                  : (family) => i.update(
                      layer.id,
                      (l) => (l as TextLayer).copyWith(
                        font: BundledFont(
                          family,
                          weight: family.weights.contains(bundled.weight)
                              ? bundled.weight
                              : family.weights.last,
                        ),
                      ),
                    ),
              segments: row,
            ),
          PorcelainSegmentedControl<int>(
            selected: bundled.weight,
            disabledReason: reason,
            onChanged: locked
                ? null
                : (weight) => i.update(
                    layer.id,
                    (l) => (l as TextLayer).copyWith(
                      font: BundledFont(bundled.family, weight: weight),
                    ),
                  ),
            segments: [
              for (final weight in bundled.family.weights)
                PorcelainSegment(
                  value: weight,
                  label: switch (weight) {
                    400 => 'Regular',
                    500 => 'Medium',
                    600 => 'Semibold',
                    _ => '$weight',
                  },
                ),
            ],
          ),
        ] else
          Text(
            'An imported font, used as the template supplies it.',
            style: theme.text.bodyMedium.copyWith(color: theme.colors.inkMuted),
          ),
        InspectorPair(
          InspectorNumberField(
            label: 'Size',
            unit: 'pt',
            value: layer.sizePt,
            decimals: 1,
            min: 1,
            max: TextLayer.maxSizePt,
            enabled: !locked,
            disabledReason: reason,
            onCommit: (v) =>
                i.update(layer.id, (l) => (l as TextLayer).copyWith(sizePt: v)),
          ),
          InspectorNumberField(
            label: 'Spacing',
            unit: 'pt',
            value: layer.letterSpacingPt,
            decimals: 1,
            min: -50,
            max: 200,
            enabled: !locked,
            disabledReason: reason,
            onCommit: (v) => i.update(
              layer.id,
              (l) => (l as TextLayer).copyWith(letterSpacingPt: v),
            ),
          ),
        ),
        if (!locked)
          InspectorColorField(
            label: 'Colour',
            value: layer.color,
            onChanged: (c) =>
                i.update(layer.id, (l) => (l as TextLayer).copyWith(color: c)),
          ),
        Row(
          children: [
            for (final (align, icon, name) in const [
              (TextAlignment.left, PorcelainIcons.alignLeft, 'Align left'),
              (TextAlignment.center, PorcelainIcons.alignCenter, 'Centre'),
              (TextAlignment.right, PorcelainIcons.alignRight, 'Align right'),
            ])
              EditorIconToggle(
                icon: icon,
                toggled: layer.align == align,
                semanticLabel: name,
                disabledReason: reason,
                onPressed: locked
                    ? null
                    : () => i.update(
                        layer.id,
                        (l) => (l as TextLayer).copyWith(align: align),
                      ),
              ),
            const Spacer(),
            for (final (align, icon, name) in const [
              (VerticalAlignment.top, PorcelainIcons.alignTop, 'Top'),
              (VerticalAlignment.middle, PorcelainIcons.alignMiddle, 'Middle'),
              (VerticalAlignment.bottom, PorcelainIcons.alignBottom, 'Bottom'),
            ])
              EditorIconToggle(
                icon: icon,
                toggled: layer.verticalAlign == align,
                semanticLabel: name,
                disabledReason: reason,
                onPressed: locked
                    ? null
                    : () => i.update(
                        layer.id,
                        (l) => (l as TextLayer).copyWith(verticalAlign: align),
                      ),
              ),
          ],
        ),
        InspectorSlider(
          label: 'Line height',
          value: layer.lineHeight,
          min: 0.5,
          max: 3,
          enabled: !locked,
          valueLabel: '${layer.lineHeight.toStringAsFixed(2)}×',
          onStart: lineHeight.start,
          onChanged: lineHeight.change,
          onEnd: lineHeight.end,
        ),
      ],
    );
  }

  /// Whether [layer]'s words, laid out as the print renders them, are
  /// taller than its frame.
  static bool _overflows(TemplateEditorController controller, TextLayer layer) {
    for (final node in controller.scene.nodes) {
      if (node is TextNode && node.layerId == layer.id) {
        final paragraph = layoutText(
          node,
          controller.resources.fonts[node.font] ??
              const ResolvedFont(fallbackFontFamily, FontWeight.w400),
        );
        final over = paragraph.height > node.placement.rect.height + 0.5;
        paragraph.dispose();
        return over;
      }
    }
    return false;
  }
}

/// The words of a text layer. Typing updates the canvas live; one editing
/// session (until the field loses focus) is one undo step.
class _TextContentField extends StatefulWidget {
  const _TextContentField({required this.i, required this.layer});

  final _Inspect i;
  final TextLayer layer;

  @override
  State<_TextContentField> createState() => _TextContentFieldState();
}

class _TextContentFieldState extends State<_TextContentField> {
  late final _text = TextEditingController(text: widget.layer.text);
  var _inGesture = false;
  var _focused = false;

  @override
  void didUpdateWidget(_TextContentField old) {
    super.didUpdateWidget(old);
    if (!_focused && widget.layer.text != _text.text) {
      _text.text = widget.layer.text;
    }
  }

  @override
  void dispose() {
    if (_inGesture) widget.i.controller.endGesture();
    _text.dispose();
    super.dispose();
  }

  void _changed(String value) {
    final controller = widget.i.controller;
    if (!_inGesture) {
      controller.beginGesture();
      _inGesture = true;
    }
    final text = value.length > TextLayer.maxLength
        ? value.substring(0, TextLayer.maxLength)
        : value;
    widget.i.run(
      () => controller.updateLayerInGesture(
        widget.layer.id,
        (l) => (l as TextLayer).copyWith(text: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (focused) {
      _focused = focused;
      if (!focused && _inGesture) {
        _inGesture = false;
        widget.i.controller.endGesture();
      }
    },
    child: PorcelainTextField(
      label: 'Words',
      controller: _text,
      enabled: !widget.layer.locked,
      disabledReason: widget.layer.locked ? _lockedReason : null,
      minLines: 2,
      maxLines: 6,
      maxLength: TextLayer.maxLength,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      onChanged: _changed,
    ),
  );
}

class _ShapeSection extends StatelessWidget {
  const _ShapeSection(this.i, this.layer);

  final _Inspect i;
  final ShapeLayer layer;

  @override
  Widget build(BuildContext context) {
    final locked = layer.locked;
    final reason = locked ? _lockedReason : null;
    final stroke = layer.stroke;
    final radius = i.drag(
      layer.id,
      (l, v) => (l as ShapeLayer).copyWith(cornerRadius: v),
    );
    final strokeWidth = i.drag(
      layer.id,
      (l, v) => (l as ShapeLayer).copyWith(
        stroke: v < 0.25
            ? null
            : Stroke(
                widthPt: (v * 4).roundToDouble() / 4,
                color: stroke?.color ?? DocumentPalette.gold,
              ),
      ),
    );
    return InspectorSection(
      title: 'Shape',
      children: [
        PorcelainSegmentedControl<ShapeKind>(
          selected: layer.shape,
          disabledReason: reason,
          onChanged: locked
              ? null
              : (kind) => i.update(
                  layer.id,
                  (l) => (l as ShapeLayer).copyWith(
                    shape: kind,
                    cornerRadius: kind == ShapeKind.roundedRect
                        ? math.max(layer.cornerRadius, 0.1)
                        : layer.cornerRadius,
                  ),
                ),
          segments: const [
            PorcelainSegment(value: ShapeKind.rect, label: 'Rectangle'),
            PorcelainSegment(value: ShapeKind.roundedRect, label: 'Rounded'),
            PorcelainSegment(value: ShapeKind.ellipse, label: 'Oval'),
          ],
        ),
        if (layer.shape == ShapeKind.roundedRect)
          InspectorSlider(
            label: 'Corner roundness',
            value: layer.cornerRadius,
            min: 0,
            max: 0.5,
            enabled: !locked,
            valueLabel: '${(layer.cornerRadius * 200).round()}%',
            onStart: radius.start,
            onChanged: radius.change,
            onEnd: radius.end,
          ),
        if (!locked)
          InspectorColorField(
            label: 'Fill',
            value: layer.fill,
            allowNone: true,
            onChanged: (c) =>
                i.update(layer.id, (l) => (l as ShapeLayer).copyWith(fill: c)),
          ),
        InspectorSlider(
          label: 'Outline',
          value: stroke?.widthPt ?? 0,
          min: 0,
          max: 24,
          enabled: !locked,
          valueLabel: stroke == null ? 'None' : '${stroke.widthPt} pt',
          onStart: strokeWidth.start,
          onChanged: strokeWidth.change,
          onEnd: strokeWidth.end,
        ),
        if (stroke != null && !locked)
          InspectorColorField(
            label: 'Outline colour',
            value: stroke.color,
            onChanged: (c) => i.update(
              layer.id,
              (l) => (l as ShapeLayer).copyWith(
                stroke: Stroke(widthPt: stroke.widthPt, color: c!),
              ),
            ),
          ),
      ],
    );
  }
}
