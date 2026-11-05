import 'dart:ui' show Offset, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_time/models/camp_biome.dart';
import 'package:focus_time/models/camp_layout_config.dart';
import 'package:focus_time/models/city_network.dart';
import 'package:focus_time/models/companion.dart';

void main() {
  group('Companion & CompanionData', () {
    test('tous les compagnons du catalogue ont un id unique et une ville de déblocage valide', () {
      final ids = <String>{};
      for (final companion in CompanionData.allCompanions) {
        expect(ids.add(companion.id), isTrue, reason: 'ID dupliqué : ${companion.id}');
        expect(
          CityNetwork.network.containsKey(companion.unlockCity),
          isTrue,
          reason: 'La ville ${companion.unlockCity} de ${companion.id} n\'existe pas dans CityNetwork',
        );
        expect(companion.campImagePath, isNotEmpty);
      }
    });

    test('getById résout les identifiants sans sensibilité à la casse et gère null/inconnu', () {
      expect(CompanionData.getById('chien')?.name, 'Dogito');
      expect(CompanionData.getById('HUSKY')?.name, 'Azur');
      expect(CompanionData.getById('husky_beige')?.name, 'huskyto');
      expect(CompanionData.getById('renard')?.name, 'Renardo');
      expect(CompanionData.getById('inconnu'), isNull);
      expect(CompanionData.getById(null), isNull);
    });

    test('animationFrames génère les chemins de marche, d\'arrêt sélectionné et non sélectionné', () {
      final dog = CompanionData.getById('chien')!;

      final walkFrames = dog.animationFrames(moving: true, selected: true);
      expect(walkFrames.length, dog.walkFrameCount);
      expect(walkFrames.first, '${dog.walkDirectory}/0.png');

      final selectedIdleFrames = dog.animationFrames(moving: false, selected: true);
      expect(selectedIdleFrames.length, dog.idleFrameCount);
      expect(selectedIdleFrames.first, '${dog.idleDirectory}/0.png');

      final unselectedIdleFrames = dog.animationFrames(moving: false, selected: false);
      expect(unselectedIdleFrames.length, dog.unselectedIdleFrameCount);
      expect(unselectedIdleFrames.first, '${dog.unselectedIdleDirectory}/0.png');

      // Pour un compagnon sans dossier unselectedIdleDirectory, repli sur idleDirectory
      final husky = CompanionData.getById('husky')!;
      final huskyUnselected = husky.animationFrames(moving: false, selected: false);
      expect(huskyUnselected.length, husky.idleFrameCount);
      expect(huskyUnselected.first, '${husky.idleDirectory}/0.png');
    });
  });

  group('CampBiome & CampBiomes', () {
    test('chaque ville de CityNetwork possède une correspondance de biome valide', () {
      for (final city in CityNetwork.network.keys) {
        final biome = CampBiomes.resolve(city: city);
        expect(
          biome.id,
          isNot(equals(CampBiomes.fallback.id)),
          reason: 'La ville "$city" devrait être rattachée à un biome précis',
        );
        expect(CampBiomes.byZone.containsKey(biome.id), isTrue);
      }
    });

    test('resolve donne la priorité au paramètre zone sur la ville et utilise fallback si inconnu', () {
      final forcedZone = CampBiomes.resolve(
        city: 'Le village de Néris', // montagnes
        zone: '  DESERT ',
      );
      expect(forcedZone.id, 'desert');

      final fromCity = CampBiomes.resolve(
        city: '  La cascade de Nayris ',
        zone: '   ',
      );
      expect(fromCity.id, 'lac');

      final fallback = CampBiomes.resolve(city: 'Atlantide', zone: null);
      expect(fallback.id, CampBiomes.fallback.id);
    });
  });

  group('CampElementLayout & CampLayoutConfig', () {
    test('CampElementLayout supporte copyWith, toMap et fromMap', () {
      const initial = CampElementLayout(
        position: Offset(0.2, 0.4),
        size: Size(100, 120),
        scale: 1.5,
      );

      final updated = initial.copyWith(scale: 2.0);
      expect(updated.position, const Offset(0.2, 0.4));
      expect(updated.size, const Size(100, 120));
      expect(updated.scale, 2.0);

      final map = updated.toMap();
      final restored = CampElementLayout.fromMap(map);
      expect(restored.position, updated.position);
      expect(restored.size, updated.size);
      expect(restored.scale, updated.scale);

      final emptyRestored = CampElementLayout.fromMap(const {});
      expect(emptyRestored.position, Offset.zero);
      expect(emptyRestored.size, Size.zero);
      expect(emptyRestored.scale, 1.0);
    });

    test('CampLayoutConfig sérialise, désérialise et conserve les valeurs par défaut en cas de clé manquante', () {
      final config = CampLayoutConfig.defaults.copyWith(
        campfire: CampLayoutConfig.defaults.campfire.copyWith(scale: 1.8),
      );

      final serialized = config.toMap();
      final deserialized = CampLayoutConfig.fromMap(serialized);
      expect(deserialized.campfire.scale, 1.8);
      expect(deserialized.tent.size, CampLayoutConfig.defaults.tent.size);

      final partial = CampLayoutConfig.fromMap(const {'tent': 'invalide'});
      expect(partial.tent.position, CampLayoutConfig.defaults.tent.position);
      expect(partial.character.scale, CampLayoutConfig.defaults.character.scale);
    });
  });
}
