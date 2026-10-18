import 'package:flutter/material.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../domain/template/template_layers.dart';
import '../../shared/widgets/pressable.dart';
import 'editor_canvas.dart';
import 'editor_controller.dart';
import 'inspector_controls.dart';

/// The layer tree (S09, AC-0504): every layer in the one global paint
/// order, top first, photo slots and artwork alike. Drag a row's handle to
/// reorder; tap a row to select it; show, hide, lock and unlock in place.
/// The background stays at the bottom.
class LayersPanel extends StatelessWidget {
  const LayersPanel({
    super.key,
    required this.controller,
    required this.onRefused,
  });

  final TemplateEditorController controller;
  final ValueChanged<Object> onRefused;

  void _run(VoidCallback edit) {
    try {
      edit();
    } on Exception catch (error) {
      onRefused(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final paintOrder = controller.document.paintOrder;
        final background = paintOrder.whereType<BackgroundLayer>().toList();
        final stack = [
          for (final layer in paintOrder.reversed)
            if (layer is! BackgroundLayer) layer,
        ];
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                PorcelainSpace.sm,
                PorcelainSpace.sm,
                PorcelainSpace.sm,
                0,
              ),
              sliver: SliverReorderableList(
                itemCount: stack.length,
                onReorderItem: (from, to) {
                  // Rows are top first; paint indexes count from the bottom
                  // and include the background.
                  final layer = stack[from];
                  final paintIndex = paintOrder.length - 1 - to;
                  _run(() => controller.moveLayer(layer.id, paintIndex));
                },
                itemBuilder: (context, index) {
                  final layer = stack[index];
                  return _LayerRow(
                    key: ValueKey(layer.id),
                    layer: layer,
                    index: index,
                    controller: controller,
                    run: _run,
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                PorcelainSpace.sm,
                0,
                PorcelainSpace.sm,
                PorcelainSpace.sm,
              ),
              sliver: SliverList.list(
                children: [
                  for (final layer in background)
                    _LayerRow(
                      key: ValueKey(layer.id),
                      layer: layer,
                      index: null,
                      controller: controller,
                      run: _run,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

IconData layerIcon(TemplateLayer layer) => switch (layer) {
  BackgroundLayer() => PorcelainIcons.background,
  PhotoSlotLayer() => PorcelainIcons.camera,
  ImageLayer() => PorcelainIcons.image,
  TextLayer() => PorcelainIcons.text,
  ShapeLayer(:final shape) => switch (shape) {
    ShapeKind.rect => PorcelainIcons.rectangle,
    ShapeKind.roundedRect => PorcelainIcons.roundedRectangle,
    ShapeKind.ellipse => PorcelainIcons.ellipse,
  },
};

String layerKind(TemplateLayer layer) => switch (layer) {
  BackgroundLayer() => 'Background',
  PhotoSlotLayer(:final slotIndex) => 'Photo ${slotIndex + 1}',
  ImageLayer() => 'Image',
  TextLayer() => 'Text',
  ShapeLayer() => 'Shape',
};

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    super.key,
    required this.layer,
    required this.index,
    required this.controller,
    required this.run,
  });

  final TemplateLayer layer;

  /// Position in the reorderable list; null for the fixed background.
  final int? index;
  final TemplateEditorController controller;
  final void Function(VoidCallback edit) run;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final selected = controller.isSelected(layer.id);
    final label = layerLabel(layer);
    final kind = layerKind(layer);
    final index = this.index;
    return Padding(
      padding: const EdgeInsets.only(bottom: PorcelainSpace.xxs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? colors.selected : null,
          borderRadius: PorcelainRadius.controlAll,
          border: Border.all(
            color: selected ? colors.focusRing : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            if (index != null)
              ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  label: 'Reorder $label',
                  hint: 'Drag up or down',
                  child: SizedBox(
                    width: 36,
                    height: 52,
                    child: Icon(
                      PorcelainIcons.dragHandle,
                      size: PorcelainSize.iconSmall,
                      color: colors.inkMuted,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 36),
            Expanded(
              child: Pressable(
                onPressed: () => controller.select(layer.id),
                semanticLabel: '$label, $kind',
                selected: selected,
                builder: (context, state) => ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Row(
                    children: [
                      Icon(
                        layerIcon(layer),
                        size: PorcelainSize.iconSmall,
                        color: colors.accentIcon,
                      ),
                      const SizedBox(width: PorcelainSpace.sm),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.text.labelLarge.copyWith(
                                color: layer.visible
                                    ? colors.ink
                                    : colors.inkMuted,
                              ),
                            ),
                            if (label != kind)
                              Text(
                                kind,
                                maxLines: 1,
                                style: theme.text.bodySmall.copyWith(
                                  color: colors.inkMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            EditorIconToggle(
              icon: PorcelainIcons.visible,
              activeIcon: PorcelainIcons.hidden,
              toggled: !layer.visible,
              semanticLabel: layer.visible ? 'Hide $label' : 'Show $label',
              onPressed: () => run(
                () => controller.setVisible(layer.id, visible: !layer.visible),
              ),
            ),
            EditorIconToggle(
              icon: PorcelainIcons.unlocked,
              activeIcon: PorcelainIcons.locked,
              toggled: layer.locked,
              semanticLabel: layer.locked ? 'Unlock $label' : 'Lock $label',
              onPressed: () => run(
                () => controller.setLocked(layer.id, locked: !layer.locked),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
