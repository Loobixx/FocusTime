// lib/widgets/game_sprites.dart
import 'package:flutter/material.dart';
import '../models/companion.dart';
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
          frames.walk,
          // Vérifie bien que les dossiers "Marche" ont une majuscule sur ton PC
          (i) => 'assets/PersonnageAnimation/$folder/Marche/${i + 1}.png',
        ),
        'arret': List.generate(
          frames.idle,
          // Vérifie bien que les dossiers "Arret" ont une majuscule sur ton PC
          (i) => 'assets/PersonnageAnimation/$folder/Arret/${i + 1}.png',
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
    final companion = CompanionData.getById(companionId);
    if (companion == null) {
      return SizedBox(width: size.width, height: size.height);
    }
    final animations = {
      'marche': companion.animationFrames(moving: true, selected: isSelected),
      'arret': companion.animationFrames(moving: false, selected: isSelected),
    };

    return SpriteAnimator(
      key: ValueKey(
        'comp_${companionId}_${size.width}x${size.height}_'
        '${isSelected ? 'selected' : 'unselected'}_'
        '${isMoving ? 'moving' : 'idle'}',
      ),
      width: size.width,
      height: size.height,
      currentState: isMoving ? 'marche' : 'arret',
      animations: animations,
      frameDuration: SpriteConfig.companionSpeed,
    );
  }
}
