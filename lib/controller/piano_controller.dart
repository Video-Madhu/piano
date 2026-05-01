import 'dart:async';
import 'dart:math';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:get/get.dart';
import 'package:piano/soloud_tools.dart';

/// Holds both handles for one active (pressed) note.
class _ActiveNote {
  final SoundHandle triHandle;
  final SoundHandle sineHandle;
  final DateTime pressedAt;
  _ActiveNote(this.triHandle, this.sineHandle) : pressedAt = DateTime.now();
}

class PianoController extends GetxController {
  final _soloud = SoLoud.instance;

  // ── Observable (UI only) ─────────────────────────────────────────────────
  final activeKeys = <int>{}.obs;
  final sustain = false.obs;
  final volume = 0.7.obs;
  final showKeyLabels = true.obs;
  final isLoading = true.obs;

  // ── Audio state (never observable — zero-latency mutations) ─────────────
  List<NotePool> _pools = [];
  final Map<int, _ActiveNote> _active = {};

  // ADSR timings
  static const _attackMs = 8; // ms — fast piano-like attack
  static const _decayMs = 200; // ms — natural fall after peak
  static const _sustainLv = 0.55; // 0..1 — level after decay
  // release is dynamic: sustain toggle changes it (see stop())

  @override
  void onInit() {
    super.onInit();
    loadNotes();
  }

  @override
  void onClose() {
    MySoLoudTools.disposeAll(_pools);
    _soloud.deinit();
    super.onClose();
  }

  Future<void> loadNotes() async {
    isLoading.value = true;
    stopAll();
    MySoLoudTools.disposeAll(_pools);
    _pools = [];

    _pools = await MySoLoudTools.createNotes(startOctave: 3, octaveCount: 3);

    _soloud.setGlobalVolume(volume.value);
    isLoading.value = false;
  }

  // ── velocity: 0.0 (softest) → 1.0 (hardest) ─────────────────────────────
  // We measure how quickly the pointer moves at the moment of press.
  // If no velocity data available, defaults to 0.7 (mezzoforte).
  void play(int index, {double velocity = 0.7}) {
    if (_pools.isEmpty || index < 0 || index >= _pools.length) return;
    if (_active.containsKey(index)) return; // already playing

    final pool = _pools[index];
    velocity = velocity.clamp(0.1, 1.0);

    // ── Triangle: loud (body of the note) ──────────────────────────────────
    // volume = velocity * masterVolume * 0.75 (triangle is the main layer)
    final triVol = velocity * volume.value * 0.75;
    final triHandle = _soloud.play(pool.triangle, volume: 0); // start silent
    _applyAdsr(triHandle, triVol);

    // ── Sine: quieter (adds shimmer/brightness) ─────────────────────────────
    // Soft notes have less high-harmonic content — velocity² roll-off
    final sineVol = pow(velocity, 2).toDouble() * volume.value * 0.30;
    final sineHandle = _soloud.play(pool.sine, volume: 0);
    _applyAdsr(sineHandle, sineVol);

    _active[index] = _ActiveNote(triHandle, sineHandle);
    activeKeys.add(index);
  }

  /// Applies a piano-style ADSR using SoLoud faders.
  ///
  ///  0ms ──attack──▶ peak  ──decay──▶ sustainLevel  (held until stop())
  void _applyAdsr(SoundHandle handle, double peakVolume) {
    // Attack: ramp from 0 → peakVolume in _attackMs
    _soloud.fadeVolume(
      handle,
      peakVolume,
      const Duration(milliseconds: _attackMs),
    );

    // Decay: schedule a second fade from peakVolume → sustainLevel
    // starting right after attack ends
    Future.delayed(const Duration(milliseconds: _attackMs), () {
      if (!_soloud.getIsValidVoiceHandle(handle)) return;
      _soloud.fadeVolume(
        handle,
        peakVolume * _sustainLv,
        const Duration(milliseconds: _decayMs),
      );
    });
  }

  void stop(int index) {
    final note = _active.remove(index);
    if (note == null) return;

    final releaseMs = sustain.value ? 1400 : 280;
    final releaseDur = Duration(milliseconds: releaseMs);

    _soloud.fadeVolume(note.triHandle, 0, releaseDur);
    _soloud.scheduleStop(note.triHandle, releaseDur);

    _soloud.fadeVolume(note.sineHandle, 0, releaseDur);
    _soloud.scheduleStop(note.sineHandle, releaseDur);

    activeKeys.remove(index);
  }

  void stopAll() {
    for (final index in _active.keys.toList()) stop(index);
  }

  void setVolume(double v) {
    volume.value = v;
    _soloud.setGlobalVolume(v);
  }
}
