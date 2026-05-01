import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Octave 3 — white keys
  LogicalKeyboardKey.keyQ: 0,
  LogicalKeyboardKey.keyW: 2,
  LogicalKeyboardKey.keyE: 4,
  LogicalKeyboardKey.keyR: 5,
  LogicalKeyboardKey.keyT: 7,
  LogicalKeyboardKey.keyY: 9,
  LogicalKeyboardKey.keyU: 11,
  // Octave 3 — black keys
  LogicalKeyboardKey.digit2: 1,
  LogicalKeyboardKey.digit3: 3,
  LogicalKeyboardKey.digit5: 6,
  LogicalKeyboardKey.digit6: 8,
  LogicalKeyboardKey.digit7: 10,
  // Octave 4 — white keys
  LogicalKeyboardKey.keyI: 12,
  LogicalKeyboardKey.keyO: 14,
  LogicalKeyboardKey.keyP: 16,
  LogicalKeyboardKey.keyZ: 17,
  LogicalKeyboardKey.keyX: 19,
  LogicalKeyboardKey.keyC: 21,
  LogicalKeyboardKey.keyV: 23,
  // Octave 4 — black keys
  LogicalKeyboardKey.digit9: 13,
  LogicalKeyboardKey.digit0: 15,
  LogicalKeyboardKey.keyS: 18,
  LogicalKeyboardKey.keyD: 20,
  LogicalKeyboardKey.keyF: 22,
  // Octave 5 — white keys
  LogicalKeyboardKey.keyB: 24,
  LogicalKeyboardKey.keyN: 26,
  LogicalKeyboardKey.keyM: 28,
  LogicalKeyboardKey.comma: 29,
  LogicalKeyboardKey.period: 31,
  LogicalKeyboardKey.slash: 33,
  // Octave 5 — black keys
  LogicalKeyboardKey.keyH: 25,
  LogicalKeyboardKey.keyJ: 27,
  LogicalKeyboardKey.keyL: 30,
  LogicalKeyboardKey.semicolon: 32,
  LogicalKeyboardKey.quote: 34,
};

// ── Key layout constants ──────────────────────────────────────────────────────

const double _whiteW = 44;
const double _whiteH = 200;
const double _blackW = 28;
const double _blackH = 124;
const int _totalNotes = 36;

/// Precomputed left-edge X position for every note index.
final List<double> _keyOffsets = () {
  final offsets = List<double>.filled(_totalNotes, 0);
  int whiteCount = 0;
  for (int i = 0; i < _totalNotes; i++) {
    if (_isBlack[i % 12]) {
      offsets[i] = (whiteCount * _whiteW) - (_blackW / 2);
    } else {
      offsets[i] = whiteCount * _whiteW;
      whiteCount++;
    }
  }
  return offsets;
}();

/// Total keyboard width based on white key count.
final double _totalKeyboardWidth = () {
  int whites = 0;
  for (int i = 0; i < _totalNotes; i++) {
    if (!_isBlack[i % 12]) whites++;
  }
  return whites * _whiteW;
}();

/// Hit-test: returns note index at (x, y). Black keys take priority.
int? _hitTest(double x, double y) {
  // Black keys first (visually on top)
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

// ── Root widget ───────────────────────────────────────────────────────────────

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
          if (event is KeyDownEvent) ctrl.play(idx, velocity: 0.75);
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

            // Volume slider
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

            // Sustain toggle
            _CtrlBtn(
              icon: Icons.music_note,
              label: 'SUSTAIN',
              active: ctrl.sustain.value,
              onTap: () => ctrl.sustain.toggle(),
            ),
            const SizedBox(width: 16),

            // Key labels toggle
            _CtrlBtn(
              icon: Icons.keyboard,
              label: 'KEYS',
              active: ctrl.showKeyLabels.value,
              onTap: () => ctrl.showKeyLabels.toggle(),
            ),

            const Spacer(),

            // Octave label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                'OCT 3–5',
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
  int? _lastDragIndex;

  // Velocity tracking per pointer
  final Map<int, Offset> _lastPointerPos = {};
  final Map<int, DateTime> _lastPointerTime = {};

  void _onPointerDown(PointerDownEvent e) {
    final idx = _hitTest(e.localPosition.dx, e.localPosition.dy);
    if (idx == null) return;

    _lastPointerPos[e.pointer] = e.localPosition;
    _lastPointerTime[e.pointer] = DateTime.now();

    // Use hardware pressure if available, else default to 0.7
    final velocity = e.pressureMax > 0
        ? (e.pressure / e.pressureMax).clamp(0.1, 1.0)
        : 0.7;

    _lastDragIndex = idx;
    widget.ctrl.play(idx, velocity: velocity);
  }

  void _onPointerMove(PointerMoveEvent e) {
    final idx = _hitTest(e.localPosition.dx, e.localPosition.dy);

    // Compute velocity from pointer speed (pixels/ms)
    double velocity = 0.7;
    final lastPos = _lastPointerPos[e.pointer];
    final lastTime = _lastPointerTime[e.pointer];
    if (lastPos != null && lastTime != null) {
      final dt = DateTime.now().difference(lastTime).inMicroseconds / 1000.0;
      if (dt > 0) {
        final dist = (e.localPosition - lastPos).distance;
        velocity = (dist / dt / 15.0).clamp(0.1, 1.0);
      }
    }
    _lastPointerPos[e.pointer] = e.localPosition;
    _lastPointerTime[e.pointer] = DateTime.now();

    if (idx == _lastDragIndex) return;
    if (_lastDragIndex != null) widget.ctrl.stop(_lastDragIndex!);
    if (idx != null) widget.ctrl.play(idx, velocity: velocity);
    _lastDragIndex = idx;
  }

  void _onPointerUp(PointerUpEvent e) {
    _lastPointerPos.remove(e.pointer);
    _lastPointerTime.remove(e.pointer);
    if (_lastDragIndex != null) {
      widget.ctrl.stop(_lastDragIndex!);
      _lastDragIndex = null;
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _lastPointerPos.remove(e.pointer);
    _lastPointerTime.remove(e.pointer);
    if (_lastDragIndex != null) {
      widget.ctrl.stop(_lastDragIndex!);
      _lastDragIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: SizedBox(
          width: _totalKeyboardWidth,
          height: _whiteH,
          child: Obx(() {
            final active = widget.ctrl.activeKeys.toSet();
            final showLabels = widget.ctrl.showKeyLabels.value;
            return Stack(children: _buildAllKeys(active, showLabels));
          }),
        ),
      ),
    );
  }

  List<Widget> _buildAllKeys(Set<int> active, bool showLabels) {
    final widgets = <Widget>[];

    // White keys — bottom layer
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

    // Black keys — top layer
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

// ── Pure display key widget — no gesture handling ─────────────────────────────

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
    final Color bg;
    if (isBlack) {
      bg = isActive ? const Color(0xFF5A4FCF) : const Color(0xFF111122);
    } else {
      bg = isActive ? const Color(0xFFD4CBFF) : Colors.white;
    }

    // Find keyboard shortcut label for this note index
    final shortcutLabel = _keyMap.entries
        .where((e) => e.value == index)
        .map((e) => e.key.keyLabel)
        .where((label) => label.length == 1)
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
          // Keyboard shortcut badge
          if (showLabel && shortcutLabel != null)
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
                shortcutLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: isBlack ? Colors.white54 : Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // Note name
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
