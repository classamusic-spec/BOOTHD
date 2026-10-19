import '../../domain/value_objects/calendar_date.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// `14 November 2026`. Localised formats arrive with localisation.
String formatCalendarDate(CalendarDate date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// `14 Nov 2026`, for compact lists.
String formatCalendarDateShort(CalendarDate date) =>
    '${date.day} ${_months[date.month - 1].substring(0, 3)} ${date.year}';

/// `14 Nov 2026, 18:05` (24-hour clock), for when something was saved.
String formatTimestamp(DateTime time) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${time.day} ${_months[time.month - 1].substring(0, 3)} '
      '${time.year}, ${two(time.hour)}:${two(time.minute)}';
}

String _two(int n) => n.toString().padLeft(2, '0');

/// `18:05` (24-hour clock), for times within a day.
String formatClock(DateTime time) => '${_two(time.hour)}:${_two(time.minute)}';

/// `14 Nov 2026`, for a moment's day.
String formatDay(DateTime time) =>
    '${time.day} ${_months[time.month - 1].substring(0, 3)} ${time.year}';

/// `14 Nov 2026, 18:05 – 23:40`, or across days
/// `14 Nov 2026, 18:05 – 15 Nov 2026, 01:10`.
String formatSpan(DateTime from, DateTime to) =>
    from.year == to.year && from.month == to.month && from.day == to.day
    ? '${formatTimestamp(from)} – ${formatClock(to)}'
    : '${formatTimestamp(from)} – ${formatTimestamp(to)}';
