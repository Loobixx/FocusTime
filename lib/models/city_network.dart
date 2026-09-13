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
    // --- ZONE DÉSERT (Sahur) ---
    'La port de commerce de Solaris': const CityNode(
      name: 'La port de commerce de Solaris',
      connectedCities: {'La cité Solaris': 1, 'Le puits des Mirages': 1},
    ),
    'La cité Solaris': const CityNode(
      name: 'La cité Solaris',
      connectedCities: {'La port de commerce de Solaris': 1, 'Le piège des sables': 1, 'La stelle du desert de Sahur': 1},
    ),
    'Le puits des Mirages': const CityNode(
      name: 'Le puits des Mirages',
      connectedCities: {'La port de commerce de Solaris': 1, 'Le piège des sables': 1},
    ),
    'Le piège des sables': const CityNode(
      name: 'Le piège des sables',
      connectedCities: {'La cité Solaris': 1, 'Le puits des Mirages': 1, 'La stelle du desert de Sahur': 1},
    ),
    'La stelle du desert de Sahur': const CityNode(
      name: 'La stelle du desert de Sahur',
      connectedCities: {'La cité Solaris': 1, 'Le piège des sables': 1, 'Le coeur du désert': 1},
    ),
    'Le coeur du désert': const CityNode(
      name: 'Le coeur du désert',
      connectedCities: {'La stelle du desert de Sahur': 1, 'La piste des marchands': 1, 'Les monts de Sahur': 1},
    ),
    'La piste des marchands': const CityNode(
      name: 'La piste des marchands',
      connectedCities: {'Le coeur du désert': 1, 'Le champs des épines': 1, 'La porte du désert': 1},
    ),
    'Le champs des épines': const CityNode(
      name: 'Le champs des épines',
      connectedCities: {'La piste des marchands': 1, 'Les monts de Sahur': 1},
    ),
    'Les monts de Sahur': const CityNode(
      name: 'Les monts de Sahur',
      connectedCities: {'Le coeur du désert': 1, 'Le champs des épines': 1, 'L\'autel du soleil': 1},
    ),
    'La porte du désert': const CityNode(
      name: 'La porte du désert',
      connectedCities: {'La piste des marchands': 1, 'Le cimetières des géants': 1, 'Rive Calme': 1}, // Connexion vers le lac
    ),
    'L\'autel du soleil': const CityNode(
      name: 'L\'autel du soleil',
      connectedCities: {'Les monts de Sahur': 1, 'Le bain du désert': 1, 'La grotte infini': 1},
    ),
    'Le bain du désert': const CityNode(
      name: 'Le bain du désert',
      connectedCities: {'L\'autel du soleil': 1, 'Le cimetières des géants': 1},
    ),
    'Le cimetières des géants': const CityNode(
      name: 'Le cimetières des géants',
      connectedCities: {'Le bain du désert': 1, 'La porte du désert': 1},
    ),
    'La grotte infini': const CityNode(
      name: 'La grotte infini',
      connectedCities: {'L\'autel du soleil': 1, 'Le passage secret': 1},
    ),
    'Le passage secret': const CityNode(
      name: 'Le passage secret',
      connectedCities: {'La grotte infini': 1, 'L\'oasis de l\'exil': 1},
    ),
    'L\'oasis de l\'exil': const CityNode(
      name: 'L\'oasis de l\'exil',
      connectedCities: {'Le passage secret': 1},
    ),

    // --- AUTRES ZONES ---
    'Rive Calme': const CityNode(
      name: 'Rive Calme',
      connectedCities: {'La porte du désert': 1, 'Sanctuaire Obscur': 1, 'Île Céleste': 1},
    ),
    'Sanctuaire Obscur': const CityNode(
      name: 'Sanctuaire Obscur',
      connectedCities: {'Rive Calme': 1},
    ),
    'Île Céleste': const CityNode(
      name: 'Île Céleste',
      connectedCities: {'Rive Calme': 1},
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