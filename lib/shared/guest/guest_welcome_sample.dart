import 'guest_welcome.dart';

/// The guest welcome's own words (CR-002 board), used for operator
/// previews and wherever an event has not supplied its own. Generic on
/// purpose: no names, dates or sample people (UX-09), and no promise of a
/// print (CR-001 fix 8).
const sampleGuestWelcomeCopy = GuestWelcomeCopy(
  wordmark: 'Porcelain',
  wordmarkSubtitle: 'Photo booth',
  title: "Let's Make Some Memories",
  steps: ['Photo booth', 'Pose', 'Smile', 'Enjoy'],
  startPrompt: 'Tap to',
  startLabel: 'Start',
  startHint: 'Begins your photo session',
  privacyNote: 'Photos are kept on this booth for the event host.',
);

/// What the event editor suggests for a welcome message: optional, and
/// shown under the title when given.
const sampleWelcomeMessage =
    "Tap Start when you're ready. We'll count down before each photo and "
    'show you the results.';
