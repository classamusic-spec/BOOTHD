import '../../domain/models/booth_event.dart';
import '../formatters/date_format.dart';
import 'guest_welcome.dart';
import 'guest_welcome_sample.dart';

/// The guest welcome (S20) for [event]: its own greeting, message and
/// privacy note where the operator wrote them, the board's warm defaults
/// otherwise (CR-002). The event's name and date sit above the title.
/// Never promises a print (CR-001 fix 8).
GuestWelcomeCopy welcomeCopyFor(BoothEvent event) {
  String? text(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
  final date = event.date;
  // The date never breaks across lines.
  final eyebrow = [
    ?text(event.title),
    if (date != null) formatCalendarDate(date).replaceAll(' ', '\u00A0'),
  ].join(' · ');
  const sample = sampleGuestWelcomeCopy;
  return GuestWelcomeCopy(
    wordmark: sample.wordmark,
    wordmarkSubtitle: sample.wordmarkSubtitle,
    eyebrow: eyebrow.isEmpty ? null : eyebrow,
    title: text(event.guest.welcomeTitle) ?? sample.title,
    subtitle: text(event.guest.welcomeMessage),
    steps: sample.steps,
    startPrompt: sample.startPrompt,
    startLabel: sample.startLabel,
    startHint: sample.startHint,
    privacyNote: text(event.guest.consentText) ?? sample.privacyNote,
  );
}
