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
    final id = companionId.toLowerCase();
    // Chaque compagnon déclare ses chemins ici, à partir de la même structure
    // d'états (marche / arrêt) utilisée par le chien.
    final animations = switch (id) {
      'chien' => <String, List<String>>{
          'marche': List.generate(
            6,
            (i) => 'assets/compagnons/Chien/chien_marche/$i.png',
          ),
          'arret': List.generate(
            isSelected ? 8 : 18,
            (i) =>
                'assets/compagnons/Chien/${isSelected ? 'chien_arret' : 'chien_arret_non_choisi'}/$i.png',
          ),
        },
      'chat' => <String, List<String>>{
          'marche': List.generate(
            3,
            (i) =>
                'assets/compagnons/Chat/marche/frame${i.toString().padLeft(2, '0')}.png',
          ),
          // Le dossier du chat ne contient pas de frames d'arrêt séparées.
          // Sa première frame individuelle sert donc d'image fixe au repos.
          'arret': const [
            'assets/compagnons/Chat/chat_marche/0.png',
          ],
        },
      _ => const <String, List<String>>{},
    };

    if (animations.isEmpty) {
      return SizedBox(width: size.width, height: size.height);
    }

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
