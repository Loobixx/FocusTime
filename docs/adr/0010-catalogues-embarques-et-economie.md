# ADR 0010 : Catalogues statiques embarqués et transactions Firestore pour l'économie

- **Statut :** Accepté (décision observée)
- **Date :** 2026-11-05

## Contexte

En plus du graphe des villes (ADR 0003), le jeu propose des compagnons
déblocables par ville, des décors de campement dépendant de la région courante
(biomes) et une boutique de cosmétiques (tentes, clôtures) achetables avec les
pièces gagnées pendant les sessions de concentration.

## Décision

Les catalogues de contenus sont embarqués statiquement dans le code client,
tandis que Firestore ne stocke que l'état de possession et d'équipement du
joueur :

- **Catalogues côté client :** `CompanionData.allCompanions` définit les
  compagnons et leur ville de déblocage ; `CampBiomes` associe chaque ville et
  zone à ses ressources graphiques ; `ShopScreen` contient le catalogue des
  cosmétiques, leurs variantes, leurs prix et leurs chemins d'assets.
- **État économique et inventaire dans Firestore :** le document `users/{uid}`
  conserve le solde (`points`), les identifiants débloqués (`unlockedItems`,
  `unlockedCompanions`), la meute active (`activeCompanions`, jusqu'à 4
  compagnons, avec rétrocompatibilité sur `activeCompanion`) et les chemins des
  cosmétiques équipés (`equippedTent`, `equippedEnclosureBack`,
  `equippedEnclosureFront`).
- **Achat atomique :** l'achat d'une variante dans `ShopScreen` utilise une
  transaction Firestore (`runTransaction`) qui vérifie le solde, débite
  `points` et ajoute l'identifiant à `unlockedItems` via
  `FieldValue.arrayUnion`.

## Conséquences

- L'affichage de la boutique, du campement et des compagnons ne nécessite aucune
  lecture de collection de catalogue distante.
- L'ajout d'un compagnon, d'un biome ou d'un article de boutique passe par une
  mise à jour de l'application et des assets embarqués.
- Les prix et récompenses (2 pièces par minute de focus) étant évalués par le
  client lors de la transaction, l'économie repose sur la logique applicative
  cliente.

## Éléments observés

`lib/models/companion.dart`, `lib/models/camp_biome.dart` et
`lib/screens/shop/shop_screen.dart` définissent les catalogues et la transaction
d'achat `_buyVariant`. `lib/screens/home/home_screen.dart` et
`lib/screens/focus/expedition_screen.dart` synchronisent les compagnons et
cosmétiques équipés.
