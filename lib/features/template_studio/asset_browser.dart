import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/templates/bundled_decorations.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/services/operator_files.dart';
import '../../domain/template/asset_formats.dart';
import '../../domain/template/template_assets.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_sheet.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';
import 'editor_copy.dart';

/// Opens the asset browser (S08) and returns the image chosen, stored in
/// the template library; null when closed without choosing.
Future<StoredAsset?> chooseTemplateImage(BuildContext context) =>
    showPorcelainSheet<StoredAsset>(
      context: context,
      title: 'Add artwork',
      body: const _AssetBrowser(),
    );

enum _Tab { decorations, yours }

class _AssetBrowser extends ConsumerStatefulWidget {
  const _AssetBrowser();

  @override
  ConsumerState<_AssetBrowser> createState() => _AssetBrowserState();
}

class _AssetBrowserState extends ConsumerState<_AssetBrowser> {
  var _tab = _Tab.decorations;
  var _busy = false;

  Future<void> _choose(Future<StoredAsset> Function() store) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final asset = await store();
      if (mounted) Navigator.of(context).pop(asset);
    } on TemplateStoreException catch (error) {
      if (mounted) {
        PorcelainToast.show(
          context,
          EditorCopy.storeError(error),
          tone: PorcelainTone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final files = ref.read(operatorFilesProvider);
    final library = ref.read(templateLibraryProvider);
    final PickedFile? file;
    try {
      file = await files.pick(
        PickableFile.image,
        maxBytes: AssetLimits.maxImageBytes,
      );
    } on FilePickException catch (error) {
      if (mounted) {
        PorcelainToast.show(
          context,
          EditorCopy.pickError(error),
          tone: PorcelainTone.danger,
        );
      }
      return;
    }
    if (file == null) return;
    // The bytes are copied into managed storage now; the picker's
    // temporary file is never used again (AC-0508).
    await _choose(() => library.importImage(file!.bytes, name: file.name));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Transparent PNG artwork layers over photos and is never cut by '
          'them. Images are copied into the booth, so the original file can '
          'be moved or deleted afterwards.',
          style: theme.text.bodyMedium.copyWith(color: theme.colors.inkMuted),
        ),
        const SizedBox(height: PorcelainSpace.md),
        Row(
          children: [
            Expanded(
              child: PorcelainSegmentedControl<_Tab>(
                selected: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
                segments: const [
                  PorcelainSegment(
                    value: _Tab.decorations,
                    label: 'Decorations',
                    icon: PorcelainIcons.decorations,
                  ),
                  PorcelainSegment(
                    value: _Tab.yours,
                    label: 'Your images',
                    icon: PorcelainIcons.image,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.md),
        PorcelainButton(
          label: 'Import an image…',
          icon: PorcelainIcons.upload,
          busy: _busy,
          onPressed: _import,
        ),
        const SizedBox(height: PorcelainSpace.md),
        switch (_tab) {
          _Tab.decorations => _DecorationGrid(
            onChoose: (decoration) => _choose(
              () =>
                  ref.read(templateLibraryProvider).storeDecoration(decoration),
            ),
          ),
          _Tab.yours => _YourImages(
            onChoose: (asset) => _choose(() async => asset),
          ),
        },
      ],
    );
  }
}

class _DecorationGrid extends StatelessWidget {
  const _DecorationGrid({required this.onChoose});

  final ValueChanged<BundledDecoration> onChoose;

  @override
  Widget build(BuildContext context) => _TileGrid(
    children: [
      for (final decoration in bundledDecorations)
        _ImageTile(
          label: decoration.name,
          detail: switch (decoration.kind) {
            DecorationKind.floral => 'Florals',
            DecorationKind.frame => 'Frame',
            DecorationKind.accent => 'Accent',
          },
          transparent: true,
          image: Image.asset(
            decoration.assetPath,
            cacheWidth: 320,
            fit: BoxFit.contain,
          ),
          onPressed: () => onChoose(decoration),
        ),
    ],
  );
}

class _YourImages extends ConsumerWidget {
  const _YourImages({required this.onChoose});

  final ValueChanged<StoredAsset> onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetRepositoryProvider);
    return StreamBuilder<List<StoredAsset>>(
      stream: assets.watchImages(),
      builder: (context, snapshot) {
        final images = snapshot.data;
        if (snapshot.hasError) {
          return const EmptyState(
            icon: PorcelainIcons.error,
            title: "Your images couldn't be listed",
            message: 'Close this and try again.',
            tone: PorcelainTone.danger,
          );
        }
        if (images == null) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (images.isEmpty) {
          return const EmptyState(
            icon: PorcelainIcons.image,
            title: 'No images yet',
            message:
                'Import a PNG or JPEG. Transparent PNGs work best for '
                'artwork over photos.',
          );
        }
        return _TileGrid(
          children: [
            for (final image in images)
              _StoredImageTile(
                key: ValueKey(image.id),
                asset: image,
                onChoose: () => onChoose(image),
              ),
          ],
        );
      },
    );
  }
}

class _StoredImageTile extends ConsumerStatefulWidget {
  const _StoredImageTile({
    super.key,
    required this.asset,
    required this.onChoose,
  });

  final StoredAsset asset;
  final VoidCallback onChoose;

  @override
  ConsumerState<_StoredImageTile> createState() => _StoredImageTileState();
}

class _StoredImageTileState extends ConsumerState<_StoredImageTile> {
  late Future<Uint8List> _bytes = ref
      .read(assetRepositoryProvider)
      .read(widget.asset.id);
  late Future<bool> _inUse = ref
      .read(assetRepositoryProvider)
      .isInUse(widget.asset.id);

  Future<void> _rename() async {
    final name = await showPorcelainNameSheet(
      context: context,
      title: 'Rename image',
      label: 'Name',
      initialValue: widget.asset.asset.name ?? '',
      maxLength: AssetLimits.maxNameLength,
    );
    if (name == null || !mounted) return;
    try {
      await ref.read(assetRepositoryProvider).rename(widget.asset.id, name);
    } on TemplateStoreException catch (error) {
      if (mounted) {
        PorcelainToast.show(context, EditorCopy.storeError(error));
      }
    }
  }

  Future<void> _remove() async {
    final confirmed = await showPorcelainSheet<bool>(
      context: context,
      title: 'Remove this image?',
      body: const Text(
        'No template uses it. It is deleted from the booth; the original '
        'file elsewhere is not affected.',
      ),
      actions: (sheet) => [
        PorcelainButton(
          label: 'Keep it',
          onPressed: () => Navigator.of(sheet).pop(false),
        ),
        PorcelainButton(
          label: 'Remove',
          icon: PorcelainIcons.delete,
          variant: PorcelainButtonVariant.danger,
          onPressed: () => Navigator.of(sheet).pop(true),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(assetRepositoryProvider).remove(widget.asset.id);
    } on TemplateStoreException catch (error) {
      if (mounted) {
        setState(
          () => _inUse = ref
              .read(assetRepositoryProvider)
              .isInUse(widget.asset.id),
        );
        PorcelainToast.show(context, EditorCopy.storeError(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        final damaged = snapshot.hasError;
        return _ImageTile(
          label: asset.asset.name ?? 'Image',
          detail: '${asset.asset.widthPx} × ${asset.asset.heightPx} px',
          transparent: bytes != null && pngHasTransparency(bytes),
          damaged: damaged,
          image: bytes == null
              ? null
              : Image.memory(bytes, cacheWidth: 320, fit: BoxFit.contain),
          onPressed: damaged ? null : widget.onChoose,
          actions: FutureBuilder<bool>(
            future: _inUse,
            builder: (context, used) => Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _TileAction(
                  icon: PorcelainIcons.rename,
                  label: 'Rename ${asset.asset.name ?? 'image'}',
                  onPressed: _rename,
                ),
                _TileAction(
                  icon: PorcelainIcons.delete,
                  label: 'Remove ${asset.asset.name ?? 'image'}',
                  disabledReason: used.data == false
                      ? null
                      : 'A template or unsaved work uses this image.',
                  onPressed: used.data == false ? _remove : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(_StoredImageTile old) {
    super.didUpdateWidget(old);
    if (old.asset.id != widget.asset.id) {
      final assets = ref.read(assetRepositoryProvider);
      _bytes = assets.read(widget.asset.id);
      _inUse = assets.isInUse(widget.asset.id);
    }
  }
}

class _TileAction extends StatelessWidget {
  const _TileAction({
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
    final reason = disabledReason;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      disabledReason: reason,
      onDisabledTap: reason == null
          ? null
          : () => PorcelainToast.show(context, reason),
      builder: (context, state) => SizedBox(
        width: 48,
        height: 48,
        child: Icon(
          icon,
          size: PorcelainSize.iconSmall,
          color: state.enabled ? colors.inkMuted : colors.inkDisabled,
        ),
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = (constraints.maxWidth / 170).floor().clamp(2, 5);
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: PorcelainSpace.sm,
        crossAxisSpacing: PorcelainSpace.sm,
        childAspectRatio: 0.72,
        children: children,
      );
    },
  );
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.label,
    required this.detail,
    required this.image,
    required this.onPressed,
    this.transparent = false,
    this.damaged = false,
    this.actions,
  });

  final String label;
  final String detail;
  final Widget? image;
  final VoidCallback? onPressed;
  final bool transparent;
  final bool damaged;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: PorcelainRadius.controlAll,
        border: Border.all(color: colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Pressable(
              onPressed: onPressed,
              semanticLabel: 'Use $label',
              disabledReason: damaged
                  ? 'This image is damaged and cannot be used.'
                  : null,
              builder: (context, state) => Padding(
                padding: const EdgeInsets.all(PorcelainSpace.xs),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: CustomPaint(
                    painter: _Checkerboard(colors.inset, colors.surface),
                    child: Center(
                      child: damaged
                          ? Icon(PorcelainIcons.error, color: colors.danger)
                          : image ??
                                const SizedBox.square(
                                  dimension: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PorcelainSpace.sm,
              0,
              PorcelainSpace.sm,
              PorcelainSpace.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.text.labelLarge.copyWith(color: colors.ink),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
                ),
                if (transparent)
                  const Padding(
                    padding: EdgeInsets.only(top: PorcelainSpace.xxs),
                    child: StatusBadge(
                      label: 'Transparent',
                      tone: PorcelainTone.info,
                      icon: PorcelainIcons.transparent,
                    ),
                  ),
                ?actions,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The usual sign of transparency behind artwork.
class _Checkerboard extends CustomPainter {
  _Checkerboard(this.dark, this.light);

  final Color dark;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = light);
    final paint = Paint()..color = dark.withValues(alpha: 0.5);
    const cell = 10.0;
    for (var y = 0.0; y < size.height; y += cell) {
      for (
        var x = ((y / cell).floor().isEven ? 0.0 : cell);
        x < size.width;
        x += cell * 2
      ) {
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Checkerboard old) =>
      old.dark != dark || old.light != light;
}
