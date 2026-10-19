import '../../domain/gallery/export_plan.dart';
import '../../domain/gallery/gallery_models.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/services/operator_files.dart';
import '../formatters/byte_format.dart';

/// The gallery's words (S13, S14, S16): plain, exact about what happened,
/// never claiming more than the tablet knows. Codes appear only beside a
/// plain explanation, for support.
abstract final class GalleryCopy {
  static const title = 'Gallery';
  static const subtitle =
      "Every session's photos and finished photos, stored on this tablet. "
      'Guests never see the gallery.';

  static const noEvents = 'No events yet';
  static const noEventsMessage =
      'Create an event and run the booth; each guest session appears here.';
  static const noSessions = 'No sessions yet';
  static const noSessionsMessage =
      'When guests use the booth for this event, their sessions appear here '
      'with every photo and finished photo.';
  static const loadFailed = "The gallery couldn't be read";
  static const loadFailedMessage =
      'The booth storage could not be read just now. Try again.';
  static const noMatch = 'No matching sessions';

  static const searchLabel = 'Find a session';
  static const searchHint = '42 or 21:30';
  static const searchNotUnderstood =
      'Type a session number (42) or a time (21:30, 9:30 pm).';

  static String filter(GalleryFilter filter) => switch (filter) {
    GalleryFilter.all => 'All',
    GalleryFilter.finished => 'Finished',
    GalleryFilter.needsAttention => 'To finish',
    GalleryFilter.notFinished => 'Ended early',
  };

  static String sessionTitle(int number) => 'Session $number';

  static String state(GallerySession session) => switch (session.state) {
    GallerySessionState.finished =>
      session.status == SessionStatus.completed
          ? 'Finished'
          : 'Finished in gallery',
    GallerySessionState.waitingToFinish => 'Waiting to finish',
    GallerySessionState.renderFailed => 'Finishing failed',
    GallerySessionState.notFinished => switch (session.endReason) {
      SessionEndReason.timedOut => 'Guest left',
      SessionEndReason.operatorExit => 'Ended by operator',
      SessionEndReason.interrupted => 'App closed',
      SessionEndReason.problem => 'Stopped by a problem',
      SessionEndReason.renderFailed || null => 'Not finished',
    },
    GallerySessionState.inProgress => 'In progress',
  };

  static String statusOf(
    SessionRecord session, {
    required bool hasOutput,
  }) => switch (session.status) {
    SessionStatus.completed => 'Finished',
    SessionStatus.rendering => 'Waiting for its finished photo',
    SessionStatus.failed =>
      hasOutput
          ? 'Its finished photo failed in the booth; made later in the gallery'
          : 'Its finished photo failed ${session.renderAttempts} times',
    SessionStatus.abandoned => switch (session.endReason) {
      SessionEndReason.timedOut => 'The guest left before the end',
      SessionEndReason.operatorExit => 'Ended when the operator left',
      SessionEndReason.interrupted => 'The app closed during it',
      SessionEndReason.problem => 'Stopped by a camera or storage problem',
      SessionEndReason.renderFailed || null => 'Not finished',
    },
    SessionStatus.capturing ||
    SessionStatus.reviewing => 'A guest is in this session',
  };

  static String sessions(int count) =>
      count == 1 ? '1 session' : '$count sessions';
  static String photos(int count) => count == 1 ? '1 photo' : '$count photos';
  static String files(int count) => count == 1 ? '1 file' : '$count files';

  // Selection.
  static const select = 'Select';
  static const cancelSelect = 'Done';
  static String selectAll(int count) => 'Select all $count';
  static const clearSelection = 'Clear';
  static String selected(int count) =>
      count == 0 ? 'Tap sessions to select them' : '$count selected';
  static const selectFirst = 'Select sessions first.';

  // Rendering again.
  static const finishNow = 'Finish now';
  static const makeAgain = 'Make again';
  static const makePrint = 'Make finished photo';
  static const making = 'Making…';
  static const cannotRenderIncomplete =
      "Some photos are missing, so a finished photo can't be made.";
  static const cannotRenderInProgress = 'A guest is in this session.';
  static const rendered =
      'A new finished photo was made. Earlier ones are kept.';
  static const finished = 'The session is finished and its photo saved.';
  static String renderFailed(String code) =>
      "The finished photo couldn't be made ($code). Nothing was changed.";

  // Deleting.
  static String deleteSessionsTitle(int count) =>
      count == 1 ? 'Delete this session?' : 'Delete $count sessions?';
  static String deleteSessionsBody(int count) =>
      '${count == 1 ? 'Its' : 'Their'} camera photos, retakes and finished '
      "photos are removed from this tablet. This can't be undone; export "
      'first if you need them.';
  static const deleteConfirm = 'Delete';
  static const keep = 'Keep';
  static String deleted(int count) =>
      count == 1 ? 'Session deleted.' : '$count sessions deleted.';
  static const filesPending =
      "Some files couldn't be removed yet. The tablet tries again on its own.";
  static String deleteFailed(String code) =>
      'Nothing was deleted ($code). Try again.';

  // Retention.
  static String keeps(int? days) => days == null
      ? 'Keeps photos until you delete them'
      : 'Keeps photos for $days ${days == 1 ? 'day' : 'days'}';
  static String pastRetention(int count, int days) =>
      '${count == 1 ? '1 session is' : '$count sessions are'} older than this '
      'event keeps photos ($days ${days == 1 ? 'day' : 'days'}).';
  static const reviewRetention = 'Review and delete';
  static String retentionTitle(int count) =>
      count == 1 ? 'Delete 1 old session?' : 'Delete $count old sessions?';
  static String retentionBody(int count, int days) =>
      'These ${count == 1 ? 'session was' : 'sessions were'} taken more than '
      '$days days ago, past what this event keeps. Their photos and finished '
      "photos are removed from this tablet. This can't be undone; export "
      'first if you need them. Nothing is deleted until you confirm.';

  // Export.
  static const export = 'Export';
  static String exportTitle(int sessions) =>
      sessions == 1 ? 'Export this session' : 'Export $sessions sessions';
  static const exportContent = 'What to export';
  static String content(ExportContent content) => switch (content) {
    ExportContent.finishedPhotos => 'Finished photos',
    ExportContent.finishedAndOriginals => 'Finished and camera photos',
  };
  static const exportExplainer =
      "Copies are checked against the tablet's records, then offered to "
      'the share sheet. Choose where they go there: Files on this tablet, a '
      'connected drive, AirDrop or another app. The tablet keeps its own '
      'copies.';
  static const chooseDestination = 'Choose destination';
  static const preparing = 'Checking files…';
  static const copying = 'Checking and copying files…';
  static String part(int index, int count) => 'Part $index of $count';
  static String partsNote(int count) =>
      'This export goes in $count parts of up to '
      '${ExportPlan.maxFilesPerPart} files; you choose a destination for '
      'each.';
  static const nextPart = 'Next part';
  static const shareAgain = 'Share again';
  static const skipPart = 'Skip this part';
  static const done = 'Done';
  static const tryAgain = 'Try again';

  static String handedOver(int count, String destination) =>
      '${files(count)} handed to $destination.';
  static String handedOverUnknown(int count) =>
      '${files(count)} handed to the share sheet. The tablet was not told '
      'where they went.';
  static const sheetClosed = 'The share sheet was closed, so nothing was sent.';
  static const nothingToExport = 'Nothing could be exported.';
  static String noSpace(String needed, String free) =>
      'Not enough free space to prepare the copies: about $needed needed, '
      '$free free. Export fewer sessions at a time or free some space.';
  static String notSent(int count) =>
      count == 1 ? '1 file did not go:' : '$count files did not go:';
  static const exportsNote =
      '"Handed to" means the platform passed the files on; it does not '
      'confirm that the destination finished saving them.';

  static String problem(ExportProblem problem) => switch (problem) {
    ExportProblem.noFinishedPhoto => 'no finished photo yet',
    ExportProblem.missing => 'file missing from storage',
    ExportProblem.damaged => 'file no longer matches its record',
    ExportProblem.noSpace => 'no space to copy it',
    ExportProblem.copyFailed => 'the copy could not be written',
  };

  static String failureLine(ExportFailureItem failure) {
    final what = switch (failure.kind) {
      ExportFileKind.finished || null => 'finished photo',
      ExportFileKind.original => failure.fileName ?? 'camera photo',
    };
    return 'Session ${failure.sessionNumber}, $what: '
        '${problem(failure.problem)}';
  }

  /// The destination as the platform named it: the iPadOS activity, or
  /// the Android app's package.
  static String destination(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'a destination the tablet was not told';
    }
    const known = {
      'com.apple.DocumentManagerUICore.SaveToFiles': 'Save to Files',
      'com.apple.UIKit.activity.AirDrop': 'AirDrop',
      'com.apple.UIKit.activity.SaveToCameraRoll': 'Save to Photos',
      'com.apple.UIKit.activity.Mail': 'Mail',
      'com.apple.UIKit.activity.Message': 'Messages',
      'com.apple.UIKit.activity.CopyToPasteboard': 'Copy',
    };
    if (known[raw] case final name?) return name;
    final slash = raw.indexOf('/');
    return slash > 0 ? 'the app ${raw.substring(0, slash)}' : raw;
  }

  static String exportRecord(ExportRecordSummary record) =>
      switch (record.outcome) {
        ShareOutcome.unknown => 'Handed to the share sheet',
        _ => 'Handed to ${destination(record.destination)}',
      };

  // Storage.
  static String bytes(int bytes) => formatBytes(bytes);
}
