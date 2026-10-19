import '../../domain/delivery/delivery_intent.dart';

/// Words guests read about texting their photos (S30 to S32, PD-02,
/// UX-PD1 to UX-PD3). Honest about what happens: "sent" is not
/// "received", nothing is promised when the booth is offline, and the
/// photo is always saved whatever happens to the text.
abstract final class DeliveryCopy {
  // S30 Delivery choice.
  static const textMyPhotos = 'Text my photos';
  static const noThanksFinish = 'No thanks, finish';
  static const offlineNote =
      'The booth is offline right now. If it reconnects within 24 hours, '
      "we'll send your text then. It may not arrive.";

  // S31 Phone and consent.
  static const entryTitle = 'Text my photos';
  static const entrySubtitle =
      'One text with a preview and a private link to the full-size photo.';
  static const country = 'United States +1';
  static const countryHint = 'US mobile numbers only';
  static const numberLabel = 'Your mobile number';
  static const numberPlaceholder = '(   )    -    ';
  static const invalid = 'Check the number: it needs 10 digits.';
  static const unsupported =
      'We can only text US mobile numbers from this booth.';
  static const privacy = 'Privacy';
  static const terms = 'Terms';
  static const sendMyPhotos = 'Send my photos';
  static const noThanks = 'No thanks';
  static const needNumber = 'Enter your 10-digit number first';
  static const needConsent = 'Check the box to agree first';
  static const clear = 'Clear';
  static const deleteDigit = 'Delete last digit';
  static const nothingToClear = 'No digits entered yet';
  static String digitLabel(String digit) => digit;

  // Confirm.
  static const confirmTitle = 'Is this your number?';
  static const editNumber = 'Edit number';
  static const send = 'Send';

  // Privacy and terms (the booth never opens a browser).
  static const privacyTitle = 'Privacy notice';
  static const termsTitle = 'Terms';
  static String readOnPhone(String address) =>
      'Read it on your phone at $address';
  static const close = 'OK';
  static String help(String contact) => 'Questions? $contact';

  // S32 Result.
  static const done = 'Done';
  static const photoSaved = 'Your photo is saved at the booth.';
  static String sentTo(String masked) => 'To $masked';

  /// The headline and explanation for a request's state, as the guest
  /// sees it right after asking.
  static (String, String) result(
    DeliveryIntent intent, {
    required bool offline,
  }) => switch (intent.phase) {
    DeliveryPhase.queuedLocally when intent.lastErrorCode != null || offline =>
      (
        'Waiting for a connection',
        "We'll keep trying while the booth is on, for up to 24 hours. "
            'The text may arrive later, or not at all if we can\'t '
            'connect.',
      ),
    DeliveryPhase.queuedLocally || DeliveryPhase.uploading => (
      'Sending your photos…',
      'This takes a few seconds. You can finish any time.',
    ),
    DeliveryPhase.sending => ('Sending your text…', 'You can finish any time.'),
    DeliveryPhase.submitted || DeliveryPhase.sent => (
      'Text request sent',
      'It should arrive in a few minutes. Delivery depends on your '
          'phone company and isn\'t guaranteed.',
    ),
    DeliveryPhase.delivered => (
      'Delivery confirmed',
      'Your phone company confirmed the text was delivered.',
    ),
    DeliveryPhase.failed => switch (intent.lastErrorCode) {
      'RECIPIENT_OPTED_OUT' => (
        'This number opted out of our texts',
        'Reply START to our number to receive texts again.',
      ),
      'PHONE_INVALID' ||
      'PHONE_REGION_UNSUPPORTED' ||
      'PROVIDER_INVALID_NUMBER' ||
      'PROVIDER_NOT_MOBILE' => (
        "We can't text this number",
        'Only US mobile numbers can receive texts from this booth.',
      ),
      'RECIPIENT_RATE_LIMITED' ||
      'BOOTH_DAILY_LIMIT' ||
      'DAILY_LIMIT' ||
      'EVENT_LIMIT' ||
      'BUDGET_REACHED' => (
        'Texting is paused for now',
        'The booth has sent as many texts as it can for now.',
      ),
      _ => ("We couldn't send your text", 'Something went wrong on our side.'),
    },
    DeliveryPhase.unknown => (
      "We couldn't confirm your text",
      'It may still arrive. The event host can check.',
    ),
    DeliveryPhase.expired => (
      "We couldn't send it in time",
      'The booth was offline too long.',
    ),
    DeliveryPhase.canceled => ('Text canceled', ''),
  };
}
