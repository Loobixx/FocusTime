import 'package:flutter/material.dart';

class AnimatedCharacter extends StatefulWidget {
  final double size;
  final bool isWalking; // Permet de l'arrêter quand tu es en pause !

  const AnimatedCharacter({
    super.key, 
    this.size = 90.0,
    this.isWalking = true,
  });

  @override
  State<AnimatedCharacter> createState() => _AnimatedCharacterState();
}

class _AnimatedCharacterState extends State<AnimatedCharacter> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  
  // 📝 Mets ici les chemins exacts de tes images dans le bon ordre
// Génère automatiquement les 16 chemins d'images !
  final List<String> _frames = List.generate(
    16, 
    (index) => 'assets/PersonnageAnimation/Nuit/${index + 1}.png'
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // 👈 On augmente les millisecondes (1500ms = 1,5 seconde par cycle). 
      // Si c'est encore trop rapide, essaie 2000 !
      duration: const Duration(milliseconds: 1500), 
    );

    if (widget.isWalking) {
      _controller.repeat();
    }
  }
  
  @override
  void didUpdateWidget(covariant AnimatedCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si l'état de pause change, on arrête ou on relance l'animation
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
        // 🧮 Mathématiques simples : on calcule quelle image afficher selon l'avancement
        // _controller.value va de 0.0 à 1.0. On multiplie par le nombre d'images.
        int frameIndex = (_controller.value * _frames.length).floor();
        
        // Sécurité au cas où la valeur atteigne exactement 1.0
        if (frameIndex == _frames.length) frameIndex = _frames.length - 1;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Image.asset(
            _frames[frameIndex],
            fit: BoxFit.contain,
            // ✨ TRÈS IMPORTANT : Évite un clignotement blanc entre chaque image
            gaplessPlayback: true, 
          ),
        );
      },
    );
  }
}