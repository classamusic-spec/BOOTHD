import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/models/event_rules.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/preflight.dart';
import '../../domain/value_objects/orientation.dart';
import '../../shared/widgets/tone.dart';

/// Words for events (S03, S04, S19). Rules and checks are typed values in
/// the domain; this is where they become operator copy.
abstract final class EventCopy {
  static const archivedReadOnly =
      'Archived events are read-only. Reopen it to make changes.';
  static const copySuffix = '(copy)';

  static String status(EventStatus status) => switch (status) {
    EventStatus.draft => 'Draft',
    EventStatus.active => 'Active',
    EventStatus.archived => 'Archived',
  };

  static PorcelainTone statusTone(EventStatus status) => switch (status) {
    EventStatus.draft => PorcelainTone.neutral,
    EventStatus.active => PorcelainTone.success,
    EventStatus.archived => PorcelainTone.info,
  };

  static IconData statusIcon(EventStatus status) => switch (status) {
    EventStatus.draft => PorcelainIcons.draft,
    EventStatus.active => PorcelainIcons.active,
    EventStatus.archived => PorcelainIcons.archive,
  };

  static String lens(CameraLens lens) => switch (lens) {
    CameraLens.front => 'Front camera',
    CameraLens.back => 'Rear camera',
    CameraLens.external => 'External camera',
  };

  static String orientation(GuestOrientationPreference orientation) =>
      switch (orientation) {
        GuestOrientationPreference.portrait => 'Portrait',
        GuestOrientationPreference.landscape => 'Landscape',
      };

  static String retakes(RetakePolicy policy) => switch (policy) {
    RetakePolicy.none => 'No retakes',
    RetakePolicy.perShot => 'Single photos',
    RetakePolicy.wholeSession => 'Whole session',
  };

  static String format(OutputFormat format) => switch (format) {
    OutputFormat.jpeg => 'JPEG',
    OutputFormat.png => 'PNG',
  };

  static String photos(int count) => count == 1 ? '1 photo' : '$count photos';

  static String templates(int count) => switch (count) {
    0 => 'No templates yet',
    1 => '1 template',
    _ => '$count templates',
  };

  static String seconds(int value) => '$value s';

  /// "2 templates · 3 photos · JPEG"
  static String summary(BoothEvent event) => [
    templates(event.templates.revisionIds.length),
    photos(event.capture.shotCount),
    format(event.output.format),
  ].join(' · ');

  static String field(EventTextField field) => switch (field) {
    EventTextField.title => 'Title',
    EventTextField.venue => 'Venue',
    EventTextField.notes => 'Notes',
    EventTextField.welcomeTitle => 'Welcome title',
    EventTextField.welcomeMessage => 'Welcome message',
    EventTextField.consentText => 'Privacy note',
  };

  static String setting(EventSetting setting) => switch (setting) {
    EventSetting.shotCount => 'Photos per session',
    EventSetting.countdownSeconds => 'Countdown',
    EventSetting.shotIntervalSeconds => 'Pause between photos',
    EventSetting.retakeLimit => 'Retake limit',
    EventSetting.finishTimeoutSeconds => 'Finished screen time',
    EventSetting.jpegQuality => 'JPEG quality',
    EventSetting.retentionDays => 'Days to keep photos',
  };

  /// The words for an issue. [templateName] names a revision by ID.
  static String issue(
    EventIssue issue, {
    String Function(String revisionId)? templateName,
  }) {
    String name(String id) => templateName?.call(id) ?? 'A template';
    return switch (issue) {
      TitleRequired() => 'Give the event a title.',
      TextTooLong(:final field) =>
        '${EventCopy.field(field)} is too long: at most '
            '${field.maxLength} characters.',
      SettingOutOfRange(:final setting, :final range)
          when range.min == range.max =>
        '${EventCopy.setting(setting)} must be ${range.min} here.',
      SettingOutOfRange(:final setting, :final range) =>
        '${EventCopy.setting(setting)} must be between ${range.min} and '
            '${range.max}.',
      NoTemplates() => 'Choose at least one template.',
      TooManyTemplates() =>
        'Use at most ${EventLimits.maxTemplates} templates.',
      DuplicateTemplate(:final revisionId) =>
        '${name(revisionId)} is listed twice.',
      DefaultTemplateMissing() => 'Choose the template guests get by default.',
      DefaultTemplateNotAllowed() =>
        "The default template isn't one of this event's templates.",
      TemplateNotFound() =>
        'A chosen template is no longer in the library. Remove it and '
            'choose another.',
      TemplateArchived(:final template) =>
        '“${template.templateName}” was archived in the library. It still '
            'works, but a current template may suit better.',
      TemplateSlotsMismatch(:final template, :final shotCount) =>
        '“${template.templateName}” has '
            '${photoSlots(template.photoSlotCount)} but the event takes '
            '${photos(shotCount)} per session.',
      EventNotActive(status: EventStatus.archived) =>
        "Archived events can't run the booth. Reopen it first.",
      EventNotActive() =>
        'This event is a draft. Activate it once its templates and '
            'settings are complete.',
    };
  }

  static String photoSlots(int count) =>
      count == 1 ? '1 photo slot' : '$count photo slots';

  // Launch checks (S19).

  static String checkTitle(PreflightCheckId id) => switch (id) {
    PreflightCheckId.eventStatus => 'Event status',
    PreflightCheckId.eventSettings => 'Event settings',
    PreflightCheckId.templates => 'Templates',
    PreflightCheckId.templateAssets => 'Template images and fonts',
    PreflightCheckId.camera => 'Camera',
    PreflightCheckId.storageWrite => 'Saving photos',
    PreflightCheckId.freeSpace => 'Free space',
    PreflightCheckId.orientation => 'Screen orientation',
    PreflightCheckId.renderer => 'Print-ready files',
    PreflightCheckId.printer => 'Printer',
    PreflightCheckId.operatorPin => 'Operator PIN',
    PreflightCheckId.kioskLock => 'Kiosk lock',
  };

  static IconData checkIcon(PreflightCheckId id) => switch (id) {
    PreflightCheckId.eventStatus => PorcelainIcons.events,
    PreflightCheckId.eventSettings => PorcelainIcons.preflight,
    PreflightCheckId.templates => PorcelainIcons.templates,
    PreflightCheckId.templateAssets => PorcelainIcons.layers,
    PreflightCheckId.camera => PorcelainIcons.camera,
    PreflightCheckId.storageWrite => PorcelainIcons.fileWrite,
    PreflightCheckId.freeSpace => PorcelainIcons.storage,
    PreflightCheckId.orientation => PorcelainIcons.orientation,
    PreflightCheckId.renderer => PorcelainIcons.outputFormat,
    PreflightCheckId.printer => PorcelainIcons.printerOff,
    PreflightCheckId.operatorPin => PorcelainIcons.security,
    PreflightCheckId.kioskLock => PorcelainIcons.locked,
  };

  static String group(PreflightGroup group) => switch (group) {
    PreflightGroup.event => 'Event',
    PreflightGroup.device => 'This tablet',
    PreflightGroup.output => 'Output',
    PreflightGroup.security => 'Security',
  };

  static String checkStatus(PreflightStatus status) => switch (status) {
    PreflightStatus.pass => 'Passed',
    PreflightStatus.info => 'For information',
    PreflightStatus.warning => 'Warning',
    PreflightStatus.blocked => 'Blocked',
    PreflightStatus.notYetAvailable => 'Not yet available',
  };

  static PorcelainTone checkTone(PreflightStatus status) => switch (status) {
    PreflightStatus.pass => PorcelainTone.success,
    PreflightStatus.info => PorcelainTone.info,
    PreflightStatus.warning => PorcelainTone.warning,
    PreflightStatus.blocked => PorcelainTone.danger,
    PreflightStatus.notYetAvailable => PorcelainTone.neutral,
  };

  static IconData checkStatusIcon(PreflightStatus status) => switch (status) {
    PreflightStatus.pass => PorcelainIcons.success,
    PreflightStatus.info => PorcelainIcons.info,
    PreflightStatus.warning => PorcelainIcons.warning,
    PreflightStatus.blocked => PorcelainIcons.error,
    PreflightStatus.notYetAvailable => PorcelainIcons.pending,
  };

  /// What a check found, in a sentence or two.
  static List<String> checkDetail(
    PreflightCheck check,
    BoothEvent event, {
    required ViewportOrientation viewport,
    String Function(String revisionId)? templateName,
  }) {
    final issues = [
      for (final issue in check.issues)
        EventCopy.issue(issue, templateName: templateName),
    ];
    final notYet = check.status == PreflightStatus.notYetAvailable;
    final milestone = check.milestone;
    return switch (check.id) {
      PreflightCheckId.eventStatus when issues.isEmpty => [
        'Active and ready for guests.',
      ],
      PreflightCheckId.eventSettings when issues.isEmpty => [
        'Every setting is within its limits.',
      ],
      PreflightCheckId.templates when issues.isEmpty => [
        '${templates(event.templates.revisionIds.length)}, '
            '${photos(event.capture.shotCount)} per session.',
      ],
      PreflightCheckId.eventStatus ||
      PreflightCheckId.eventSettings ||
      PreflightCheckId.templates => issues,
      PreflightCheckId.templateAssets
          when check.status == PreflightStatus.pass =>
        [
          if (event.templates.revisionIds.isEmpty)
            'No templates to check yet.'
          else
            "Every image and font the event's templates use is present and "
                'unchanged.',
        ],
      PreflightCheckId.templateAssets when !notYet => [
        "A template's files are missing or damaged "
            '(${check.problemCode}). Import the template again.',
      ],
      PreflightCheckId.camera when notYet => [
        'Camera permission and the ${lens(event.capture.lens).toLowerCase()} '
            'are checked once the production camera service arrives '
            '($milestone).',
      ],
      PreflightCheckId.freeSpace when notYet => [
        'Measuring free space arrives with device diagnostics ($milestone).',
      ],
      PreflightCheckId.renderer when check.status == PreflightStatus.pass => [
        '${event.templates.revisionIds.isEmpty ? 'A test page' : 'Each template'}'
            ' rendered at full print size as '
            '${event.output.format == OutputFormat.jpeg ? 'JPEG' : 'PNG'}; '
            'nothing was saved.',
      ],
      PreflightCheckId.renderer when !notYet => [
        "A template couldn't be rendered (${check.problemCode}).",
      ],
      PreflightCheckId.kioskLock => [
        'Not checked by the app yet${milestone == null ? '' : ' ($milestone)'}. '
            'Turn on Guided Access (iPad) or app pinning (Android) before '
            'guests arrive.',
      ],
      PreflightCheckId.storageWrite when check.status == PreflightStatus.pass =>
        ['A test file was written, read back and removed.'],
      PreflightCheckId.storageWrite => [
        "Photos can't be saved: a test file couldn't be written "
            '(${check.problemCode}).',
      ],
      PreflightCheckId.orientation when check.status == PreflightStatus.pass => [
        'The tablet is ${orientation(event.capture.orientation).toLowerCase()}, '
            'as the event prefers.',
      ],
      PreflightCheckId.orientation => [
        'The event prefers '
            '${orientation(event.capture.orientation).toLowerCase()} but the '
            'tablet is ${viewport.name}. Guest screens adapt, but rotate the '
            'tablet or change the event for the intended layout.',
      ],
      PreflightCheckId.printer => [
        'Export only: finished photos are saved at full print resolution. '
            'Printing waits for a chosen and tested printer.',
      ],
      PreflightCheckId.operatorPin when check.status == PreflightStatus.pass =>
        ['Set. It is needed to leave Booth Mode.'],
      PreflightCheckId.operatorPin => [
        "The PIN can't be read on this tablet. Lock the Studio and reset it "
            'with the recovery code.',
      ],
      _ when check.status == PreflightStatus.pass => ['Ready.'],
      _ => [
        'Not ready${check.problemCode == null ? '' : ' (${check.problemCode})'}.',
      ],
    };
  }
}
