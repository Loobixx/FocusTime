# 🗺️ FocusTime - Architecture et Résumé du Projet

## 1. Résumé du Concept
**FocusTime** est une application de productivité ludifiée (gamification). Elle combine la technique du minuteur de concentration (type Pomodoro) avec un jeu d'exploration RPG.
Le temps de concentration de l'utilisateur se transforme en « temps de trajet », lui permettant de voyager sur une carte, d'explorer des régions couvertes par un brouillard de guerre, de débloquer de nouvelles villes (nœuds d'un graphe), de collectionner des compagnons animés et de personnaliser son campement.

## 2. Stack Technique
*   **Frontend :** Flutter / Dart (cibles Android, iOS, Web, Windows, macOS, Linux)
*   **Backend / Base de données :** Firebase Authentication (e-mail/mot de passe et Google Sign-In) & Cloud Firestore (sauvegarde isolée sous `users/{uid}` et gestion des rôles dans `admin_emails`).
*   **Préférences locales :** `SharedPreferences` pour le thème clair/sombre, l'haptique et l'état muet de l'audio.
*   **Logique de graphe :** Algorithme de Dijkstra modifié (calcul des plus courts chemins avec blocage au-delà des villes non visitées et réduction `~/ 3` sur les villes déjà traversées).
*   **Graphismes :** `CustomPainter` procédural (`FogOfWarPainter`, `WorldCloudsPainter`, `BiomeBackdrop`, `Campfire`), sprites PNG préchargés via `SpriteAnimator` (`ResizeImage` + `precacheImage`).

## 3. Arborescence Complète du Projet

```text
flutter_time/
├── docs/
│   └── adr/                         # 📜 Architecture Decision Records (0001 à 0011)
│
├── lib/
│   ├── config/
│   │   └── sprite_config.dart       # ⚙️ Dimensions, positions et nombre de frames des sprites
│   │
│   ├── models/
│   │   ├── camp_biome.dart          # 🏞️ Association ville/zone -> décor de camp et d'expédition
│   │   ├── camp_layout_config.dart  # 📐 Disposition (tente, feu, personnage, enclos) sur l'accueil
│   │   ├── city_network.dart        # 🧠 Graphe des villes, visibilité et algorithme de Dijkstra
│   │   └── companion.dart           # 🐾 Catalogue des compagnons déblocables et séquences PNG
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   └── login_screen.dart    # 🔐 Connexion, inscription, Google Sign-In et mot de passe oublié
│   │   ├── camp/
│   │   │   └── companion_pen_screen.dart # 🐕 Enclos de sélection de la meute (jusqu'à 4 compagnons)
│   │   ├── focus/
│   │   │   ├── focus_screen.dart    # ⏱️ Configuration de la durée de focus et de l'itinéraire
│   │   │   ├── expedition_screen.dart # 🚶‍♂️ Session active, pauses, anti-triche et bilan
│   │   │   └── expedition_dialogs.dart # 💬 Modales de pause, d'abandon et de fin de session
│   │   ├── home/
│   │   │   └── home_screen.dart     # 🏕️ Campement dynamique (biome, tente, feu, enclos, compagnons)
│   │   ├── map/
│   │   │   ├── map_screen.dart      # 🌍 Carte du monde interactive par régions
│   │   │   ├── region_detail_screen.dart # 🗺️ Carte régionale détaillée avec brouillard et villes
│   │   │   ├── fog_of_war.dart      # ☁️ Génération procédurale des nuages et masques de révélation
│   │   │   └── data/
│   │   │       ├── map_region_data.dart   # 📐 Tracés vectoriels (Path) des 5 régions du monde
│   │   │       └── region_cross_data.dart # 📍 Coordonnées X/Y des villes dans chaque région
│   │   ├── profile/
│   │   │   ├── profile_screen.dart  # 👤 Profil, thème, audio, haptique et accès aux sous-écrans
│   │   │   ├── about_profil/about_screen.dart
│   │   │   ├── admin/admin_management_screen.dart
│   │   │   ├── change_password/auth_helper.dart
│   │   │   ├── character/character_customize_screen.dart & character_options.dart
│   │   │   ├── companion/companion_selection_screen.dart
│   │   │   ├── delete_profil/delete_account_dialog.dart
│   │   │   ├── historique/history_screen.dart
│   │   │   ├── notification/notification_settings_screen.dart
│   │   │   ├── politique_de_confidentialité/privacy_policy_screen.dart
│   │   │   └── stat/stats_screen.dart
│   │   └── shop/
│   │       └── shop_screen.dart     # 🛒 Boutique de cosmétiques (tentes, clôtures) avec transactions Firestore
│   │
│   ├── services/
│   │   ├── admin_access_service.dart       # 🛡️ Vérification et gestion de la liste blanche admin_emails
│   │   ├── audio_service.dart              # 🎵 Musique d'ambiance en boucle avec garde-fou Web
│   │   ├── notification_service.dart       # 🔔 Notifications locales, chrono de pause et bilan de 20h
│   │   ├── travel_service.dart             # 🧭 Calcul d'avancée, trajets partiels et historique Firestore
│   │   └── user_data_deletion_service.dart # 🗑️ Suppression par lots des sous-collections utilisateur
│   │
│   ├── starter/
│   │   └── character_selection_screen.dart # 🎭 Choix initial du personnage à l'onboarding
│   │
│   ├── theme/
│   │   └── app_theme.dart           # 🎨 Palettes clair/sombre et AppThemeController
│   │
│   ├── utils/
│   │   ├── app_constants.dart       # 📌 Nom et version de l'application
│   │   ├── app_haptics.dart         # 📳 Retour haptique multiplateforme (natif + Web Vibration API)
│   │   ├── city_name.dart           # 🔤 Normalisation des noms de villes (accents, apostrophes)
│   │   ├── haptics_stub.dart & haptics_web.dart
│   │   ├── text_formatters.dart & time_formatter.dart
│   │   └── user_roles.dart          # 👑 Personnalisation visuelle dédiée (rôle Lise vs standard)
│   │
│   ├── widgets/
│   │   ├── biome_backdrop.dart      # 🌄 Décors de biomes dessinés en CustomPainter
│   │   ├── camp_widgets.dart        # 🔥 Feu de camp animé (Campfire) et clôture (CampFencePainter)
│   │   ├── game_sprites.dart        # 🏃‍♂️ Widgets CharacterSprite et CompanionSprite
│   │   ├── location_biome_background.dart
│   │   ├── parallax_background.dart # 🏞️ Défilement parallaxe du sol et du fond pendant l'expédition
│   │   └── sprite_animator.dart     # 🎞️ Animateur de séquences PNG avec ResizeImage et precacheImage
│   │
│   └── main.dart                    # 🚀 Initialisation (cache images 300 Mo, Firebase, thème, haptique)
│
└── test/
    ├── models/
    │   ├── city_network_test.dart          # Tests du graphe, visibilité et Dijkstra modifié
    │   └── companion_and_biome_test.dart   # Tests des compagnons, biomes et layout du camp
    ├── services/
    │   └── travel_service_test.dart        # Tests complets de TravelService (trajets, reprises, admin)
    ├── utils/
    │   └── utils_and_config_test.dart      # Tests des formatteurs, thème, haptique, cartes et configs
    ├── widgets/
    │   └── widgets_and_screens_test.dart   # Tests widgets (biomes, feu, brouillard, modales, enclos)
    ├── security/
    │   └── firestore_rules.test.cjs        # Tests d'intégration Node.js sur l'émulateur Firebase
    ├── admin_access_service_test.dart      # Tests unitaires de AdminAccessService
    ├── user_data_deletion_service_test.dart # Tests unitaires de UserDataDeletionService
    └── user_roles_test.dart                # Tests unitaires de UserRoles
```
