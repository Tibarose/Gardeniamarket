import 'package:flutter/material.dart';
import 'dart:math';

class ShimmeringWave extends StatefulWidget {
  const ShimmeringWave({super.key});

  @override
  _ShimmeringWaveState createState() => _ShimmeringWaveState();
}

class _ShimmeringWaveState extends State<ShimmeringWave> with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Long duration for smooth looping
    )..repeat();

    // Initialize 10 particles with random properties
    for (int i = 0; i < 10; i++) {
      _particles.add(_Particle(
        startX: Random().nextDouble(),
        startY: Random().nextDouble() * 0.5, // Upper half of SliverAppBar
        speed: Random().nextDouble() * 0.5 + 0.2, // Speed between 0.2 and 0.7
        size: Random().nextDouble() * 8 + 4, // Size between 4 and 12
        phase: Random().nextDouble() * 2 * pi, // Random phase for wave
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expandedHeight = MediaQuery.of(context).size.width < 600 ? 220.0 : 260.0;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: _particles.map((particle) {
            // Calculate particle position and opacity
            final progress = (_controller.value + particle.phase) % 1.0;
            final x = (particle.startX + progress * particle.speed) % 1.0;
            final y = particle.startY + sin((progress + particle.phase) * 2 * pi) * 0.1; // Wave motion
            final opacity = 0.3 + sin((progress + particle.phase) * 2 * pi) * 0.2; // Shimmer effect
            final scale = 0.8 + sin((progress + particle.phase) * 2 * pi) * 0.2; // Pulse effect

            return Positioned(
              left: x * MediaQuery.of(context).size.width,
              top: y * expandedHeight,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: particle.size,
                  height: particle.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(opacity),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Particle {
  final double startX;
  final double startY;
  final double speed;
  final double size;
  final double phase;

  _Particle({
    required this.startX,
    required this.startY,
    required this.speed,
    required this.size,
    required this.phase,
  });
}