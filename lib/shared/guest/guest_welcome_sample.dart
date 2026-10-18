import 'guest_welcome.dart';

/// Welcome copy used for operator previews until events supply their own
/// (M03). Generic on purpose: no names, dates or sample people (UX-09), and
/// no promise of a print (CR-001 fix 8).
const sampleGuestWelcomeCopy = GuestWelcomeCopy(
  eyebrow: 'Welcome',
  title: 'Step in and smile',
  subtitle:
      "Tap Start when you're ready. We'll count down before each photo "
      'and show you the results.',
  steps: ['Get ready', 'Strike a pose', 'See your photos'],
  startLabel: 'Start',
  startHint: 'Begins your photo session',
  privacyNote: 'Photos are kept on this booth for the event host.',
);
