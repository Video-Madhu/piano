import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:piano/soloud_tools.dart';

// ─── Music theory constants ───────────────────────────────────────────────────

const List<bool> _isBlack = [
  false,
  true,
  false,
  true,
  false,
  false,
  true,
  false,
  true,
  false,
  true,
  false,
];

const List<String> _noteNames = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

/// Keyboard shortcuts mapped to note indices (0-based across all 36 keys).
/// Row 1 (white keys): Q W E R T Y U I O P Z X C V B N M , . /
/// Row 2 (black keys): 2 3 _ 5 6 7 _ 9 0 _ S D _ F H _ J _ L ; '
final Map<LogicalKeyboardKey, int> _keyMap = {
  // Octave 3 white keys
  LogicalKeyboardKey.keyQ: 0, // C3
  LogicalKeyboardKey.keyW: 2, // D3
  LogicalKeyboardKey.keyE: 4, // E3
  LogicalKeyboardKey.keyR: 5, // F3
  LogicalKeyboardKey.keyT: 7, // G3
  LogicalKeyboardKey.keyY: 9, // A3
  LogicalKeyboardKey.keyU: 11, // B3
  // Octave 3 black keys
  LogicalKeyboardKey.digit2: 1, // C#3
  LogicalKeyboardKey.digit3: 3, // D#3
  LogicalKeyboardKey.digit5: 6, // F#3
  LogicalKeyboardKey.digit6: 8, // G#3
  LogicalKeyboardKey.digit7: 10, // A#3
  // Octave 4 white keys
  LogicalKeyboardKey.keyI: 12, // C4
  LogicalKeyboardKey.keyO: 14, // D4
  LogicalKeyboardKey.keyP: 16, // E4
  LogicalKeyboardKey.keyZ: 17, // F4
  LogicalKeyboardKey.keyX: 19, // G4
  LogicalKeyboardKey.keyC: 21, // A4
  LogicalKeyboardKey.keyV: 23, // B4
  // Octave 4 black keys
  LogicalKeyboardKey.digit9: 13, // C#4
  LogicalKeyboardKey.digit0: 15, // D#4
  LogicalKeyboardKey.keyS: 18, // F#4
  LogicalKeyboardKey.keyD: 20, // G#4
  LogicalKeyboardKey.keyF: 22, // A#4
  // Octave 5 white keys
  LogicalKeyboardKey.keyB: 24, // C5
  LogicalKeyboardKey.keyN: 26, // D5
  LogicalKeyboardKey.keyM: 28, // E5
  LogicalKeyboardKey.comma: 29, // F5
  LogicalKeyboardKey.period: 31, // G5
  LogicalKeyboardKey.slash: 33, // A5
  // Octave 5 black keys
  LogicalKeyboardKey.keyH: 25, // C#5
  LogicalKeyboardKey.keyJ: 27, // D#5
  LogicalKeyboardKey.keyL: 30, // F#5
  LogicalKeyboardKey.semicolon: 32, // G#5
  LogicalKeyboardKey.quote: 34, // A#5
};

// ─── Entry widget ─────────────────────────────────────────────────────────────

class OldPiano extends StatefulWidget {
  const OldPiano({super.key});

  @override
  State<OldPiano> createState() => _OldPianoState();
}

class _OldPianoState extends State<OldPiano> {
  final _soloud = SoLoud.instance;
  final Map<int, SoundHandle> _activeHandles = {};
  List<AudioSource>? _notes;

  // Control bar state
  WaveForm _waveForm = WaveForm.triangle;
  bool _sustain = false;
  double _volume = 0.7;
  bool _showKeyLabels = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await MySoLoudTools.createNotes(
      startOctave: 3,
      octaveCount: 3,
      waveForm: _waveForm,
    );
    if (mounted) setState(() => _notes = notes);
  }

  Future<void> _reloadNotes() async {
    // Dispose old notes
    if (_notes != null) {
      for (final n in _notes!) {
        _soloud.disposeSource(n);
      }
    }
    setState(() => _notes = null);
    await _loadNotes();
  }

  @override
  void dispose() {
    _soloud.deinit();
    super.dispose();
  }

  void _play(int index) {
    if (_notes == null || index < 0 || index >= _notes!.length) return;
    if (_activeHandles.containsKey(index)) return; // already playing
    _soloud.setGlobalVolume(_volume);
    final handle = _soloud.play(_notes![index]);
    setState(() => _activeHandles[index] = handle);
  }

  void _stop(int index) {
    final handle = _activeHandles[index];
    if (handle == null) return;
    final duration = _sustain
        ? const Duration(milliseconds: 1200)
        : const Duration(milliseconds: 300);
    _soloud.fadeVolume(handle, 0, duration);
    _soloud.scheduleStop(handle, duration);
    setState(() => _activeHandles.remove(index));
  }

  void _stopAll() {
    for (final index in _activeHandles.keys.toList()) {
      _stop(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_soloud.isInitialized) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (event) {
          final noteIndex = _keyMap[event.logicalKey];
          if (noteIndex == null) return;
          if (event is KeyDownEvent) _play(noteIndex);
          if (event is KeyUpEvent) _stop(noteIndex);
        },
        child: Column(
          children: [
            // ── Control bar ──
            _ControlBar(
              waveForm: _waveForm,
              sustain: _sustain,
              volume: _volume,
              showKeyLabels: _showKeyLabels,
              onWaveFormChanged: (wf) {
                setState(() => _waveForm = wf);
                _reloadNotes();
              },
              onSustainChanged: (v) => setState(() => _sustain = v),
              onVolumeChanged: (v) => setState(() => _volume = v),
              onKeyLabelsChanged: (v) => setState(() => _showKeyLabels = v),
            ),
            // ── Piano ──
            Expanded(
              child: Center(
                child: _notes == null
                    ? const CircularProgressIndicator(color: Colors.white24)
                    : _PianoKeyboard(
                        totalNotes: 36,
                        activeIndices: _activeHandles.keys.toSet(),
                        showKeyLabels: _showKeyLabels,
                        onNoteDown: _play,
                        onNoteUp: _stop,
                        onStopAll: _stopAll,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Control Bar ──────────────────────────────────────────────────────────────

class _ControlBar extends StatelessWidget {
  final WaveForm waveForm;
  final bool sustain;
  final double volume;
  final bool showKeyLabels;
  final ValueChanged<WaveForm> onWaveFormChanged;
  final ValueChanged<bool> onSustainChanged;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<bool> onKeyLabelsChanged;

  const _ControlBar({
    required this.waveForm,
    required this.sustain,
    required this.volume,
    required this.showKeyLabels,
    required this.onWaveFormChanged,
    required this.onSustainChanged,
    required this.onVolumeChanged,
    required this.onKeyLabelsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Instrument label
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Majical Piano',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.blue[300],
                  letterSpacing: 1,
                ),
              ),
              Text(
                'By Madhu',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),

          // Waveform selector
          _ControlButton(
            icon: Icons.waves,
            label: 'SOUND',
            active: false,
            onTap: () => _showWaveformPicker(context),
          ),
          const SizedBox(width: 12),

          // Volume
          SizedBox(
            width: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'VOL',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white38,
                    letterSpacing: 1,
                  ),
                ),
                Slider(
                  value: volume,
                  min: 0,
                  max: 1,
                  onChanged: onVolumeChanged,
                  activeColor: Colors.white70,
                  inactiveColor: Colors.white12,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Sustain
          _ControlButton(
            icon: Icons.music_note,
            label: 'SUSTAIN',
            active: sustain,
            onTap: () => onSustainChanged(!sustain),
          ),
          const SizedBox(width: 12),

          // Key labels toggle
          _ControlButton(
            icon: Icons.keyboard,
            label: 'KEYS',
            active: showKeyLabels,
            onTap: () => onKeyLabelsChanged(!showKeyLabels),
          ),

          const Spacer(),

          // Waveform chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(38),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.withAlpha(77)),
            ),
            child: Text(
              waveForm.name.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[300],
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWaveformPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select waveform',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: WaveForm.values.map((wf) {
                final selected = wf == waveForm;
                return GestureDetector(
                  onTap: () {
                    onWaveFormChanged(wf);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.blue.withAlpha(64)
                          : Colors.white.withAlpha(13),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? Colors.blue : Colors.white12,
                      ),
                    ),
                    child: Text(
                      wf.name,
                      style: TextStyle(
                        color: selected ? Colors.blue[300] : Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: active ? Colors.amber : Colors.white38),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 0.8,
              color: active ? Colors.amber : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Piano Keyboard ───────────────────────────────────────────────────────────

/// Reverse lookup: keyboard key → note index
final Map<int, LogicalKeyboardKey> _noteToKey = {
  for (final e in _keyMap.entries) e.value: e.key,
};

String _keyLabel(LogicalKeyboardKey key) {
  final k = key.keyLabel;
  return k.length == 1 ? k.toUpperCase() : '';
}

class _PianoKeyboard extends StatelessWidget {
  final int totalNotes;
  final Set<int> activeIndices;
  final bool showKeyLabels;
  final void Function(int) onNoteDown;
  final void Function(int) onNoteUp;
  final VoidCallback onStopAll;

  const _PianoKeyboard({
    required this.totalNotes,
    required this.activeIndices,
    required this.showKeyLabels,
    required this.onNoteDown,
    required this.onNoteUp,
    required this.onStopAll,
  });

  @override
  Widget build(BuildContext context) {
    const double whiteW = 44;
    const double whiteH = 200;
    const double blackW = 28;
    const double blackH = 124;

    // Collect white key indices across all 36 notes
    final whiteIndices = <int>[];
    for (int i = 0; i < totalNotes; i++) {
      if (!_isBlack[i % 12]) whiteIndices.add(i);
    }

    final totalWidth = whiteW * whiteIndices.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        height: whiteH,
        child: Stack(
          children: [
            // White keys
            Row(
              children: whiteIndices.map((noteIndex) {
                final shortcut = _noteToKey[noteIndex];
                return _PianoKey(
                  noteIndex: noteIndex,
                  noteName: _noteNames[noteIndex % 12],
                  isBlack: false,
                  width: whiteW,
                  height: whiteH,
                  isActive: activeIndices.contains(noteIndex),
                  keyboardShortcut: showKeyLabels && shortcut != null
                      ? _keyLabel(shortcut)
                      : null,
                  onNoteDown: onNoteDown,
                  onNoteUp: onNoteUp,
                );
              }).toList(),
            ),

            // Black keys
            ..._buildBlackKeys(
              totalNotes,
              whiteIndices,
              whiteW,
              blackW,
              blackH,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBlackKeys(
    int total,
    List<int> whiteIndices,
    double whiteW,
    double blackW,
    double blackH,
  ) {
    final widgets = <Widget>[];
    for (int i = 0; i < total; i++) {
      if (!_isBlack[i % 12]) continue;

      final leftWhite = whiteIndices.indexOf(i - 1);
      if (leftWhite == -1) continue;
      final left = (leftWhite + 1) * whiteW - blackW / 2;

      final shortcut = _noteToKey[i];

      widgets.add(
        Positioned(
          left: left,
          top: 0,
          child: _PianoKey(
            noteIndex: i,
            noteName: _noteNames[i % 12],
            isBlack: true,
            width: blackW,
            height: blackH,
            isActive: activeIndices.contains(i),
            keyboardShortcut: shortcut != null ? _keyLabel(shortcut) : null,
            onNoteDown: onNoteDown,
            onNoteUp: onNoteUp,
          ),
        ),
      );
    }
    return widgets;
  }
}

// ─── Individual Key ───────────────────────────────────────────────────────────

class _PianoKey extends StatelessWidget {
  final int noteIndex;
  final String noteName;
  final bool isBlack;
  final double width;
  final double height;
  final bool isActive;
  final String? keyboardShortcut;
  final void Function(int) onNoteDown;
  final void Function(int) onNoteUp;

  const _PianoKey({
    required this.noteIndex,
    required this.noteName,
    required this.isBlack,
    required this.width,
    required this.height,
    required this.isActive,
    required this.keyboardShortcut,
    required this.onNoteDown,
    required this.onNoteUp,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (isBlack) {
      bg = isActive ? const Color(0xFF5A4FCF) : const Color(0xFF111122);
    } else {
      bg = isActive ? const Color(0xFFD4CBFF) : Colors.white;
    }

    return Listener(
      onPointerDown: (_) => onNoteDown(noteIndex),
      onPointerUp: (_) => onNoteUp(noteIndex),
      onPointerCancel: (_) => onNoteUp(noteIndex),
      // Drag enter/exit — when pointer moves over this key while held down
      onPointerMove: (event) {
        // Handled at the parent via GestureDetector drag, see below
      },
      child: MouseRegion(
        // For drag-play: if pointer is down while entering, play
        onEnter: (event) {
          if (event.buttons != 0) onNoteDown(noteIndex);
        },
        onExit: (event) {
          if (event.buttons != 0) onNoteUp(noteIndex);
        },
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(
              color: isBlack ? Colors.black : Colors.black26,
              width: isBlack ? 0 : 0.5,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.purpleAccent.withAlpha(102),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (keyboardShortcut != null && keyboardShortcut!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isBlack
                        ? Colors.white.withAlpha(30)
                        : Colors.black.withAlpha(18),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    keyboardShortcut!,
                    style: TextStyle(
                      fontSize: 10,
                      color: isBlack
                          ? Colors.white.withAlpha(138)
                          : Colors.black.withAlpha(115),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  noteName,
                  style: TextStyle(
                    fontSize: 9,
                    color: isBlack ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
