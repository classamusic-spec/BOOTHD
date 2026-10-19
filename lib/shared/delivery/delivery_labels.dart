import '../../domain/delivery/consent.dart';
import '../../domain/delivery/delivery_intent.dart';
import '../widgets/tone.dart';

/// Words operators read about phone delivery (S34 to S36, UX-PD5,
/// UX-PD6): status pills that never claim more than the provider said,
/// readiness reasons, and the consent proof for sender registration.
abstract final class DeliveryLabels {
  static String phase(DeliveryPhase phase) => switch (phase) {
    DeliveryPhase.queuedLocally => 'Queued locally',
    DeliveryPhase.uploading => 'Uploading',
    DeliveryPhase.sending => 'Sending',
    DeliveryPhase.submitted => 'Submitted',
    DeliveryPhase.sent => 'Sent',
    DeliveryPhase.delivered => 'Delivered',
    DeliveryPhase.failed => 'Failed',
    DeliveryPhase.unknown => 'Unknown',
    DeliveryPhase.expired => 'Expired',
    DeliveryPhase.canceled => 'Canceled',
  };

  static PorcelainTone tone(DeliveryPhase phase) => switch (phase) {
    DeliveryPhase.delivered => PorcelainTone.success,
    DeliveryPhase.submitted || DeliveryPhase.sent => PorcelainTone.info,
    DeliveryPhase.failed => PorcelainTone.danger,
    DeliveryPhase.unknown || DeliveryPhase.expired => PorcelainTone.warning,
    _ => PorcelainTone.neutral,
  };

  /// What each phase means, for the status history.
  static String meaning(DeliveryPhase phase) => switch (phase) {
    DeliveryPhase.queuedLocally =>
      'Stored on the booth, waiting to reach the service.',
    DeliveryPhase.uploading => 'The booth is handing the photo over.',
    DeliveryPhase.sending => 'The service is submitting the text.',
    DeliveryPhase.submitted =>
      'The provider accepted the text. Not yet sent or delivered.',
    DeliveryPhase.sent =>
      'The provider sent it to the carrier. Not confirmed delivered.',
    DeliveryPhase.delivered =>
      'The carrier confirmed delivery. Texts do not report being read.',
    DeliveryPhase.failed =>
      'It was not sent, or the carrier could not deliver it.',
    DeliveryPhase.unknown =>
      'The service could not confirm whether it was submitted. Check it '
          'before sending again.',
    DeliveryPhase.expired => 'Not sent within 24 hours of the guest asking.',
    DeliveryPhase.canceled => 'Canceled before it was sent.',
  };

  /// Readiness reasons the service gives (capabilities).
  static String reason(String code) => switch (code) {
    'PROVIDER_NOT_CONFIGURED' =>
      'The service has no messaging provider set up.',
    'REGISTRATION_NOT_ATTESTED' =>
      "The sender's registration (10DLC or toll-free) is not recorded.",
    'LEGAL_REVIEW_NOT_ATTESTED' =>
      'The legal review of the consent and privacy text is not recorded.',
    'SENDING_DISABLED' => 'Sending is switched off at the service.',
    'PUBLIC_URL_NOT_HTTPS' => "The service's public address is not https.",
    _ => 'The service is not ready ($code).',
  };

  /// A problem code as operators see it (codes are shown too, for
  /// support).
  static String problem(String code) => switch (code) {
    'OFFLINE' || 'TIMEOUT' || 'TLS' || 'NETWORK' || 'RESPONSE_INVALID' =>
      'No connection to the service (a captive portal or no internet).',
    'SERVER_ERROR' || 'INTERNAL' => 'The service had a problem.',
    'NOT_PAIRED' => 'This booth is not paired.',
    'CREDENTIAL_INVALID' || 'ACCESS_TOKEN_INVALID' =>
      "The service no longer accepts this booth's pairing. Pair it again.",
    'RECIPIENT_OPTED_OUT' => 'The number replied STOP.',
    'PHONE_INVALID' || 'PHONE_REGION_UNSUPPORTED' => 'Not a US mobile number.',
    'RECIPIENT_RATE_LIMITED' => 'Too many texts to this number.',
    'BOOTH_DAILY_LIMIT' => "The booth's daily limit is reached.",
    'DAILY_LIMIT' => "The service's daily limit is reached.",
    'EVENT_LIMIT' => "The event's limit is reached.",
    'BUDGET_REACHED' => "The month's spending limit is reached.",
    'SENDING_NOT_READY' => 'The service is not ready to send.',
    'QUEUE_WINDOW_ENDED' ||
    'CONSENT_WINDOW_ENDED' => 'Not sent within 24 hours.',
    'NOT_FOUND_AT_PROVIDER' =>
      'The provider has no record of it. Close it, or send again (the guest '
          'may get two texts).',
    'PHOTO_MISSING' ||
    'PHOTO_UNREADABLE' => 'The finished photo could not be read.',
    'PREVIEW_FAILED' => 'The preview could not be made.',
    'PHONE_MISSING' => 'The number was no longer stored.',
    'CANCELED_BY_OPERATOR' => 'Canceled by an operator.',
    'NO_LONGER_AT_SERVICE' =>
      'The service no longer keeps this record; the last report is shown.',
    'CLOSED_BY_OPERATOR' => 'Closed by an operator.',
    _ when code.startsWith('PROVIDER_') => 'The provider reported a problem.',
    _ => 'Something went wrong.',
  };

  /// US cents as dollars: `$12.34`.
  static String dollars(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

  /// A text describing exactly what guests see and agree to, for the
  /// sender registration and legal review (UX-PD5 "proof of consent flow").
  static String consentProof({
    required String brand,
    required String eventName,
    required int linkDays,
    required String privacyUrl,
    required String termsUrl,
    required String supportContact,
  }) {
    final consent = ConsentText(brand: brand, linkDays: linkDays);
    final days = linkDays == 1 ? '1 day' : '$linkDays days';
    return [
      'Porcelain Photo Booth: phone delivery consent proof',
      'Event: $eventName',
      '',
      'How a guest asks for a text (in person, at the booth):',
      '1. The finished photo is shown and saved. Buttons: "Text my photos" '
          'and "No thanks, finish". Texting is never required.',
      '2. The guest types a US mobile number on the booth keypad (+1 '
          'only). The consent box below starts unchecked:',
      '   [ ] ${consent.text}',
      '   Links shown: Privacy ($privacyUrl), Terms ($termsUrl).',
      '   "Send my photos" stays disabled until the number is valid and the '
          'box is checked.',
      '3. The guest confirms the number ("Is this your number?" with Edit '
          'number and Send).',
      '4. One text is sent; no marketing, no list, no further messages.',
      '',
      'Consent text version: ${ConsentText.version}',
      'SHA-256 of the consent text: ${consent.digest}',
      '',
      'Sample message:',
      '$brand: Your photos from $eventName are ready: '
          'https://<your photo domain>/p/<private link> (available for '
          '$days). Reply STOP to opt out, HELP for help.',
      '',
      'Help: $supportContact',
      'Stored with each request: the consent version, its SHA-256, the time '
          'it was accepted, the event, the session and the screen (S31).',
    ].join('\n');
  }
}
