# ADR 0007 : Répartition hybride des préférences entre SharedPreferences et Firestore

- **Statut :** Accepté (décision observée)
- **Date :** 2026-11-05

## Contexte

L'application manipule à la fois des réglages d'interface et de confort propres
à l'appareil (utilisés dès le lancement, parfois avant même la connexion) et des
préférences ou équipements liés au profil du joueur qui doivent le suivre d'un
appareil à l'autre.

## Décision

La persistance des préférences est répartie sur deux niveaux :

- **`SharedPreferences` (stockage local à l'appareil) :** conserve le mode de
  thème (`app_theme_mode`), l'activation des retours haptiques
  (`app_haptics_enabled`) et l'état muet de la musique (`is_audio_muted`). Ces
  valeurs sont chargées au démarrage de l'application avant ou indépendamment de
  l'authentification.
- **Cloud Firestore (stockage lié au compte sous `users/{uid}`) :** conserve les
  préférences de notifications métier (`notifArrival`, `notifPauseReminder`,
  `notifSound`), le personnage sélectionné, les compagnons actifs et les
  cosmétiques de campement équipés.

## Conséquences

- Le thème, le son et l'haptique s'appliquent immédiatement au lancement sans
  attendre de requête réseau et respectent le contexte de chaque appareil
  (par exemple muet sur navigateur Web et sonore sur mobile).
- Les préférences liées à la progression et aux notifications suivent le compte
  utilisateur.
- Les réglages stockés dans `SharedPreferences` ne sont pas synchronisés entre
  appareils et sont réinitialisés si les données locales de l'application ou du
  navigateur sont effacées.

## Éléments observés

`lib/theme/app_theme.dart`, `lib/utils/app_haptics.dart` et
`lib/services/audio_service.dart` lisent et écrivent dans `SharedPreferences`.
`lib/services/notification_service.dart` et `lib/screens/home/home_screen.dart`
lisent les préférences et cosmétiques depuis `users/{uid}` dans Firestore.
