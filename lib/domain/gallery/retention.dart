import '../models/booth_event.dart';

/// An event's retention rule applied to its sessions (P-05, P-13,
/// AC-0805). Retention never deletes by itself: sessions past it are
/// offered to the operator, who confirms the deletion.
abstract final class RetentionRules {
  /// Sessions that started before this moment are past [policy] at
  /// [nowUtc]; null when the event keeps photos until they are deleted.
  static DateTime? cutoff(RetentionPolicy policy, DateTime nowUtc) =>
      switch (policy.mode) {
        RetentionMode.keepUntilDeleted => null,
        RetentionMode.deleteAfterDays => nowUtc.toUtc().subtract(
          Duration(days: policy.days!),
        ),
      };

  /// Whether a session that started at [startedAtUtc] is past [policy].
  static bool isDue(
    RetentionPolicy policy,
    DateTime startedAtUtc,
    DateTime nowUtc,
  ) {
    final before = cutoff(policy, nowUtc);
    return before != null && startedAtUtc.isBefore(before);
  }
}
