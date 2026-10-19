import 'package:meta/meta.dart';

import 'gallery_models.dart';

/// The gallery's search (S13): a session number ("42" or "#42") or a time
/// of day ("21:30", "9:30 pm", "21:3" for 21:30 to 21:39), matched
/// against when sessions started on the tablet's clock.
@immutable
final class GallerySearch {
  const GallerySearch._({this.number, this.minutes, this.minuteSpan = 1});

  /// Nothing to search for: every session matches.
  static const none = GallerySearch._();

  /// Reads [text]; null when it is neither a number nor a time.
  static GallerySearch? parse(String text) {
    final query = text.trim().toLowerCase();
    if (query.isEmpty) return none;
    final number = RegExp(r'^#?\s*(\d{1,6})$').firstMatch(query);
    if (number != null) {
      return GallerySearch._(number: int.parse(number.group(1)!));
    }
    final time = RegExp(r'^(\d{1,2})(?::(\d{0,2}))?\s*(am|pm|a\.m\.|p\.m\.)?$')
        .firstMatch(query);
    if (time == null) return null;
    var hour = int.parse(time.group(1)!);
    final minutesText = time.group(2);
    final meridiem = time.group(3);
    if (meridiem != null) {
      if (hour < 1 || hour > 12) return null;
      hour = hour % 12 + (meridiem.startsWith('p') ? 12 : 0);
    } else if (minutesText == null) {
      // A bare number is a session number (handled above).
      return null;
    }
    if (hour > 23) return null;
    final start = hour * 60;
    return switch (minutesText) {
      null || '' => GallerySearch._(minutes: start, minuteSpan: 60),
      final text when text.length == 1 =>
        int.parse(text) > 5
            ? null
            : GallerySearch._(
                minutes: start + int.parse(text) * 10,
                minuteSpan: 10,
              ),
      final text =>
        int.parse(text) > 59
            ? null
            : GallerySearch._(minutes: start + int.parse(text)),
    };
  }

  /// The session number searched for.
  final int? number;

  /// The first minute of the day searched for, and how many minutes from
  /// it match.
  final int? minutes;
  final int minuteSpan;

  bool get isEmpty => number == null && minutes == null;

  /// Whether [session] matches; [toLocal] gives the tablet's clock time.
  bool matches(
    GallerySession session, {
    DateTime Function(DateTime utc) toLocal = _toLocal,
  }) {
    if (number case final number?) return session.number == number;
    if (minutes case final minutes?) {
      final local = toLocal(session.startedAtUtc);
      final minute = local.hour * 60 + local.minute;
      return minute >= minutes && minute < minutes + minuteSpan;
    }
    return true;
  }

  static DateTime _toLocal(DateTime utc) => utc.toLocal();
}
