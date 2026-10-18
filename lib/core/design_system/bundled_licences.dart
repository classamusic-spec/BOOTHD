import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Licence texts of the bundled fonts, keyed by the name shown on the
/// licence page. Package licences (including the icon font's) are added by
/// Flutter automatically.
const bundledFontLicences = {
  'Inter (font)': 'assets/fonts/inter/OFL.txt',
  'Cormorant Garamond (font)': 'assets/fonts/cormorant_garamond/OFL.txt',
};

/// Adds the bundled fonts' licences to the app's licence page (AC-0211).
void registerBundledLicences([AssetBundle? bundle]) {
  final assets = bundle ?? rootBundle;
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: path)
        in bundledFontLicences.entries) {
      yield LicenseEntryWithLineBreaks([name], await assets.loadString(path));
    }
  });
}
