import 'package:flutter/widgets.dart';

import '../../domain/experience/experience_catalog.dart';
import '../../domain/experience/experience_registry.dart';
import '../../domain/services/guest_sound_service.dart';
import '../../domain/session/guest_flow.dart';

/// Turns guest moments into the pack's sounds (EP03).
///
/// Sound follows the session's frozen experience: off unless the event
/// turned it on, at the event's volume. The player only listens: it never
/// waits for a sound, and the flow never waits for it.
final class GuestCuePlayer {
  GuestCuePlayer(this._sounds);

  final GuestSoundService _sounds;
  ResolvedExperience? _experience;

  /// The experience whose sounds play from now on; its sounds are loaded
  /// when sound is on.
  Future<void> use(ResolvedExperience experience) async {
    if (identical(experience, _experience)) return;
    _experience = experience;
    if (!experience.soundEnabled) return;
    try {
      await _sounds.preload(experience.sounds.values.toSet());
    } on Object {
      // Unloaded sounds stay silent.
    }
  }

  /// Plays [cue]'s sound, if sound is on.
  void cue(SoundCue cue) {
    final experience = _experience;
    if (experience == null || !experience.soundEnabled) return;
    final id = experience.sounds[cue];
    if (id == null) return;
    try {
      _sounds.play(id, volume: experience.soundVolume / 100);
    } on Object {
      // A sound is never worth a broken step.
    }
  }

  /// The cues for the guest moving from [previous] to [next]: the start of
  /// a session, each countdown second (the last one says "go"), the
  /// shutter, and the finished photo.
  void onFlow(GuestFlow previous, GuestFlow next) {
    if (next.stage == GuestStage.countdown) {
      final newSecond =
          previous.stage != GuestStage.countdown ||
          previous.secondsLeft != next.secondsLeft ||
          previous.shot != next.shot;
      if (newSecond) cue(next.secondsLeft <= 1 ? SoundCue.go : SoundCue.tick);
      return;
    }
    if (next.stage == previous.stage) return;
    switch (next.stage) {
      case GuestStage.templateSelection:
      case GuestStage.preparing when previous.stage == GuestStage.idle:
        cue(SoundCue.start);
      case GuestStage.capturing:
        cue(SoundCue.shutter);
      case GuestStage.completed:
        final celebrate = _experience?.celebrationPresetId != 'none';
        cue(celebrate ? SoundCue.celebrate : SoundCue.success);
      default:
        break;
    }
  }

  Future<void> dispose() async {
    try {
      await _sounds.dispose();
    } on Object {
      // Released with the app anyway.
    }
  }
}

/// Gives guest controls below it a way to sound their press (EP03).
class GuestCueScope extends InheritedWidget {
  const GuestCueScope({super.key, required this.onCue, required super.child});

  final void Function(SoundCue cue) onCue;

  /// Sounds [cue] through the nearest scope; nothing without one.
  static void play(BuildContext context, SoundCue cue) =>
      context.getInheritedWidgetOfExactType<GuestCueScope>()?.onCue(cue);

  @override
  bool updateShouldNotify(GuestCueScope old) => old.onCue != onCue;
}
