/// Décor du camp associé à une zone du monde.
class CampBiome {
  final String id;
  final String background;
  final String expeditionFarBackground;
  final String expeditionGround;
  final double expeditionGroundOffsetFactor;

  const CampBiome({
    required this.id,
    required this.background,
    this.expeditionFarBackground = 'assets/biome/expedition/fond/fond_lointain_montagne.png',
    this.expeditionGround = 'assets/biome/expedition/sol/sol_proche_montagne.png',
    this.expeditionGroundOffsetFactor = 0,
  });
}

class CampBiomes {
  CampBiomes._();

  /// Décor utilisé quand la zone est inconnue ou que l'image n'existe pas.
  static const CampBiome fallback = CampBiome(
    id: 'default',
    background: 'assets/biome/fond2.png',
  );

  /// Un décor par zone (mêmes ids que les personnages : desert, montagnes,
  /// lac, nuages, nuit). Ajoute les images dans assets/biome/.
  static const Map<String, CampBiome> byZone = {
    'desert': CampBiome(id: 'desert', background: 'assets/biome/camp/camp_desert.png'),
    'montagnes': CampBiome(
      id: 'montagnes',
      background: 'assets/biome/camp/camp_montagnes.png',
      expeditionFarBackground: 'assets/biome/expedition/fond/fond_lointain_montagne.png',
      expeditionGround: 'assets/biome/expedition/sol/sol_proche_montagne.png',
      expeditionGroundOffsetFactor: 0,
    ),
    'lac': CampBiome(
      id: 'lac',
      background: 'assets/biome/camp/camp_lac.png',
      expeditionFarBackground: 'assets/biome/expedition/fond/fond_lointain_lac.png',
      expeditionGround: 'assets/biome/expedition/sol/sol_proche_lac.png',
      // Le chemin est dessiné plus bas dans l'image du lac ; on remonte
      // la couche pour aligner sa piste sur celle de la montagne.
      expeditionGroundOffsetFactor: 0,
    ),
    'nuages': CampBiome(id: 'nuages', background: 'assets/biome/camp/camp_nuages.png'),
    'nuit': CampBiome(id: 'nuit', background: 'assets/biome/camp/camp_nuit.png'),
  };

  /// Ville -> zone (générée depuis CityNetwork).
  static const Map<String, String> zoneByCity = {
    'Le port de commerce de Solaris': 'desert',
    'La cité Solaris': 'desert',
    'Le puits des Mirages': 'desert',
    'Le piège des sables': 'desert',
    'La stelle du desert de Sahur': 'desert',
    'Le coeur du désert': 'desert',
    'La piste des marchands': 'desert',
    'Le champs des épines': 'desert',
    'Les monts de Sahur': 'desert',
    'La porte du désert': 'desert',
    'L\'autel du soleil': 'desert',
    'Le bain du désert': 'desert',
    'Le cimetières des géants': 'desert',
    'La grotte infini': 'desert',
    'Le passage secret': 'desert',
    'L\'oasis de l\'exil': 'desert',
    'La tombe oubliée': 'montagnes',
    'Le ponton des brunes': 'montagnes',
    'Les ruines de garde-roc': 'montagnes',
    'Le Ruisseau des murmures': 'montagnes',
    'La grange au vent': 'montagnes',
    'Le phare d\'Orane': 'montagnes',
    'Le campement de l\'île Sud': 'montagnes',
    'Le bosquet enchanté': 'montagnes',
    'Le village de Néris': 'montagnes',
    'L\'île Aos Sé': 'montagnes',
    'L\'épée Maudite': 'montagnes',
    'Le cercle des anciens': 'montagnes',
    'Le miroir d\'Emeraude': 'montagnes',
    'L\'Antre d\'émeraude': 'montagnes',
    'L\'Halte blanche': 'montagnes',
    'Les nacelles du Pics': 'montagnes',
    'Le refuge des neiges': 'montagnes',
    'Le chateau d\'azur': 'montagnes',
    'Le sommet d\'azur': 'montagnes',
    'La stelle des montagnes d\'Orane': 'montagnes',
    'L\'observatoire d\'Ouest': 'montagnes',
    'La forêt d\'Orane': 'montagnes',
    'La stelle de Nayris': 'lac',
    'La pointe fleurie': 'lac',
    'Les vestiges d\'Aelion': 'lac',
    'La Source Magique': 'lac',
    'Les 4 tours de la forêt': 'lac',
    'Le bateau fantôme': 'lac',
    'La zone de plongée': 'lac',
    'Le voilier du lac': 'lac',
    'Le village Keltia': 'lac',
    'La cascade de Nayris': 'lac',
    'Rive Calme': 'lac',
    'Sanctuaire Obscur': 'nuit',
    'Île Céleste': 'nuages',
  };

  /// [zone] (champ Firestore `currentZone`, optionnel) est prioritaire sur la
  /// table ville -> zone.
  static CampBiome resolve({String? city, String? zone}) {
    final key = _normalize(zone) ?? zoneByCity[city?.trim()];
    return byZone[key] ?? fallback;
  }

  static String? _normalize(String? value) {
    if (value == null) return null;
    final s = value.trim().toLowerCase();
    return s.isEmpty ? null : s;
  }
}
