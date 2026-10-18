/// Fonts for template text (A-06, ADR-0010).
///
/// Bundled families (Inter, Cormorant Garamond) are registered by the app
/// and render the same on every device. Imported fonts are registered with
/// the engine once per process, under a family named after their content
/// id, so two templates using the same file share it and a changed file can
/// never be confused with an old one. A font that is missing or not a font
/// falls back to the bundled default, and the render reports it.
library;

import 'package:flutter/services.dart';

import '../../domain/template/asset_formats.dart';
import '../../domain/template/template_assets.dart';

/// The family that replaces a font that cannot be loaded.
const fallbackFontFamily = 'Inter';

/// How a text layer's font resolved.
final class ResolvedFont {
  const ResolvedFont(this.family, this.weight, {this.fellBack = false});

  /// The family name to lay text out with.
  final String family;
  final FontWeight weight;

  /// The requested font could not be used; [family] is the fallback.
  final bool fellBack;
}

/// Loads imported font files into the engine on first use.
final class TemplateFontLoader {
  final _families = <String, Future<String?>>{};

  /// The family to use for [font]. [read] returns an imported font's bytes
  /// (and may throw if it is missing).
  Future<ResolvedFont> resolve(
    FontRef font,
    Future<Uint8List> Function(String assetId) read,
  ) async {
    switch (font) {
      case BundledFont(:final family, :final weight):
        return ResolvedFont(family.family, weightOf(weight));
      case AssetFont(:final assetId):
        final family = await (_families[assetId] ??= _load(assetId, read));
        return family == null
            ? const ResolvedFont(
                fallbackFontFamily,
                FontWeight.w400,
                fellBack: true,
              )
            : ResolvedFont(family, FontWeight.w400);
    }
  }

  static FontWeight weightOf(int weight) =>
      FontWeight.values[(weight ~/ 100 - 1).clamp(0, 8)];

  /// Engine family name for an imported font.
  static String familyFor(String assetId) =>
      'porcelain-font-${assetId.substring(0, 16)}';

  static Future<String?> _load(
    String assetId,
    Future<Uint8List> Function(String assetId) read,
  ) async {
    final Uint8List bytes;
    try {
      bytes = await read(assetId);
    } on Object {
      return null;
    }
    // The engine accepts anything silently and then draws with a system
    // font; refuse non-fonts and changed files here instead.
    if (sniffAsset(bytes).asset?.mediaType.kind != AssetKind.font ||
        assetIdOf(bytes) != assetId) {
      return null;
    }
    final family = familyFor(assetId);
    try {
      await (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    } on Object {
      return null;
    }
    return family;
  }
}
