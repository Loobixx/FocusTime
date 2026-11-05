# ADR 0003 : Graphe de voyage embarqué dans l'application

- **Statut :** Accepté (décision observée)
- **Date :** 2026-11-05

## Contexte

Le jeu représente les villes et leurs liaisons comme un réseau pondéré. Le
calcul des itinéraires et du temps de trajet doit être disponible dans
l'expérience de sélection et de progression.

## Décision

La topologie du réseau et les durées de liaison sont définies dans le code
Dart, dans `CityNetwork`. Les écrans et services de voyage consomment ce modèle
local ; les états de progression propres à l'utilisateur sont enregistrés dans
Firestore. Les trajets utilisent les poids du graphe et appliquent un coût
réduit aux villes déjà visitées.

## Conséquences

- Le calcul du réseau ne nécessite pas de requête distante et reste disponible
  avec les données embarquées.
- Une modification de la carte nécessite une mise à jour de l'application.
- Les règles de graphe et les données de progression doivent rester cohérentes
  entre les versions du client.
- Les poids doivent être non négatifs si l'algorithme de plus courts chemins
  utilisé est Dijkstra.

## Éléments observés

`lib/models/city_network.dart` contient les nœuds et liaisons. `TravelService`
lit ces liaisons pour calculer l'avancée et persiste l'état et l'historique du
voyage dans Firestore.
