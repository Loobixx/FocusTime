# ADR 0002 : Firebase Authentication et Cloud Firestore

- **Statut :** Accepté (décision observée)
- **Date :** 2026-11-05

## Contexte

Les comptes doivent pouvoir se connecter sur plusieurs plateformes et
retrouver leur profil, leur position, leurs voyages et leur progression. Le
projet a besoin d'un service distant accessible depuis Flutter.

## Décision

FocusTime utilise Firebase Authentication pour l'identité et Cloud Firestore
pour les données persistantes. L'application initialise Firebase avec les
options propres à la plateforme. Le flux d'authentification détermine l'écran
d'accueil ou de connexion ; sur le Web, la persistance Firebase Auth est
configurée en mode local.

## Conséquences

- L'application dépend de la disponibilité et de la configuration d'un projet
  Firebase.
- Les données sont accessibles depuis plusieurs appareils après connexion.
- Les règles Firestore font partie intégrante de la sécurité et doivent être
  déployées avec la configuration du projet Firebase.
- Les comportements hors ligne, conflits d'écriture et migrations de schéma
  doivent être pris en compte au fil de l'évolution des données.

## Éléments observés

Les dépendances `firebase_core`, `firebase_auth` et `cloud_firestore` figurent
dans `pubspec.yaml`. `lib/main.dart` initialise Firebase et écoute
`authStateChanges()`.
