# ADR 0004 : Données isolées par utilisateur et protégées par les règles Firestore

- **Statut :** Accepté (décision observée)
- **Date :** 2026-11-05

## Contexte

Les voyages, villes visitées, préférences et informations de compte sont des
données personnelles. Les droits d'administration doivent être gérés
explicitement et les données doivent pouvoir être supprimées à la demande.

## Décision

Les données de progression sont rangées sous `users/{uid}` et ses
sous-collections autorisées (`travel`, `travel_history`, `visited_cities`,
`stopped_cities`, `history`). Les règles Firestore :

- autorisent l'accès au propriétaire authentifié et aux administrateurs actifs ;
- valident le schéma et les bornes des documents écrits (taille du pseudo,
  solde `points` entier positif et borné, nombre maximal de clés et de
  compagnons actifs, liste blanche des sous-collections) ;
- vérifient les comptes administrateurs via `admin_emails` avec normalisation en
  minuscules (`request.auth.token.email.lower()`), une adresse vérifiée et un
  indicateur `enabled`, tout en interdisant l'auto-modification ;
- refusent par défaut toute collection ou sous-collection non explicitement
  autorisée.

Lors de la suppression de compte, l'utilisateur est d'abord ré-authentifié
(`DeleteAccountDialog`) avant que `UserDataDeletionService` n'efface les
sous-collections connues par lots puis le document utilisateur et le compte
Firebase Auth.

## Conséquences

- Les accès sont liés à l'identifiant Firebase de l'utilisateur plutôt qu'à
  une adresse saisie par le client.
- Toute nouvelle sous-collection utilisateur doit être ajoutée à la routine de
  suppression pour éviter de laisser des données orphelines.
- Les règles doivent être revues avec chaque changement de schéma ou de rôle.
- Les règles Firestore ne remplacent pas la validation métier des opérations
  sensibles côté serveur ; le client ne doit pas être considéré comme une
  autorité de confiance.

## Éléments observés

`firestore.rules` applique l'isolation par UID, vérifie les administrateurs et
refuse par défaut les chemins non couverts. `UserDataDeletionService` parcourt
les sous-collections listées puis supprime le document utilisateur.
