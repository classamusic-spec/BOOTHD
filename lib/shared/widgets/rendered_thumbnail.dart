import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_theme.dart';

/// A template drawn by the print renderer, shown as a small print on
/// paper with a soft shadow. While it renders, the paper is blank; if it
/// cannot be drawn, a warning mark says so (it is never left looking like
/// a finished design).
class RenderedThumbnail extends ConsumerWidget {
  const RenderedThumbnail({
    super.key,
    required this.thumbnail,
    required this.aspectRatio,
    required this.semanticLabel,
  });

  /// The rendered PNG, e.g. `templateThumbnailProvider(revisionId)`.
  final ProviderListenable<AsyncValue<Uint8List>> thumbnail;

  /// Page width over height.
  final double aspectRatio;
  final String semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.porcelain.colors;
    final image = ref.watch(thumbnail);
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.hairline),
              boxShadow: [
                BoxShadow(
                  color: colors.shadowKey,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: switch (image) {
              AsyncData(:final value) => Image.memory(
                value,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
              AsyncError() => Center(
                child: Icon(PorcelainIcons.warning, color: colors.warning),
              ),
              _ => const SizedBox.expand(),
            },
          ),
        ),
      ),
    );
  }
}
