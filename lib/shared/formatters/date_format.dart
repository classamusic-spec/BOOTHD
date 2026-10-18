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
