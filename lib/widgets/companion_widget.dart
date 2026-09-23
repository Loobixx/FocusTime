// lib/widgets/companion_widget.dart
import 'package:flutter/material.dart';
import '../models/companion.dart';

class CompanionWidget extends StatefulWidget {
  final String? companionId;
  final Color? tintColor;

  const CompanionWidget({
    super.key,
    required this.companionId,
    this.tintColor,
  });

  @override
  State<CompanionWidget> createState() => _CompanionWidgetState();
}

class _CompanionWidgetState extends State<CompanionWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    // Animation de trottinement en boucle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companion = CompanionData.getById(widget.companionId);
    if (companion == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: SizedBox(
            width: 70,
            height: 70,
            child: Image.asset(
              companion.assetPath,
              fit: BoxFit.contain,
              // Permet d'appliquer la couleur choisie par le joueur
              color: widget.tintColor ?? companion.defaultColor,
              colorBlendMode: BlendMode.modulate,
              errorBuilder: (_, __, ___) => const Icon(Icons.pets, color: Colors.white, size: 40),
            ),
          ),
        );
      },
    );
  }
}