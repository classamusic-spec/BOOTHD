/// The launch checklist (S05, S19, P-05 rules, AC-0306): what stands
/// between an event and Booth Mode, with blockers kept apart from warnings
/// and checks the app cannot make yet reported as such, never as passed.
library;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../models/booth_event.dart';
import '../models/event_rules.dart';
import '../models/template_revision_summary.dart';
import '../value_objects/orientation.dart';
import 'booth_capabilities.dart';

enum PreflightStatus {
  pass,

  /// For information only, e.g. export-only printing.
  info,
  warning,
  blocked,

  /// The app cannot check this yet. Blocks launch: nothing unchecked is
  /// assumed to work.
  notYetAvailable,
}

enum PreflightGroup { event, device, output, security }

/// Every launch check, in display order.
enum PreflightCheckId {
  eventStatus(PreflightGroup.event),
  eventSettings(PreflightGroup.event),
  templates(PreflightGroup.event),
  templateAssets(PreflightGroup.event),
  camera(PreflightGroup.device),
  storageWrite(PreflightGroup.device),
  freeSpace(PreflightGroup.device),
  orientation(PreflightGroup.device),
  renderer(PreflightGroup.output),
  printer(PreflightGroup.output),
  operatorPin(PreflightGroup.security),
  kioskLock(PreflightGroup.security);

  const PreflightCheckId(this.group);

  final PreflightGroup group;
}

@immutable
final class PreflightCheck {
  const PreflightCheck(
    this.id,
    this.status, {
    this.issues = const [],
    this.problemCode,
    this.milestone,
  });

  final PreflightCheckId id;
  final PreflightStatus status;

  /// Event configuration problems behind an event check.
  final List<EventIssue> issues;

  /// Diagnostic code of a failed device check (A-14).
  final String? problemCode;

  /// For [PreflightStatus.notYetAvailable]: the milestone that adds it.
  final String? milestone;

  bool get blocksLaunch =>
      status == PreflightStatus.blocked ||
      status == PreflightStatus.notYetAvailable;
}

@immutable
final class PreflightReport {
  const PreflightReport(this.checks);

  final List<PreflightCheck> checks;

  bool get canLaunch => checks.none((check) => check.blocksLaunch);

  int get blockerCount => checks.where((check) => check.blocksLaunch).length;

  int get warningCount =>
      checks.where((check) => check.status == PreflightStatus.warning).length;

  PreflightCheck operator [](PreflightCheckId id) =>
      checks.firstWhere((check) => check.id == id);
}

/// What the device reported for the launch checks.
@immutable
final class DeviceFacts {
  const DeviceFacts({
    required this.camera,
    required this.storageWrite,
    required this.freeSpace,
    required this.renderer,
    required this.templateAssets,
    required this.kioskLock,
    required this.viewport,
    required this.operatorPinAvailable,
  });

  final CapabilityStatus camera;
  final CapabilityStatus storageWrite;
  final CapabilityStatus freeSpace;
  final CapabilityStatus renderer;
  final CapabilityStatus templateAssets;
  final CapabilityStatus kioskLock;

  /// The window's current shape (not the operator's preference).
  final ViewportOrientation viewport;
  final bool operatorPinAvailable;
}

abstract final class Preflight {
  /// The launch checklist for [event], given the template library
  /// ([library]: summaries by revision ID) and what the device reported.
  static PreflightReport evaluate({
    required BoothEvent event,
    required Map<String, TemplateRevisionSummary> library,
    required DeviceFacts device,
  }) {
    PreflightCheck fromCapability(
      PreflightCheckId id,
      CapabilityStatus status,
    ) => switch (status) {
      CapabilityReady() => PreflightCheck(id, PreflightStatus.pass),
      CapabilityProblem(:final code) => PreflightCheck(
        id,
        PreflightStatus.blocked,
        problemCode: code,
      ),
      CapabilityNotYetAvailable(:final milestone) => PreflightCheck(
        id,
        PreflightStatus.notYetAvailable,
        milestone: milestone,
      ),
    };

    final structural = EventRules.structuralIssues(event);
    final templates = EventRules.templateIssues(event, library);
    final preferred = switch (event.capture.orientation) {
      GuestOrientationPreference.portrait => ViewportOrientation.portrait,
      GuestOrientationPreference.landscape => ViewportOrientation.landscape,
    };

    return PreflightReport([
      event.status == EventStatus.active
          ? const PreflightCheck(
              PreflightCheckId.eventStatus,
              PreflightStatus.pass,
            )
          : PreflightCheck(
              PreflightCheckId.eventStatus,
              PreflightStatus.blocked,
              issues: [EventNotActive(event.status)],
            ),
      PreflightCheck(
        PreflightCheckId.eventSettings,
        structural.isEmpty ? PreflightStatus.pass : PreflightStatus.blocked,
        issues: structural,
      ),
      PreflightCheck(
        PreflightCheckId.templates,
        EventRules.blocksActivation(templates)
            ? PreflightStatus.blocked
            : templates.isEmpty
            ? PreflightStatus.pass
            : PreflightStatus.warning,
        issues: templates,
      ),
      fromCapability(PreflightCheckId.templateAssets, device.templateAssets),
      fromCapability(PreflightCheckId.camera, device.camera),
      fromCapability(PreflightCheckId.storageWrite, device.storageWrite),
      fromCapability(PreflightCheckId.freeSpace, device.freeSpace),
      // Guest screens adapt to whatever window they get (ADR-0004), so a
      // mismatch is worth fixing but never blocks.
      PreflightCheck(
        PreflightCheckId.orientation,
        device.viewport == preferred
            ? PreflightStatus.pass
            : PreflightStatus.warning,
      ),
      fromCapability(PreflightCheckId.renderer, device.renderer),
      // Export-only release: there is no printer to check (A-13).
      const PreflightCheck(PreflightCheckId.printer, PreflightStatus.info),
      PreflightCheck(
        PreflightCheckId.operatorPin,
        device.operatorPinAvailable
            ? PreflightStatus.pass
            : PreflightStatus.blocked,
      ),
      // The kiosk lock is the operator's to set; an unverifiable lock is a
      // reminder, not a blocker.
      switch (device.kioskLock) {
        CapabilityReady() => const PreflightCheck(
          PreflightCheckId.kioskLock,
          PreflightStatus.pass,
        ),
        CapabilityProblem(:final code) => PreflightCheck(
          PreflightCheckId.kioskLock,
          PreflightStatus.warning,
          problemCode: code,
        ),
        CapabilityNotYetAvailable(:final milestone) => PreflightCheck(
          PreflightCheckId.kioskLock,
          PreflightStatus.warning,
          milestone: milestone,
        ),
      },
    ]);
  }
}
