import 'package:flutter_test/flutter_test.dart';
import 'package:focus_time/models/city_network.dart';

void main() {
  group('CityNetwork - intégrité du graphe', () {
    test('chaque nœud du réseau possède un nom cohérent et au moins une liaison', () {
      expect(CityNetwork.network, isNotEmpty);

      for (final entry in CityNetwork.network.entries) {
        final cityKey = entry.key;
        final node = entry.value;

        expect(node.name, equals(cityKey));
        expect(
          node.connectedCities,
          isNotEmpty,
          reason: '$cityKey doit avoir au moins une ville connectée',
        );
      }
    });

    test('toutes les liaisons pointent vers des villes existantes avec un poids strictement positif', () {
      for (final entry in CityNetwork.network.entries) {
        final origin = entry.key;
        for (final connection in entry.value.connectedCities.entries) {
          final target = connection.key;
          final duration = connection.value;

          expect(
            CityNetwork.network.containsKey(target),
            isTrue,
            reason: 'La liaison $origin -> $target pointe vers une ville inexistante',
          );
          expect(
            duration,
            greaterThan(0),
            reason: 'La durée $origin -> $target doit être > 0',
          );
        }
      }
    });

    test('getAvailableDestinations retourne les voisins ou une map vide si la ville est inconnue', () {
      final nerisNeighbors = CityNetwork.getAvailableDestinations('Le village de Néris');
      expect(nerisNeighbors, containsPair('Le Ruisseau des murmures', 30));
      expect(nerisNeighbors, containsPair('L\'Halte blanche', 60));

      expect(CityNetwork.getAvailableDestinations('Ville Imaginaire'), isEmpty);
    });
  });

  group('CityNetwork - brouillard et visibilité (getVisibleCities)', () {
    test('inclut la ville actuelle, les villes connues et leurs voisins à 1 saut', () {
      final visible = CityNetwork.getVisibleCities(
        currentCity: 'Le village de Néris',
        knownCities: const {},
      );

      // Ville actuelle
      expect(visible, contains('Le village de Néris'));
      // Voisins directs (1 saut)
      expect(visible, contains('Le Ruisseau des murmures'));
      expect(visible, contains('Le cercle des anciens'));
      expect(visible, contains('L\'Halte blanche'));
      expect(visible, contains('L\'île Aos Sé'));
      expect(visible, contains('Île Céleste'));

      // Voisin à 2 sauts non visité (ne doit pas être visible)
      expect(visible, isNot(contains('Le miroir d\'Emeraude')));
      expect(visible, isNot(contains('Les nacelles du Pics')));
    });

    test('combine les voisins de plusieurs villes connues même si currentCity est null', () {
      final visible = CityNetwork.getVisibleCities(
        currentCity: null,
        knownCities: const {'La tombe oubliée'},
      );

      expect(visible, containsAll(['La tombe oubliée', 'Le ponton des brunes']));
      expect(visible, isNot(contains('La forêt d\'Orane')));
    });
  });

  group('CityNetwork - Dijkstra modifié (calculateAllShortestPaths)', () {
    test('bloque le transit à travers une ville non visitée (règle de brouillard)', () {
      // Au départ de Néris sans aucune ville visitée :
      // On peut atteindre les voisins directs de Néris, mais pas traverser
      // 'Le cercle des anciens' pour aller à 'Le miroir d\'Emeraude'.
      final paths = CityNetwork.calculateAllShortestPaths(
        startCity: 'Le village de Néris',
        visitedCities: const {},
      );

      expect(paths.containsKey('Le cercle des anciens'), isTrue);
      expect(paths['Le cercle des anciens']!.path, ['Le cercle des anciens']);
      expect(paths['Le cercle des anciens']!.totalTravelMinutes, 30);

      expect(paths.containsKey('L\'Halte blanche'), isTrue);
      expect(paths['L\'Halte blanche']!.totalTravelMinutes, 60);

      // À 2 sauts derrière une ville non visitée -> inaccessible
      expect(paths.containsKey('Le miroir d\'Emeraude'), isFalse);
      expect(paths.containsKey('Les nacelles du Pics'), isFalse);
    });

    test('débloque le transit au-delà d\'une ville visitée et applique le bonus ~/ 3 sur les étapes visitées', () {
      final paths = CityNetwork.calculateAllShortestPaths(
        startCity: 'Le village de Néris',
        visitedCities: const {'Le cercle des anciens'},
      );

      // 'Le cercle des anciens' est déjà visitée : son coût passe de 30 à 30 ~/ 3 = 10 min
      expect(paths['Le cercle des anciens']!.totalTravelMinutes, 10);

      // Comme 'Le cercle des anciens' est visitée, on peut la traverser pour
      // atteindre 'Le miroir d\'Emeraude' (non visitée, coût 30) -> 10 + 30 = 40 min
      expect(paths.containsKey('Le miroir d\'Emeraude'), isTrue);
      expect(
        paths['Le miroir d\'Emeraude']!.path,
        ['Le cercle des anciens', 'Le miroir d\'Emeraude'],
      );
      expect(paths['Le miroir d\'Emeraude']!.totalTravelMinutes, 40);

      // Mais 'Le miroir d\'Emeraude' n'étant pas visitée, 'L\'Antre d\'émeraude' reste bloquée
      expect(paths.containsKey('L\'Antre d\'émeraude'), isFalse);
    });

    test('calcule le plus court chemin sur plusieurs étapes visitées', () {
      final visited = CityNetwork.network.keys.toSet();
      final paths = CityNetwork.calculateAllShortestPaths(
        startCity: 'Le village de Néris',
        visitedCities: visited,
      );

      // Toutes les autres villes du graphe connecté sont atteignables
      expect(paths.length, CityNetwork.network.length - 1);

      final toAntre = paths['L\'Antre d\'émeraude']!;
      expect(
        toAntre.path,
        ['Le cercle des anciens', 'Le miroir d\'Emeraude', 'L\'Antre d\'émeraude'],
      );
      // 3 liaisons de 30 min toutes visitées -> 10 + 10 + 10 = 30 min
      expect(toAntre.totalTravelMinutes, 30);
    });
  });
}
