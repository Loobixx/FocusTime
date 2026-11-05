# ADR 0001 : Flutter pour l'application multiplateforme

- **Statut :** Accepté (décision observée)
- **Date :** 2026-11-05

## Contexte

FocusTime propose une expérience interactive de concentration et de voyage,
avec une interface animée et des ressources graphiques. Le dépôt contient les
cibles Android, iOS, Web, Linux, macOS et Windows, ainsi que des adaptations
spécifiques aux plateformes.

## Décision

L'application est développée en Flutter et Dart, avec une interface partagée
entre les plateformes prises en charge. Les fonctionnalités spécifiques à une
plateforme sont intégrées au moyen des API Flutter et de dépendances adaptées.

## Conséquences

- L'interface et une grande partie du comportement peuvent être maintenus dans
  une base de code commune.
- Les API natives et les dépendances doivent être vérifiées pour chaque cible.
- Les animations et grandes ressources d'images demandent une attention
  particulière aux performances et à la mémoire des appareils.

## Éléments observés

`pubspec.yaml` déclare Flutter comme SDK ; les dossiers de plateformes sont
présents à la racine et `lib/main.dart` constitue le point d'entrée commun.
