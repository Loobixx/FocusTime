# 🗺️ FocusTime - Architecture et Résumé du Projet

## 1. Résumé du Concept
**FocusTime** est une application de productivité ludifiée (gamification). Elle combine la technique du minuteur de concentration (type Pomodoro) avec un jeu d'exploration RPG.
Le temps de concentration de l'utilisateur se transforme en "temps de trajet", lui permettant de voyager sur une carte, d'explorer des régions couvertes par un brouillard de guerre, de débloquer de nouvelles villes (nœuds d'un graphe), et de rencontrer des compagnons animés.

## 2. Stack Technique
*   **Frontend :** Flutter / Dart
*   **Backend / Base de données :** Firebase Authentication (gestion des utilisateurs) & Cloud Firestore (sauvegarde des états de voyage, villes visitées, compagnons débloqués).
*   **Logique de graphe :** Algorithme de Dijkstra (calcul des plus courts chemins).
*   **Graphismes :** CustomPainter (Brouillard), Sprites animés (Personnages et Compagnons), Animations fluides à 60 FPS (optimisation via pre-rendering).

## 3. Mécaniques Principales
*   **Le Voyage (CityNetwork) :** La carte est un graphe où chaque ville est reliée à d'autres avec un "poids" (temps de trajet en minutes). L'algorithme de Dijkstra calcule si l'utilisateur a assez de temps de focus pour atteindre une destination. Les trajets sur des routes déjà visitées coûtent 5 fois moins de temps.
*   **Le Brouillard de Guerre (FogOfWar) :** Un système visuel avancé qui masque la carte. Il génère des nuages animés (sprites pré-calculés) et évide des zones (RadialGradient) autour des villes visitées et frontalières.
*   **Les Compagnons :** Système de récompense. Des familiers animés (ex: chien) se débloquent en atteignant certaines villes et apparaissent dans l'interface de l'utilisateur.

## 4. Arborescence du Projet (Dossier `lib/`)

Voici la structure logique actuelle (et projetée) de l'application :

```text
lib/
│
├── models/
│   ├── city_network.dart        # 🧠 Cœur logique : Définit les villes, leurs connexions et l'algorithme de Dijkstra.
│   └── companion.dart           # 🐾 Modèle de données pour les compagnons déblocables.
│
├── screens/
│   ├── focus_screen.dart        # ⏱️ Écran de sélection du temps de focus (en cours de refonte).
│   ├── focus_moment/
│   │   └── expedition_screen.dart # 🚶‍♂️ Écran actif pendant que le minuteur tourne (le voyage en direct).
│   ├── map/
│   │   ├── map_screen.dart      # 🗺️ Carte globale permettant de choisir sa destination.
│   │   └── data/
│   │       └── region_cross_data.dart # 📍 Coordonnées X/Y exactes des villes sur l'image de la carte.
│   └── profil/
│       └── profile_screen.dart  # 👤 Écran des statistiques, paramètres et inventaire de l'utilisateur.
│
├── starter/
│   └── character_selection_screen.dart # 🎭 Écran de lancement (onboarding) pour choisir son biome/avatar.
│
├── services/
│   ├── notification_service.dart # 🔔 Gère les alertes locales (rappel du soir, fin de timer).
│   └── audio_service.dart        # 🎵 Gère la musique d'ambiance et les sons d'interface.
│
├── utils/
│   ├── time_formatter.dart      # 🛠️ Convertit les minutes en format lisible (ex: 1h 30m).
│   └── city_name.dart           # 🛠️ Normalise les noms de villes pour éviter les bugs d'accents entre Firestore et le code.
│
├── widgets/
│   ├── persistent_animated_character.dart # 🏃‍♂️ Composant affichant les sprites animés (GIF/Frames) du héros.
│   └── camp_scene_widget.dart   # 🏕️ (À VENIR) Le hub/campement dynamique affiché sur l'accueil.
│
└── main.dart                    # 🚀 Point d'entrée de l'application, initialise Firebase et la première page (HomeScreen).
```

## 5. Explication des Fichiers Clés actuels

*   **`lib/models/city_network.dart` :** C'est le "cerveau" mathématique du jeu. Il contient la liste de toutes les villes (Sahur, Orane, etc.), leurs liaisons, et la fonction `calculateAllShortestPaths` qui utilise Dijkstra pour dire à l'interface "Où le joueur peut-il aller avec X minutes ?".
*   **`lib/screens/map/map_screen.dart` (et `FogOfWarPainter`) :** Le fichier le plus lourd visuellement. Il charge l'image de la carte, dessine le brouillard avec des nuages en mouvement permanent, et positionne les points d'intérêts (villes accessibles en vert, visitées en violet) grâce aux coordonnées de `region_cross_data.dart`.
*   **`HomeScreen` (dans main ou home_screen.dart) :** Le tableau de bord de l'utilisateur. Actuellement, il vérifie l'état de l'utilisateur dans Firestore (a-t-il un voyage en cours planté ? a-t-il débloqué un compagnon ?) et lui permet de lancer la carte ou un focus. Ce sera bientôt remplacé par le "Campement".