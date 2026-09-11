class CityNode {
  final String name;
  // La clé est le nom de la ville de destination.
  // La valeur est le temps de trajet en minutes.
  final Map<String, int> connectedCities; 

  const CityNode({
    required this.name,
    required this.connectedCities,
  });
}

class CityNetwork {
  static final Map<String, CityNode> network = {
    // 🌍 --- VILLES RÉELLES ---
    'Valenciennes': CityNode(
      name: 'Valenciennes',
      connectedCities: {'Lille': 1, 'Arras': 1, 'Cambrai': 1},
    ),
    'Lille': CityNode(
      name: 'Lille',
      connectedCities: {'Valenciennes': 1, 'Dunkerque': 1, 'Calais': 1},
    ),
    'Arras': CityNode(
      name: 'Arras',
      connectedCities: {'Valenciennes': 1, 'Amiens': 1, 'Paris': 1},
    ),
    'Cambrai': CityNode(
      name: 'Cambrai',
      connectedCities: {'Valenciennes': 1, 'Saint-Quentin': 1},
    ),
    'Dunkerque': CityNode(
      name: 'Dunkerque',
      connectedCities: {'Lille': 1},
    ),
    'Calais': CityNode(
      name: 'Calais',
      connectedCities: {'Lille': 1},
    ),
    'Amiens': CityNode(
      name: 'Amiens',
      connectedCities: {'Arras': 1, 'Rouen': 1, 'Paris': 1},
    ),
    'Saint-Quentin': CityNode(
      name: 'Saint-Quentin',
      connectedCities: {'Cambrai': 1, 'Reims': 1},
    ),
    'Rouen': CityNode(
      name: 'Rouen',
      connectedCities: {'Amiens': 1, 'Paris': 1},
    ),
    'Reims': CityNode(
      name: 'Reims',
      connectedCities: {'Saint-Quentin': 1, 'Paris': 1},
    ),
    'Paris': CityNode(
      name: 'Paris',
      connectedCities: {'Arras': 1, 'Amiens': 1, 'Rouen': 1, 'Reims': 1, 'Lyon': 1, 'Eldoria': 1},
    ),
    'Lyon': CityNode(
      name: 'Lyon',
      connectedCities: {'Paris': 1, 'Solaris': 1},
    ),

    // 🌌 --- VILLES IMAGINAIRES (Temps de trajet plus longs pour le challenge) ---
    'Eldoria': CityNode(
      name: 'Eldoria',
      connectedCities: {'Paris': 1, 'Chronos': 1, 'Lumina': 1},
    ),
    'Chronos': CityNode(
      name: 'Chronos',
      connectedCities: {'Eldoria': 1, 'Nebula': 1},
    ),
    'Lumina': CityNode(
      name: 'Lumina',
      connectedCities: {'Eldoria': 1, 'Atlantis': 1},
    ),
    'Solaris': CityNode(
      name: 'Solaris',
      connectedCities: {'Lyon': 1, 'Nebula': 1},
    ),
    'Nebula': CityNode(
      name: 'Nebula',
      connectedCities: {'Chronos': 1, 'Solaris': 1, 'Zenith': 1},
    ),
    'Atlantis': CityNode(
      name: 'Atlantis',
      connectedCities: {'Lumina': 1, 'Zenith': 1},
    ),
    'Zenith': CityNode(
      name: 'Zenith',
      connectedCities: {'Nebula': 1, 'Atlantis': 1}, 
    ),
  };

  // Récupérer les villes adjacentes avec leur durée
  static Map<String, int> getAvailableDestinations(String currentCity) {
    return network[currentCity]?.connectedCities ?? {};
  }
}