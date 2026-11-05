# Architecture Decision Records

Ce dossier documente les décisions d'architecture de FocusTime. Les ADR
décrivent les décisions observées dans le code au 5 novembre 2026 ; ils ne
prétendent pas reconstituer les discussions qui ont conduit à ces choix.

## Index

| ADR | Sujet | Statut |
| --- | --- | --- |
| [0001](0001-flutter-multiplateforme.md) | Flutter et cibles multiplateformes | Accepté |
| [0002](0002-firebase-auth-et-firestore.md) | Authentification et persistance Firebase | Accepté |
| [0003](0003-graphe-de-voyage-cote-client.md) | Graphe des villes et calcul des trajets | Accepté |
| [0004](0004-donnees-utilisateur-et-regles-firestore.md) | Isolation et suppression des données utilisateur | Accepté |
| [0005](0005-gestion-etat-primitives-flutter.md) | Gestion d'état avec les primitives natives de Flutter | Accepté |
| [0006](0006-rendu-brouillard-et-sprites.md) | Rendu procédural du brouillard de guerre et animation de sprites par séquences PNG | Accepté |
| [0007](0007-stockage-hybride-preferences.md) | Répartition hybride des préférences entre SharedPreferences et Firestore | Accepté |
| [0008](0008-session-focus-anti-triche-et-transit.md) | Cycle de vie des sessions de focus, anti-triche et trajets partiels | Accepté |
| [0009](0009-adaptations-web-et-deploiement.md) | Adaptations aux contraintes du Web et déploiement continu | Accepté |
| [0010](0010-catalogues-embarques-et-economie.md) | Catalogues statiques embarqués et transactions Firestore pour l'économie | Accepté |
| [0011](0011-strategie-tests-firestore-et-regles.md) | Stratégie de test à double niveau (simulacre Dart et émulateur Firebase) | Accepté |

Pour ajouter une décision, créer le prochain fichier numéroté et le référencer
dans cet index. Une décision remplacée doit rester dans l'historique avec le
statut « Remplacé » et un lien vers son successeur.
