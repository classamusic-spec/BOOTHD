import '../../domain/repositories/template_store.dart';
import '../../domain/services/operator_files.dart';

/// What went wrong with templates, images and files, in plain words for
/// operators (S06, S08, S12). Never paths or file contents.
abstract final class TemplateMessages {
  static String storeError(TemplateStoreException error) =>
      switch (error.code) {
        TemplateStoreErrorCode.assetUnknownFormat =>
          'That file is not a PNG or JPEG image.',
        TemplateStoreErrorCode.assetUnsupportedVariant =>
          'That kind of image file is not supported. Save it as a PNG or '
              'JPEG and try again.',
        TemplateStoreErrorCode.assetDamaged =>
          'That image is damaged and could not be read.',
        TemplateStoreErrorCode.assetTooLarge =>
          'That image is too large: at most 50 MB and 12,000 pixels a side.',
        TemplateStoreErrorCode.assetMismatch ||
        TemplateStoreErrorCode.assetMissing =>
          "One of this template's images is missing or has changed on this "
              'device.',
        TemplateStoreErrorCode.assetInUse =>
          'A template or unsaved work still uses this image.',
        TemplateStoreErrorCode.invalidDocument =>
          error.detail == null
              ? 'The template breaks a rule and was not saved.'
              : 'Not saved: ${error.detail}.',
        TemplateStoreErrorCode.newerVersion =>
          'This template was made by a newer version of the app. Update the '
              'app to open it.',
        TemplateStoreErrorCode.notFound => 'That template no longer exists.',
        TemplateStoreErrorCode.manifestDamaged =>
          "This template's saved file is damaged and can't be opened.",
        TemplateStoreErrorCode.storageFailed =>
          "The booth's storage couldn't be written. Check free space and try "
              'again.',
        TemplateStoreErrorCode.packageInvalid =>
          "That file isn't a Porcelain template package, or parts of it are "
              'missing.',
        TemplateStoreErrorCode.packageUnsafe =>
          'That package contains unsafe file paths and was refused.',
        TemplateStoreErrorCode.packageTooLarge =>
          'That package is too large to import.',
        TemplateStoreErrorCode.packageUnsupported =>
          'That package is encrypted or compressed in a way the booth '
              "can't read.",
      };

  static String pickError(FilePickException error) => switch (error.failure) {
    FilePickFailure.tooLarge =>
      'That file is larger than '
          '${((error.limitBytes ?? 0) / (1024 * 1024)).round()} MB.',
    FilePickFailure.unreadable => "That file couldn't be read. Try again.",
  };
}
