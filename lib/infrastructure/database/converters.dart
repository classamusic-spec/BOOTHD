import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/delivery/delivery_intent.dart';
import '../../domain/experience/experience_configuration.dart';
import '../../domain/template/template_tags.dart';
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

/// Stores a delivery request's state by name ("DeliveryIntentState"
/// contains "INT", which would give ENUMNAME columns integer affinity).
const deliveryIntentStateByName = EnumNameConverter<DeliveryIntentState>(
  DeliveryIntentState.values,
);

/// Stores an event's experience (EP01) as JSON. A stored value this
/// version cannot read gives the default experience, so the booth still
/// opens; the registry then reports nothing unusual about it.
final class ExperienceConfigurationConverter
    extends TypeConverter<EventExperienceConfiguration, String> {
  const ExperienceConfigurationConverter();

  @override
  EventExperienceConfiguration fromSql(String fromDb) {
    try {
      final json = jsonDecode(fromDb);
      if (json is Map<String, Object?>) {
        return EventExperienceConfiguration.fromJson(json);
      }
    } on FormatException {
      // Falls through to the default.
    }
    return const EventExperienceConfiguration();
  }

  @override
  String toSql(EventExperienceConfiguration value) =>
      jsonEncode(value.toJson());
}

/// Stores a template's recommendation tags (EP01) as JSON; unreadable tags
/// read as none.
final class TemplateTagsConverter extends TypeConverter<TemplateTags, String> {
  const TemplateTagsConverter();

  @override
  TemplateTags fromSql(String fromDb) {
    try {
      final json = jsonDecode(fromDb);
      if (json is Map<String, Object?>) return TemplateTags.fromJson(json);
    } on FormatException {
      // Falls through to none.
    }
    return const TemplateTags();
  }

  @override
  String toSql(TemplateTags value) => jsonEncode(value.toJson());
}
