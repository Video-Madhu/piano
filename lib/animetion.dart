import 'package:flutter/material.dart';

/// Drop-in replacement for your static gradient Container.
/// Wrap your existing Column (or any child) with this widget.
class AnimatedGradientContainer extends StatefulWidget {
  final Widget child;

  const AnimatedGradientContainer({super.key, required this.child});

  @override
  State<AnimatedGradientContainer> createState() =>
      _AnimatedGradientContainerState();
}

class _AnimatedGradientContainerState extends State<AnimatedGradientContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // The three base colours from your original gradient
  static const _colorsA = [
    Color(0xFFde4343), // red
    Color(0xFF7c1472), // purple
    Color(0xFF094b47), // teal
  ];

  // A second palette the gradient breathes toward
  static const _colorsB = [
    Color(0xFF9b1a1a), // darker red
    Color(0xFFb03090), // shifted purple-pink
    Color(0xFF0d7a6e), // brighter teal
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ).value;

        // Interpolate each colour pair
        final colors = List.generate(
          _colorsA.length,
          (i) => Color.lerp(_colorsA[i], _colorsB[i], t)!,
        );

        // Focal point drifts gently from top-left toward center
        final center = AlignmentGeometry.lerp(
          Alignment.topLeft,
          const Alignment(-0.2, -0.2),
          t,
        )!;

        // Radius breathes between tight and expansive
        final radius = 0.6 + (1.1 - 0.6) * t;

        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: center,
              radius: radius,
              focalRadius: 0.0,
              colors: colors,
            ),
          ),
          child: child,
        );
      },
      child: widget.child, // child is built once, not on every animation tick
    );
  }
}
