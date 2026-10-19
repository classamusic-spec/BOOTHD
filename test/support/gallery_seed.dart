import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/session/session_plan.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';

import 'seed.dart';
import 'simulated_camera.dart';
import 'test_database.dart';

/// How a seeded session ended.
enum SeededOutcome {
  /// Finished, with its finished photo.
  completed,

  /// Finished, then made again in the gallery: two finished photos.
  rerendered,

  /// The guest left during review: a full set, no finished photo.
  abandonedComplete,

  /// The guest left after the first photo.
  abandonedIncomplete,

  /// The finished photo failed three times.
  failed,

  /// Still waiting for its finished photo.
  rendering,
}

/// The default mix: mostly finished sessions, with some of every other
/// kind spread through the event.
SeededOutcome mixedOutcome(int number) => switch (number) {
  _ when number % 50 == 7 => SeededOutcome.rendering,
  _ when number % 25 == 3 => SeededOutcome.failed,
  _ when number % 10 == 5 => SeededOutcome.abandonedIncomplete,
  _ when number % 20 == 9 => SeededOutcome.abandonedComplete,
  _ when number % 30 == 1 => SeededOutcome.rerendered,
  _ => SeededOutcome.completed,
};

/// Ids the seeded gallery uses: session `n` (from 1) of an event.
abstract final class GalleryIds {
  static String session(int number, {int event = 0}) =>
      'c${event.toString().padLeft(7, '0')}-0000-4000-8000-'
      '${number.toString().padLeft(12, '0')}';

  static String output(int number, {int version = 1, int event = 0}) =>
      'd${event.toString().padLeft(6, '0')}$version-0000-4000-8000-'
      '${number.toString().padLeft(12, '0')}';

  static String original(int number, int shot, int attempt, {int event = 0}) =>
      'g$event-$number-$shot-$attempt';
}

/// A two-photo plan for [eventId] on Two-up classic.
SessionPlan galleryPlan(String eventId) => SessionPlan(
  eventId: eventId,
  templateRevisionId: TestIds.revisionA1,
  slotIndexes: const [0, 1],
  capture: const CaptureSettings(
    lens: CameraLens.front,
    mirrorPreview: true,
    mirrorOutput: false,
    orientation: GuestOrientationPreference.portrait,
    shotCount: 2,
    retakePolicy: RetakePolicy.perShot,
    retakeLimit: 1,
  ),
  output: const OutputProfile(),
  finishTimeoutSeconds: 30,
);

/// Adds [count] sessions to [eventId] straight into the database (fast
/// enough for thousands): session `n` started [firstStart] + n - 1
/// minutes, ended as [outcome] says; every fourth one has a retake of its
/// second photo. With [filesRoot], every original and finished photo is
/// also written there (managed storage layout) with its real checksum.
/// Returns the session ids, oldest first.
Future<List<String>> seedGallery(
  BoothDatabase db, {
  String eventId = SeedIds.active,
  int eventIndex = 0,
  int count = 12,
  DateTime? firstStart,
  SeededOutcome Function(int number) outcome = mixedOutcome,
  Directory? filesRoot,
}) async {
  final start = firstStart ?? DateTime.utc(2026, 11, 14, 18);
  final planJson = jsonEncode(galleryPlan(eventId).toJson());
  final photoBytes = SimulatedStillStore.photoBytes;
  final photoSha = crypto.sha256.convert(photoBytes).toString();
  final outputBytes = finishedStandIn;
  final outputSha = crypto.sha256.convert(outputBytes).toString();
  final real = filesRoot != null;

  final sessions = <CaptureSessionsCompanion>[];
  final photos = <SessionPhotosCompanion>[];
  final originals = <OriginalPhotosCompanion>[];
  final outputs = <SessionOutputsCompanion>[];
  final ids = <String>[];

  for (var number = 1; number <= count; number++) {
    final id = GalleryIds.session(number, event: eventIndex);
    ids.add(id);
    final began = start.add(Duration(minutes: number - 1));
    final ended = began.add(const Duration(seconds: 60));
    final kind = outcome(number);
    final complete = kind != SeededOutcome.abandonedIncomplete;
    final takes = <(int, int)>[
      (0, 1),
      if (complete) (1, 1),
      if (complete && number % 4 == 0) (1, 2),
    ];
    for (final (shot, attempt) in takes) {
      final originalId = GalleryIds.original(
        number,
        shot,
        attempt,
        event: eventIndex,
      );
      final at = began.add(Duration(seconds: 10 * (shot + attempt)));
      originals.add(
        OriginalPhotosCompanion.insert(
          id: originalId,
          relativePath: 'originals/$originalId.jpg',
          widthPx: real ? 64 : 4032,
          heightPx: real ? 48 : 3024,
          byteLength: real ? photoBytes.length : 3000000,
          sha256: real ? photoSha : 'a' * 64,
          lens: CameraLens.front,
          sensorOrientation: 270,
          deviceOrientation: CaptureOrientation.portraitUp,
          mirrorPreview: true,
          mirrorOutput: false,
          origin: CaptureOrigin.session,
          capturedAt: at,
          committedAt: at,
        ),
      );
      photos.add(
        SessionPhotosCompanion.insert(
          sessionId: id,
          shotIndex: shot,
          attempt: attempt,
          round: 0,
          slotIndex: shot,
          originalId: originalId,
          capturedAt: at,
        ),
      );
      if (real) {
        _write(filesRoot, 'originals/$originalId.jpg', photoBytes);
      }
    }
    final versions = switch (kind) {
      SeededOutcome.completed => 1,
      SeededOutcome.rerendered => 2,
      _ => 0,
    };
    for (var version = 1; version <= versions; version++) {
      final outputId = GalleryIds.output(
        number,
        version: version,
        event: eventIndex,
      );
      outputs.add(
        SessionOutputsCompanion.insert(
          id: outputId,
          sessionId: id,
          relativePath: 'outputs/$outputId.jpg',
          sha256: real ? outputSha : 'e' * 64,
          byteLength: real ? outputBytes.length : 812345,
          widthPx: 1200,
          heightPx: 1800,
          format: OutputFormat.jpeg,
          renderVersion: 2,
          createdAt: ended.add(Duration(days: version - 1)),
          origin: Value(
            version == 1
                ? SessionOutputOrigin.session
                : SessionOutputOrigin.rerender,
          ),
        ),
      );
      if (real) _write(filesRoot, 'outputs/$outputId.jpg', outputBytes);
    }
    final (status, reason) = switch (kind) {
      SeededOutcome.completed ||
      SeededOutcome.rerendered => (SessionStatus.completed, null),
      SeededOutcome.abandonedComplete => (
        SessionStatus.abandoned,
        SessionEndReason.operatorExit,
      ),
      SeededOutcome.abandonedIncomplete => (
        SessionStatus.abandoned,
        SessionEndReason.timedOut,
      ),
      SeededOutcome.failed => (
        SessionStatus.failed,
        SessionEndReason.renderFailed,
      ),
      SeededOutcome.rendering => (SessionStatus.rendering, null),
    };
    sessions.add(
      CaptureSessionsCompanion.insert(
        id: id,
        eventId: eventId,
        sequence: number,
        templateRevisionId: TestIds.revisionA1,
        plannedShots: 2,
        planJson: planJson,
        status: status,
        endReason: Value(reason),
        renderAttempts: Value(switch (kind) {
          SeededOutcome.failed => 3,
          SeededOutcome.abandonedComplete ||
          SeededOutcome.abandonedIncomplete => 0,
          _ => 1,
        }),
        outputId: Value(
          status == SessionStatus.completed
              ? GalleryIds.output(number, event: eventIndex)
              : null,
        ),
        startedAt: began,
        updatedAt: ended,
        endedAt: Value(status == SessionStatus.rendering ? null : ended),
      ),
    );
  }
  await db.batch((batch) {
    batch
      ..insertAll(db.originalPhotos, originals)
      ..insertAll(db.captureSessions, sessions)
      ..insertAll(db.sessionPhotos, photos)
      ..insertAll(db.sessionOutputs, outputs);
  });
  return ids;
}

/// A small, valid finished-photo stand-in (JPEG).
final Uint8List finishedStandIn = SimulatedStillStore.photoBytes;

void _write(Directory root, String relativePath, Uint8List bytes) {
  final file = File('${root.path}/$relativePath');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}
