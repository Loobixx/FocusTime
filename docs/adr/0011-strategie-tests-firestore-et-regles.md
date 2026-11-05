# ADR 0011 : Stratégie de test à double niveau (simulacre Firestore en Dart et émulateur Firebase en Node.js)

- **Statut :** Accepté (décision observée)
- **Date :** 2026-11-05

## Contexte

La logique critique liée aux comptes (droits d'administration et suppression
complète des données utilisateur par lots) dépend de Cloud Firestore, tandis que
le contrôle d'accès réel repose sur l'évaluation serveur de `firestore.rules` et
sur les jetons Firebase Authentication (adresse vérifiée).

## Décision

La vérification automatisée est scindée en deux niveaux complémentaires :

- **Tests unitaires et widgets Dart avec injection de dépendances :** les
  services liés à Firestore (`AdminAccessService`, `UserDataDeletionService`,
  `TravelService`) acceptent une instance `FirebaseFirestore` injectable au
  constructeur (ainsi qu'un résolveur d'identifiant utilisateur pour
  `TravelService`). La suite `flutter test` couvre hors ligne :
  - les modèles et le graphe (`test/models/city_network_test.dart`,
    `test/models/companion_and_biome_test.dart`) ;
  - les services métier (`test/services/travel_service_test.dart`,
    `test/admin_access_service_test.dart`,
    `test/user_data_deletion_service_test.dart`, `test/user_roles_test.dart`) ;
  - les utilitaires, configurations de carte et préférences locales
    (`test/utils/utils_and_config_test.dart`) ;
  - les widgets graphiques, peintres personnalisés et écrans/modales
    (`test/widgets/widgets_and_screens_test.dart`).
- **Tests d'intégration des règles avec les émulateurs Firebase :** le fichier
  `test/security/firestore_rules.test.cjs` utilise le runner natif Node.js
  (`node:test`) pour interroger les émulateurs Auth (`127.0.0.1:9099`) et
  Firestore (`127.0.0.1:8080`), vérifier le flux complet d'e-mail vérifié
  (`VERIFY_EMAIL`), la validation de schéma, la liste blanche des
  sous-collections et la protection contre l'auto-modification administrateur.

## Conséquences

- Les tests unitaires et widgets Dart s'exécutent via `flutter test` sans
  nécessiter d'émulateur démarré ni de connexion réseau.
- Les règles de sécurité Firestore, qui ne sont pas interprétées par
  `fake_cloud_firestore`, disposent d'une couverture dédiée fidèle au moteur
  d'évaluation réel de Firebase.
- La cohérence entre le graphe des villes (`CityNetwork`), les coordonnées de
  carte (`RegionCrossesData`), les biomes (`CampBiomes`) et les compagnons
  (`CompanionData`) est vérifiée automatiquement à chaque exécution des tests.

## Éléments observés

`pubspec.yaml` déclare `fake_cloud_firestore` dans `dev_dependencies`. Les
dossiers `test/models/`, `test/services/`, `test/utils/`, `test/widgets/` et les
fichiers à la racine de `test/` couvrent l'application Flutter ;
`test/security/firestore_rules.test.cjs` teste `firestore.rules` contre les
émulateurs locaux.
