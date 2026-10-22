// EP03: every sound a pack can name ships with the app as a short, valid
// WAV file, and the owner's sound sheet lists exactly what each pack plays.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_catalog.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';

void main() {
  test('every catalog sound is a short 44.1 kHz 16-bit mono WAV', () {
    for (final id in ExperienceCatalog.sounds) {
      final file = File('assets/sounds/$id.wav');
      expect(file.existsSync(), isTrue, reason: id);
      final bytes = file.readAsBytesSync();
      final data = ByteData.sublistView(bytes);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF', reason: id);
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE', reason: id);
      expect(data.getUint16(20, Endian.little), 1, reason: '$id: PCM');
      expect(data.getUint16(22, Endian.little), 1, reason: '$id: mono');
      expect(data.getUint32(24, Endian.little), 44100, reason: id);
      expect(data.getUint16(34, Endian.little), 16, reason: id);
      final seconds = (bytes.length - 44) / (44100 * 2);
      expect(seconds, inInclusiveRange(0.05, 2.5), reason: id);
    }
    final shipped = {
      for (final file in Directory('assets/sounds').listSync())
        file.uri.pathSegments.last,
    };
    expect(shipped, {for (final id in ExperienceCatalog.sounds) '$id.wav'});
  });

  test('the sound sheet lists what each pack plays', () {
    final sheet = File('docs/experience_packs/SOUND_SCRIPT_ELEVENLABS.md')
        .readAsLinesSync();
    final start = sheet.indexWhere((l) => l.startsWith('| Pack | Press'));
    final rows = {
      for (final line
          in sheet.skip(start + 2).takeWhile((l) => l.startsWith('|')))
        line.split('|')[1].trim(): [
          for (final cell in line.split('|').skip(2).take(7)) cell.trim(),
        ],
    };
    for (final pack in ExperienceRegistry.bundled.packs) {
      expect(rows[pack.displayName], [
        for (final cue in SoundCue.values) pack.sounds[cue],
      ], reason: pack.displayName);
    }
    expect(rows, hasLength(ExperienceRegistry.bundled.packs.length));
  });

  test('the sheet has one prompt row for every sound', () {
    final sheet = File('docs/experience_packs/SOUND_SCRIPT_ELEVENLABS.md')
        .readAsStringSync();
    for (final id in ExperienceCatalog.sounds) {
      expect(sheet, contains('`$id.mp3`'), reason: id);
    }
  });
}
