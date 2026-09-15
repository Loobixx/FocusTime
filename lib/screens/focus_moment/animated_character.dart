import 'package:flutter/material.dart';

class AnimatedCharacter extends StatefulWidget {
  final double size;
  final bool isWalking;
  final List<String> frames;       // ✨ les frames à utiliser
  final Duration frameDuration;    // ✨ durée d'un cycle complet

  const AnimatedCharacter({
    super.key,
    this.size = 90.0,
    this.isWalking = true,
    required this.frames,
    this.frameDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<AnimatedCharacter> createState() => _AnimatedCharacterState();
}

class _AnimatedCharacterState extends State<AnimatedCharacter> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.frameDuration,
    );

    if (widget.isWalking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWalking) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
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
        int frameIndex = (_controller.value * widget.frames.length).floor();
        if (frameIndex == widget.frames.length) frameIndex = widget.frames.length - 1;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Image.asset(
            widget.frames[frameIndex],
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        );
      },
    );
  }
}