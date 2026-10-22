import 'package:meta/meta.dart';

import '../models/booth_event.dart';
import 'session_plan.dart';

/// One photo taken for one shot of a session (A-05 CapturedPhoto). Never
/// changed or removed by the session: a retake adds another attempt and
/// the original stays in storage (AC-0703).
@immutable
final class ShotPhoto {
  const ShotPhoto({
    required this.shot,
    required this.attempt,
    required this.round,
    required this.originalId,
    required this.capturedAtUtc,
  });

  /// Which photo of the session, 0-based in taking order.
  final int shot;

  /// 1 for the first photo of this shot, 2 for its first retake, and so on.
  final int attempt;

  /// 0 for the first set; each whole-session retake starts the next round.
  final int round;

  /// The committed original (`CapturedStill.id`).
  final String originalId;
  final DateTime capturedAtUtc;

  @override
  bool operator ==(Object other) =>
      other is ShotPhoto &&
      other.shot == shot &&
      other.attempt == attempt &&
      other.round == round &&
      other.originalId == originalId &&
      other.capturedAtUtc == capturedAtUtc;

  @override
  int get hashCode =>
      Object.hash(shot, attempt, round, originalId, capturedAtUtc);
}

/// A session's photos was asked to accept one that breaks its rules.
final class InvalidShotPhoto implements Exception {
  const InvalidShotPhoto(this.reason);

  final String reason;

  @override
  String toString() => 'InvalidShotPhoto($reason)';
}

/// The photos of one session and the retake rules (A-10, S25, AC-0703).
///
/// The photo used for a shot is always its latest attempt; earlier
/// attempts stay recorded. Under [RetakePolicy.perShot] each shot may be
/// retaken up to the event's limit; under [RetakePolicy.wholeSession] the
/// whole set may be taken again up to the limit, as a new [round] in which
/// every shot needs a new photo.
@immutable
final class SessionShots {
  const SessionShots._(this.plan, this.photos, this.round);

  factory SessionShots.empty(SessionPlan plan) =>
      SessionShots._(plan, const [], 0);

  /// Rebuilds the shots recorded for a session (startup recovery, the
  /// gallery). The round is the latest one recorded.
  factory SessionShots.restore(SessionPlan plan, List<ShotPhoto> photos) {
    var shots = SessionShots.empty(plan);
    final ordered = [...photos]
      ..sort((a, b) {
        final byRound = a.round.compareTo(b.round);
        if (byRound != 0) return byRound;
        final byAttempt = a.attempt.compareTo(b.attempt);
        return byAttempt != 0 ? byAttempt : a.shot.compareTo(b.shot);
      });
    for (final photo in ordered) {
      if (photo.round > shots.round) {
        shots = SessionShots._(plan, shots.photos, photo.round);
      }
      shots = shots.withPhoto(photo);
    }
    return shots;
  }

  final SessionPlan plan;

  /// Every photo taken, in taking order.
  final List<ShotPhoto> photos;

  /// The current round: 0, or the number of whole-session retakes started.
  final int round;

  int get shotCount => plan.shotCount;
  RetakePolicy get _policy => plan.capture.retakePolicy;
  int get _limit => plan.capture.retakeLimit;

  /// Attempts so far for [shot].
  int attemptsOf(int shot) => photos.where((p) => p.shot == shot).length;

  /// The photo used for [shot]: its latest attempt, or null.
  ShotPhoto? selected(int shot) {
    ShotPhoto? latest;
    for (final photo in photos) {
      if (photo.shot == shot &&
          (latest == null || photo.attempt > latest.attempt)) {
        latest = photo;
      }
    }
    return latest;
  }

  /// Shots that still need a photo in the current round, in order.
  List<int> get remaining => [
    for (var shot = 0; shot < shotCount; shot++)
      if (selected(shot)?.round != round) shot,
  ];

  /// The next shot to take, or null when the set is complete.
  int? get nextShot => remaining.firstOrNull;

  bool get isComplete => remaining.isEmpty;

  /// How many more times [shot] may be retaken on its own.
  int retakesLeft(int shot) => _policy == RetakePolicy.perShot
      ? (_limit - (attemptsOf(shot) - 1)).clamp(0, _limit)
      : 0;

  bool canRetake(int shot) =>
      isComplete && shot >= 0 && shot < shotCount && retakesLeft(shot) > 0;

  /// How many more times the whole set may be taken again.
  int get roundsLeft => _policy == RetakePolicy.wholeSession
      ? (_limit - round).clamp(0, _limit)
      : 0;

  bool get canRetakeAll => isComplete && roundsLeft > 0;

  /// Starts a whole-session retake: every shot needs a new photo.
  SessionShots retakeAll() {
    if (!canRetakeAll) {
      throw const InvalidShotPhoto('no whole-session retake left');
    }
    return SessionShots._(plan, photos, round + 1);
  }

  /// The attempt number the next photo of [shot] gets.
  int nextAttempt(int shot) => attemptsOf(shot) + 1;

  /// Adds [photo]: the next attempt of a shot in range, in the current
  /// round. A shot already taken this round is a per-shot retake and needs
  /// one left.
  SessionShots withPhoto(ShotPhoto photo) {
    if (photo.shot < 0 || photo.shot >= shotCount) {
      throw const InvalidShotPhoto('no such shot');
    }
    if (photo.attempt != nextAttempt(photo.shot)) {
      throw const InvalidShotPhoto('attempts are numbered in order');
    }
    if (photo.round != round) {
      throw const InvalidShotPhoto('photo from another round');
    }
    if (photos.any((p) => p.originalId == photo.originalId)) {
      throw const InvalidShotPhoto('original already used');
    }
    final takenThisRound = selected(photo.shot)?.round == round;
    if (takenThisRound && !canRetake(photo.shot)) {
      throw const InvalidShotPhoto('no retake left for this shot');
    }
    return SessionShots._(plan, List.unmodifiable([...photos, photo]), round);
  }

  /// [withPhoto] as a session's record sees it: a whole-session retake is
  /// recorded with its first photo, so a photo of the next round starts
  /// that round when one is left.
  SessionShots record(ShotPhoto photo) =>
      photo.round == round + 1 && canRetakeAll
      ? retakeAll().withPhoto(photo)
      : withPhoto(photo);

  /// Photo space to original for the shots already taken in this round,
  /// at any point of the session: what the live template (EP06) shows
  /// around the shot being taken. Never used for a print.
  Map<int, String> get takenBindings => {
    for (var shot = 0; shot < shotCount; shot++)
      if (selected(shot) case final photo? when photo.round == round)
        plan.slotFor(shot): photo.originalId,
  };

  /// Photo space to original, for rendering; only once complete.
  Map<int, String> get slotBindings {
    if (!isComplete) {
      throw const InvalidShotPhoto('the set is not complete');
    }
    return {
      for (var shot = 0; shot < shotCount; shot++)
        plan.slotFor(shot): selected(shot)!.originalId,
    };
  }
}
