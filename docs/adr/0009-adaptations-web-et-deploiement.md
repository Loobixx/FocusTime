# ADR 0009 : Adaptations aux contraintes du Web et déploiement continu

- **Statut :** Accepté (décision observée)
- **Date :** 2026-11-05

## Contexte

Bien que le code soit partagé entre plateformes (ADR 0001), la cible Web présente
des contraintes propres aux navigateurs : blocage de la lecture audio
automatique sans geste utilisateur, absence de support des notifications locales
planifiées par `flutter_local_notifications` et API de vibration distincte des
canaux natifs Flutter. Par ailleurs, la version Web doit pouvoir être publiée
automatiquement.

## Décision

Les fonctionnalités dépendantes des capacités système sont isolées derrière des
adaptateurs dédiés et le déploiement Web est automatisé :

- **Imports conditionnels pour l'haptique :** `lib/utils/app_haptics.dart`
  charge `haptics_web.dart` (utilisant `dart:js_interop` et `navigator.vibrate`)
  lorsque `dart.library.js_interop` est disponible, ou `haptics_stub.dart` et
  `HapticFeedback` sur les cibles natives.
- **Garde-fous Web pour l'audio et les notifications :** `AudioManager` ignore
  le lancement automatique au démarrage sur le Web (`kIsWeb`) et attend une
  interaction explicite via `ensurePlaying()` ou `setMuted(false)` avant
  d'appeler `play()`. `NotificationService` court-circuite l'affichage et la
  planification des notifications locales lorsque `kIsWeb` est vrai.
- **CI/CD Web :** le workflow GitHub Actions `.github/workflows/deploy.yml`
  compile la cible Web en mode release (`--base-href "/FocusTime/"`) à chaque
  push sur `main` et déploie l'artefact sur GitHub Pages. Un script `build.sh`
  fournit également la séquence de construction pour Netlify.

## Conséquences

- Le code métier et les écrans peuvent appeler `AppHaptics`, `AudioManager` et
  `NotificationService` sans multiplier les conditions de plateforme.
- Certaines fonctionnalités de rappel (bilan quotidien à 20 h, chronomètre de
  pause en notification système) ne sont actives que sur les plateformes
  natives.
- Le chemin de base `/FocusTime/` est fixé dans le workflow GitHub Pages et doit
  être adapté si le nom du dépôt ou le domaine d'hébergement change.

## Éléments observés

`lib/utils/app_haptics.dart`, `lib/utils/haptics_web.dart`,
`lib/utils/haptics_stub.dart`, `lib/services/audio_service.dart` et
`lib/services/notification_service.dart` gèrent les différences Web/natif.
`.github/workflows/deploy.yml` et `build.sh` définissent les pipelines de build
Web.
