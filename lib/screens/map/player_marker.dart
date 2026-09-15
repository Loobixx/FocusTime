import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PlayerMarker extends StatefulWidget {
  const PlayerMarker({super.key});

  @override
  State<PlayerMarker> createState() => _PlayerMarkerState();
}

class _PlayerMarkerState extends State<PlayerMarker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const focusOrange = Color(0xFFFF8C00);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double pulse = 0.6 + (_controller.value * 0.4); // entre 0.6 et 1.0
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: focusOrange.withValues(alpha: pulse * 0.6),
                blurRadius: 18 * pulse,
                spreadRadius: 4 * pulse,
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on,
            size: 32,
            color: focusOrange,
            shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))],
          ),
        );
      },
    );
  }
}