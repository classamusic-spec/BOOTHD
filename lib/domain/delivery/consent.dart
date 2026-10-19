import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

/// The words the guest agrees to on S31 (PD-02, AC-0904): one
/// transactional text, nothing else. A draft for the operator's legal
/// review and sender registration, not a pre-approved compliance template.
/// Any change to the wording needs a new [version]; the receipt records
/// the version and the SHA-256 of the exact text shown.
@immutable
final class ConsentText {
  const ConsentText({required this.brand, required this.linkDays});

  /// Bumped whenever the wording changes.
  static const version = 'pd-consent-1';

  /// The sender identity at the start of the text (the tenant's brand).
  final String brand;

  /// How long the download link works.
  final int linkDays;

  String get _days => linkDays == 1 ? '1 day' : '$linkDays days';

  /// Exactly what the guest sees next to the checkbox.
  String get text =>
      'I agree to receive one photo-delivery text from $brand at the '
      'number I entered. The text includes a photo preview and a private '
      'download link. Message and data rates may apply. Reply STOP to opt '
      'out or HELP for help. Your download link expires after $_days.';

  /// SHA-256 of [text] (UTF-8), lowercase hex: the receipt's proof of the
  /// words shown.
  String get digest => sha256.convert(utf8.encode(text)).toString();
}

/// What the guest accepted, when and where (PD-06). Sent with the
/// delivery; the service refuses a delivery without one.
@immutable
final class ConsentReceipt {
  const ConsentReceipt({
    required this.textVersion,
    required this.textDigest,
    required this.acceptedAtUtc,
    this.locale = 'en-US',
    this.sourceScreen = 'S31',
  });

  final String textVersion;
  final String textDigest;
  final DateTime acceptedAtUtc;
  final String locale;
  final String sourceScreen;

  Map<String, Object> toJson() => {
    'accepted': true,
    'textVersion': textVersion,
    'textDigest': textDigest,
    'acceptedAt': acceptedAtUtc.toUtc().toIso8601String(),
    'locale': locale,
    'sourceScreen': sourceScreen,
  };
}
