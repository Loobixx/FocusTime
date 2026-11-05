import 'dart:ui' show Size;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_time/config/sprite_config.dart';
import 'package:focus_time/models/city_network.dart';
import 'package:focus_time/screens/map/data/map_region_data.dart';
import 'package:focus_time/screens/map/data/region_cross_data.dart';
import 'package:focus_time/screens/profile/character/character_options.dart';
import 'package:focus_time/theme/app_theme.dart';
import 'package:focus_time/utils/app_constants.dart';
import 'package:focus_time/utils/app_haptics.dart';
import 'package:focus_time/utils/city_name.dart' as city_name;
import 'package:focus_time/utils/text_formatters.dart' as text_formatters;
import 'package:focus_time/utils/time_formatter.dart' as time_formatter;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Formatage du temps et normalisation des noms de villes', () {
    test('formatMinutesToHours formate correctement les durées nulles, minutes, heures pleines et combinées', () {
      expect(time_formatter.formatMinutesToHours(-10), '0 min');
      expect(time_formatter.formatMinutesToHours(0), '0 min');
      expect(time_formatter.formatMinutesToHours(45), '45 min');
      expect(time_formatter.formatMinutesToHours(60), '1h');
      expect(time_formatter.formatMinutesToHours(120), '2h');
      expect(time_formatter.formatMinutesToHours(65), '1h05');
      expect(time_formatter.formatMinutesToHours(150), '2h30');

      // Vérifie la cohérence avec text_formatters.dart
      expect(
        text_formatters.formatMinutesToHours(95),
        equals(time_formatter.formatMinutesToHours(95)),
      );
    });

    test('normalizeCityName retire les accents, ligatures, apostrophes typographiques et espaces superflus', () {
      expect(city_name.normalizeCityName(null), '');
      expect(city_name.normalizeCityName('   '), '');
      expect(
        city_name.normalizeCityName('  Le Phare d’Orane '),
        "le phare d'orane",
      );
      expect(
        city_name.normalizeCityName('L‘Île\u00A0Aos   Sé - Cœur'),
        "l'ile aos se - coeur",
      );
      expect(
        text_formatters.normalizeCityName('L’Antre d’Émeraude'),
        equals(city_name.normalizeCityName('L’Antre d’Émeraude')),
      );
    });
  });

  group('SpriteConfig & AppConstants', () {
    test('SpriteConfig retourne les dimensions, nombres de frames et dossiers attendus', () {
      expect(SpriteConfig.character(SpriteScene.expedition), const Size(420, 420));
      expect(SpriteConfig.character(SpriteScene.region), const Size(200, 200));
      expect(SpriteConfig.companion(SpriteScene.world), const Size(60, 60));

      final nuitFrames = SpriteConfig.framesFor('NUIT');
      expect(nuitFrames.walk, 16);
      expect(nuitFrames.idle, 21);

      final fallbackFrames = SpriteConfig.framesFor('inconnu');
      expect(fallbackFrames.walk, 16);
      expect(fallbackFrames.idle, 21);

      expect(SpriteConfig.folder('nuit'), 'Nuit');
      expect(SpriteConfig.folder(''), 'Nuit');
    });

    test('AppConstants expose le nom et la version de l\'application', () {
      expect(AppConstants.appName, 'FocusTime');
      expect(AppConstants.appVersion, isNotEmpty);
    });
  });

  group('AppThemeController & AppHaptics (SharedPreferences)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('AppThemeController charge le mode système par défaut et persiste les changements', () async {
      await AppThemeController.load();
      expect(AppThemeController.mode.value, ThemeMode.system);

      await AppThemeController.setMode(ThemeMode.dark);
      expect(AppThemeController.mode.value, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'dark');

      await AppThemeController.setMode(ThemeMode.light);
      await AppThemeController.load();
      expect(AppThemeController.mode.value, ThemeMode.light);
    });

    test('AppHaptics charge l\'état activé par défaut et persiste la désactivation', () async {
      await AppHaptics.load();
      expect(AppHaptics.isEnabled.value, isTrue);

      await AppHaptics.setEnabled(false);
      expect(AppHaptics.isEnabled.value, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app_haptics_enabled'), isFalse);
    });
  });

  group('Données de carte (MapRegionsData, RegionCrossesData, CharacterOptionsList)', () {
    test('MapRegionsData définit les 5 régions avec des tracés non vides', () {
      final regionIds = MapRegionsData.regions.map((r) => r.id).toSet();
      expect(regionIds, containsAll(['desert', 'lac', 'nuit', 'nuages', 'montagnes']));

      for (final region in MapRegionsData.regions) {
        expect(region.name, isNotEmpty);
        expect(region.path.getBounds().isEmpty, isFalse);
      }
    });

    test('toutes les croix de RegionCrossesData correspondent à des villes de CityNetwork', () {
      final normalizedNetworkCities = CityNetwork.network.keys
          .map(city_name.normalizeCityName)
          .toSet();

      for (final entry in RegionCrossesData.crossesByRegion.entries) {
        expect(entry.value, isNotEmpty, reason: 'La région ${entry.key} n\'a aucune croix');
        for (final cross in entry.value) {
          expect(
            normalizedNetworkCities.contains(city_name.normalizeCityName(cross.name)),
            isTrue,
            reason: 'La croix "${cross.name}" (${cross.id}) dans ${entry.key} est absente de CityNetwork',
          );
        }
      }
    });

    test('CharacterOptionsList contient les 5 avatars de biome avec des identifiants uniques', () {
      final ids = CharacterOptionsList.characters.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids, containsAll(['nuit', 'desert', 'montagnes', 'lac', 'nuages']));
    });
  });
}
