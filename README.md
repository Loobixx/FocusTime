# FocusTime

FocusTime transforme les sessions de concentration en voyages. Choisissez une
durée et un itinéraire sur la carte : le temps de focus fait progresser votre
personnage de ville en ville.

## Fonctionnalités

- Créer un compte ou se connecter avec Firebase Authentication (e-mail ou
  Google).
- Choisir une durée de concentration et planifier un itinéraire sur la carte.
- Découvrir des villes et suivre sa progression au fil des voyages.
- Débloquer et équiper des compagnons, et personnaliser son personnage.
- Consulter l'historique des voyages et les statistiques de progression.
- Profiter d'une ambiance sonore et configurer les notifications de voyage et
  de pause.

## Prérequis

- Flutter avec le SDK Dart **3.12.0 ou supérieur** (voir la contrainte dans
  `pubspec.yaml`).
- Un projet Firebase avec **Authentication** et **Cloud Firestore** configurés.
  Les options Firebase de l'application sont dans `lib/firebase_options.dart`.
  Si vous utilisez votre propre projet Firebase, remplacez-les par sa
  configuration et activez les méthodes de connexion souhaitées. La connexion
  Google peut aussi nécessiter une configuration OAuth propre à la plateforme.
- Les règles Firestore du dépôt limitent chaque compte à ses propres données.
  Déployez-les avec Firebase CLI en remplaçant l'identifiant par celui de votre
  projet :

  ```sh
  firebase deploy --only firestore:rules --project YOUR_FIREBASE_PROJECT_ID
  ```

## Lancer l'application

À la racine du projet, récupérez les dépendances puis démarrez l'application sur
un appareil ou un émulateur :

```sh
flutter pub get
flutter run
```

Pour lancer la version Web dans Chrome sur le port 5000 :

```sh
flutter run -d chrome --web-port=5000
```

## Tests

Lancer les tests Flutter :

```sh
flutter test
```

Les règles d'accès Firestore se testent contre les émulateurs Firebase :

```sh
firebase emulators:exec --only auth,firestore --project demo-focustime "node --test test/security/firestore_rules.test.cjs"
```

## Accès administrateur

L'adresse `yoprudhomme59@gmail.com` est reconnue comme administrateur dans
l'interface. Pour lui accorder aussi l'accès Firestore aux données des comptes,
crée dans Firebase Console une collection `admin_emails`, puis un document dont
l'ID est `yoprudhomme59@gmail.com` et dont le champ booléen `enabled` vaut
`true`. Le compte doit avoir une adresse e-mail vérifiée.

Ne donne pas à l'application cliente le droit d'écrire dans `admin_emails` :
seul un administrateur de confiance doit pouvoir ajouter ou retirer ces accès.
L'adresse de Lise personnalise son interface, mais ne lui accorde pas d'accès
aux données des autres comptes.

## Envoyer les changements

Pour utiliser `push.sh`, ouvrez **Git Bash** à la racine du projet et lancez le
script en lui passant un message de commit entre guillemets :

```sh
./push.sh "nom de commit"
```
