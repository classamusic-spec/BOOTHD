/// Plays the short guest sounds (EP03, ADR-0017): button presses, the
/// countdown, the shutter and the celebrations.
///
/// Sounds are decoration. Implementations preload, play without waiting
/// and swallow every failure: a sound that cannot load or play is silent
/// and never delays or breaks a guest step. Nothing here touches the
/// network; sounds are bundled with the app.
abstract interface class GuestSoundService {
  /// Loads [soundIds] (ids from `ExperienceCatalog.sounds`) so they play
  /// at once. Unknown or unloadable ids are skipped.
  Future<void> preload(Set<String> soundIds);

  /// Starts [soundId] at [volume] (0 to 1) and returns at once. Does
  /// nothing for a sound that is not loaded.
  void play(String soundId, {double volume = 1});

  /// Releases every loaded sound.
  Future<void> dispose();
}

/// No sound at all: events with sound off, tests and platforms without
/// audio.
final class SilentGuestSoundService implements GuestSoundService {
  const SilentGuestSoundService();

  @override
  Future<void> preload(Set<String> soundIds) async {}

  @override
  void play(String soundId, {double volume = 1}) {}

  @override
  Future<void> dispose() async {}
}
