import 'dart:math';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:get/get.dart';
import 'package:piano/soloud_tools.dart';

class PianoController extends GetxController {
  final _soloud = SoLoud.instance;

  // Observable state (for UI only)
  final activeKeys = <int>{}.obs;
  final waveForm = WaveForm.triangle.obs;
  final sustain = false.obs;
  final volume = 0.7.obs;
  final showKeyLabels = true.obs;
  final isLoading = true.obs;

  // Audio state — NOT observable, mutated directly for zero-latency
  List<AudioSource> _notes = [];
  final Map<int, SoundHandle> _handles = {};

  @override
  void onInit() {
    super.onInit();
    loadNotes();
  }

  @override
  void onClose() {
    _soloud.deinit();
    super.onClose();
  }

  Future<void> loadNotes() async {
    isLoading.value = true;
    stopAll();

    for (final n in _notes) {
      _soloud.disposeSource(n);
    }

    _notes = await MySoLoudTools.createNotes(
      startOctave: 3,
      octaveCount: 3,
      waveForm: waveForm.value,
    );

    _soloud.setGlobalVolume(volume.value);
    isLoading.value = false;
  }

  void play(int index) {
    if (_notes.isEmpty || index < 0 || index >= _notes.length) return;
    if (_handles.containsKey(index)) return;

    final handle = _soloud.play(_notes[index]);
    _handles[index] = handle;
    activeKeys.add(index); // triggers UI update only
  }

  void stop(int index) {
    final handle = _handles.remove(index);
    if (handle == null) return;

    final ms = sustain.value ? 1200 : 250;
    _soloud.fadeVolume(handle, 0, Duration(milliseconds: ms));
    _soloud.scheduleStop(handle, Duration(milliseconds: ms));
    activeKeys.remove(index);
  }

  void stopAll() {
    for (final index in _handles.keys.toList()) {
      stop(index);
    }
  }

  void setWaveForm(WaveForm wf) {
    waveForm.value = wf;
    loadNotes();
  }

  void setVolume(double v) {
    volume.value = v;
    _soloud.setGlobalVolume(v);
  }
}
