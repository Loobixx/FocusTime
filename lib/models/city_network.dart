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

  static const bool isDevMode = false;

  static final Map<String, CityNode> network = {
    // ==========================================
    // --- ZONE DÉSERT (Sahur) ---
    // ==========================================
    'Le port de commerce de Solaris': const CityNode(
      name: 'Le port de commerce de Solaris',
      connectedCities: {'La cité Solaris': 30, 'Le puits des Mirages': 60},
    ),
    'La cité Solaris': const CityNode(
      name: 'La cité Solaris',
      connectedCities: {'Le port de commerce de Solaris': 30, 'Le piège des sables': 30, 'La stelle du desert de Sahur': 30},
    ),
    'Le puits des Mirages': const CityNode(
      name: 'Le puits des Mirages',
      connectedCities: {'Le port de commerce de Solaris': 30, 'Le piège des sables': 30},
    ),
    'Le piège des sables': const CityNode(
      name: 'Le piège des sables',
      connectedCities: {'La cité Solaris': 30, 'Le puits des Mirages': 30, 'La stelle du desert de Sahur': 30},
    ),
    'La stelle du desert de Sahur': const CityNode(
      name: 'La stelle du desert de Sahur',
      connectedCities: {'La cité Solaris': 30, 'Le piège des sables': 30, 'Le coeur du désert': 30},
    ),
    'Le coeur du désert': const CityNode(
      name: 'Le coeur du désert',
      connectedCities: {'La stelle du desert de Sahur': 30, 'La piste des marchands': 30, 'Les monts de Sahur': 30},
    ),
    'La piste des marchands': const CityNode(
      name: 'La piste des marchands',
      connectedCities: {'Le coeur du désert': 30, 'Le champs des épines': 30, 'La porte du désert': 30},
    ),
    'Le champs des épines': const CityNode(
      name: 'Le champs des épines',
      connectedCities: {'La piste des marchands': 30, 'Les monts de Sahur': 30},
    ),
    'Les monts de Sahur': const CityNode(
      name: 'Les monts de Sahur',
      connectedCities: {'Le coeur du désert': 30, 'Le champs des épines': 30, 'L\'autel du soleil': 30},
    ),
    'La porte du désert': const CityNode(
      name: 'La porte du désert',
      connectedCities: {'La piste des marchands': 30, 'Le cimetières des géants': 30, 'Rive Calme': 30}, // Vers le lac
    ),
    'L\'autel du soleil': const CityNode(
      name: 'L\'autel du soleil',
      connectedCities: {'Les monts de Sahur': 30, 'Le bain du désert': 30, 'La grotte infini': 30},
    ),
    'Le bain du désert': const CityNode(
      name: 'Le bain du désert',
      connectedCities: {'L\'autel du soleil': 30, 'Le cimetières des géants': 30},
    ),
    'Le cimetières des géants': const CityNode(
      name: 'Le cimetières des géants',
      connectedCities: {'Le bain du désert': 30, 'La porte du désert': 30},
    ),
    'La grotte infini': const CityNode(
      name: 'La grotte infini',
      connectedCities: {'L\'autel du soleil': 30, 'Le passage secret': 30},
    ),
    'Le passage secret': const CityNode(
      name: 'Le passage secret',
      connectedCities: {'La grotte infini': 30, 'L\'oasis de l\'exil': 30},
    ),
    'L\'oasis de l\'exil': const CityNode(
      name: 'L\'oasis de l\'exil',
      connectedCities: {'Le passage secret': 30},
    ),

    // ==========================================
    // --- ZONE MONTAGNES (Orane) ---
    // ==========================================
    'La tombe oubliée': const CityNode(
      name: 'La tombe oubliée',
      connectedCities: {'Le ponton des brunes': 30},
    ),
    'Le ponton des brunes': const CityNode(
      name: 'Le ponton des brunes',
      connectedCities: {'La tombe oubliée': 30, 'La forêt d\'Orane': 30, 'Les ruines de garde-roc': 30},
    ),
    'Les ruines de garde-roc': const CityNode(
      name: 'Les ruines de garde-roc',
      connectedCities: {'Le ponton des brunes': 30, 'Le Ruisseau des murmures': 30},
    ),
    'Le Ruisseau des murmures': const CityNode(
      name: 'Le Ruisseau des murmures',
      connectedCities: {'Les ruines de garde-roc': 30, 'La grange au vent': 30, 'Le bosquet enchanté': 30, 'Le village de Néris': 30},
    ),
    'La grange au vent': const CityNode(
      name: 'La grange au vent',
      connectedCities: {'Le Ruisseau des murmures': 30, 'Le phare d\'Orane': 30}, 
    ),
    'Le phare d\'Orane': const CityNode(
      name: 'Le phare d\'Orane',
      connectedCities: {'La grange au vent': 30, 'Le campement de l\'île Sud': 30},
    ),
    'Le campement de l\'île Sud': const CityNode(
      name: 'Le campement de l\'île Sud',
      connectedCities: {'Le phare d\'Orane': 30},
    ),
    'Le bosquet enchanté': const CityNode(
      name: 'Le bosquet enchanté',
      connectedCities: {'Le Ruisseau des murmures': 30},
    ),
    'Le village de Néris': const CityNode(
      name: 'Le village de Néris',
      connectedCities: {'Le Ruisseau des murmures': 30, 'Le cercle des anciens': 30, 'L\'Halte blanche': 60, 'L\'île Aos Sé': 30},
    ),
    'L\'île Aos Sé': const CityNode(
      name: 'L\'île Aos Sé',
      connectedCities: {'Le village de Néris': 30, 'L\'épée Maudite': 60},
    ),
    'L\'épée Maudite': const CityNode(
      name: 'L\'épée Maudite',
      connectedCities: {'L\'île Aos Sé': 30},
    ),
    'Le cercle des anciens': const CityNode(
      name: 'Le cercle des anciens',
      connectedCities: {'Le village de Néris': 30, 'Le miroir d\'Emeraude': 30},
    ),
    'Le miroir d\'Emeraude': const CityNode(
      name: 'Le miroir d\'Emeraude',
      connectedCities: {'Le cercle des anciens': 30, 'L\'Antre d\'émeraude': 30},
    ),
    'L\'Antre d\'émeraude': const CityNode(
      name: 'L\'Antre d\'émeraude',
      connectedCities: {'Le miroir d\'Emeraude': 30},
    ),
    'L\'Halte blanche': const CityNode(
      name: 'L\'Halte blanche',
      connectedCities: {'Le village de Néris': 30, 'Les nacelles du Pics': 30},
    ),
    'Les nacelles du Pics': const CityNode(
      name: 'Les nacelles du Pics',
      connectedCities: {'Le refuge des neiges': 60, 'L\'Halte blanche': 30},
    ),
    'Le refuge des neiges': const CityNode(
      name: 'Le refuge des neiges',
      connectedCities: {'Les nacelles du Pics': 30, 'Le chateau d\'azur': 60},
    ),
    'Le chateau d\'azur': const CityNode(
      name: 'Le chateau d\'azur',
      connectedCities: {'Le refuge des neiges': 30, 'Le sommet d\'azur': 60},
    ),
    'Le sommet d\'azur': const CityNode(
      name: 'Le sommet d\'azur',
      connectedCities: {'Le chateau d\'azur': 30, 'La stelle des montagnes d\'Orane': 30},
    ),
    'La stelle des montagnes d\'Orane': const CityNode(
      name: 'La stelle des montagnes d\'Orane',
      connectedCities: {'L\'observatoire d\'Ouest': 30, 'Le sommet d\'azur': 30},
    ),
    'L\'observatoire d\'Ouest': const CityNode(
      name: 'L\'observatoire d\'Ouest',
      connectedCities: {'La stelle des montagnes d\'Orane': 30, 'La forêt d\'Orane': 60},
    ),
    'La forêt d\'Orane': const CityNode(
      name: 'La forêt d\'Orane',
      connectedCities: {'L\'observatoire d\'Ouest': 30, 'Le ponton des brunes': 30},
    ),

    // ==========================================
    // --- AUTRES ZONES (Connexions) ---
    // ==========================================
    'Rive Calme': const CityNode(
      name: 'Rive Calme',
      connectedCities: {'La porte du désert': 30, 'Sanctuaire Obscur': 30, 'Île Céleste': 30},
    ),
    'Sanctuaire Obscur': const CityNode(
      name: 'Sanctuaire Obscur',
      connectedCities: {'Rive Calme': 30},
    ),
    'Île Céleste': const CityNode(
      name: 'Île Céleste',
      connectedCities: {'Rive Calme': 30, 'Le village de Néris': 30},
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

        // Si on est en mode dev, on force le trajet à 1 minute, sinon on prend la vraie valeur (30)
        int weight = isDevMode ? 1 : entry.value;

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