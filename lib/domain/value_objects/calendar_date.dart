import 'package:meta/meta.dart';

/// A day on the calendar, without a time or time zone: an event's date is
/// the same day wherever the tablet's clock is set.
@immutable
final class CalendarDate implements Comparable<CalendarDate> {
  /// Throws [ArgumentError] unless [year], [month] and [day] name a real
  /// day between the years 2000 and 2999.
  CalendarDate(this.year, this.month, this.day) {
    final normalised = DateTime.utc(year, month, day);
    if (year < 2000 ||
        year > 2999 ||
        normalised.month != month ||
        normalised.day != day) {
      throw ArgumentError('Not a supported calendar date: $year-$month-$day');
    }
  }

  /// The local calendar day of [moment].
  factory CalendarDate.fromDateTime(DateTime moment) =>
      CalendarDate(moment.year, moment.month, moment.day);

  /// Parses `YYYY-MM-DD`; returns null for anything else.
  static CalendarDate? tryParse(String text) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) return null;
    try {
      return CalendarDate(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    } on ArgumentError {
      return null;
    }
  }

  final int year;
  final int month;
  final int day;

  /// Midnight at the start of this day, in local time.
  DateTime toLocalDateTime() => DateTime(year, month, day);

  /// `YYYY-MM-DD`, as stored.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(CalendarDate other) => toIso().compareTo(other.toIso());

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
