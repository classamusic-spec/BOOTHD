import 'package:meta/meta.dart';

import '../experience/experience_registry.dart';
import '../models/booth_event.dart';
import '../models/event_rules.dart';
import '../services/camera_service.dart';
import '../template/template_document.dart';
import '../value_objects/orientation.dart';

/// Why a guest session cannot start with an event and template (A-14
/// `SESSION_*` codes). Launch checks prevent these; a session still refuses
/// rather than guess.
enum SessionPlanProblem {
  /// The event lists no template.
  noTemplate('SESSION_NO_TEMPLATE'),

  /// The template's photo spaces don't match the event's photos per session
  /// (one photo per space, ADR-0009).
  slotsMismatch('SESSION_TEMPLATE_SLOTS_MISMATCH'),

  /// Photos per session outside 1 to 4.
  shotCountOutOfRange('SESSION_SHOT_COUNT_OUT_OF_RANGE');

  const SessionPlanProblem(this.diagnostic);

  final String diagnostic;
}

final class SessionPlanException implements Exception {
  const SessionPlanException(this.problem);

  final SessionPlanProblem problem;

  @override
  String toString() => 'SessionPlanException(${problem.diagnostic})';
}

/// What a guest session is frozen to when it starts (A-10, P-09): the
/// event's capture, output and finish settings and one template revision.
/// Changing the event afterwards changes nothing about a session under way
/// or recorded.
///
/// Shot `k` (0-based, in the order photos are taken) fills the template's
/// photo space [slotIndexes]`[k]`: the spaces in slot-number order
/// (AC-0704). Counts always match, so no space is left empty and no photo
/// is left over.
@immutable
final class SessionPlan {
  SessionPlan({
    required this.eventId,
    required this.templateRevisionId,
    required List<int> slotIndexes,
    required this.capture,
    required this.output,
    required this.finishTimeoutSeconds,
    this.experience,
  }) : slotIndexes = List.unmodifiable(slotIndexes) {
    if (!EventLimits.shotCount.contains(slotIndexes.length) ||
        slotIndexes.length != capture.shotCount) {
      throw const SessionPlanException(SessionPlanProblem.slotsMismatch);
    }
  }

  /// Freezes [event] with the template [document] of revision
  /// [templateRevisionId].
  factory SessionPlan.freeze({
    required BoothEvent event,
    required String templateRevisionId,
    required TemplateDocument document,
    ExperienceRegistry? experiences,
  }) {
    if (!EventLimits.shotCount.contains(event.capture.shotCount)) {
      throw const SessionPlanException(SessionPlanProblem.shotCountOutOfRange);
    }
    final slots = [for (final slot in document.photoSlots) slot.slotIndex];
    if (slots.length != event.capture.shotCount) {
      throw const SessionPlanException(SessionPlanProblem.slotsMismatch);
    }
    return SessionPlan(
      eventId: event.id,
      templateRevisionId: templateRevisionId,
      slotIndexes: slots,
      capture: event.capture,
      output: event.output,
      finishTimeoutSeconds: event.guest.finishTimeoutSeconds,
      experience: (experiences ?? ExperienceRegistry.bundled).resolve(
        event.experience,
      ),
    );
  }

  final String eventId;
  final String templateRevisionId;

  /// Photo spaces in the order they are filled.
  final List<int> slotIndexes;
  final CaptureSettings capture;
  final OutputProfile output;
  final int finishTimeoutSeconds;

  /// What the guest sees and hears (EP01), resolved when the session
  /// starts so editing the event never changes a running session. Null for
  /// sessions from before experiences, or when the stored snapshot can no
  /// longer be read; their screens use the fallback experience.
  final ResolvedExperience? experience;

  int get shotCount => slotIndexes.length;

  /// The photo space shot [shot] fills.
  int slotFor(int shot) => slotIndexes[shot];

  /// The camera request for this session's lens and mirroring, given the
  /// tablet's cameras; null when the tablet has no built-in camera.
  CameraRequest? cameraRequest(List<CameraDescriptor> cameras) {
    final camera = CameraChoice.of(cameras, capture.lens).camera;
    return camera == null
        ? null
        : CameraRequest(
            cameraId: camera.id,
            mirrorPreview: capture.mirrorPreview,
            mirrorOutput: capture.mirrorOutput,
          );
  }

  /// The frozen settings, as stored with the session record.
  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'eventId': eventId,
    'templateRevisionId': templateRevisionId,
    'slotIndexes': slotIndexes,
    'capture': {
      'lens': capture.lens.name,
      'mirrorPreview': capture.mirrorPreview,
      'mirrorOutput': capture.mirrorOutput,
      'orientation': capture.orientation.name,
      'shotCount': capture.shotCount,
      'countdownSeconds': capture.countdownSeconds,
      'shotIntervalSeconds': capture.shotIntervalSeconds,
      'retakePolicy': capture.retakePolicy.name,
      'retakeLimit': capture.retakeLimit,
    },
    'output': {'format': output.format.name, 'jpegQuality': output.jpegQuality},
    'finishTimeoutSeconds': finishTimeoutSeconds,
    'experience': ?experience?.toJson(),
  };

  /// Reads [toJson]'s output. Throws [FormatException] when it is not a
  /// plan this version understands.
  static SessionPlan fromJson(Map<String, Object?> json) {
    try {
      if (json['schemaVersion'] != 1) {
        throw const FormatException('Unknown session plan version');
      }
      final capture = json['capture']! as Map<String, Object?>;
      final output = json['output']! as Map<String, Object?>;
      return SessionPlan(
        eventId: json['eventId']! as String,
        templateRevisionId: json['templateRevisionId']! as String,
        slotIndexes: [
          for (final slot in json['slotIndexes']! as List<Object?>)
            slot! as int,
        ],
        capture: CaptureSettings(
          lens: CameraLens.values.byName(capture['lens']! as String),
          mirrorPreview: capture['mirrorPreview']! as bool,
          mirrorOutput: capture['mirrorOutput']! as bool,
          orientation: GuestOrientationPreference.values.byName(
            capture['orientation']! as String,
          ),
          shotCount: capture['shotCount']! as int,
          countdownSeconds: capture['countdownSeconds']! as int,
          shotIntervalSeconds: capture['shotIntervalSeconds']! as int,
          retakePolicy: RetakePolicy.values.byName(
            capture['retakePolicy']! as String,
          ),
          retakeLimit: capture['retakeLimit']! as int,
        ),
        output: OutputProfile(
          format: OutputFormat.values.byName(output['format']! as String),
          jpegQuality: output['jpegQuality']! as int,
        ),
        finishTimeoutSeconds: json['finishTimeoutSeconds']! as int,
        experience: _experience(json['experience']),
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Unreadable session plan: ${error.runtimeType}');
    }
  }

  /// An unreadable snapshot costs the session its look, never its photos.
  static ResolvedExperience? _experience(Object? json) {
    if (json is! Map<String, Object?>) return null;
    try {
      return ResolvedExperience.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SessionPlan &&
      other.eventId == eventId &&
      other.templateRevisionId == templateRevisionId &&
      _sameInts(other.slotIndexes, slotIndexes) &&
      other.capture == capture &&
      other.output == output &&
      other.finishTimeoutSeconds == finishTimeoutSeconds &&
      other.experience == experience;

  @override
  int get hashCode => Object.hash(
    eventId,
    templateRevisionId,
    Object.hashAll(slotIndexes),
    capture,
    output,
    finishTimeoutSeconds,
    experience,
  );

  static bool _sameInts(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
