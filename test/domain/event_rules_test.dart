// AC-0303, AC-0306: event validation rules.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/models/event_rules.dart';
import 'package:porcelain_photo_booth/domain/models/template_revision_summary.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/value_objects/calendar_date.dart';
import 'package:porcelain_photo_booth/domain/value_objects/entity_id.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';

final _now = DateTime.utc(2026, 10, 18);

BoothEvent event({
  String title = 'Gala',
  CaptureSettings? capture,
  TemplateSelection templates = const TemplateSelection(),
  EventStatus status = EventStatus.draft,
}) => BoothEvent(
  id: '00000000-0000-4000-8000-000000000001',
  title: title,
  status: status,
  boothProfileId: '00000000-0000-4000-8000-0000000000b0',
  createdAt: _now,
  updatedAt: _now,
  capture:
      capture ??
      const CaptureSettings(
        lens: CameraLens.front,
        mirrorPreview: true,
        mirrorOutput: false,
        orientation: GuestOrientationPreference.portrait,
        shotCount: 2,
      ),
  templates: templates,
);

TemplateRevisionSummary template(
  String id, {
  int slots = 2,
  bool archived = false,
}) => TemplateRevisionSummary(
  revisionId: id,
  templateId: 't-$id',
  templateName: 'Template $id',
  revisionNumber: 1,
  pageWidthPx: 1200,
  pageHeightPx: 1800,
  photoSlotCount: slots,
  templateArchived: archived,
);

void main() {
  group('structural rules (block saving)', () {
    test('a sensible draft has no issues', () {
      expect(EventRules.structuralIssues(event()), isEmpty);
    });

    test('a title is required and limited', () {
      expect(EventRules.structuralIssues(event(title: '  ')), [
        const TitleRequired(),
      ]);
      expect(EventRules.structuralIssues(event(title: 'x' * 81)), [
        const TextTooLong(EventTextField.title),
      ]);
    });

    test('numeric settings stay in range', () {
      final base = event().capture;
      final issues = EventRules.structuralIssues(
        event(
          capture: base.copyWith(
            shotCount: 5,
            countdownSeconds: 1,
            shotIntervalSeconds: 11,
            retakeLimit: 9,
          ),
        ),
      );
      expect(issues.map((issue) => (issue as SettingOutOfRange).setting), [
        EventSetting.shotCount,
        EventSetting.countdownSeconds,
        EventSetting.shotIntervalSeconds,
        EventSetting.retakeLimit,
      ]);
      expect(
        issues.every((issue) => issue.level == IssueLevel.invalid),
        isTrue,
      );
    });

    test('with retakes off the limit must be zero', () {
      final capture = event().capture.copyWith(
        retakePolicy: RetakePolicy.none,
        retakeLimit: 1,
      );
      expect(EventRules.structuralIssues(event(capture: capture)), [
        const SettingOutOfRange(EventSetting.retakeLimit, IntRange(0, 0), 1),
      ]);
    });

    test('templates are unique and the default is one of them', () {
      final issues = EventRules.structuralIssues(
        event(
          templates: const TemplateSelection(
            revisionIds: ['a', 'a'],
            defaultRevisionId: 'b',
          ),
        ),
      );
      expect(issues, [
        const DuplicateTemplate('a'),
        const DefaultTemplateNotAllowed('b'),
      ]);
    });
  });

  group('template rules (block activation and launch)', () {
    test('no templates blocks', () {
      final issues = EventRules.templateIssues(event(), const {});
      expect(issues, [const NoTemplates()]);
      expect(EventRules.blocksActivation(issues), isTrue);
    });

    test('a missing revision blocks: the operator must choose again', () {
      final issues = EventRules.templateIssues(
        event(templates: const TemplateSelection().add('gone')),
        const {},
      );
      expect(issues, [const TemplateNotFound('gone')]);
    });

    test('photo slots must match photos per session', () {
      final three = template('three', slots: 3);
      final issues = EventRules.templateIssues(
        event(templates: const TemplateSelection().add('three')),
        {'three': three},
      );
      expect(issues, [TemplateSlotsMismatch(three, 2)]);
      expect(EventRules.blocksActivation(issues), isTrue);
    });

    test('an archived template only warns', () {
      final old = template('old', archived: true);
      final issues = EventRules.templateIssues(
        event(templates: const TemplateSelection().add('old')),
        {'old': old},
      );
      expect(issues, [TemplateArchived(old)]);
      expect(EventRules.blocksActivation(issues), isFalse);
    });

    test('a valid selection has no issues', () {
      final issues = EventRules.activationIssues(
        event(templates: const TemplateSelection().add('a').add('b')),
        {'a': template('a'), 'b': template('b')},
      );
      expect(issues, isEmpty);
    });
  });

  group('template selection', () {
    test('the first template added becomes the default', () {
      final selection = const TemplateSelection().add('a').add('b');
      expect(selection.defaultRevisionId, 'a');
      expect(selection.add('a'), selection, reason: 'no duplicates');
    });

    test('removing the default promotes the next one', () {
      final selection = const TemplateSelection().add('a').add('b').remove('a');
      expect(selection.revisionIds, ['b']);
      expect(selection.defaultRevisionId, 'b');
      expect(selection.remove('b').defaultRevisionId, isNull);
    });

    test('templates can be reordered', () {
      final selection = const TemplateSelection()
          .add('a')
          .add('b')
          .add('c')
          .move(2, 0);
      expect(selection.revisionIds, ['c', 'a', 'b']);
      expect(selection.defaultRevisionId, 'a');
    });
  });

  group('value objects', () {
    test('entity IDs are random UUID v4s', () {
      final ids = RandomIdGenerator();
      final generated = {for (var i = 0; i < 200; i++) ids.newId()};
      expect(generated, hasLength(200));
      expect(generated.every(isEntityId), isTrue);
      expect(isEntityId('not-an-id'), isFalse);
      expect(isEntityId('00000000-0000-1000-8000-000000000000'), isFalse);
    });

    test('calendar dates are real days and round-trip as ISO text', () {
      expect(CalendarDate.tryParse('2026-02-29'), isNull);
      expect(CalendarDate.tryParse('2028-02-29'), CalendarDate(2028, 2, 29));
      expect(CalendarDate(2026, 1, 5).toIso(), '2026-01-05');
      expect(CalendarDate.tryParse('26-1-5'), isNull);
      expect(() => CalendarDate(2026, 13, 1), throwsArgumentError);
    });
  });
}
