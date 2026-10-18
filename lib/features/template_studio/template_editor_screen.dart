import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/routing/route_paths.dart';
import '../../core/templates/document_colors.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/template/template_layers.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_sheet.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';
import 'asset_browser.dart';
import 'editor_canvas.dart';
import 'editor_controller.dart';
import 'editor_copy.dart';
import 'editor_viewport.dart';
import 'inspector_panel.dart';
import 'layers_panel.dart';

/// The side panel's two views.
enum _Panel { inspector, layers }

/// The Template Studio (S07): a zoomable canvas with the template's
/// layers, tools to add photo slots, artwork, text and shapes, the layer
/// tree and the inspector. Landscape shows tools on the left and the panel
/// on the right; portrait condenses the bar, puts the tools in a bottom
/// shelf and the panel in a sheet over the canvas. Rotating keeps the
/// selection, history and view (UX-03, UX-08).
///
/// Work is autosaved as a draft a moment after each change and whenever
/// the app leaves the foreground; Save stores a new revision. Leaving with
/// unsaved work asks first, and reopening offers a draft back (AC-0507).
class TemplateEditorScreen extends ConsumerStatefulWidget {
  const TemplateEditorScreen({super.key, required this.templateId});

  final String templateId;

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  TemplateEditorController? _controller;
  EditorViewport? _viewport;
  TemplateStoreException? _loadError;
  var _panel = _Panel.inspector;
  var _sheetOpen = false;
  late final AppLifecycleListener _lifecycle;
  final _focus = FocusNode(debugLabel: 'template editor');

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: _keepDraft,
      onHide: _keepDraft,
      onPause: _keepDraft,
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _focus.dispose();
    _controller?.dispose();
    _viewport?.dispose();
    super.dispose();
  }

  void _keepDraft() {
    final controller = _controller;
    if (controller != null && controller.hasUnsavedChanges) {
      unawaited(controller.writeDraft());
    }
  }

  Future<void> _load() async {
    final library = ref.read(templateLibraryProvider);
    try {
      final opened = await library.open(widget.templateId);
      if (!mounted) return;
      var draft = opened.draft;
      if (draft != null) {
        final restore = await _askRestore(draft, opened.revision);
        if (!mounted) return;
        if (restore != true) {
          await library.discardDraft(widget.templateId);
          draft = null;
        }
      }
      if (!mounted) return;
      final page = opened.revision.document.page;
      setState(() {
        _controller = TemplateEditorController(
          library: library,
          assets: ref.read(assetRepositoryProvider),
          revision: opened.revision,
          restoredDraft: draft,
        );
        _viewport = EditorViewport(
          pageWidth: page.widthPx.toDouble(),
          pageHeight: page.heightPx.toDouble(),
        );
      });
    } on TemplateStoreException catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  Future<bool?> _askRestore(
    TemplateDraft draft,
    StoredTemplateRevision revision,
  ) => showPorcelainSheet<bool>(
    context: context,
    title: 'Pick up where you left off?',
    body: Text(
      'Changes to "${revision.summary.templateName}" from '
      '${formatTimestamp(draft.savedAt.toLocal())} were not saved. '
      '${draft.baseRevisionId == revision.summary.revisionId ? '' : 'They were made to an earlier revision; restoring puts them on top of the newest one. '}'
      'Restore them to keep editing, or discard them and open the saved '
      'template.',
    ),
    actions: (sheet) => [
      PorcelainButton(
        label: 'Discard',
        icon: PorcelainIcons.delete,
        variant: PorcelainButtonVariant.quiet,
        onPressed: () => Navigator.of(sheet).pop(false),
      ),
      PorcelainButton(
        label: 'Restore',
        icon: PorcelainIcons.restore,
        variant: PorcelainButtonVariant.primary,
        onPressed: () => Navigator.of(sheet).pop(true),
      ),
    ],
  );

  void _refused(Object error) {
    if (!mounted) return;
    PorcelainToast.show(
      context,
      error is FormatException ? error.message : EditorCopy.refusal(error),
      tone: PorcelainTone.warning,
    );
  }

  void _run(VoidCallback edit) {
    try {
      edit();
    } on Exception catch (error) {
      _refused(error);
    }
  }

  Future<void> _save() async {
    final controller = _controller!;
    try {
      await controller.save();
      if (!mounted) return;
      PorcelainToast.show(
        context,
        EditorCopy.saved(controller.revision.summary.revisionNumber),
        tone: PorcelainTone.success,
        icon: PorcelainIcons.success,
      );
    } on TemplateStoreException catch (error) {
      if (!mounted) return;
      PorcelainToast.show(
        context,
        '${EditorCopy.storeError(error)} Your changes are still here.',
        tone: PorcelainTone.danger,
      );
    }
  }

  Future<void> _addImage() async {
    final asset = await chooseTemplateImage(context);
    if (asset == null || !mounted) return;
    try {
      await _controller!.addImage(asset);
    } on Exception catch (error) {
      _refused(error);
    }
  }

  Future<void> _chooseShape() async {
    final kind = await showPorcelainSheet<ShapeKind>(
      context: context,
      title: 'Add a shape',
      body: Wrap(
        spacing: PorcelainSpace.sm,
        runSpacing: PorcelainSpace.sm,
        children: [
          for (final (kind, icon, label) in const [
            (ShapeKind.rect, PorcelainIcons.rectangle, 'Rectangle'),
            (
              ShapeKind.roundedRect,
              PorcelainIcons.roundedRectangle,
              'Rounded rectangle',
            ),
            (ShapeKind.ellipse, PorcelainIcons.ellipse, 'Oval'),
          ])
            Builder(
              builder: (sheet) => PorcelainButton(
                label: label,
                icon: icon,
                onPressed: () => Navigator.of(sheet).pop(kind),
              ),
            ),
        ],
      ),
    );
    if (kind != null) _run(() => _controller!.addShape(kind));
  }

  void _background() {
    final controller = _controller!;
    final existing = controller.document.background;
    if (existing == null) {
      _run(
        () => unawaited(
          controller
              .setBackground(const SolidFill(DocumentPalette.ivory))
              .then(
                (_) => controller.select(controller.document.background?.id),
              ),
        ),
      );
    } else {
      controller.select(existing.id);
    }
    _showPanel(_Panel.inspector);
  }

  void _showPanel(_Panel panel) => setState(() {
    if (_sheetOpen && _panel == panel) {
      _sheetOpen = false;
    } else {
      _panel = panel;
      _sheetOpen = true;
    }
  });

  Future<bool> _confirmLeave() async {
    final controller = _controller;
    if (controller == null || !controller.hasUnsavedChanges) return true;
    final choice = await showPorcelainSheet<String>(
      context: context,
      title: 'Save your changes?',
      body: const Text(
        'Save them as a new revision, or leave them as a draft to finish '
        'later. Events keep using the revision they offer until you choose '
        'another.',
      ),
      actions: (sheet) => [
        PorcelainButton(
          label: 'Discard',
          icon: PorcelainIcons.delete,
          variant: PorcelainButtonVariant.danger,
          onPressed: () => Navigator.of(sheet).pop('discard'),
        ),
        PorcelainButton(
          label: 'Keep as draft',
          onPressed: () => Navigator.of(sheet).pop('draft'),
        ),
        PorcelainButton(
          label: 'Save',
          icon: PorcelainIcons.save,
          variant: PorcelainButtonVariant.primary,
          onPressed: () => Navigator.of(sheet).pop('save'),
        ),
      ],
    );
    switch (choice) {
      case 'save':
        await _save();
        return !controller.hasUnsavedChanges;
      case 'draft':
        await controller.writeDraft();
        return true;
      case 'discard':
        await controller.discardChanges();
        return true;
      default:
        return false;
    }
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.templates);
    }
  }

  void _preview() {
    final controller = _controller!;
    unawaited(
      context.push(
        RoutePaths.templatePreview(controller.templateId),
        extra: controller.document,
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> _shortcuts(
    TemplateEditorController controller,
    EditorViewport viewport,
  ) {
    SingleActivator cmd(LogicalKeyboardKey key, {bool shift = false}) =>
        SingleActivator(key, meta: true, shift: shift);
    SingleActivator ctrl(LogicalKeyboardKey key, {bool shift = false}) =>
        SingleActivator(key, control: true, shift: shift);
    final undo = controller.undo;
    final redo = controller.redo;
    void duplicate() => _run(controller.duplicateSelected);
    void save() => unawaited(_save());
    return {
      cmd(LogicalKeyboardKey.keyZ): undo,
      ctrl(LogicalKeyboardKey.keyZ): undo,
      cmd(LogicalKeyboardKey.keyZ, shift: true): redo,
      ctrl(LogicalKeyboardKey.keyZ, shift: true): redo,
      ctrl(LogicalKeyboardKey.keyY): redo,
      cmd(LogicalKeyboardKey.keyD): duplicate,
      ctrl(LogicalKeyboardKey.keyD): duplicate,
      cmd(LogicalKeyboardKey.keyS): save,
      ctrl(LogicalKeyboardKey.keyS): save,
      cmd(LogicalKeyboardKey.digit0): viewport.fit,
      ctrl(LogicalKeyboardKey.digit0): viewport.fit,
      cmd(LogicalKeyboardKey.equal): viewport.zoomIn,
      ctrl(LogicalKeyboardKey.equal): viewport.zoomIn,
      cmd(LogicalKeyboardKey.minus): viewport.zoomOut,
      ctrl(LogicalKeyboardKey.minus): viewport.zoomOut,
      const SingleActivator(LogicalKeyboardKey.delete): () =>
          _run(controller.deleteSelected),
      const SingleActivator(LogicalKeyboardKey.backspace): () =>
          _run(controller.deleteSelected),
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          controller.select(null),
      for (final (key, dx, dy) in const [
        (LogicalKeyboardKey.arrowLeft, -1.0, 0.0),
        (LogicalKeyboardKey.arrowRight, 1.0, 0.0),
        (LogicalKeyboardKey.arrowUp, 0.0, -1.0),
        (LogicalKeyboardKey.arrowDown, 0.0, 1.0),
      ]) ...{
        SingleActivator(key): () => _run(() => controller.nudge(dx, dy)),
        SingleActivator(key, shift: true): () =>
            _run(() => controller.nudge(dx * 10, dy * 10)),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final viewport = _viewport;
    final error = _loadError;
    if (controller == null || viewport == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                title: 'Template',
                status: error == null ? 'Opening…' : null,
                onBack: _leave,
              ),
              Expanded(
                child: error == null
                    ? const Padding(
                        padding: EdgeInsets.all(PorcelainSpace.xxl),
                        child: SkeletonList(
                          semanticLabel: 'Opening the template',
                        ),
                      )
                    : EmptyState(
                        icon: PorcelainIcons.error,
                        title: "This template couldn't be opened",
                        message: EditorCopy.storeError(error),
                        tone: PorcelainTone.danger,
                        actions: [
                          PorcelainButton(
                            label: 'Back to Templates',
                            icon: PorcelainIcons.back,
                            onPressed: () => context.go(RoutePaths.templates),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => PopScope(
        canPop: !controller.hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await _confirmLeave() && mounted) _leave();
        },
        child: CallbackShortcuts(
          bindings: _shortcuts(controller, viewport),
          child: Focus(
            focusNode: _focus,
            autofocus: true,
            child: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final wide =
                      constraints.maxWidth >= 1000 &&
                      constraints.maxWidth > constraints.maxHeight;
                  return wide
                      ? _wideLayout(controller, viewport)
                      : _compactLayout(controller, viewport);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar(TemplateEditorController controller, {required bool compact}) =>
      _TopBar(
        title: controller.templateName,
        status: EditorCopy.draftState(
          controller.draftState,
          saving: controller.saving,
        ),
        onBack: () => Navigator.of(context).maybePop(),
        actions: [
          EditorBarButton(
            icon: PorcelainIcons.undo,
            label: 'Undo',
            onPressed: controller.canUndo ? controller.undo : null,
            disabledReason: 'Nothing to undo.',
          ),
          EditorBarButton(
            icon: PorcelainIcons.redo,
            label: 'Redo',
            onPressed: controller.canRedo ? controller.redo : null,
            disabledReason: 'Nothing to redo.',
          ),
          const SizedBox(width: PorcelainSpace.sm),
          if (!compact)
            PorcelainButton(
              label: 'Preview',
              icon: PorcelainIcons.preview,
              size: PorcelainButtonSize.compact,
              onPressed: _preview,
            )
          else
            EditorBarButton(
              icon: PorcelainIcons.preview,
              label: 'Preview',
              onPressed: _preview,
            ),
          const SizedBox(width: PorcelainSpace.xs),
          PorcelainButton(
            label: 'Save',
            icon: PorcelainIcons.save,
            variant: PorcelainButtonVariant.primary,
            size: PorcelainButtonSize.compact,
            busy: controller.saving,
            busyLabel: 'Saving',
            disabledReason: 'Everything is saved.',
            onPressed: controller.hasUnsavedChanges ? _save : null,
          ),
        ],
      );

  List<_Tool> _tools(TemplateEditorController controller) => [
    _Tool(
      PorcelainIcons.selectTool,
      'Select',
      () => controller.tool = EditorTool.select,
      selected: controller.tool == EditorTool.select,
    ),
    _Tool(
      PorcelainIcons.panTool,
      'Pan',
      () => controller.tool = EditorTool.pan,
      selected: controller.tool == EditorTool.pan,
    ),
    _Tool(PorcelainIcons.background, 'Background', _background),
    _Tool(
      PorcelainIcons.photoSlot,
      'Photo',
      () => _run(controller.addPhotoSlot),
    ),
    _Tool(PorcelainIcons.image, 'Artwork', () => unawaited(_addImage())),
    _Tool(PorcelainIcons.text, 'Text', () => _run(controller.addText)),
    _Tool(PorcelainIcons.shape, 'Shape', () => unawaited(_chooseShape())),
  ];

  Widget _wideLayout(
    TemplateEditorController controller,
    EditorViewport viewport,
  ) {
    final colors = context.porcelain.colors;
    return Column(
      children: [
        SafeArea(bottom: false, child: _bar(controller, compact: false)),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.rail,
                  border: Border(right: BorderSide(color: colors.divider)),
                ),
                child: SafeArea(
                  top: false,
                  right: false,
                  child: SizedBox(
                    width: 92,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        vertical: PorcelainSpace.sm,
                      ),
                      children: [
                        for (final tool in _tools(controller))
                          _ToolTile(tool: tool),
                        _ToolTile(
                          tool: _Tool(
                            PorcelainIcons.layers,
                            'Layers',
                            () => setState(() => _panel = _Panel.layers),
                            selected: _panel == _Panel.layers,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: _canvas(controller, viewport)),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(left: BorderSide(color: colors.divider)),
                ),
                child: SafeArea(
                  top: false,
                  left: false,
                  child: SizedBox(
                    width: 380,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            PorcelainSpace.lg,
                            PorcelainSpace.md,
                            PorcelainSpace.lg,
                            0,
                          ),
                          child: _panelSwitch(),
                        ),
                        Expanded(child: _panelBody(controller)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compactLayout(
    TemplateEditorController controller,
    EditorViewport viewport,
  ) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(bottom: false, child: _bar(controller, compact: true)),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sheetHeight = constraints.maxHeight * 0.5;
              return Stack(
                children: [
                  Positioned.fill(child: _canvas(controller, viewport)),
                  AnimatedPositioned(
                    duration: motion.standard,
                    curve: Curves.easeOutCubic,
                    left: 0,
                    right: 0,
                    height: sheetHeight,
                    bottom: _sheetOpen ? 0 : -sheetHeight - 24,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(PorcelainRadius.dialog),
                        ),
                        border: Border.all(color: colors.divider),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadowAmbient,
                            blurRadius: 24,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              PorcelainSpace.lg,
                              PorcelainSpace.sm,
                              PorcelainSpace.xs,
                              0,
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _panelSwitch()),
                                EditorBarButton(
                                  icon: PorcelainIcons.close,
                                  label: 'Close panel',
                                  onPressed: () =>
                                      setState(() => _sheetOpen = false),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _sheetOpen
                                ? _panelBody(controller)
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.rail,
            border: Border(top: BorderSide(color: colors.divider)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: PorcelainSpace.sm,
                vertical: PorcelainSpace.xxs,
              ),
              child: Row(
                children: [
                  for (final tool in _tools(controller))
                    _ToolTile(tool: tool, compact: true),
                  _ToolTile(
                    compact: true,
                    tool: _Tool(
                      PorcelainIcons.layers,
                      'Layers',
                      () => _showPanel(_Panel.layers),
                      selected: _sheetOpen && _panel == _Panel.layers,
                    ),
                  ),
                  _ToolTile(
                    compact: true,
                    tool: _Tool(
                      PorcelainIcons.inspector,
                      'Inspector',
                      () => _showPanel(_Panel.inspector),
                      selected: _sheetOpen && _panel == _Panel.inspector,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _panelSwitch() => PorcelainSegmentedControl<_Panel>(
    selected: _panel,
    onChanged: (panel) => setState(() => _panel = panel),
    segments: const [
      PorcelainSegment(
        value: _Panel.inspector,
        label: 'Inspector',
        icon: PorcelainIcons.inspector,
      ),
      PorcelainSegment(
        value: _Panel.layers,
        label: 'Layers',
        icon: PorcelainIcons.layers,
      ),
    ],
  );

  Widget _panelBody(TemplateEditorController controller) => switch (_panel) {
    _Panel.inspector => InspectorPanel(
      controller: controller,
      onRefused: _refused,
      chooseImage: chooseTemplateImage,
    ),
    _Panel.layers => LayersPanel(controller: controller, onRefused: _refused),
  };

  Widget _canvas(TemplateEditorController controller, EditorViewport viewport) {
    final colors = context.porcelain.colors;
    return ColoredBox(
      color: colors.inset,
      child: Stack(
        children: [
          Positioned.fill(
            child: EditorCanvas(
              controller: controller,
              viewport: viewport,
              onRefused: _refused,
            ),
          ),
          Positioned(
            left: PorcelainSpace.md,
            bottom: PorcelainSpace.md,
            child: _ZoomControls(viewport: viewport),
          ),
          if (!controller.ready)
            const Positioned(
              right: PorcelainSpace.md,
              bottom: PorcelainSpace.md,
              child: StatusBadge(
                label: 'Loading artwork…',
                tone: PorcelainTone.info,
                icon: PorcelainIcons.busy,
              ),
            ),
        ],
      ),
    );
  }
}

final class _Tool {
  const _Tool(this.icon, this.label, this.onPressed, {this.selected});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// For mode tools (select, pan, panel switches); null for actions.
  final bool? selected;
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool, this.compact = false});

  final _Tool tool;

  /// Tighter spacing, for the portrait shelf.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    final selected = tool.selected ?? false;
    return Pressable(
      onPressed: tool.onPressed,
      semanticLabel: tool.label,
      selected: tool.selected,
      builder: (context, state) => AnimatedContainer(
        duration: motion.press,
        width: 80,
        height: 68,
        margin: EdgeInsets.symmetric(horizontal: compact ? 2 : 6, vertical: 3),
        decoration: BoxDecoration(
          color: state.pressed
              ? colors.inset
              : selected
              ? colors.selected
              : null,
          borderRadius: PorcelainRadius.controlAll,
          border: Border.all(
            color: state.focused
                ? colors.focusRing
                : selected
                ? colors.accentIcon
                : Colors.transparent,
            width: state.focused ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tool.icon,
              size: PorcelainSize.icon,
              fill: selected ? 1 : 0,
              color: selected ? colors.accentIcon : colors.ink,
            ),
            const SizedBox(height: 4),
            Text(
              tool.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: selected
                  ? theme.text.labelMedium.copyWith(fontWeight: FontWeight.w600)
                  : theme.text.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact icon button for the editor's bars.
class EditorBarButton extends StatelessWidget {
  const EditorBarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.disabledReason,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final reason = onPressed == null ? disabledReason : null;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      disabledReason: reason,
      onDisabledTap: reason == null
          ? null
          : () => PorcelainToast.show(context, reason),
      builder: (context, state) => Tooltip(
        message: label,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: state.pressed ? colors.inset : null,
            shape: BoxShape.circle,
            border: state.focused
                ? Border.all(color: colors.focusRing, width: 2)
                : null,
          ),
          child: Icon(
            icon,
            size: PorcelainSize.icon,
            color: state.enabled ? colors.ink : colors.inkDisabled,
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    this.status,
    this.actions = const [],
  });

  final String title;
  final String? status;
  final VoidCallback onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final status = this.status;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.rail,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PorcelainSpace.sm,
          vertical: PorcelainSpace.xxs,
        ),
        child: Row(
          children: [
            EditorBarButton(
              icon: PorcelainIcons.back,
              label: 'Back to Templates',
              onPressed: onBack,
            ),
            const SizedBox(width: PorcelainSpace.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.text.titleMedium,
                    ),
                  ),
                  if (status != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.text.bodySmall.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.viewport});

  final EditorViewport viewport;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return ListenableBuilder(
      listenable: viewport,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.94),
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EditorBarButton(
              icon: PorcelainIcons.zoomOut,
              label: 'Zoom out',
              onPressed: viewport.scale > viewport.minScale
                  ? viewport.zoomOut
                  : null,
              disabledReason: 'Zoomed out as far as it goes.',
            ),
            Semantics(
              label: 'Zoom',
              value: '${viewport.percent}%',
              child: SizedBox(
                width: 56,
                child: Text(
                  '${viewport.percent}%',
                  textAlign: TextAlign.center,
                  style: theme.text.numeric.copyWith(color: colors.ink),
                ),
              ),
            ),
            EditorBarButton(
              icon: PorcelainIcons.zoomIn,
              label: 'Zoom in',
              onPressed: viewport.scale < EditorViewport.maxScale
                  ? viewport.zoomIn
                  : null,
              disabledReason: 'Zoomed in as far as it goes.',
            ),
            EditorBarButton(
              icon: PorcelainIcons.fitScreen,
              label: 'Fit the page',
              onPressed: viewport.fitted ? null : viewport.fit,
              disabledReason: 'The page already fits.',
            ),
          ],
        ),
      ),
    );
  }
}
