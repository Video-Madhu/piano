import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:get/get.dart';
import 'package:piano/controller/piano_controller.dart';

// ── Music theory ──────────────────────────────────────────────────────────────

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

final Map<LogicalKeyboardKey, int> _keyMap = {
  LogicalKeyboardKey.keyQ: 0,
  LogicalKeyboardKey.digit2: 1,
  LogicalKeyboardKey.keyW: 2,
  LogicalKeyboardKey.digit3: 3,
  LogicalKeyboardKey.keyE: 4,
  LogicalKeyboardKey.keyR: 5,
  LogicalKeyboardKey.digit5: 6,
  LogicalKeyboardKey.keyT: 7,
  LogicalKeyboardKey.digit6: 8,
  LogicalKeyboardKey.keyY: 9,
  LogicalKeyboardKey.digit7: 10,
  LogicalKeyboardKey.keyU: 11,
  LogicalKeyboardKey.keyI: 12,
  LogicalKeyboardKey.digit9: 13,
  LogicalKeyboardKey.keyO: 14,
  LogicalKeyboardKey.digit0: 15,
  LogicalKeyboardKey.keyP: 16,
  LogicalKeyboardKey.keyZ: 17,
  LogicalKeyboardKey.keyS: 18,
  LogicalKeyboardKey.keyX: 19,
  LogicalKeyboardKey.keyD: 20,
  LogicalKeyboardKey.keyC: 21,
  LogicalKeyboardKey.keyF: 22,
  LogicalKeyboardKey.keyV: 23,
  LogicalKeyboardKey.keyB: 24,
  LogicalKeyboardKey.keyH: 25,
  LogicalKeyboardKey.keyN: 26,
  LogicalKeyboardKey.keyJ: 27,
  LogicalKeyboardKey.keyM: 28,
  LogicalKeyboardKey.comma: 29,
  LogicalKeyboardKey.keyL: 30,
  LogicalKeyboardKey.period: 31,
  LogicalKeyboardKey.semicolon: 32,
  LogicalKeyboardKey.slash: 33,
  LogicalKeyboardKey.quote: 34,
};

// ── Key layout helpers ────────────────────────────────────────────────────────

const double _whiteW = 44;
const double _whiteH = 200;
const double _blackW = 28;
const double _blackH = 124;
const int _totalNotes = 36;

/// Precomputed left-edge X positions for all 36 keys
List<double> _buildKeyOffsets() {
  final offsets = List<double>.filled(_totalNotes, 0);
  int whiteCount = 0;
  for (int i = 0; i < _totalNotes; i++) {
    if (_isBlack[i % 12]) {
      // Black key: centered over the gap between its two white neighbours
      offsets[i] = (whiteCount * _whiteW) - _blackW / 2;
    } else {
      offsets[i] = whiteCount * _whiteW;
      whiteCount++;
    }
  }
  return offsets;
}

final _keyOffsets = _buildKeyOffsets();

/// Given an x position on the keyboard, returns the note index.
/// Black keys take priority (they're on top).
int? _hitTest(double x, double y) {
  // First check black keys (they're visually on top)
  for (int i = 0; i < _totalNotes; i++) {
    if (!_isBlack[i % 12]) continue;
    final left = _keyOffsets[i];
    if (x >= left && x <= left + _blackW && y >= 0 && y <= _blackH) {
      return i;
    }
  }
  // Then white keys
  for (int i = 0; i < _totalNotes; i++) {
    if (_isBlack[i % 12]) continue;
    final left = _keyOffsets[i];
    if (x >= left && x <= left + _whiteW) return i;
  }
  return null;
}

int _whiteKeyCount() {
  int count = 0;
  for (int i = 0; i < _totalNotes; i++) {
    if (!_isBlack[i % 12]) count++;
  }
  return count;
}

// ── Entry ─────────────────────────────────────────────────────────────────────

class MyPiano extends StatelessWidget {
  const MyPiano({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(PianoController());

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (event) {
          final idx = _keyMap[event.logicalKey];
          if (idx == null) return;
          if (event is KeyDownEvent) ctrl.play(idx);
          if (event is KeyUpEvent) ctrl.stop(idx);
        },
        child: Column(
          children: [
            _ControlBar(ctrl: ctrl),
            Expanded(
              child: Center(
                child: Obx(
                  () => ctrl.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white24)
                      : _PianoKeyboard(ctrl: ctrl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Control bar ───────────────────────────────────────────────────────────────

class _ControlBar extends StatelessWidget {
  final PianoController ctrl;
  const _ControlBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(
        () => Row(
          children: [
            // Instrument label
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INSTR',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.blue[300],
                    letterSpacing: 1,
                  ),
                ),
                const Text(
                  'Piano',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),

            _CtrlBtn(
              icon: Icons.waves,
              label: 'SOUND',
              active: false,
              onTap: () => _pickWaveform(context, ctrl),
            ),
            const SizedBox(width: 16),

            // Volume
            SizedBox(
              width: 110,
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
                    value: ctrl.volume.value,
                    onChanged: ctrl.setVolume,
                    activeColor: Colors.white70,
                    inactiveColor: Colors.white12,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            _CtrlBtn(
              icon: Icons.music_note,
              label: 'SUSTAIN',
              active: ctrl.sustain.value,
              onTap: () => ctrl.sustain.toggle(),
            ),
            const SizedBox(width: 16),

            _CtrlBtn(
              icon: Icons.keyboard,
              label: 'KEYS',
              active: ctrl.showKeyLabels.value,
              onTap: () => ctrl.showKeyLabels.toggle(),
            ),

            const Spacer(),

            // Waveform chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                ctrl.waveForm.value.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue[300],
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickWaveform(BuildContext context, PianoController ctrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Obx(
        () => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select waveform',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: WaveForm.values.map((wf) {
                  final selected = wf == ctrl.waveForm.value;
                  return GestureDetector(
                    onTap: () {
                      ctrl.setWaveForm(wf);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.blue.withOpacity(0.25)
                            : Colors.white.withOpacity(0.05),
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
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CtrlBtn({
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

// ── Piano keyboard — single Listener, manual hit-test ─────────────────────────

class _PianoKeyboard extends StatefulWidget {
  final PianoController ctrl;
  const _PianoKeyboard({required this.ctrl});

  @override
  State<_PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<_PianoKeyboard> {
  int? _lastDragIndex; // tracks which key the pointer is currently over

  void _onPointerDown(PointerDownEvent e) {
    final idx = _hitTest(e.localPosition.dx, e.localPosition.dy);
    if (idx == null) return;
    _lastDragIndex = idx;
    widget.ctrl.play(idx);
  }

  void _onPointerMove(PointerMoveEvent e) {
    final idx = _hitTest(e.localPosition.dx, e.localPosition.dy);
    if (idx == _lastDragIndex) return; // same key, do nothing
    // Left old key
    if (_lastDragIndex != null) widget.ctrl.stop(_lastDragIndex!);
    // Entered new key
    if (idx != null) widget.ctrl.play(idx);
    _lastDragIndex = idx;
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_lastDragIndex != null) {
      widget.ctrl.stop(_lastDragIndex!);
      _lastDragIndex = null;
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (_lastDragIndex != null) {
      widget.ctrl.stop(_lastDragIndex!);
      _lastDragIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = _whiteKeyCount() * _whiteW;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Listener(
        // Captures ALL pointer events even when dragging fast
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: SizedBox(
          width: totalWidth,
          height: _whiteH,
          child: Obx(() {
            final active = widget.ctrl.activeKeys.toSet();
            final showLabels = widget.ctrl.showKeyLabels.value;
            return Stack(children: _buildKeys(active, showLabels));
          }),
        ),
      ),
    );
  }

  List<Widget> _buildKeys(Set<int> active, bool showLabels) {
    final widgets = <Widget>[];

    // White keys first (bottom layer)
    int whiteCount = 0;
    for (int i = 0; i < _totalNotes; i++) {
      if (_isBlack[i % 12]) continue;
      widgets.add(
        Positioned(
          left: whiteCount * _whiteW,
          top: 0,
          child: _KeyWidget(
            index: i,
            isBlack: false,
            isActive: active.contains(i),
            showLabel: showLabels,
          ),
        ),
      );
      whiteCount++;
    }

    // Black keys on top
    for (int i = 0; i < _totalNotes; i++) {
      if (!_isBlack[i % 12]) continue;
      widgets.add(
        Positioned(
          left: _keyOffsets[i],
          top: 0,
          child: _KeyWidget(
            index: i,
            isBlack: true,
            isActive: active.contains(i),
            showLabel: showLabels,
          ),
        ),
      );
    }

    return widgets;
  }
}

// ── Pure display widget — no gesture handling ─────────────────────────────────

class _KeyWidget extends StatelessWidget {
  final int index;
  final bool isBlack;
  final bool isActive;
  final bool showLabel;

  const _KeyWidget({
    required this.index,
    required this.isBlack,
    required this.isActive,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (isBlack) {
      bg = isActive ? const Color(0xFF5A4FCF) : const Color(0xFF111122);
    } else {
      bg = isActive ? const Color(0xFFD4CBFF) : Colors.white;
    }

    final shortcutKey = _keyMap.entries
        .where((e) => e.value == index)
        .map((e) => e.key.keyLabel)
        .firstOrNull;

    return Container(
      width: isBlack ? _blackW : _whiteW,
      height: isBlack ? _blackH : _whiteH,
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
                  color: Colors.purpleAccent.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showLabel && shortcutKey != null && shortcutKey.length == 1)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isBlack
                    ? Colors.white.withOpacity(0.12)
                    : Colors.black.withOpacity(0.07),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                shortcutKey.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: isBlack ? Colors.white54 : Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _noteNames[index % 12],
              style: TextStyle(
                fontSize: 9,
                color: isBlack ? Colors.white24 : Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
