# ADR 0006 : Rendu procédural du brouillard de guerre et animation de sprites par séquences PNG

- **Statut :** Accepté (décision observée)
- **Date :** 2026-11-05

## Contexte

L'expérience visuelle repose sur une carte du monde et des cartes régionales
masquées par un brouillard de guerre animé, ainsi que sur des personnages et
compagnons animés dans plusieurs scènes (expédition, région, monde, campement).
Le décodage simultané de nombreuses ressources haute résolution peut saturer la
mémoire ou dégrader la fluidité.

## Décision

Le rendu graphique combine deux approches :

- **Brouillard et nuages procéduraux :** `CloudSprites` pré-génère en mémoire
  des variantes de nuages (`ui.Image`) via `PictureRecorder` et des filtres de
  flou (`MaskFilter.blur`). `FogOfWarPainter` et `WorldCloudsPainter` animent
  ces sprites sur un `Canvas` et révèlent les zones visitées, frontalières ou
  côtières par soustraction alpha (`saveLayer` et `BlendMode.dstOut` avec
  `RadialGradient` ou `Path`).
- **Sprites par séquences PNG préchargées :** les animations de personnages et
  de compagnons sont stockées sous forme de frames PNG numérotées (`1.png`,
  `2.png`, etc., converties depuis des GIF via `scripts/convert_sprite_frames.py`).
  `SpriteAnimator` enveloppe chaque frame dans un `ResizeImage` adapté à la
  taille d'affichage, précharge les images avec `precacheImage` et active
  `gaplessPlayback`. Le cache d'images global de Flutter est relevé à 300 Mo et
  500 images au démarrage.

## Conséquences

- Les animations restent fluides sans dépendre du décodage continu de fichiers
  GIF lourds à l'exécution.
- Le brouillard de guerre s'adapte dynamiquement aux coordonnées des villes et
  des régions sans nécessiter de masques matriciels par combinaison de villes.
- La consommation mémoire du cache d'images est plus élevée (jusqu'à 300 Mo) et
  le nombre de frames par personnage doit être maintenu dans `SpriteConfig`.

## Éléments observés

`lib/screens/map/fog_of_war.dart` implémente `CloudSprites`, `FogOfWarPainter`
et `WorldCloudsPainter`. `lib/widgets/sprite_animator.dart`,
`lib/widgets/game_sprites.dart` et `lib/config/sprite_config.dart` gèrent les
séquences PNG. `lib/main.dart` configure `PaintingBinding.instance.imageCache`.
