# ADR 0005 : Gestion d'état avec les primitives natives de Flutter

- **Statut :** Accepté (décision observée)
- **Date :** 2026-11-05

## Contexte

L'application doit synchroniser l'état d'authentification, les données joueur
issues de Firestore, les réglages globaux (thème clair/sombre, retour haptique,
état muet de l'audio) ainsi que des états visuels à haute fréquence comme
l'animation image par image des sprites et les compteurs de session.

## Décision

FocusTime n'utilise aucune bibliothèque tierce de gestion d'état (telle que
Provider, Riverpod ou Bloc) et s'appuie exclusivement sur les mécanismes natifs
de Flutter :

- `StreamBuilder` et `StreamSubscription` pour écouter les flux Firebase
  (`authStateChanges()` et snapshots Firestore du document utilisateur).
- `ValueNotifier` et `ValueListenableBuilder` pour les états globaux légers
  (`AppThemeController.mode`, `AppHaptics.isEnabled`,
  `AudioManager.isMutedNotifier`) et les mises à jour ciblées (`_frameIndex`
  dans `SpriteAnimator`).
- `StatefulWidget` et `setState` pour l'état local des écrans.

## Conséquences

- L'arbre de dépendances reste réduit et sans génération de code ni
  surcouche architecturale.
- Les reconstructions de widgets à haute fréquence (comme le changement de frame
  d'un sprite toutes les 100 ms) sont isolées dans des `ValueListenableBuilder`
  sans reconstruire l'écran parent.
- Le couplage entre les écrans et les singletons de services ou Firebase est
  plus direct, ce qui demande de gérer manuellement l'annulation des
  abonnements (`StreamSubscription`, `Timer`) dans `dispose()`.

## Éléments observés

`pubspec.yaml` ne contient aucun paquet de gestion d'état tiers. `lib/main.dart`,
`lib/theme/app_theme.dart`, `lib/utils/app_haptics.dart`,
`lib/services/audio_service.dart` et `lib/widgets/sprite_animator.dart`
utilisent `ValueNotifier` et `ValueListenableBuilder`.
