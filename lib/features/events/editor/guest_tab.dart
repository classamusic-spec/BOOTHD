import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/porcelain_icons.dart';
import '../../../core/design_system/porcelain_metrics.dart';
import '../../../core/design_system/porcelain_theme.dart';
import '../../../core/design_system/theme_profiles.dart';
import '../../../core/experience/guest_theme.dart';
import '../../../core/routing/route_paths.dart';
import '../../../domain/experience/experience_catalog.dart';
import '../../../domain/experience/experience_configuration.dart';
import '../../../domain/experience/experience_pack.dart';
import '../../../domain/experience/experience_registry.dart';
import '../../../domain/models/event_rules.dart';
import '../../../domain/session/countdown_state.dart';
import '../../../domain/value_objects/orientation.dart';
import '../../../shared/guest/event_welcome_copy.dart';
import '../../../shared/guest/guest_countdown.dart';
import '../../../shared/guest/guest_welcome.dart';
import '../../../shared/guest/guest_welcome_sample.dart';
import '../../../shared/widgets/porcelain_button.dart';
import '../../../shared/widgets/porcelain_segmented_control.dart';
import '../../../shared/widgets/porcelain_stepper.dart';
import '../../../shared/widgets/porcelain_switch.dart';
import '../../../shared/widgets/porcelain_text_field.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/tablet_frame.dart';
import '../event_copy.dart';
import 'editor_parts.dart';
import 'experience_card.dart';

/// Which part of the Experience panel to show: both in the editor's
/// Experience tab, one per step in the Event Builder (EP07).
enum GuestTabSection { choose, customize, all }

/// What guests see (S04 Experience, EP07): the guest experience pack and
/// its variant, with a live preview of the welcome and the countdown; then
/// everything the operator may change about it (words, accent colour,
/// countdown, motion, celebration, sound, the camera screen) with Reset to
/// pack defaults; then the finished screen's time. Changing pack keeps the
/// event's words, templates and camera settings.
class GuestTab extends StatefulWidget {
  const GuestTab({
    super.key,
    required this.tab,
    required this.boothTheme,
    this.section = GuestTabSection.all,
  });

  final EditorTabContext tab;

  /// The booth's own theme, used when the event has no override.
  final PorcelainThemeProfile boothTheme;
  final GuestTabSection section;

  @override
  State<GuestTab> createState() => _GuestTabState();
}

class _GuestTabState extends State<GuestTab> {
  late final _title = TextEditingController(
    text: widget.tab.event.guest.welcomeTitle,
  );
  late final _message = TextEditingController(
    text: widget.tab.event.guest.welcomeMessage,
  );
  late final _getReady = TextEditingController(
    text: widget.tab.event.experience.getReadyText,
  );
  late final _finish = TextEditingController(
    text: widget.tab.event.experience.finishText,
  );

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _getReady.dispose();
    _finish.dispose();
    super.dispose();
  }

  static String? _optional(String text) => text.trim().isEmpty ? null : text;

  EditorTabContext get _tab => widget.tab;
  EventExperienceConfiguration get _config => _tab.event.experience;

  void _setExperience(EventExperienceConfiguration config) =>
      _tab.onChanged(_tab.event.copyWith(experience: config));

  /// [pack] chosen: a new pack keeps only the event-level choices; a pack
  /// made for children asks for a guardian (EP00 4.7).
  void _choosePack(ExperiencePack pack) {
    if (pack.packId == _config.packId) return;
    _setExperience(
      _config
          .switchPack(pack.packId, pack.packVersion)
          .copyWith(
            childrenMayBeGuests:
                ExperienceRegistry.childrenPackIds.contains(pack.packId) ||
                _config.childrenMayBeGuests,
          ),
    );
  }

  void _reset() {
    _getReady.clear();
    _finish.clear();
    _setExperience(
      _config.resetToPackDefaults().copyWith(variantId: _config.variantId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final shown = ExperienceRegistry.bundled.resolve(_config);
    final pack =
        ExperienceRegistry.bundled.pack(_config.packId) ??
        ExperienceRegistry.bundled.fallback;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section != GuestTabSection.customize) ...[
          _chooseCard(pack, shown),
          if (section == GuestTabSection.all)
            const SizedBox(height: PorcelainSpace.xl),
        ],
        if (section != GuestTabSection.choose) ...[
          _welcomeCard(),
          const SizedBox(height: PorcelainSpace.xl),
          _wordsCard(pack),
          const SizedBox(height: PorcelainSpace.xl),
          _lookCard(shown),
          const SizedBox(height: PorcelainSpace.xl),
          _soundCard(shown),
          const SizedBox(height: PorcelainSpace.xl),
          _cameraCard(),
          const SizedBox(height: PorcelainSpace.xl),
          _finishedCard(),
        ],
      ],
    );
  }

  Widget _chooseCard(ExperiencePack pack, ResolvedExperience shown) {
    final tab = _tab;
    final event = tab.event;
    final reason = tab.readOnlyReason;
    final landscape =
        event.capture.orientation == GuestOrientationPreference.landscape;
    final frame = landscape ? const Size(1180, 820) : const Size(820, 1180);
    return EditorCard(
      title: 'Choose guest experience',
      subtitle:
          'The look, words, buttons, countdown and sounds of every guest '
          'screen. The Studio keeps the booth theme; changing it keeps the '
          "event's words, templates and camera settings.",
      children: [
        Wrap(
          spacing: PorcelainSpace.md,
          runSpacing: PorcelainSpace.md,
          children: [
            for (final candidate in ExperienceRegistry.bundled.packs)
              ExperienceCard(
                experience: ExperienceRegistry.bundled.resolve(
                  candidate.packId == _config.packId
                      ? _config
                      : _config.switchPack(
                          candidate.packId,
                          candidate.packVersion,
                        ),
                ),
                title: candidate.displayName,
                selected: candidate.packId == _config.packId,
                disabledReason: reason,
                onPressed: tab.readOnly ? null : () => _choosePack(candidate),
              ),
          ],
        ),
        if (pack.variants.length > 1)
          EditorSetting(
            title: 'Variant',
            description: 'Two looks of ${pack.displayName}.',
            control: PorcelainSegmentedControl<String>(
              selected: shown.variantId,
              onChanged: tab.readOnly
                  ? null
                  : (id) => _setExperience(
                      _config.copyWith(
                        variantId: id == pack.defaultVariantId ? null : id,
                      ),
                    ),
              disabledReason: reason,
              segments: [
                for (final variant in pack.variants)
                  PorcelainSegment(value: variant.id, label: variant.name),
              ],
            ),
          ),
        PorcelainSwitchRow(
          title: 'Guests may be children',
          subtitle:
              'Texting screens add: "A parent or guardian enters the '
              'number and gives consent." On for Kid Party Arcade.',
          icon: PorcelainIcons.privacy,
          value: _config.childrenMayBeGuests,
          onChanged: tab.readOnly
              ? null
              : (on) =>
                    _setExperience(_config.copyWith(childrenMayBeGuests: on)),
          disabledReason: reason,
        ),
        GuestExperienceScope(
          experience: shown,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: PorcelainSpace.xl,
            runSpacing: PorcelainSpace.md,
            children: [
              SizedBox(
                height: 260,
                width: 260 * frame.width / frame.height + 18,
                child: TabletFrame(
                  logicalSize: frame,
                  semanticLabel:
                      'Preview of the guest welcome in ${shown.displayName}, '
                      '${EventCopy.orientation(event.capture.orientation).toLowerCase()}',
                  child: GuestWelcome(
                    copy: welcomeCopyFor(event),
                    onStart: () {},
                  ),
                ),
              ),
              Semantics(
                label:
                    'Preview of the countdown: '
                    '${ExperienceCatalog.countdownNames[shown.countdownPresetId]}',
                child: ExcludeSemantics(
                  child: _CountdownSample(experience: shown),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: PorcelainButton(
            label: 'Preview the whole guest journey',
            icon: PorcelainIcons.preview,
            variant: PorcelainButtonVariant.secondary,
            onPressed: () =>
                context.push(RoutePaths.experiencePreview, extra: event),
          ),
        ),
      ],
    );
  }

  Widget _welcomeCard() {
    final tab = _tab;
    final event = tab.event;
    final guest = event.guest;
    final reason = tab.readOnlyReason;
    return EditorCard(
      title: 'Welcome screen',
      subtitle: 'Leave a field empty to use the standard words.',
      children: [
        PorcelainTextField(
          label: 'Welcome title',
          controller: _title,
          hint: sampleGuestWelcomeCopy.title,
          helper:
              'The largest words guests see. The event name and date sit '
              'above them.',
          enabled: !tab.readOnly,
          disabledReason: reason,
          maxLength: EventLimits.welcomeTitleMaxLength,
          showCounter: true,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (text) => tab.onChanged(
            event.copyWith(
              guest: guest.copyWith(welcomeTitle: _optional(text)),
            ),
          ),
        ),
        PorcelainTextField(
          label: 'Welcome message',
          controller: _message,
          hint: sampleWelcomeMessage,
          enabled: !tab.readOnly,
          disabledReason: reason,
          maxLength: EventLimits.welcomeMessageMaxLength,
          showCounter: true,
          maxLines: 4,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (text) => tab.onChanged(
            event.copyWith(
              guest: guest.copyWith(welcomeMessage: _optional(text)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wordsCard(ExperiencePack pack) {
    final tab = _tab;
    final reason = tab.readOnlyReason;
    // The pack's own words, shown as the hint of an empty field.
    final defaults = ExperienceRegistry.bundled
        .resolve(_config.copyWith(getReadyText: null, finishText: null))
        .copy;
    return EditorCard(
      title: 'Guest words',
      subtitle: 'Leave a field empty to use ${pack.displayName}\'s own words.',
      children: [
        PorcelainTextField(
          label: 'Get ready words',
          controller: _getReady,
          hint: defaults[GuestCopyKey.getReady],
          helper: 'Above the camera before each photo.',
          enabled: !tab.readOnly,
          disabledReason: reason,
          maxLength: EventExperienceConfiguration.maxGetReadyLength,
          showCounter: true,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (text) =>
              _setExperience(_config.copyWith(getReadyText: _optional(text))),
        ),
        PorcelainTextField(
          label: 'Finished title',
          controller: _finish,
          hint: defaults[GuestCopyKey.readyTitle],
          helper: 'Above the finished photo.',
          enabled: !tab.readOnly,
          disabledReason: reason,
          maxLength: EventExperienceConfiguration.maxFinishLength,
          showCounter: true,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (text) =>
              _setExperience(_config.copyWith(finishText: _optional(text))),
        ),
      ],
    );
  }

  Widget _lookCard(ResolvedExperience shown) {
    final tab = _tab;
    final reason = tab.readOnlyReason;
    final theme = context.porcelain;
    // Only colours this pack's text stays readable on.
    final accents = [
      for (final (name, argb) in ExperienceCatalog.accentChoices)
        if (ExperienceRegistry.bundled
            .resolve(_config.copyWith(accentColor: argb))
            .problems
            .isEmpty)
          (name, argb),
    ];
    final atDefaults =
        _config.resetToPackDefaults().copyWith(variantId: _config.variantId) ==
        _config;
    return EditorCard(
      title: 'Look and motion',
      subtitle: 'Choices this pack allows. Readability is kept for you.',
      trailing: PorcelainButton(
        label: 'Reset to pack defaults',
        icon: PorcelainIcons.restore,
        variant: PorcelainButtonVariant.secondary,
        size: PorcelainButtonSize.compact,
        onPressed: tab.readOnly || atDefaults ? null : _reset,
        disabledReason:
            reason ?? 'Everything already follows ${shown.displayName}.',
      ),
      children: [
        EditorSetting(
          title: 'Accent colour',
          stacked: true,
          description: 'Buttons and highlights on guest screens.',
          control: Wrap(
            spacing: PorcelainSpace.sm,
            runSpacing: PorcelainSpace.sm,
            children: [
              _Swatch(
                name: 'Pack colour',
                argb: null,
                selected: _config.accentColor == null,
                onPressed: tab.readOnly
                    ? null
                    : () => _setExperience(_config.copyWith(accentColor: null)),
                disabledReason: reason,
              ),
              for (final (name, argb) in accents)
                _Swatch(
                  name: name,
                  argb: argb,
                  selected: _config.accentColor == argb,
                  onPressed: tab.readOnly
                      ? null
                      : () =>
                            _setExperience(_config.copyWith(accentColor: argb)),
                  disabledReason: reason,
                ),
            ],
          ),
        ),
        EditorSetting(
          title: 'Countdown',
          stacked: true,
          description: 'The numbers before each photo.',
          control: Wrap(
            spacing: PorcelainSpace.sm,
            runSpacing: PorcelainSpace.sm,
            children: [
              for (final MapEntry(key: id, value: name)
                  in ExperienceCatalog.countdownNames.entries)
                _Chip(
                  label: name,
                  selected: shown.countdownPresetId == id,
                  onPressed: tab.readOnly
                      ? null
                      : () => _setExperience(
                          _config.copyWith(countdownPresetId: id),
                        ),
                  disabledReason: reason,
                ),
            ],
          ),
        ),
        EditorSetting(
          title: 'Animation',
          description: 'Guests who ask for reduced motion always get none.',
          control: PorcelainSegmentedControl<AnimationIntensity>(
            selected: shown.animation,
            onChanged: tab.readOnly
                ? null
                : (value) => _setExperience(_config.copyWith(animation: value)),
            disabledReason: reason,
            segments: const [
              PorcelainSegment(value: AnimationIntensity.off, label: 'Off'),
              PorcelainSegment(
                value: AnimationIntensity.gentle,
                label: 'Gentle',
              ),
              PorcelainSegment(value: AnimationIntensity.full, label: 'Full'),
            ],
          ),
        ),
        PorcelainSwitchRow(
          title: 'Celebrate the finished photo',
          subtitle: 'Confetti around the finished photo.',
          icon: PorcelainIcons.active,
          value: _config.celebrationEnabled,
          onChanged: tab.readOnly
              ? null
              : (on) =>
                    _setExperience(_config.copyWith(celebrationEnabled: on)),
          disabledReason: reason,
        ),
        if (!atDefaults)
          Text(
            'Changed from ${shown.displayName}\'s defaults.',
            style: theme.text.bodyMedium.copyWith(color: theme.colors.inkMuted),
          ),
      ],
    );
  }

  Widget _soundCard(ResolvedExperience shown) {
    final tab = _tab;
    final reason = tab.readOnlyReason;
    final on = shown.soundEnabled;
    return EditorCard(
      title: 'Sound',
      subtitle:
          'Short sounds at the start, each countdown second, the photo and '
          "the finish. Off unless you turn it on; it mixes with the venue's "
          'music.',
      children: [
        PorcelainSwitchRow(
          title: 'Play sounds',
          icon: PorcelainIcons.sound,
          value: on,
          onChanged: tab.readOnly
              ? null
              : (value) =>
                    _setExperience(_config.copyWith(soundEnabled: value)),
          disabledReason: reason,
        ),
        EditorSetting(
          title: 'Volume',
          control: PorcelainStepper(
            label: 'Volume',
            value: _config.soundVolume,
            min: 10,
            max: 100,
            step: 10,
            formatValue: (value) => '$value%',
            decreaseLabel: 'Quieter',
            increaseLabel: 'Louder',
            onChanged: tab.readOnly || !on
                ? null
                : (value) =>
                      _setExperience(_config.copyWith(soundVolume: value)),
            disabledReason: reason ?? 'Turn sounds on first.',
            minimumReason: reason ?? 'At least 10%.',
            maximumReason: reason ?? 'At most 100%.',
          ),
        ),
      ],
    );
  }

  Widget _cameraCard() {
    final tab = _tab;
    final reason = tab.readOnlyReason;
    return EditorCard(
      title: 'Camera screen',
      subtitle:
          'Full template shows the photo template around the live picture, '
          'the photo being taken in its own space. Camera-focused shows '
          'the live picture large. The finished photo is the same either '
          'way.',
      children: [
        PorcelainSegmentedControl<CameraStageMode>(
          selected: _config.cameraStage,
          onChanged: tab.readOnly
              ? null
              : (mode) => _setExperience(_config.copyWith(cameraStage: mode)),
          disabledReason: reason,
          segments: const [
            PorcelainSegment(
              value: CameraStageMode.cameraFocused,
              label: 'Camera-focused',
              icon: PorcelainIcons.camera,
            ),
            PorcelainSegment(
              value: CameraStageMode.fullTemplate,
              label: 'Full template',
              icon: PorcelainIcons.templates,
            ),
          ],
        ),
      ],
    );
  }

  Widget _finishedCard() {
    final tab = _tab;
    final event = tab.event;
    final guest = event.guest;
    final reason = tab.readOnlyReason;
    return EditorCard(
      title: 'Finished screen',
      subtitle:
          'How long the finished photo stays before the booth resets for '
          'the next guest.',
      children: [
        EditorSetting(
          title: EventCopy.setting(EventSetting.finishTimeoutSeconds),
          control: PorcelainStepper(
            label: EventCopy.setting(EventSetting.finishTimeoutSeconds),
            value: guest.finishTimeoutSeconds,
            min: EventLimits.finishTimeoutSeconds.min,
            max: EventLimits.finishTimeoutSeconds.max,
            step: 5,
            formatValue: EventCopy.seconds,
            decreaseLabel: 'Shorter',
            increaseLabel: 'Longer',
            onChanged: tab.edit(
              (seconds) => event.copyWith(
                guest: guest.copyWith(finishTimeoutSeconds: seconds),
              ),
            ),
            disabledReason: reason,
            minimumReason:
                reason ??
                'At least ${EventLimits.finishTimeoutSeconds.min} seconds.',
            maximumReason:
                reason ??
                'At most ${EventLimits.finishTimeoutSeconds.max} seconds.',
          ),
        ),
      ],
    );
  }
}

/// The pack's countdown, mid-way, as guests will see it.
class _CountdownSample extends StatelessWidget {
  const _CountdownSample({required this.experience});

  final ResolvedExperience experience;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final name = ExperienceCatalog.countdownNames[experience.countdownPresetId];
    return Container(
      width: 176,
      padding: const EdgeInsets.all(PorcelainSpace.md),
      decoration: BoxDecoration(
        color: theme.colors.canvas,
        borderRadius: PorcelainRadius.cardAll,
        border: Border.all(color: theme.colors.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GuestCountdown(
            size: 140,
            state: CountdownState(
              remaining: 2,
              total: 3,
              shot: 0,
              shotCount: 2,
            ),
          ),
          const SizedBox(height: PorcelainSpace.sm),
          Text(
            name ?? '',
            style: theme.text.labelLarge.copyWith(color: theme.colors.ink),
          ),
        ],
      ),
    );
  }
}

/// One accent colour: a round swatch with a check when chosen; "Pack
/// colour" is the pack's own.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.name,
    required this.argb,
    required this.selected,
    required this.onPressed,
    this.disabledReason,
  });

  final String name;
  final int? argb;
  final bool selected;
  final VoidCallback? onPressed;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    final fill = argb == null ? null : Color(argb!);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: name,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      disabledReason: disabledReason,
      builder: (context, state) => Tooltip(
        message: name,
        child: Container(
          width: PorcelainSize.minTouchTarget,
          height: PorcelainSize.minTouchTarget,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill ?? colors.surface,
            border: Border.all(
              color: selected || state.focused
                  ? colors.focusRing
                  : colors.outline,
              width: selected || state.focused ? 3 : 1,
            ),
          ),
          child: Icon(
            selected
                ? PorcelainIcons.check
                : fill == null
                ? PorcelainIcons.appearance
                : null,
            size: 20,
            color: fill == null
                ? colors.ink
                : ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
                ? colors.surface
                : colors.ink,
          ),
        ),
      ),
    );
  }
}

/// A named choice among several, raised when chosen.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.disabledReason,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      disabledReason: disabledReason,
      builder: (context, state) => Container(
        constraints: const BoxConstraints(
          minHeight: PorcelainSize.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: PorcelainSpace.md),
        decoration: BoxDecoration(
          color: selected ? colors.surface : colors.inset,
          borderRadius: PorcelainRadius.controlAll,
          border: Border.all(
            color: selected
                ? colors.accentIcon
                : state.focused
                ? colors.focusRing
                : colors.hairline,
            width: selected || state.focused ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(PorcelainIcons.check, size: 18, color: colors.accentIcon),
              const SizedBox(width: PorcelainSpace.xxs),
            ],
            Text(
              label,
              style: theme.text.labelLarge.copyWith(
                color: colors.ink,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
