import 'package:flutter/widgets.dart';

import '../../core/experience/guest_experience.dart';
import '../../domain/experience/experience_pack.dart';

/// The words of the experience in effect (EP06): Porcelain Classic's are
/// the booth's original wording, so guests of earlier events read exactly
/// what they did.
extension GuestWordsContext on BuildContext {
  GuestCopy get guestCopy => GuestExperience.experienceOf(this).copy;
}
