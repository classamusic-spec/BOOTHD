/// Import rules that keep the layered architecture honest (ADR-0005).
///
/// Pure logic, unit-tested in `layer_boundaries_test.dart` with deliberate
/// violations so a broken rule cannot pass silently.
library;

enum Layer { entrypoint, app, core, domain, features, infrastructure, shared }

/// Own-package layers each layer may import. Dependencies point inward; only
/// the composition root (`app`) sees everything.
const Map<Layer, Set<Layer>> allowedLayerImports = {
  Layer.entrypoint: {Layer.app},
  Layer.app: {...Layer.values},
  Layer.core: {Layer.core, Layer.domain},
  Layer.domain: {Layer.domain},
  Layer.features: {Layer.features, Layer.shared, Layer.core, Layer.domain},
  Layer.infrastructure: {Layer.infrastructure, Layer.core, Layer.domain},
  Layer.shared: {Layer.shared, Layer.core, Layer.domain},
};

const _uiPackages = {
  'flutter',
  'flutter_riverpod',
  'go_router',
  'meta',
  'collection',
};

/// External packages a layer may import. Layers absent from this map may
/// import any package: `infrastructure` adapts plugins and `app` wires them.
/// Widening a set is an architecture decision that needs an ADR.
const Map<Layer, Set<String>> allowedPackages = {
  Layer.entrypoint: {},
  Layer.core: _uiPackages,
  Layer.domain: {'meta', 'collection'},
  Layer.features: _uiPackages,
  Layer.shared: _uiPackages,
};

/// Dart SDK libraries the pure-Dart domain may use: no `dart:ui`, I/O,
/// isolates or FFI.
const allowedDomainDartLibraries = {
  'async',
  'collection',
  'convert',
  'core',
  'math',
  'typed_data',
};

/// Dart SDK libraries reserved for infrastructure and the composition root.
const platformDartLibraries = {'ffi', 'io', 'isolate'};

/// Returns the layer of a path relative to `lib/`, or null when the path is
/// outside the approved layout.
Layer? layerOf(String libPath) {
  final segments = libPath.split('/');
  if (segments.length == 1) {
    return libPath == 'main.dart' ? Layer.entrypoint : null;
  }
  for (final layer in Layer.values) {
    if (layer != Layer.entrypoint && segments.first == layer.name) {
      return layer;
    }
  }
  return null;
}

/// The feature a `features/<name>/...` path belongs to.
String? featureOf(String libPath) {
  final segments = libPath.split('/');
  return segments.length > 2 && segments.first == 'features'
      ? segments[1]
      : null;
}

/// Extracts every URI from the import and export directives in [source],
/// including conditional-import alternatives.
List<String> directiveUris(String source) {
  final directive = RegExp(
    r'^\s*(?:import|export)\s+([^;]+);',
    multiLine: true,
  );
  final uri = RegExp('[\'"]([^\'"]+)[\'"]');
  return [
    for (final match in directive.allMatches(source))
      for (final quoted in uri.allMatches(match.group(1)!)) quoted.group(1)!,
  ];
}

/// Describes each rule that [importUri] breaks when used from [libPath].
List<String> violationsFor({
  required String libPath,
  required String importUri,
  required String packageName,
}) {
  final layer = layerOf(libPath);
  if (layer == null) return ['$libPath is outside the approved lib/ layout'];

  if (importUri.startsWith('dart:')) {
    final library = importUri.substring('dart:'.length);
    if (layer == Layer.domain &&
        !allowedDomainDartLibraries.contains(library)) {
      return ['domain must stay pure Dart but $libPath imports $importUri'];
    }
    if (platformDartLibraries.contains(library) &&
        layer != Layer.infrastructure &&
        layer != Layer.app) {
      return ['$libPath imports $importUri; platform I/O is infrastructure'];
    }
    return const [];
  }

  final String targetPath;
  if (importUri.startsWith('package:')) {
    final rest = importUri.substring('package:'.length);
    final slash = rest.indexOf('/');
    final package = slash < 0 ? rest : rest.substring(0, slash);
    if (package != packageName) {
      final allowed = allowedPackages[layer];
      return allowed == null || allowed.contains(package)
          ? const []
          : ['${layer.name} may not import package:$package ($libPath)'];
    }
    targetPath = rest.substring(slash + 1);
  } else {
    final resolved = _resolveRelative(libPath, importUri);
    if (resolved == null) return ['$libPath imports $importUri outside lib/'];
    targetPath = resolved;
  }

  final target = layerOf(targetPath);
  if (target == null) {
    return ['$libPath imports $targetPath outside the approved layout'];
  }
  if (!allowedLayerImports[layer]!.contains(target)) {
    return [
      '${layer.name} may not import ${target.name} ($libPath -> $targetPath)',
    ];
  }
  final fromFeature = featureOf(libPath);
  final toFeature = featureOf(targetPath);
  if (fromFeature != null && toFeature != null && fromFeature != toFeature) {
    return [
      'feature $fromFeature may not import feature $toFeature '
          '($libPath -> $targetPath); share code via shared/ or domain/',
    ];
  }
  return const [];
}

String? _resolveRelative(String libPath, String relativeUri) {
  final parts = libPath.split('/')..removeLast();
  for (final segment in relativeUri.split('/')) {
    if (segment == '..') {
      if (parts.isEmpty) return null;
      parts.removeLast();
    } else if (segment != '.') {
      parts.add(segment);
    }
  }
  return parts.join('/');
}
