class ShortestPathResult {
  final List<String> path;
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
    // ==========================================
    // --- ZONE DÉSERT (Sahur) ---
    // ==========================================
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
      connectedCities: {'La piste des marchands': 1, 'Le cimetières des géants': 1, 'Rive Calme': 1}, // Vers le lac
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

    // ==========================================
    // --- ZONE MONTAGNES (Orane) ---
    // ==========================================
    'La tombe oubliée': const CityNode(
      name: 'La tombe oubliée',
      connectedCities: {'La forêt d\'Orane': 1, 'Le ponton des brunes': 1},
    ),
    'Le ponton des brunes': const CityNode(
      name: 'Le ponton des brunes',
      connectedCities: {'La tombe oubliée': 1, 'La grange au vent': 1},
    ),
    'Le Ruisseau des murmures': const CityNode(
      name: 'Le Ruisseau des murmures',
      connectedCities: {'Le village de Néris': 1, 'Le miroir d\'Emeraude': 1, 'Le bosquet enchanté': 1},
    ),
    'La grange au vent': const CityNode(
      name: 'La grange au vent',
      connectedCities: {'Le ponton des brunes': 1, 'Le campement de l\'île Sud': 1}, 
    ),
    'Le campement de l\'île Sud': const CityNode(
      name: 'Le campement de l\'île Sud',
      connectedCities: {'La grange au vent': 1, 'Le phare d\'Orane': 1},
    ),
    'Le phare d\'Orane': const CityNode(
      name: 'Le phare d\'Orane',
      connectedCities: {'Le campement de l\'île Sud': 1},
    ),
    'Le bosquet enchanté': const CityNode(
      name: 'Le bosquet enchanté',
      connectedCities: {'Le Ruisseau des murmures': 1, 'Le village de Néris': 1},
    ),
    'L\'épée Maudite': const CityNode(
      name: 'L\'épée Maudite',
      connectedCities: {'L\'île Aos Sé': 1},
    ),
    'L\'île Aos Sé': const CityNode(
      name: 'L\'île Aos Sé',
      connectedCities: {'Les nacelles du Pics': 1, 'L\'épée Maudite': 1},
    ),
    'Le village de Néris': const CityNode(
      name: 'Le village de Néris',
      connectedCities: {'L\'Halte blanche': 1, 'Le bosquet enchanté': 1, 'Le Ruisseau des murmures': 1, 'Île Céleste': 1}, // Vers les nuages
    ),
    'L\'Halte blanche': const CityNode(
      name: 'L\'Halte blanche',
      connectedCities: {'Le village de Néris': 1, 'Le refuge des neiges': 1},
    ),
    'Les nacelles du Pics': const CityNode(
      name: 'Les nacelles du Pics',
      connectedCities: {'Le refuge des neiges': 1, 'L\'île Aos Sé': 1},
    ),
    'Le refuge des neiges': const CityNode(
      name: 'Le refuge des neiges',
      connectedCities: {'L\'Halte blanche': 1, 'Les nacelles du Pics': 1, 'Le chateau d\'azur': 1},
    ),
    'Le chateau d\'azur': const CityNode(
      name: 'Le chateau d\'azur',
      connectedCities: {'Le refuge des neiges': 1, 'Le sommet d\'azur': 1, 'L\'observatoire d\'Ouest': 1},
    ),
    'Le sommet d\'azur': const CityNode(
      name: 'Le sommet d\'azur',
      connectedCities: {'Le chateau d\'azur': 1},
    ),
    'La stelle des montagnes d\'Orane': const CityNode(
      name: 'La stelle des montagnes d\'Orane',
      connectedCities: {'L\'observatoire d\'Ouest': 1},
    ),
    'L\'observatoire d\'Ouest': const CityNode(
      name: 'L\'observatoire d\'Ouest',
      connectedCities: {'Le chateau d\'azur': 1, 'La stelle des montagnes d\'Orane': 1},
    ),
    'L\'Antre d\'émeraude': const CityNode(
      name: 'L\'Antre d\'émeraude',
      connectedCities: {'Le miroir d\'Emeraude': 1, 'Le cercle des anciens': 1},
    ),
    'Le cercle des anciens': const CityNode(
      name: 'Le cercle des anciens',
      connectedCities: {'L\'Antre d\'émeraude': 1, 'Les ruines de garde-roc': 1},
    ),
    'Les ruines de garde-roc': const CityNode(
      name: 'Les ruines de garde-roc',
      connectedCities: {'Le cercle des anciens': 1, 'La forêt d\'Orane': 1},
    ),
    'Le miroir d\'Emeraude': const CityNode(
      name: 'Le miroir d\'Emeraude',
      connectedCities: {'Le Ruisseau des murmures': 1, 'L\'Antre d\'émeraude': 1},
    ),
    'La forêt d\'Orane': const CityNode(
      name: 'La forêt d\'Orane',
      connectedCities: {'Les ruines de garde-roc': 1, 'La tombe oubliée': 1},
    ),

    // ==========================================
    // --- AUTRES ZONES (Connexions) ---
    // ==========================================
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
      connectedCities: {'Rive Calme': 1, 'Le village de Néris': 1},
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