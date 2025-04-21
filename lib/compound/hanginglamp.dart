import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';

class HangingLamp extends StatelessWidget {
  final double pullOffset; // How far the lamp is pulled down
  final bool isPulling; // Whether the lamp is being pulled
  final VoidCallback onPullComplete; // Callback when pull is complete

  const HangingLamp({
    super.key,
    required this.pullOffset,
    required this.isPulling,
    required this.onPullComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Use Flutter's Theme for simplicity
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Chain
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 50 + pullOffset, // Chain extends as lamp is pulled
            width: 4,
            color: Colors.grey[700],
          ),
          // Lamp
          GestureDetector(
            onVerticalDragUpdate: (details) {
              // Handled by parent widget
            },
            onVerticalDragEnd: (_) {
              // Handled by parent widget
            },
            child: FadeInDown(
              animate: isPulling,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber[300],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const FaIcon(
                  FontAwesomeIcons.lightbulb,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}