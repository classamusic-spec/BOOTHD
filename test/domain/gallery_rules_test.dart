// AC-0803, AC-0805, AC-0806 (rules): export names and parts, the gallery
// search, retention cutoffs and the printer boundary.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/gallery/export_plan.dart';
import 'package:porcelain_photo_booth/domain/gallery/gallery_models.dart';
import 'package:porcelain_photo_booth/domain/gallery/gallery_search.dart';
import 'package:porcelain_photo_booth/domain/gallery/retention.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/repositories/session_repository.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/domain/services/print_service.dart';
import 'package:porcelain_photo_booth/domain/template/page_spec.dart';

SessionFiles _files(int number, {int outputs = 1, int photos = 2}) =>
    SessionFiles(
      sessionId: 'session-$number',
      number: number,
      eventTitle: 'Garden Party 2026!',
      startedAtUtc: DateTime.utc(2026, 6, 20, 21, 5),
      outputs: [
        for (var v = 1; v <= outputs; v++)
          ExportableOutput(
            id: 'output-$number-$v',
            relativePath: 'outputs/output-$number-$v.jpg',
            sha256: 'e' * 64,
            byteLength: 1000,
            format: OutputFormat.jpeg,
          ),
      ],
      photos: [
        for (var shot = 0; shot < photos; shot++)
          ExportablePhoto(
            shot: shot,
            attempt: 1,
            originalId: 'original-$number-$shot',
            relativePath: 'originals/original-$number-$shot.jpg',
            sha256: 'a' * 64,
            byteLength: 3000,
          ),
      ],
    );

GallerySession _session(int number, int minute) => GallerySession(
  id: 'session-$number',
  eventId: 'event',
  number: number,
  status: SessionStatus.completed,
  startedAtUtc: DateTime.utc(2026, 6, 20, 21, minute),
  plannedShots: 2,
  photoCount: 2,
  outputCount: 1,
  setComplete: true,
);

void main() {
  group('export names', () {
    test('event titles become short, safe slugs', () {
      expect(ExportNames.slug('Garden Party 2026!'), 'garden-party-2026');
      expect(
        ExportNames.slug('Hannah & Theo’s wedding'),
        'hannah-theo-s-wedding',
      );
      expect(ExportNames.slug('../../etc/passwd'), 'etc-passwd');
      expect(ExportNames.slug('Été à Paris'), 't-paris');
      expect(ExportNames.slug('🎉'), 'event');
      expect(ExportNames.slug('a' * 80), hasLength(ExportNames.maxSlugLength));
    });

    test('finished photos and camera photos sort by session', () {
      expect(
        ExportNames.finished(
          eventTitle: 'Garden Party',
          number: 42,
          localStart: DateTime(2026, 6, 20, 21, 5),
          format: OutputFormat.png,
        ),
        'garden-party-0042-20260620-2105.png',
      );
      expect(
        ExportNames.finished(
          eventTitle: 'Garden Party',
          number: 42,
          localStart: DateTime(2026, 6, 20, 21, 5),
          format: OutputFormat.jpeg,
          version: 2,
        ),
        'garden-party-0042-20260620-2105-v2.jpg',
      );
      expect(
        ExportNames.original(
          eventTitle: 'Garden Party',
          number: 42,
          shot: 1,
          attempt: 3,
        ),
        'garden-party-0042-photo2-retake2.jpg',
      );
    });
  });

  group('export plan', () {
    test('finished photos only by default; sessions without one are '
        'reported before anything is copied', () {
      final plan = ExportPlan.build(
        [_files(1, outputs: 2), _files(2, outputs: 0), _files(3)],
        ExportContent.finishedPhotos,
        toLocal: (utc) => utc,
      );
      expect(plan.parts.single.map((i) => i.sourceId), [
        'output-1-2',
        'output-3-1',
      ], reason: "each session's newest finished photo");
      expect(plan.failures.single.sessionNumber, 2);
      expect(plan.failures.single.problem, ExportProblem.noFinishedPhoto);
      expect(plan.fileCount, 2);
    });

    test('with originals every camera photo goes too; a missing record is '
        'reported', () {
      final missing = SessionFiles(
        sessionId: 'session-4',
        number: 4,
        eventTitle: 'Garden Party',
        startedAtUtc: DateTime.utc(2026, 6, 20, 21),
        outputs: const [],
        photos: const [ExportablePhoto(shot: 0, attempt: 1, originalId: 'x')],
      );
      final plan = ExportPlan.build(
        [_files(1), missing],
        ExportContent.finishedAndOriginals,
        toLocal: (utc) => utc,
      );
      expect(plan.parts.single.map((i) => i.fileName), [
        'garden-party-2026-0001-20260620-2105.jpg',
        'garden-party-2026-0001-photo1.jpg',
        'garden-party-2026-0001-photo2.jpg',
      ]);
      expect(plan.failures.map((f) => (f.sessionNumber, f.problem, f.kind)), [
        (4, ExportProblem.noFinishedPhoto, ExportFileKind.finished),
        (4, ExportProblem.missing, ExportFileKind.original),
      ]);
    });

    test('large selections go in parts the share sheet can take', () {
      final plan = ExportPlan.build(
        [for (var n = 1; n <= 450; n++) _files(n)],
        ExportContent.finishedPhotos,
        toLocal: (utc) => utc,
      );
      expect(plan.parts.map((p) => p.length), [200, 200, 50]);
      expect(plan.parts.last.last.sessionNumber, 450);
      final names = {
        for (final part in plan.parts)
          for (final item in part) item.fileName,
      };
      expect(names, hasLength(450), reason: 'every name is unique');
    });

    test('a report hands over only what the platform says left', () {
      final item = ExportPlan.build(
        [_files(1)],
        ExportContent.finishedPhotos,
        toLocal: (utc) => utc,
      ).parts.single.single;
      ExportPartReport report(ShareOutcome? outcome) => ExportPartReport(
        part: 1,
        parts: 1,
        sent: [item],
        failures: const [],
        share: outcome == null ? null : ShareReport(outcome),
      );
      expect(report(ShareOutcome.shared).handedOver, isTrue);
      expect(report(ShareOutcome.unknown).handedOver, isTrue);
      expect(report(ShareOutcome.dismissed).handedOver, isFalse);
      expect(report(null).handedOver, isFalse);
    });
  });

  group('search', () {
    final sessions = [_session(41, 5), _session(42, 31), _session(43, 38)];

    List<int> found(String query) => [
      for (final s in sessions)
        if (GallerySearch.parse(query)!.matches(s, toLocal: (utc) => utc))
          s.number,
    ];

    test('a number finds that session', () {
      expect(found('42'), [42]);
      expect(found('#43'), [43]);
      expect(found('# 41'), [41]);
      expect(found('7'), isEmpty);
    });

    test('a time finds sessions started then', () {
      expect(found('21:31'), [42]);
      expect(found('21:3'), [42, 43]);
      expect(found('21:'), [41, 42, 43]);
      expect(found('9pm'), [41, 42, 43]);
      expect(found('9:05 PM'), [41]);
      expect(found('9:05 am'), isEmpty);
    });

    test('anything else is not a search the gallery understands', () {
      expect(GallerySearch.parse('wedding'), isNull);
      expect(GallerySearch.parse('25:00'), isNull);
      expect(GallerySearch.parse('21:7'), isNull);
      expect(GallerySearch.parse('13pm'), isNull);
      expect(GallerySearch.parse('   ')!.isEmpty, isTrue);
    });
  });

  group('retention', () {
    final now = DateTime.utc(2026, 12, 1, 12);

    test('photos kept until deleted are never due', () {
      const keep = RetentionPolicy.keepUntilDeleted();
      expect(RetentionRules.cutoff(keep, now), isNull);
      expect(RetentionRules.isDue(keep, DateTime.utc(2000), now), isFalse);
    });

    test('photos older than the event allows are due, younger ones '
        'not', () {
      const thirty = RetentionPolicy.deleteAfterDays(30);
      expect(RetentionRules.cutoff(thirty, now), DateTime.utc(2026, 11, 1, 12));
      expect(
        RetentionRules.isDue(thirty, DateTime.utc(2026, 11, 1, 11, 59), now),
        isTrue,
      );
      expect(
        RetentionRules.isDue(thirty, DateTime.utc(2026, 11, 1, 12), now),
        isFalse,
      );
    });
  });

  group('printing (AC-0806)', () {
    const service = UnconfiguredPrintService();

    test('the only adapter says printing is not configured', () async {
      final capabilities = await service.capabilities();
      expect(capabilities.configured, isFalse);
      expect(capabilities.adapterName, isNull);
      expect(capabilities.media, isEmpty);
      expect(capabilities.maxCopies, 0);
      expect(capabilities.reportsPhysicalCompletion, isFalse);
      expect(capabilities.reasonCode, 'PRINT_NOT_CONFIGURED');
    });

    test('a request is never queued, submitted or reported printed', () async {
      final job = await service.submit(
        const PrintRequest(
          outputId: 'd0000000-0000-4000-8000-000000000001',
          page: PageSpec.fourBySixPortrait,
          format: OutputFormat.jpeg,
          copies: 2,
        ),
      );
      expect(job.status, PrintJobStatus.unconfigured);
      expect(job.id, isNull, reason: 'no job exists');
      expect(job.code, 'PRINT_NOT_CONFIGURED');
      final status = await service.status('any');
      expect(status.status, PrintJobStatus.unconfigured);
      expect(status.code, 'PRINT_UNKNOWN_JOB');
    });
  });
}
