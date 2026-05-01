import 'dart:math';
import 'package:flutter_soloud/flutter_soloud.dart';

class MySoLoudTools {
  static const int semitones = 12;

  /// Loads [octaveCount] octaves of notes starting from [startOctave].
  /// Returns a flat list of [semitones * octaveCount] AudioSources.
  static Future<List<AudioSource>> createNotes({
    int startOctave = 3,
    int octaveCount = 3,
    WaveForm waveForm = WaveForm.triangle,
    bool superwave = false,
  }) async {
    const double c0 = 16.3516;
    final notes = <AudioSource>[];

    for (int oct = startOctave; oct < startOctave + octaveCount; oct++) {
      final double baseFreq = c0 * pow(2, oct.toDouble());
      for (int i = 0; i < semitones; i++) {
        final sound = await SoLoud.instance.loadWaveform(
          waveForm,
          true,
          0.25,
          1,
        );
        final freq = baseFreq * pow(2, i / semitones);
        SoLoud.instance.setWaveformFreq(sound, freq.toDouble());
        SoLoud.instance.setWaveformSuperWave(sound, superwave);
        notes.add(sound);
      }
    }
    return notes;
  }
}
