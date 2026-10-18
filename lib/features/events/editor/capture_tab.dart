import 'package:flutter/widgets.dart';

import '../../../core/design_system/porcelain_icons.dart';
import '../../../core/design_system/porcelain_metrics.dart';
import '../../../domain/models/booth_event.dart';
import '../../../domain/models/event_rules.dart';
import '../../../domain/services/camera_service.dart';
import '../../../domain/value_objects/orientation.dart';
import '../../../shared/widgets/porcelain_segmented_control.dart';
import '../../../shared/widgets/porcelain_stepper.dart';
import '../../../shared/widgets/porcelain_switch.dart';
import '../event_copy.dart';
import 'editor_parts.dart';

/// Camera, mirroring, orientation, pacing and retakes (S04 Capture, P-08).
/// Preview and saved-photo mirroring are separate settings (CR-001 fix 5).
class CaptureTab extends StatelessWidget {
  const CaptureTab({super.key, required this.tab});

  final EditorTabContext tab;

  @override
  Widget build(BuildContext context) {
    final event = tab.event;
    final capture = event.capture;
    final reason = tab.readOnlyReason;
    ValueChanged<T>? set<T>(CaptureSettings Function(T value) change) =>
        tab.edit<T>((value) => event.copyWith(capture: change(value)));

    String? limit(String text) => reason ?? text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorCard(
          title: 'Camera',
          subtitle: 'Which camera faces the guests, and how they see it.',
          children: [
            EditorSetting(
              title: 'Camera',
              control: PorcelainSegmentedControl<CameraLens>(
                selected: capture.lens,
                onChanged: set((lens) => capture.copyWith(lens: lens)),
                disabledReason: reason,
                segments: [
                  for (final lens in [CameraLens.front, CameraLens.back])
                    PorcelainSegment(
                      value: lens,
                      label: EventCopy.lens(lens),
                      icon: PorcelainIcons.camera,
                    ),
                ],
              ),
            ),
            PorcelainSwitchRow(
              title: 'Mirror the live preview',
              subtitle:
                  'Guests see themselves as in a mirror while posing. Usual '
                  'for the front camera.',
              icon: PorcelainIcons.preview,
              value: capture.mirrorPreview,
              onChanged: set((on) => capture.copyWith(mirrorPreview: on)),
              disabledReason: reason,
            ),
            PorcelainSwitchRow(
              title: 'Mirror saved photos',
              subtitle:
                  'Usually off, so text and signs in the photo read the '
                  'right way round.',
              icon: PorcelainIcons.gallery,
              value: capture.mirrorOutput,
              onChanged: set((on) => capture.copyWith(mirrorOutput: on)),
              disabledReason: reason,
            ),
            const EditorNote(
              icon: PorcelainIcons.info,
              text:
                  'Whether this tablet has the chosen camera is checked at '
                  'launch once the production camera service arrives (M06).',
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        EditorCard(
          title: 'Guest screen orientation',
          subtitle:
              "The way guests should hold or see the tablet. It's a "
              'preference: guest screens always fit the window the tablet '
              'gives them, and the launch checks warn if it is held the '
              'other way.',
          children: [
            PorcelainSegmentedControl<GuestOrientationPreference>(
              selected: capture.orientation,
              onChanged: set(
                (orientation) => capture.copyWith(orientation: orientation),
              ),
              disabledReason: reason,
              segments: [
                for (final orientation in GuestOrientationPreference.values)
                  PorcelainSegment(
                    value: orientation,
                    label: EventCopy.orientation(orientation),
                    icon: orientation == GuestOrientationPreference.portrait
                        ? PorcelainIcons.portrait
                        : PorcelainIcons.landscape,
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        EditorCard(
          title: 'Session',
          subtitle: 'One photo for each photo slot of the template.',
          children: [
            EditorSetting(
              title: EventCopy.setting(EventSetting.shotCount),
              control: PorcelainStepper(
                label: EventCopy.setting(EventSetting.shotCount),
                value: capture.shotCount,
                min: EventLimits.shotCount.min,
                max: EventLimits.shotCount.max,
                decreaseLabel: 'Fewer photos',
                increaseLabel: 'More photos',
                onChanged: set((count) => capture.copyWith(shotCount: count)),
                disabledReason: reason,
                minimumReason: limit('A session takes at least one photo.'),
                maximumReason: limit(
                  'A session takes at most ${EventLimits.shotCount.max} '
                  'photos.',
                ),
              ),
            ),
            EditorSetting(
              title: EventCopy.setting(EventSetting.countdownSeconds),
              description: 'Before each photo.',
              control: PorcelainStepper(
                label: EventCopy.setting(EventSetting.countdownSeconds),
                value: capture.countdownSeconds,
                min: EventLimits.countdownSeconds.min,
                max: EventLimits.countdownSeconds.max,
                formatValue: EventCopy.seconds,
                decreaseLabel: 'Shorter countdown',
                increaseLabel: 'Longer countdown',
                onChanged: set(
                  (seconds) => capture.copyWith(countdownSeconds: seconds),
                ),
                disabledReason: reason,
                minimumReason: limit(
                  'Guests need at least ${EventLimits.countdownSeconds.min} '
                  'seconds to get ready.',
                ),
                maximumReason: limit(
                  'The countdown is at most '
                  '${EventLimits.countdownSeconds.max} seconds.',
                ),
              ),
            ),
            EditorSetting(
              title: EventCopy.setting(EventSetting.shotIntervalSeconds),
              description: 'Between the photos of one session.',
              control: PorcelainStepper(
                label: EventCopy.setting(EventSetting.shotIntervalSeconds),
                value: capture.shotIntervalSeconds,
                min: EventLimits.shotIntervalSeconds.min,
                max: EventLimits.shotIntervalSeconds.max,
                formatValue: EventCopy.seconds,
                decreaseLabel: 'Shorter pause',
                increaseLabel: 'Longer pause',
                onChanged: capture.shotCount > 1
                    ? set(
                        (seconds) =>
                            capture.copyWith(shotIntervalSeconds: seconds),
                      )
                    : null,
                disabledReason:
                    reason ?? 'Only used when a session takes several photos.',
                minimumReason: limit('The pause is at least one second.'),
                maximumReason: limit(
                  'The pause is at most '
                  '${EventLimits.shotIntervalSeconds.max} seconds.',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        EditorCard(
          title: 'Retakes',
          subtitle:
              'A retake is a new photo; the earlier one is kept for the '
              'operator until the retention rules remove it.',
          children: [
            PorcelainSegmentedControl<RetakePolicy>(
              selected: capture.retakePolicy,
              onChanged: set(
                (policy) => capture.copyWith(
                  retakePolicy: policy,
                  retakeLimit: policy == RetakePolicy.none
                      ? 0
                      : capture.retakeLimit.clamp(
                          EventLimits.retakeLimit.min,
                          EventLimits.retakeLimit.max,
                        ),
                ),
              ),
              disabledReason: reason,
              segments: [
                for (final policy in RetakePolicy.values)
                  PorcelainSegment(
                    value: policy,
                    label: EventCopy.retakes(policy),
                  ),
              ],
            ),
            EditorSetting(
              title: EventCopy.setting(EventSetting.retakeLimit),
              description: capture.retakePolicy == RetakePolicy.wholeSession
                  ? 'Times a guest may redo the whole session.'
                  : 'Times a guest may redo each photo.',
              control: PorcelainStepper(
                label: EventCopy.setting(EventSetting.retakeLimit),
                value: capture.retakeLimit,
                min: capture.retakePolicy == RetakePolicy.none
                    ? 0
                    : EventLimits.retakeLimit.min,
                max: capture.retakePolicy == RetakePolicy.none
                    ? 0
                    : EventLimits.retakeLimit.max,
                decreaseLabel: 'Fewer retakes',
                increaseLabel: 'More retakes',
                onChanged: capture.retakePolicy == RetakePolicy.none
                    ? null
                    : set((count) => capture.copyWith(retakeLimit: count)),
                disabledReason: reason ?? 'Retakes are off.',
                minimumReason: limit(
                  'At least one retake while retakes are on.',
                ),
                maximumReason: limit(
                  'At most ${EventLimits.retakeLimit.max} retakes.',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
