import '../../domain/session/guest_flow.dart';

/// Words guests read during a session (S21 to S29), in one place so they
/// stay consistent, can be localised, and tests can find them. Plain and
/// warm; never a diagnostic code, a path or a promise of a print.
abstract final class BoothCopy {
  // S20, when the event cannot be shown.
  static const notReady =
      "The photo booth isn't quite ready yet. Please ask the event host.";

  // S21 Template choice.
  static const chooseTitle = 'Choose your style';
  static const chooseSubtitle = 'Pick a design for your photos';
  static const continueLabel = 'Continue';

  // S22 to S24 Live preview, countdown and capture.
  static const getReady = 'Get ready!';
  static const openingCamera = 'Getting the camera ready…';
  static const lookHere = 'Look at the camera';
  static const snap = 'Snap!';
  static const lovely = 'Lovely!';
  static const nextPhotoSoon = 'Next photo coming up';
  static String photoOf(int number, int count) => 'Photo $number of $count';
  static String retaking(int number) => 'Retaking photo $number';
  static String countdownLabel(int seconds) =>
      seconds == 1 ? '1 second' : '$seconds seconds';

  // S25 Review.
  static const reviewTitle = 'How do they look?';
  static const reviewTitleOne = 'How does it look?';
  static const keepThese = 'Keep these';
  static const keepIt = 'Keep it';
  static const retake = 'Retake';
  static const retakeAll = 'Retake all';
  static const noRetakesLeft = 'No retakes left';
  static String retakesLeft(int count) =>
      count == 1 ? '1 retake left' : '$count retakes left';
  static String photoNumber(int number) => 'Photo $number';
  static const confirmRetakeTitle = 'Take them all again?';
  static const goBack = 'Go back';
  static const confirmRetakeBody =
      'These photos will be replaced by the new ones.';

  // S26 Rendering.
  static const creatingTitle = 'Creating your photos';
  static const creatingBody = 'Just a moment…';

  // S27 Finished.
  static const readyTitle = 'Your photos are ready!';
  static const savedToGallery = 'Saved to the booth gallery.';
  static const nextGuest = 'Next guest';
  static const resetSoon =
      'The booth gets ready for the next guest in a moment.';
  static const finishedPhoto = 'Your finished photo';

  // Interrupted.
  static const pausedTitle = 'Welcome back!';
  static const pausedSafe = 'Your photos so far are safe.';
  static const pausedBody = "Tap Continue when you're ready.";

  // S29 Problems: plain words, Try again or a way back to the start.
  static const tryAgain = 'Try again';
  static const startOver = 'Start over';
  static const backToStart = 'Back to start';

  static (String, String) problem(
    GuestProblemKind kind, {
    bool photos = false,
  }) => switch (kind) {
    GuestProblemKind.camera => (
      'The camera needs a moment',
      "Let's try that again. If it keeps happening, please ask the "
          'event host.',
    ),
    GuestProblemKind.capture => (
      "That photo didn't save",
      photos
          ? "Your other photos are safe. Let's take that one again."
          : "Let's take that one again.",
    ),
    GuestProblemKind.render => (
      "We couldn't finish your photos",
      "Your photos are safe. Let's try again.",
    ),
    GuestProblemKind.storage => (
      'The booth is full',
      'Please ask the event host to make some room.',
    ),
    GuestProblemKind.setup => (
      "The booth isn't quite ready",
      'Please ask the event host.',
    ),
  };
}
