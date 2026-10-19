import 'package:meta/meta.dart';

/// Why a typed number cannot be used (PD-01, AC-0903).
enum PhoneProblem {
  /// Not a complete, valid phone number.
  invalid,

  /// A real number outside the certified region (release 1: the US).
  regionUnsupported,
}

/// A recipient number, parsed (PD-01): E.164 for the service, the last four
/// digits for every view that is not the guest's own entry.
@immutable
final class PhoneNumber {
  const PhoneNumber._(this.e164, this.last4);

  /// `+12125550147`.
  final String e164;

  /// `0147`: the only digits operators and logs ever see.
  final String last4;

  /// `(212) 555-0147`, for the guest's own confirmation.
  String get national {
    final digits = e164.substring(2);
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-'
        '${digits.substring(6)}';
  }

  /// `•••-•••-0147`.
  String get masked => maskLast4(last4);

  @override
  bool operator ==(Object other) => other is PhoneNumber && other.e164 == e164;

  @override
  int get hashCode => e164.hashCode;

  @override
  String toString() => 'PhoneNumber($masked)';
}

/// The result of [parseUsPhone]: a number or a [PhoneProblem].
@immutable
final class PhoneParse {
  const PhoneParse._(this.number, this.problem);

  final PhoneNumber? number;
  final PhoneProblem? problem;

  bool get ok => number != null;
}

/// `•••-•••-0147`.
String maskLast4(String last4) => '•••-•••-$last4';

/// NANP area codes that are not geographic subscriber numbers.
const _notSubscriber = {'555', '900', '976'};

/// NANP area codes outside the 50 states and DC (Canada, the Caribbean and
/// US territories): country code 1, but not certified in release 1. Kept in
/// step with the backend (`backend/supabase/functions/_shared/phone.ts`);
/// both are checked against `backend/test/fixtures/phone_cases.json`.
const nonUsNanpAreaCodes = {
  // Canada
  '204', '226', '236', '249', '250', '257', '263', '289', '306', '343', //
  '354', '365', '367', '368', '382', '387', '403', '416', '418', '428',
  '431', '437', '438', '450', '460', '468', '474', '506', '514', '519',
  '548', '579', '581', '584', '587', '604', '613', '639', '647', '672',
  '683', '705', '709', '742', '753', '778', '780', '782', '807', '819',
  '825', '867', '873', '879', '902', '905', '942',
  // Caribbean and Atlantic
  '242', '246', '264', '268', '284', '345', '441', '473', '649', '658',
  '664', '721', '758', '767', '784', '809', '829', '849', '868', '869',
  '876',
  // US territories (not certified in release 1)
  '340', '670', '671', '684', '787', '939',
};

final _shape = RegExp(r'^\+?[0-9 ()./-]{7,24}$');
final _nxx = RegExp(r'^[2-9][0-9]{2}$');
final _n11 = RegExp(r'^[2-9]11$');

/// Parses [input] (E.164 such as `+12125550147`, or digits with
/// punctuation) as a US number. Accepts only NANP numbers: ten digits
/// after the 1, area code and exchange starting 2 to 9, no N11 codes, no
/// non-geographic area codes. The same rules as the backend.
PhoneParse parseUsPhone(String input) {
  const invalid = PhoneParse._(null, PhoneProblem.invalid);
  final trimmed = input.trim();
  if (!_shape.hasMatch(trimmed)) return invalid;
  var digits = trimmed.replaceAll(RegExp('[^0-9]'), '');
  if (trimmed.startsWith('+')) {
    if (!digits.startsWith('1')) {
      return const PhoneParse._(null, PhoneProblem.regionUnsupported);
    }
    digits = digits.substring(1);
  } else if (digits.length == 11 && digits.startsWith('1')) {
    digits = digits.substring(1);
  }
  if (digits.length != 10) return invalid;
  final area = digits.substring(0, 3);
  final exchange = digits.substring(3, 6);
  if (!_nxx.hasMatch(area) ||
      !_nxx.hasMatch(exchange) ||
      _n11.hasMatch(area) ||
      _n11.hasMatch(exchange) ||
      _notSubscriber.contains(area)) {
    return invalid;
  }
  if (nonUsNanpAreaCodes.contains(area)) {
    return const PhoneParse._(null, PhoneProblem.regionUnsupported);
  }
  return PhoneParse._(PhoneNumber._('+1$digits', digits.substring(6)), null);
}

/// The guest's keypad entry, ten digits at most, shown as it is typed:
/// `(212) 555-01`.
String formatUsDigits(String digits) {
  final d = digits.length > 10 ? digits.substring(0, 10) : digits;
  if (d.isEmpty) return '';
  if (d.length <= 3) return '($d';
  if (d.length <= 6) return '(${d.substring(0, 3)}) ${d.substring(3)}';
  return '(${d.substring(0, 3)}) ${d.substring(3, 6)}-${d.substring(6)}';
}
