import 'dart:math';
import 'package:flutter_soloud/flutter_soloud.dart';

class NotePool {
  final AudioSource triangle;
  final AudioSource sine;
  NotePool(this.triangle, this.sine);
}

class MySoLoudTools {
  static const int semitones = 12;
  static const double _c0 = 16.3516;

  static Future<List<NotePool>> createNotes({
    int startOctave = 3,
    int octaveCount = 3,
  }) async {
    final soloud = SoLoud.instance;
    final pools = <NotePool>[];

    for (int oct = startOctave; oct < startOctave + octaveCount; oct++) {
      final double baseFreq = _c0 * pow(2, oct.toDouble());

      for (int i = 0; i < semitones; i++) {
        final freq = (baseFreq * pow(2, i / semitones)).toDouble();

        // ── Triangle layer (warm body) ──────────────────────────────────
        final tri = await soloud.loadWaveform(WaveForm.triangle, true, 1, 1.0);
        soloud.setWaveformFreq(tri, freq);
        soloud.setWaveformSuperWave(tri, false);

        tri.filters.freeverbFilter.activate();
        tri.filters.freeverbFilter.roomSize().value = 0.5;
        tri.filters.freeverbFilter.damp().value = 0.5;
        tri.filters.freeverbFilter.width().value = 0.8;
        tri.filters.freeverbFilter.wet().value = 0.18;
        // tri.filters.freeverbFilter.dry().value = 1.0;

        // ── Sine layer (harmonic shimmer, one octave up) ────────────────
        final sine = await soloud.loadWaveform(WaveForm.sin, true, 1, 1.0);
        soloud.setWaveformFreq(sine, freq * 2);
        soloud.setWaveformSuperWave(sine, false);

        sine.filters.freeverbFilter.activate();
        sine.filters.freeverbFilter.roomSize().value = 0.4;
        sine.filters.freeverbFilter.damp().value = 0.6;
        sine.filters.freeverbFilter.wet().value = 0.12;
        // sine.filters.freeverbFilter.dry().value = 1.0;

        pools.add(NotePool(tri, sine));
      }
    }

    await _preWarm(pools);
    return pools;
  }

  static Future<void> _preWarm(List<NotePool> pools) async {
    final soloud = SoLoud.instance;
    for (final pool in pools) {
      final h1 = soloud.play(pool.triangle, volume: 0);
      final h2 = soloud.play(pool.sine, volume: 0);
      await Future.delayed(const Duration(milliseconds: 10));
      soloud.stop(h1);
      soloud.stop(h2);
    }
  }

  static void disposeAll(List<NotePool> pools) {
    final soloud = SoLoud.instance;
    for (final pool in pools) {
      soloud.disposeSource(pool.triangle);
      soloud.disposeSource(pool.sine);
    }
  }
}
