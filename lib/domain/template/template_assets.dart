/// Files a template document refers to: images and fonts (A-05 Asset,
/// ADR-0010). Assets are content-addressed: an asset's id is the lowercase
/// hex SHA-256 of its bytes, so the same file always has the same id on
/// every device and in every package, and a reference proves which bytes it
/// means.
library;

import 'package:crypto/crypto.dart';

/// The id of an asset with these [bytes]: their lowercase hex SHA-256.
String assetIdOf(List<int> bytes) => sha256.convert(bytes).toString();

/// A colour as 0xAARRGGBB, written in documents as `#AARRGGBB`.
extension type const ArgbColor(int value) {
  int get alpha => (value >> 24) & 0xFF;
  int get red => (value >> 16) & 0xFF;
  int get green => (value >> 8) & 0xFF;
  int get blue => value & 0xFF;

  bool get isValid => value >= 0 && value <= 0xFFFFFFFF;

  String toHex() => '#${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  static final _hex = RegExp(r'^#[0-9A-Fa-f]{8}$');

  /// Parses `#AARRGGBB`; null when [text] is not in that form.
  static ArgbColor? tryParse(String text) => _hex.hasMatch(text)
      ? ArgbColor(int.parse(text.substring(1), radix: 16))
      : null;
}

enum AssetKind { image, font }

/// File types accepted as template assets (P-07: transparent PNG and JPEG
/// images; TrueType and OpenType fonts).
enum AssetMediaType {
  png('image/png', AssetKind.image, 'png'),
  jpeg('image/jpeg', AssetKind.image, 'jpg'),
  ttf('font/ttf', AssetKind.font, 'ttf'),
  otf('font/otf', AssetKind.font, 'otf');

  const AssetMediaType(this.mimeType, this.kind, this.extension);

  final String mimeType;
  final AssetKind kind;

  /// File extension used in managed storage and packages.
  final String extension;

  static AssetMediaType? fromMimeType(String mimeType) {
    for (final type in values) {
      if (type.mimeType == mimeType) return type;
    }
    return null;
  }
}

/// Size limits for assets (ADR-0010). Generous for print work, small enough
/// to bound decode memory on tablets.
abstract final class AssetLimits {
  static const maxImageSide = 12000;
  static const maxImagePixels = 50000000;
  static const maxImageBytes = 50 * 1024 * 1024;
  static const maxFontBytes = 20 * 1024 * 1024;
  static const maxNameLength = 120;
}

final _assetId = RegExp(r'^[0-9a-f]{64}$');

/// Whether [id] has the form of an asset id (64 lowercase hex digits).
bool isAssetId(String id) => _assetId.hasMatch(id);

/// What a document records about one asset. The bytes live in managed
/// storage under the same id.
final class TemplateAsset {
  const TemplateAsset({
    required this.mediaType,
    required this.byteLength,
    this.widthPx,
    this.heightPx,
    this.name,
  });

  final AssetMediaType mediaType;
  final int byteLength;

  /// Image size; null for fonts.
  final int? widthPx;
  final int? heightPx;

  /// The file name it was imported from, for operators; never a path.
  final String? name;

  AssetKind get kind => mediaType.kind;

  /// Problems with this record, empty when valid.
  List<String> get problems {
    final maxBytes = kind == AssetKind.image
        ? AssetLimits.maxImageBytes
        : AssetLimits.maxFontBytes;
    return [
      if (byteLength < 1 || byteLength > maxBytes)
        'byteLength must be 1 to $maxBytes',
      if (kind == AssetKind.image) ...[
        if (widthPx == null || heightPx == null)
          'images need widthPx and heightPx'
        else ...[
          if (widthPx! < 1 ||
              heightPx! < 1 ||
              widthPx! > AssetLimits.maxImageSide ||
              heightPx! > AssetLimits.maxImageSide)
            'each image side must be 1 to ${AssetLimits.maxImageSide} pixels',
          if (widthPx! * heightPx! > AssetLimits.maxImagePixels)
            'images must be at most ${AssetLimits.maxImagePixels} pixels',
        ],
      ] else if (widthPx != null || heightPx != null)
        'fonts have no pixel size',
      if (name != null &&
          (name!.isEmpty ||
              name!.length > AssetLimits.maxNameLength ||
              name!.contains('/') ||
              name!.contains(r'\')))
        'name must be a plain file name of 1 to ${AssetLimits.maxNameLength} '
            'characters',
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is TemplateAsset &&
      other.mediaType == mediaType &&
      other.byteLength == byteLength &&
      other.widthPx == widthPx &&
      other.heightPx == heightPx &&
      other.name == name;

  @override
  int get hashCode =>
      Object.hash(mediaType, byteLength, widthPx, heightPx, name);
}

/// Font families bundled with the app (SIL OFL 1.1, ADR-0008). Template text
/// in these families renders the same on every device.
enum BundledFontFamily {
  inter('Inter', [400, 500, 600]),
  cormorantGaramond('Cormorant Garamond', [500, 600]);

  const BundledFontFamily(this.family, this.weights);

  /// The family name as written in documents and registered with Flutter.
  final String family;

  /// The weights bundled; documents may use only these, so no weight is
  /// ever synthesised.
  final List<int> weights;

  static BundledFontFamily? fromFamily(String family) {
    for (final value in values) {
      if (value.family == family) return value;
    }
    return null;
  }
}

/// The typeface of a text layer.
sealed class FontRef {
  const FontRef();
}

/// A bundled family at one of its weights.
final class BundledFont extends FontRef {
  const BundledFont(this.family, {this.weight = 400});

  final BundledFontFamily family;
  final int weight;

  @override
  bool operator ==(Object other) =>
      other is BundledFont && other.family == family && other.weight == weight;

  @override
  int get hashCode => Object.hash(family, weight);

  @override
  String toString() => 'BundledFont(${family.family} $weight)';
}

/// An imported font file, used at its own weight.
final class AssetFont extends FontRef {
  const AssetFont(this.assetId);

  final String assetId;

  @override
  bool operator ==(Object other) =>
      other is AssetFont && other.assetId == assetId;

  @override
  int get hashCode => assetId.hashCode;

  @override
  String toString() => 'AssetFont($assetId)';
}
