# ADR 0008 : Cycle de vie des sessions de focus, anti-triche et trajets partiels

- **Statut :** Accepté (décision observée)
- **Date :** 2026-11-05

## Contexte

Une session de concentration (« expédition ») représente un trajet minuté entre
plusieurs villes. L'utilisateur peut mettre sa session en pause, quitter
l'application en cours de route, ou choisir un temps de concentration inférieur
à la durée totale de l'itinéraire planifié.

## Décision

Le déroulement d'une expédition est piloté côté client par `ActiveTimerScreen`
et persisté par `TravelService` selon les règles suivantes :

- **Maintien actif et anti-triche :** l'écran reste allumé via `wakelock_plus`.
  `ActiveTimerScreen` observe `AppLifecycleState` via `WidgetsBindingObserver` :
  si l'application passe en arrière-plan (`paused` ou `inactive`) hors pause
  autorisée, le personnage rebrousse chemin (`_isWalkingBackward`), le compteur
  remonte, une notification d'alerte est envoyée et un échec est enregistré dans
  `travel_history`.
- **Pauses encadrées :** les pauses (« pause au coin du feu ») sont chronométrées
  et tout dépassement (`_pauseOvertimeSeconds`) est ajouté en pénalité à la
  durée restante du trajet lors de la reprise.
- **Trajets partiels et distinction traversée / arrêt :** si le temps de focus
  choisi ne couvre qu'une partie de l'itinéraire, l'avancée intermédiaire est
  sauvegardée (`midRouteDestination`, `midRouteProgress` dans
  `users/{uid}/travel/status`, ainsi que `inTransit`, `transitRemainingMinutes`
  et `transitRoute` sur le document utilisateur). Les villes franchies en route
  sont ajoutées à `visited_cities` (réduisant par 3 le coût des futurs passages
  dans `TravelService`), tandis que seule la ville finale atteinte est inscrite
  dans `stopped_cities` et permet de débloquer un compagnon.

## Conséquences

- Les utilisateurs peuvent découper un long voyage en plusieurs sessions de
  concentration (« campement sauvage ») sans perdre leur progression sur une
  liaison.
- La détection de sortie d'application encourage le maintien de l'attention sans
  nécessiter de serveur temps réel.
- La logique de chronométrage et d'attribution des récompenses s'exécutant sur
  le client, elle repose sur l'état local tant que la session n'est pas
  terminée.

## Éléments observés

`lib/screens/focus/expedition_screen.dart` implémente `WidgetsBindingObserver`,
le système de pause avec pénalité, l'activation de `WakelockPlus` et la gestion
des trajets partiels. `lib/services/travel_service.dart` calcule la consommation
de minutes par étape et met à jour `visited_cities`, `stopped_cities`,
`travel_history` et `travel/status`.
