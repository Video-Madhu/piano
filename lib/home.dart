import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:piano/animetion.dart';

class MyPiano extends StatefulWidget {
  const MyPiano({super.key});

  @override
  State<MyPiano> createState() => _MyPianoState();
}

class _MyPianoState extends State<MyPiano> {
  final soloud = SoLoud.instance;

  Map<int, SoundHandle> activeHandles = {};

  List<AudioSource>? notes;

  @override
  void initState() {
    SoLoudTools.createNotes(
      octave: 2,
      waveForm: WaveForm.fSaw,
      superwave: true,
    ).then((value) => notes = value);

    super.initState();
  }

  @override
  void dispose() {
    soloud.deinit();
    super.dispose();
  }

  late List<Widget> keyss = List.generate(
    12,
    (index) => InkWell(
      onTapDown: (details) {
        play(index);
      },
      onTapUp: (details) {
        stop(index);
      },
      onTapCancel: () => stop(index),
      child: Container(
        height: 170,
        width: 40,

        decoration: BoxDecoration(
          color: Colors.white60,
          border: Border.all(color: Colors.black45, width: 0.50),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Text(
            (index + 1).toString(),
            style: TextStyle(color: Colors.black38),
          ),
        ),
      ),
    ),
  );

  void play(int index) {
    if (notes == null) return;

    // Stop the previous handle if it's still playing (optional, prevents overlapping)
    stop(index);

    // Play returns a SoundHandle
    final handle = SoLoud.instance.play(notes![index]);
    activeHandles[index] = handle;
  }

  void stop(int index) {
    final handle = activeHandles[index];
    if (handle != null) {
      // Fade to 0 volume over 200 milliseconds, then stop
      SoLoud.instance.fadeVolume(handle, 0, const Duration(milliseconds: 600));
      SoLoud.instance.scheduleStop(handle, const Duration(milliseconds: 600));
      activeHandles.remove(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!soloud.isInitialized) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF10002C),
      body: Center(
        child: AnimatedGradientContainer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: keyss),
            ],
          ),
        ),
      ),
    );
  }
}
