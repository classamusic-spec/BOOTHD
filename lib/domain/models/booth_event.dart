/// Events (P-05): a booth configuration for one occasion, with its
/// templates, capture, guest, output and retention settings.
library;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../services/camera_service.dart' show CameraLens;
import '../value_objects/appearance.dart';
import '../value_objects/calendar_date.dart';
import '../value_objects/orientation.dart';

/// Event lifecycle (P-05). Only active events can run the booth; archived
/// events keep their photos and must be reopened before editing.
enum EventStatus { draft, active, archived }

/// What guests may retake (P-05, S25).
enum RetakePolicy {
  /// No retakes.
  none,

  /// Any single photo, up to the limit per photo.
  perShot,

  /// The whole set of photos, up to the limit per session.
  wholeSession,
}

/// The file format of finished photos.
enum OutputFormat { jpeg, png }

/// How long a finished event's photos are kept (P-05, P-13).
enum RetentionMode { keepUntilDeleted, deleteAfterDays }

/// Camera and pacing settings for an event (P-05, P-08). Preview and saved
/// photo mirroring are separate settings (CR-001 fix 5).
@immutable
final class CaptureSettings {
  const CaptureSettings({
    required this.lens,
    required this.mirrorPreview,
    required this.mirrorOutput,
    required this.orientation,
    this.shotCount = 3,
    this.countdownSeconds = 3,
    this.shotIntervalSeconds = 3,
    this.retakePolicy = RetakePolicy.perShot,
    this.retakeLimit = 1,
  });

  final CameraLens lens;

  /// Mirror the live preview, as guests expect from a selfie camera.
  final bool mirrorPreview;

  /// Mirror the saved photos (normally off, so text reads correctly).
  final bool mirrorOutput;

  /// The guest presentation the operator prefers; screens still follow the
  /// window the OS gives them (ADR-0004).
  final GuestOrientationPreference orientation;

  /// Photos per session, one for each photo slot of the template.
  final int shotCount;
  final int countdownSeconds;

  /// Pause between photos in a multi-photo session.
  final int shotIntervalSeconds;
  final RetakePolicy retakePolicy;

  /// Retakes allowed under [retakePolicy]; 0 when retakes are off.
  final int retakeLimit;

  CaptureSettings copyWith({
    CameraLens? lens,
    bool? mirrorPreview,
    bool? mirrorOutput,
    GuestOrientationPreference? orientation,
    int? shotCount,
    int? countdownSeconds,
    int? shotIntervalSeconds,
    RetakePolicy? retakePolicy,
    int? retakeLimit,
  }) => CaptureSettings(
    lens: lens ?? this.lens,
    mirrorPreview: mirrorPreview ?? this.mirrorPreview,
    mirrorOutput: mirrorOutput ?? this.mirrorOutput,
    orientation: orientation ?? this.orientation,
    shotCount: shotCount ?? this.shotCount,
    countdownSeconds: countdownSeconds ?? this.countdownSeconds,
    shotIntervalSeconds: shotIntervalSeconds ?? this.shotIntervalSeconds,
    retakePolicy: retakePolicy ?? this.retakePolicy,
    retakeLimit: retakeLimit ?? this.retakeLimit,
  );

  @override
  bool operator ==(Object other) =>
      other is CaptureSettings &&
      other.lens == lens &&
      other.mirrorPreview == mirrorPreview &&
      other.mirrorOutput == mirrorOutput &&
      other.orientation == orientation &&
      other.shotCount == shotCount &&
      other.countdownSeconds == countdownSeconds &&
      other.shotIntervalSeconds == shotIntervalSeconds &&
      other.retakePolicy == retakePolicy &&
      other.retakeLimit == retakeLimit;

  @override
  int get hashCode => Object.hash(
    lens,
    mirrorPreview,
    mirrorOutput,
    orientation,
    shotCount,
    countdownSeconds,
    shotIntervalSeconds,
    retakePolicy,
    retakeLimit,
  );
}

const _unset = Object();

/// What guests see and how their session ends (S04 Guest tab, S20, S27).
@immutable
final class GuestSettings {
  const GuestSettings({
    this.welcomeTitle,
    this.welcomeMessage,
    this.consentText,
    this.guestChoosesTemplate = false,
    this.finishTimeoutSeconds = 30,
    this.themeOverride,
  });

  /// Greeting on the welcome screen; the event title when null.
  final String? welcomeTitle;
  final String? welcomeMessage;

  /// Privacy or consent note shown quietly on the welcome screen.
  final String? consentText;

  /// Guests pick one of the allowed templates (S21).
  final bool guestChoosesTemplate;

  /// Seconds the finished screen stays before resetting for the next guest.
  final int finishTimeoutSeconds;

  /// Guest screens use this profile instead of the booth's (UX-02); null
  /// follows the booth.
  final PorcelainThemeProfile? themeOverride;

  GuestSettings copyWith({
    Object? welcomeTitle = _unset,
    Object? welcomeMessage = _unset,
    Object? consentText = _unset,
    bool? guestChoosesTemplate,
    int? finishTimeoutSeconds,
    Object? themeOverride = _unset,
  }) => GuestSettings(
    welcomeTitle: identical(welcomeTitle, _unset)
        ? this.welcomeTitle
        : welcomeTitle as String?,
    welcomeMessage: identical(welcomeMessage, _unset)
        ? this.welcomeMessage
        : welcomeMessage as String?,
    consentText: identical(consentText, _unset)
        ? this.consentText
        : consentText as String?,
    guestChoosesTemplate: guestChoosesTemplate ?? this.guestChoosesTemplate,
    finishTimeoutSeconds: finishTimeoutSeconds ?? this.finishTimeoutSeconds,
    themeOverride: identical(themeOverride, _unset)
        ? this.themeOverride
        : themeOverride as PorcelainThemeProfile?,
  );

  @override
  bool operator ==(Object other) =>
      other is GuestSettings &&
      other.welcomeTitle == welcomeTitle &&
      other.welcomeMessage == welcomeMessage &&
      other.consentText == consentText &&
      other.guestChoosesTemplate == guestChoosesTemplate &&
      other.finishTimeoutSeconds == finishTimeoutSeconds &&
      other.themeOverride == themeOverride;

  @override
  int get hashCode => Object.hash(
    welcomeTitle,
    welcomeMessage,
    consentText,
    guestChoosesTemplate,
    finishTimeoutSeconds,
    themeOverride,
  );
}

/// How finished photos are encoded. The page size and print resolution
/// come from the template (A-07).
@immutable
final class OutputProfile {
  const OutputProfile({this.format = OutputFormat.jpeg, this.jpegQuality = 92});

  final OutputFormat format;

  /// JPEG quality, 80 to 100; ignored for PNG.
  final int jpegQuality;

  OutputProfile copyWith({OutputFormat? format, int? jpegQuality}) =>
      OutputProfile(
        format: format ?? this.format,
        jpegQuality: jpegQuality ?? this.jpegQuality,
      );

  @override
  bool operator ==(Object other) =>
      other is OutputProfile &&
      other.format == format &&
      other.jpegQuality == jpegQuality;

  @override
  int get hashCode => Object.hash(format, jpegQuality);
}

/// How long photos are kept once taken (P-05, P-13). Enforcement arrives
/// with the gallery (M08); until then nothing is deleted automatically.
@immutable
final class RetentionPolicy {
  const RetentionPolicy.keepUntilDeleted()
    : mode = RetentionMode.keepUntilDeleted,
      days = null;

  const RetentionPolicy.deleteAfterDays(int this.days)
    : mode = RetentionMode.deleteAfterDays;

  final RetentionMode mode;

  /// Days after capture, for [RetentionMode.deleteAfterDays].
  final int? days;

  @override
  bool operator ==(Object other) =>
      other is RetentionPolicy && other.mode == mode && other.days == days;

  @override
  int get hashCode => Object.hash(mode, days);
}

/// The template revisions guests may use, in the operator's order, and the
/// one used when guests don't choose (P-05). Events reference immutable
/// revisions, never a template that could change underneath them (A-15).
@immutable
final class TemplateSelection {
  const TemplateSelection({
    this.revisionIds = const [],
    this.defaultRevisionId,
  });

  final List<String> revisionIds;
  final String? defaultRevisionId;

  bool get isEmpty => revisionIds.isEmpty;

  /// Adds [revisionId] at the end; the first template added becomes the
  /// default.
  TemplateSelection add(String revisionId) => revisionIds.contains(revisionId)
      ? this
      : TemplateSelection(
          revisionIds: [...revisionIds, revisionId],
          defaultRevisionId: defaultRevisionId ?? revisionId,
        );

  /// Removes [revisionId]; if it was the default, the first remaining
  /// template becomes the default.
  TemplateSelection remove(String revisionId) {
    final remaining = [
      for (final id in revisionIds)
        if (id != revisionId) id,
    ];
    return TemplateSelection(
      revisionIds: remaining,
      defaultRevisionId: defaultRevisionId == revisionId
          ? remaining.firstOrNull
          : defaultRevisionId,
    );
  }

  TemplateSelection withDefault(String revisionId) => TemplateSelection(
    revisionIds: revisionIds,
    defaultRevisionId: revisionId,
  );

  /// Moves the template at [from] to [to] (both indexes into the current
  /// order).
  TemplateSelection move(int from, int to) {
    final order = [...revisionIds];
    final id = order.removeAt(from);
    order.insert(to.clamp(0, order.length), id);
    return TemplateSelection(
      revisionIds: order,
      defaultRevisionId: defaultRevisionId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TemplateSelection &&
      const ListEquality<String>().equals(other.revisionIds, revisionIds) &&
      other.defaultRevisionId == defaultRevisionId;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(revisionIds), defaultRevisionId);
}

/// An event (P-05, A-05). Immutable: edits produce new values, and the
/// repository stores them atomically.
@immutable
final class BoothEvent {
  const BoothEvent({
    required this.id,
    required this.title,
    required this.status,
    required this.boothProfileId,
    required this.createdAt,
    required this.updatedAt,
    required this.capture,
    this.date,
    this.venue,
    this.notes,
    this.archivedAt,
    this.guest = const GuestSettings(),
    this.output = const OutputProfile(),
    this.retention = const RetentionPolicy.keepUntilDeleted(),
    this.templates = const TemplateSelection(),
  });

  /// Stable identifier (UUID v4); a duplicate gets a new one.
  final String id;
  final String title;
  final CalendarDate? date;
  final String? venue;

  /// Operator notes; never shown to guests.
  final String? notes;
  final EventStatus status;

  /// The booth profile the event belongs to.
  final String boothProfileId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// When the event was archived; set exactly when [status] is archived.
  final DateTime? archivedAt;
  final CaptureSettings capture;
  final GuestSettings guest;
  final OutputProfile output;
  final RetentionPolicy retention;
  final TemplateSelection templates;

  BoothEvent copyWith({
    String? id,
    String? title,
    Object? date = _unset,
    Object? venue = _unset,
    Object? notes = _unset,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? archivedAt = _unset,
    CaptureSettings? capture,
    GuestSettings? guest,
    OutputProfile? output,
    RetentionPolicy? retention,
    TemplateSelection? templates,
  }) => BoothEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    date: identical(date, _unset) ? this.date : date as CalendarDate?,
    venue: identical(venue, _unset) ? this.venue : venue as String?,
    notes: identical(notes, _unset) ? this.notes : notes as String?,
    status: status ?? this.status,
    boothProfileId: boothProfileId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: identical(archivedAt, _unset)
        ? this.archivedAt
        : archivedAt as DateTime?,
    capture: capture ?? this.capture,
    guest: guest ?? this.guest,
    output: output ?? this.output,
    retention: retention ?? this.retention,
    templates: templates ?? this.templates,
  );

  /// Whether the operator-editable content of [other] matches this event,
  /// ignoring timestamps (used to detect unsaved changes).
  bool sameContentAs(BoothEvent other) =>
      other.id == id &&
      other.title == title &&
      other.date == date &&
      other.venue == venue &&
      other.notes == notes &&
      other.status == status &&
      other.capture == capture &&
      other.guest == guest &&
      other.output == output &&
      other.retention == retention &&
      other.templates == templates;

  @override
  bool operator ==(Object other) =>
      other is BoothEvent &&
      sameContentAs(other) &&
      other.boothProfileId == boothProfileId &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.archivedAt == archivedAt;

  @override
  int get hashCode => Object.hash(id, title, status, updatedAt);
}
