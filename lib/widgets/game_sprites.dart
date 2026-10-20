// lib/widgets/game_sprites.dart
import 'package:flutter/material.dart';
import '../config/sprite_config.dart';
import 'sprite_animator.dart';

class CharacterSprite extends StatelessWidget {
  final String characterId; // ex: 'nuit'
  final SpriteScene scene;
  final bool isMoving; 

  const CharacterSprite({
    super.key,
    required this.characterId,
    required this.scene,
    this.isMoving = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = SpriteConfig.character(scene);
    final folder = SpriteConfig.folder(characterId);
    final frames = SpriteConfig.framesFor(characterId);

    return SpriteAnimator(
      key: ValueKey('char_${characterId}_${size.width}x${size.height}'),
      width: size.width,
      height: size.height,
      currentState: isMoving ? 'marche' : 'arret',
      animations: {
        'marche': List.generate(
          frames.walk, // Utilise la vraie valeur (16) configurée
          (i) => 'PersonnageAnimation/$folder/Marche/${i + 1}.png',
        ),
        'arret': List.generate(
          frames.idle, // Utilise la vraie valeur (21) configurée
          (i) => 'PersonnageAnimation/$folder/Arret/${i + 1}.png',
        ),
      },
      frameDuration: isMoving
          ? SpriteConfig.characterWalkSpeed
          : SpriteConfig.characterIdleSpeed,
    );
  }
}

class CompanionSprite extends StatelessWidget {
  final String companionId;
  final SpriteScene scene;
  final bool isMoving;
  final bool isSelected;

  const CompanionSprite({
    super.key,
    required this.companionId,
    required this.scene,
    this.isMoving = false,
    this.isSelected = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = SpriteConfig.companion(scene);
    final id = companionId.toLowerCase();
    final isDog = id == 'chien';
    final folder = isDog ? 'Chien' : 'Chat';

    final List<String> walkFrames = isDog
        ? List.generate(
            6,
            (i) => 'compagnons/$folder/chien_marche/$i.png',
          )
        : List.generate(
            3,
            (i) =>
                'compagnons/$folder/marche/frame${i.toString().padLeft(2, '0')}.png',
          );
    final List<String> idleFrames = isDog
        ? List.generate(
            isSelected ? 8 : 18,
            (i) =>
                'compagnons/$folder/${isSelected ? 'chien_arret' : 'chien_arret_non_choisi'}/$i.png',
          )
        : ['compagnons/$folder/marche.png'];

    return SpriteAnimator(
      // Recrée l'animateur quand le statut sélectionné change : les chemins
      // d'images au repos du chien changent eux aussi.
      key: ValueKey(
        'comp_${companionId}_${size.width}x${size.height}_'
        '${isSelected ? 'selected' : 'unselected'}_'
        '${isMoving ? 'moving' : 'idle'}',
      ),
      width: size.width,
      height: size.height,
      currentState: isMoving ? 'marche' : 'arret',
      animations: {
        'marche': walkFrames,
        'arret': idleFrames,
      },
      frameDuration: SpriteConfig.companionSpeed,
    );
  }
}
