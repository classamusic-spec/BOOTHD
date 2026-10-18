import 'package:drift/drift.dart';

import '../../domain/value_objects/appearance.dart';
import '../../domain/value_objects/calendar_date.dart';

/// Stores a [CalendarDate] as `YYYY-MM-DD` text.
final class CalendarDateConverter extends TypeConverter<CalendarDate, String> {
  const CalendarDateConverter();

  @override
  CalendarDate fromSql(String fromDb) =>
      CalendarDate.tryParse(fromDb) ??
      (throw FormatException('Stored event date is malformed'));

  @override
  String toSql(CalendarDate value) => value.toIso();
}

/// Stores a theme profile by name, like the ENUMNAME columns.
const themeProfileByName = EnumNameConverter<PorcelainThemeProfile>(
  PorcelainThemeProfile.values,
);
