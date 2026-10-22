import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../core/diagnostics/safe_log.dart';
import '../../domain/experience/experience_catalog.dart';
import '../../domain/services/guest_sound_service.dart';

/// Guest sounds through the `audioplayers` package (EP03, ADR-0017): one
/// small low-latency pool per sound, loaded from the app's own assets
/// (`assets/sounds/<id>.wav`), never from a URL.
///
/// The booth's sounds mix with whatever the venue plays and never take
/// the audio focus or duck music. Every failure is swallowed and logged
/// once without detail: a sound is never worth a broken guest step.
final class AudioplayersGuestSoundService implements GuestSoundService {
  AudioplayersGuestSoundService();

  final _pools = <String, AudioPool>{};
  final _failed = <String>{};
  var _contextSet = false;

  Future<void> _setContext() async {
    if (_contextSet) return;
    _contextSet = true;
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
        respectSilence: false,
      ).build(),
    );
  }

  @override
  Future<void> preload(Set<String> soundIds) async {
    try {
      await _setContext();
    } on Object {
      SafeLog.event('GUEST_SOUND_CONTEXT_FAILED');
    }
    for (final id in soundIds) {
      if (!ExperienceCatalog.sounds.contains(id)) continue;
      if (_pools.containsKey(id) || _failed.contains(id)) continue;
      try {
        _pools[id] = await AudioPool.create(
          source: AssetSource('sounds/$id.wav'),
          maxPlayers: 3,
        );
      } on Object {
        _failed.add(id);
        SafeLog.event('GUEST_SOUND_LOAD_FAILED', id);
      }
    }
  }

  @override
  void play(String soundId, {double volume = 1}) {
    final pool = _pools[soundId];
    if (pool == null) return;
    unawaited(
      pool
          .start(volume: volume.clamp(0, 1))
          .then<void>((_) {}, onError: (Object _) {}),
    );
  }

  @override
  Future<void> dispose() async {
    final pools = [..._pools.values];
    _pools.clear();
    for (final pool in pools) {
      try {
        await pool.dispose();
      } on Object {
        // Released with the app anyway.
      }
    }
  }
}
