import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/gallery/gallery_providers.dart';
import '../../domain/services/gallery_services.dart';

/// A stored thumbnail of a finished photo or camera photo (S13), made on
/// first use and decoded at about the size shown. A missing file shows a
/// plain placeholder, never an error screen.
class GalleryThumbnail extends ConsumerWidget {
  const GalleryThumbnail({
    super.key,
    required this.source,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  });

  final ThumbnailSource source;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.porcelain.colors;
    final thumbnail = ref.watch(thumbnailProvider(source));
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = MediaQuery.devicePixelRatioOf(context);
        final width = constraints.maxWidth.isFinite
            ? (constraints.maxWidth * ratio).round().clamp(1, 960)
            : null;
        return switch (thumbnail) {
          AsyncData(:final value) => Image.memory(
            value,
            fit: fit,
            cacheWidth: width,
            gaplessPlayback: true,
            semanticLabel: semanticLabel,
            excludeFromSemantics: semanticLabel == null,
          ),
          AsyncError() => Semantics(
            label: 'Photo missing',
            child: ColoredBox(
              color: colors.inset,
              child: Center(
                child: Icon(
                  PorcelainIcons.image,
                  size: 28,
                  color: colors.inkMuted,
                ),
              ),
            ),
          ),
          _ => ColoredBox(color: colors.inset, child: const SizedBox.expand()),
        };
      },
    );
  }
}

/// A finished photo shown as a print on a tray: hairline edge and a soft
/// shadow, at its own aspect ratio.
class PrintFrame extends StatelessWidget {
  const PrintFrame({super.key, required this.aspectRatio, required this.child});

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.raised,
          border: Border.all(color: colors.hairline),
          boxShadow: [
            BoxShadow(
              color: colors.shadowAmbient,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRect(child: child),
      ),
    );
  }
}

/// Spacing used by gallery tiles.
abstract final class GalleryMetrics {
  static const tileExtent = 228.0;
  static const tileSpacing = PorcelainSpace.xl;

  /// Width over height of a tile: a 2:3 photo well and two caption lines.
  static const tileAspect = 0.6;
}
