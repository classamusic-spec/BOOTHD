import '../widgets/pin_pad.dart';

/// Words for the operator access flows (S01, S28), in one place so they
/// can be localised together.
abstract final class AccessCopy {
  static final pinPadLabels = PinPadLabels(
    entered: (entered, length) => entered == 0
        ? 'No digits entered'
        : '$entered of $length digits entered',
    delete: 'Delete last digit',
    deleteUnavailable: 'There are no digits to delete yet.',
  );

  // Unlocking.
  static const unlockTitle = 'Operator PIN';
  static const unlockPrompt = 'Enter your six-digit PIN.';
  static const checking = 'Checking…';
  static String wrongPin(int attemptsLeft) => attemptsLeft == 1
      ? "That PIN isn't right. One more try before a short wait."
      : "That PIN isn't right. $attemptsLeft tries left before a short wait.";
  static String lockedOut(String wait) =>
      'Too many tries. You can try again in $wait.';
  static String lockedReason(String wait) =>
      'Locked after too many tries. Try again in $wait.';
  static const forgotPin = 'Forgot PIN?';
  static const pinUnavailableTitle = "This tablet can't read the PIN";
  static const pinUnavailableBody =
      'The secure storage that holds the operator PIN is empty or could not '
      'be read. Use the recovery code to set a new PIN.';
  static const useRecoveryCode = 'Use recovery code';

  // Creating a PIN.
  static const choosePinTitle = 'Choose an operator PIN';
  static const choosePinBody =
      'Six digits. It opens the Studio and is the only way to leave Booth '
      'Mode, so keep it from guests.';
  static const confirmPinTitle = 'Enter the PIN again';
  static const confirmPinBody = 'To make sure it was typed as intended.';
  static const pinTooGuessable =
      'That PIN is too easy to guess. Avoid repeated digits and runs such '
      'as 123456.';
  static const pinMismatch = "Those PINs didn't match. Choose your PIN again.";
  static const pinSaveFailed =
      "The PIN couldn't be saved on this tablet. Choose it again.";
  static const startOver = 'Start over';
  static const saving = 'Saving…';

  // Recovery.
  static const recoveryTitle = 'Reset the PIN with the recovery code';
  static const recoveryBody =
      'Enter the 16-character code shown when this booth was set up. '
      'Dashes and capitals are optional.';
  static const recoveryField = 'Recovery code';
  static const recoveryHint = 'XXXX-XXXX-XXXX-XXXX';
  static const recoveryIncomplete = 'Enter all 16 characters of the code.';
  static const checkCode = 'Check code';
  static const backToPin = 'Back to PIN';
  static String wrongCode(int attemptsLeft) => attemptsLeft == 1
      ? "That code isn't right. One more try before a wait."
      : "That code isn't right. $attemptsLeft tries left before a wait.";
  static const noRecoveryCodeTitle = 'No recovery code is stored';
  static const noRecoveryCodeBody =
      'Without the PIN or a recovery code the Studio cannot be opened. The '
      "only way back in is to clear the app's data in the tablet's settings, "
      "which deletes this booth's events and photos. See the operator "
      'manual before doing this.';

  // Showing a recovery code.
  static const recoveryCodeTitle = 'Your recovery code';
  static const recoveryCodeBody =
      'If the PIN is ever forgotten, this code lets an operator set a new '
      'one. Write it down and keep it away from the booth: it is shown only '
      'now.';
  static const recoveryCodeWarning =
      'Without the PIN or this code, the only way back in is clearing the '
      "app's data, which deletes this booth's events and photos.";
  static const recoveryCodeStored = "I've written this code down";
  static const recoveryCodeStoredSubtitle =
      'Required to continue: the code cannot be shown again.';
  static const recoveryCodeLabel = 'Recovery code';
  static const recoveryDone = 'Continue';
  static const confirmStoredReason =
      'Confirm that you have written the code down first.';

  /// `0:27`, `14:59`, `1:00:00`.
  static String formatWait(Duration wait) {
    final seconds = wait.inSeconds + (wait.inMilliseconds % 1000 > 0 ? 1 : 0);
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
  }
}
