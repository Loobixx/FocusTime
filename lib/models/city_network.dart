class ShortestPathResult {
  final List<String> path; // Liste des villes traversées (sans la ville de départ)
  final int totalTravelMinutes;

  ShortestPathResult({required this.path, required this.totalTravelMinutes});
}

class CityNode {
  final String name;
  final Map<String, int> connectedCities;

  const CityNode({
    required this.name,
    required this.connectedCities,
  });
}

class CityNetwork {
  static final Map<String, CityNode> network = {
    'Valenciennes': const CityNode(
      name: 'Valenciennes',
      connectedCities: {'Lille': 5, 'Arras': 5, 'Cambrai': 5},
    ),
    'Lille': const CityNode(
      name: 'Lille',
      connectedCities: {'Valenciennes': 5, 'Dunkerque': 5, 'Calais': 5},
    ),
    'Arras': const CityNode(
      name: 'Arras',
      connectedCities: {'Valenciennes': 5, 'Amiens': 5, 'Paris': 5},
    ),
    'Cambrai': const CityNode(
      name: 'Cambrai',
      connectedCities: {'Valenciennes': 5, 'Saint-Quentin': 5},
    ),
    'Dunkerque': const CityNode(
      name: 'Dunkerque',
      connectedCities: {'Lille': 5},
    ),
    'Calais': const CityNode(
      name: 'Calais',
      connectedCities: {'Lille': 5},
    ),
    'Amiens': const CityNode(
      name: 'Amiens',
      connectedCities: {'Arras': 5, 'Rouen': 5, 'Paris': 5},
    ),
    'Saint-Quentin': const CityNode(
      name: 'Saint-Quentin',
      connectedCities: {'Cambrai': 5, 'Reims': 5},
    ),
    'Rouen': const CityNode(
      name: 'Rouen',
      connectedCities: {'Amiens': 5, 'Paris': 5},
    ),
    'Reims': const CityNode(
      name: 'Reims',
      connectedCities: {'Saint-Quentin': 5, 'Paris': 5},
    ),
    'Paris': const CityNode(
      name: 'Paris',
      connectedCities: {'Arras': 5, 'Amiens': 5, 'Rouen': 5, 'Reims': 5, 'Lyon': 5, 'Eldoria': 5},
    ),
    'Lyon': const CityNode(
      name: 'Lyon',
      connectedCities: {'Paris': 5, 'Solaris': 5},
    ),
    'Eldoria': const CityNode(
      name: 'Eldoria',
      connectedCities: {'Paris': 5, 'Chronos': 5, 'Lumina': 5},
    ),
    'Chronos': const CityNode(
      name: 'Chronos',
      connectedCities: {'Eldoria': 5, 'Nebula': 5},
    ),
    'Lumina': const CityNode(
      name: 'Lumina',
      connectedCities: {'Eldoria': 5, 'Atlantis': 5},
    ),
    'Solaris': const CityNode(
      name: 'Solaris',
      connectedCities: {'Lyon': 5, 'Nebula': 5},
    ),
    'Nebula': const CityNode(
      name: 'Nebula',
      connectedCities: {'Chronos': 5, 'Solaris': 5, 'Zenith': 5},
    ),
    'Atlantis': const CityNode(
      name: 'Atlantis',
      connectedCities: {'Lumina': 5, 'Zenith': 5},
    ),
    'Zenith': const CityNode(
      name: 'Zenith',
      connectedCities: {'Nebula': 5, 'Atlantis': 5},
    ),
  };

  static Map<String, int> getAvailableDestinations(String currentCity) {
    return network[currentCity]?.connectedCities ?? {};
  }

  // Algorithme de Dijkstra avec réduction /5 pour les villes visitées
  static Map<String, ShortestPathResult> calculateAllShortestPaths({
    required String startCity,
    required Set<String> visitedCities,
  }) {
    final Map<String, int> distances = {};
    final Map<String, String?> previous = {};
    final Set<String> unvisited = Set.from(network.keys);

    for (var city in network.keys) {
      distances[city] = 999999;
      previous[city] = null;
    }
    distances[startCity] = 0;

    while (unvisited.isNotEmpty) {
      String? current;
      int minDistance = 999999;

      for (var city in unvisited) {
        if (distances[city]! < minDistance) {
          minDistance = distances[city]!;
          current = city;
        }
      }

      if (current == null || minDistance == 999999) break;
      unvisited.remove(current);

      final neighbors = network[current]?.connectedCities ?? {};
      for (var entry in neighbors.entries) {
        final neighbor = entry.key;
        if (!unvisited.contains(neighbor)) continue;

        int weight = entry.value;
        if (visitedCities.contains(neighbor)) {
          weight = (weight ~/ 5).clamp(1, 999999);
        }

        int alt = distances[current]! + weight;
        if (alt < distances[neighbor]!) {
          distances[neighbor] = alt;
          previous[neighbor] = current;
        }
      }
    }

    // Reconstitution des trajets
    final Map<String, ShortestPathResult> results = {};

    for (var targetCity in network.keys) {
      if (targetCity == startCity || distances[targetCity] == 999999) continue;

      List<String> path = [];
      String? step = targetCity;

      while (step != null && step != startCity) {
        path.insert(0, step);
        step = previous[step];
      }

      results[targetCity] = ShortestPathResult(
        path: path,
        totalTravelMinutes: distances[targetCity]!,
      );
    }

    return results;
  }
}