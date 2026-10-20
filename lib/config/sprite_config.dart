// lib/config/sprite_config.dart
//
// ⚙️ UN SEUL ENDROIT pour régler la taille (largeur ET hauteur), la position
// et le nombre d'images de ton personnage et de tes compagnons.

import 'dart:ui' show Size;

enum SpriteScene {
  expedition, // écran du chrono (ActiveTimerScreen / ParallaxBackground)
  region, // carte d'une région (RegionDetailScreen)
  world, // carte globale (MapScreen)
}

/// Nombre d'images d'un personnage (doit correspondre à ses dossiers d'assets).
class CharacterFrames {
  final int walk; // dossier Marche
  final int idle; // dossier Arret
  const CharacterFrames({required this.walk, required this.idle});
}

class SpriteConfig {
  SpriteConfig._();

  // ---------------------------------------------------------------------------
  // 1) MULTIPLICATEURS GLOBAUX (1.0 = taille normale, 1.2 = 20 % plus grand)
  //    Ils s'appliquent à la largeur ET à la hauteur.
  // ---------------------------------------------------------------------------
  static const double characterScale = 1.0;
  static const double companionScale = 1.0;

  // ---------------------------------------------------------------------------
  // 2) TAILLE PAR ÉCRAN : Size(LARGEUR, HAUTEUR) en pixels
  // ---------------------------------------------------------------------------
  static const Map<SpriteScene, Size> _characterSize = {
    SpriteScene.expedition: Size(420, 420), // largeur, hauteur
    SpriteScene.region: Size(200, 200),
    SpriteScene.world: Size(200, 200),
  };

  static const Map<SpriteScene, Size> _companionSize = {
    SpriteScene.expedition: Size(70, 70),
    SpriteScene.region: Size(60, 60),
    SpriteScene.world: Size(60, 60),
  };

  static Size character(SpriteScene scene) {
    final s = _characterSize[scene]!;
    return Size(s.width * characterScale, s.height * characterScale);
  }

  static Size companion(SpriteScene scene) {
    final s = _companionSize[scene]!;
    return Size(s.width * companionScale, s.height * companionScale);
  }

  // ---------------------------------------------------------------------------
  // 3) POSITION (écran d'expédition)
  // ---------------------------------------------------------------------------
  /// Distance entre le bas de l'écran et le personnage.
  static const double expeditionBottom = 80;

  /// Décalage horizontal par rapport au centre de l'écran (négatif = vers la gauche).
  static const double expeditionOffsetX = -70;

  // ---------------------------------------------------------------------------
  // 4) POSITION SUR LES CARTES
  //    Le personnage est centré horizontalement sur le point (ville/région),
  //    et ses pieds sont placés à "footRatio" de sa HAUTEUR.
  //    0.8 = les pieds sont aux 80 % de la hauteur de l'image.
  // ---------------------------------------------------------------------------
  static const double footRatio = 0.8;

  // ---------------------------------------------------------------------------
  // 5) NOMBRE D'IMAGES PAR PERSONNAGE (clé = characterId en minuscules)
  //    ⚠️ Mets le vrai nombre d'images de chaque dossier Marche / Arret.
  // ---------------------------------------------------------------------------
  static const CharacterFrames _defaultFrames =
      CharacterFrames(walk: 16, idle: 21);

  static const Map<String, CharacterFrames> _characterFrames = {
    'nuit': CharacterFrames(walk: 16, idle: 21),
    'montagnes': CharacterFrames(walk: 16, idle: 21),
  };

  static CharacterFrames framesFor(String id) =>
      _characterFrames[id.toLowerCase()] ?? _defaultFrames;

  static const int companionWalkFrames = 4;

  // ---------------------------------------------------------------------------
  // 6) VITESSE DES ANIMATIONS
  // ---------------------------------------------------------------------------
  static const Duration characterWalkSpeed = Duration(milliseconds: 100);
  static const Duration characterIdleSpeed = Duration(milliseconds: 200);
  static const Duration companionSpeed = Duration(milliseconds: 175);

  // ---------------------------------------------------------------------------
  // OUTILS
  // ---------------------------------------------------------------------------
  /// 'nuit' -> 'Nuit' (nom du dossier d'assets du personnage).
  static String folder(String id) =>
      id.isEmpty ? 'Nuit' : id[0].toUpperCase() + id.substring(1);
}
