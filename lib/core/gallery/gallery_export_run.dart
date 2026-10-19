import 'package:flutter/foundation.dart';

import '../../domain/gallery/export_plan.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../../domain/services/gallery_services.dart';
import '../../domain/services/operator_files.dart';
import '../../domain/value_objects/clock.dart';
import '../../domain/value_objects/entity_id.dart';

enum ExportRunStage {
  /// Reading which files the sessions have.
  planning,

  /// The plan is ready; nothing has been offered yet.
  ready,

  /// Checking and copying files, or waiting for the share sheet.
  exporting,

  /// A part is done and another one waits.
  between,

  /// Every part was offered (or skipped).
  finished,

  /// The files could not be read from the records.
  failed,
}

/// One batch export (P-12, AC-0803): the plan, then each part offered to
/// the share sheet in turn with its report. A part whose sheet was closed
/// can be offered again or skipped. Parts whose files left for a
/// destination are recorded in the export history.
final class GalleryExportRun extends ChangeNotifier {
  GalleryExportRun({
    required this._gallery,
    required this._exporter,
    required this._clock,
    required this._ids,
    required this.sessionIds,
    required this.content,
    this.toLocal,
  });

  final GalleryRepository _gallery;
  final GalleryExporter _exporter;
  final Clock _clock;
  final IdGenerator _ids;
  final List<String> sessionIds;
  final ExportContent content;

  /// The tablet's clock time for file names; defaults to the system's.
  final DateTime Function(DateTime utc)? toLocal;

  var _stage = ExportRunStage.planning;
  ExportPlan? _plan;
  var _part = 0;
  final _reports = <ExportPartReport>[];
  String? _failureCode;
  var _disposed = false;

  ExportRunStage get stage => _stage;
  ExportPlan? get plan => _plan;

  /// Every report so far, a part offered again included.
  List<ExportPartReport> get reports => List.unmodifiable(_reports);

  ExportPartReport? get lastReport => _reports.isEmpty ? null : _reports.last;

  /// The next part to offer (0-based).
  int get partIndex => _part;
  int get partCount => _plan?.parts.length ?? 0;
  String? get failureCode => _failureCode;

  /// Files handed to a destination (the platform said so, or could not
  /// say), over every part.
  int get handedOverCount => _reports
      .where((report) => report.handedOver)
      .fold(0, (sum, report) => sum + report.sent.length);

  /// Files that could not be offered, from the plan and from each part's
  /// latest attempt.
  List<ExportFailureItem> get failures {
    final latest = <int, ExportPartReport>{};
    for (final report in _reports) {
      latest[report.part] = report;
    }
    return [
      ...?_plan?.failures,
      for (final report in latest.values) ...report.failures,
    ];
  }

  /// Reads the sessions' files and splits them into parts.
  Future<void> prepare() async {
    try {
      final files = await _gallery.files(sessionIds);
      final local = toLocal;
      _plan = local == null
          ? ExportPlan.build(files, content)
          : ExportPlan.build(files, content, toLocal: local);
      _stage = _plan!.parts.isEmpty
          ? ExportRunStage.finished
          : ExportRunStage.ready;
    } on GalleryException catch (error) {
      _failureCode = error.code;
      _stage = ExportRunStage.failed;
    }
    _notify();
  }

  /// Offers the current part to the share sheet at [anchor]. Advances when
  /// its files left for a destination or none could be offered; stays on
  /// it when the operator closed the sheet.
  Future<ExportPartReport?> exportPart(ShareAnchor anchor) async {
    final plan = _plan;
    if (plan == null ||
        _stage == ExportRunStage.exporting ||
        _part >= plan.parts.length) {
      return null;
    }
    _stage = ExportRunStage.exporting;
    _notify();
    final report = await _exporter.export(
      plan.parts[_part],
      anchor: anchor,
      part: _part + 1,
      parts: plan.parts.length,
    );
    _reports.add(report);
    if (report.handedOver) {
      try {
        await _gallery.recordExport(
          ExportRecord(
            id: _ids.newId(),
            createdAtUtc: _clock.now(),
            outcome: report.share!.outcome,
            destination: report.share!.destination,
            files: report.sent,
            failureCount: report.failures.length,
          ),
        );
      } on GalleryException {
        // The files went out; only the history entry is missing.
      }
    }
    final offered = report.sent.isNotEmpty && !report.blockedBySpace;
    final closed = offered && report.share?.outcome == ShareOutcome.dismissed;
    if (!closed && !report.blockedBySpace) _part++;
    _stage = _part >= plan.parts.length
        ? ExportRunStage.finished
        : ExportRunStage.between;
    _notify();
    return report;
  }

  /// Moves past the current part without offering it again.
  void skipPart() {
    final plan = _plan;
    if (plan == null || _stage == ExportRunStage.exporting) return;
    if (_part < plan.parts.length) _part++;
    _stage = _part >= plan.parts.length
        ? ExportRunStage.finished
        : ExportRunStage.between;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
