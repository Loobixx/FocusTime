import 'package:flutter/material.dart';

class PersistentAnimatedCharacter extends StatefulWidget {
  final double size;
  final List<String> frames;
  final Duration frameDuration;

  const PersistentAnimatedCharacter({
    super.key,
    required this.size,
    required this.frames,
    required this.frameDuration,
  });

  @override
  State<PersistentAnimatedCharacter> createState() => _PersistentAnimatedCharacterState();
}

class _PersistentAnimatedCharacterState extends State<PersistentAnimatedCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.frameDuration,
    )..repeat();
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
        final int frameIndex = (_controller.value * widget.frames.length).floor() % widget.frames.length;
        return Image.asset(
          widget.frames[frameIndex],
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          gaplessPlayback: true, // ✨ LA MAGIE EST ICI : Empêche le clignotement
        );
      },
    );
  }
}