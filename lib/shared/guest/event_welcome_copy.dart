import '../../domain/models/booth_event.dart';
import '../formatters/date_format.dart';
import 'guest_welcome.dart';
import 'guest_welcome_sample.dart';

/// The guest welcome (S20) for [event]: its own greeting, message and
/// privacy note where the operator wrote them, warm defaults otherwise.
/// Never promises a print (CR-001 fix 8).
GuestWelcomeCopy welcomeCopyFor(BoothEvent event) {
  String? text(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
  final date = event.date;
  return GuestWelcomeCopy(
    eyebrow: date == null
        ? sampleGuestWelcomeCopy.eyebrow
        : formatCalendarDate(date),
    title: text(event.guest.welcomeTitle) ?? event.title,
    subtitle:
        text(event.guest.welcomeMessage) ?? sampleGuestWelcomeCopy.subtitle,
    steps: [
      'Get ready',
      'Strike a pose',
      event.capture.shotCount == 1 ? 'See your photo' : 'See your photos',
    ],
    startLabel: sampleGuestWelcomeCopy.startLabel,
    startHint: sampleGuestWelcomeCopy.startHint,
    privacyNote:
        text(event.guest.consentText) ?? sampleGuestWelcomeCopy.privacyNote,
  );
}
