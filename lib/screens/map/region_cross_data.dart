class RegionCross {
  final String id;
  final String name;
  final double x;
  final double y;
  final double angle;
  final double size;

  const RegionCross({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    this.angle = 0.0,
    this.size = 28.0, // ← modifie ici pour changer la taille par défaut de toutes les croix
  });
}

class RegionCrossesData {
  static const Map<String, List<RegionCross>> crossesByRegion = {
    'montagnes': [
    ],
    'desert': [
      RegionCross(id: 'd1', name: 'Oasis Perdue', x: 300.0, y: 500.0, angle: 0.0, size: 50.0),
      RegionCross(id: 'd2', name: 'Dunes Brûlantes', x: 600.0, y: 900.0, angle: 30.0, size: 32.0),
    ],
    'lac': [
      RegionCross(id: 'l1', name: 'Rive Calme', x: 400.0, y: 600.0, angle: 10.0, size: 28.0),
    ],
    'nuit': [
      RegionCross(id: 'n1', name: 'Sanctuaire Obscur', x: 500.0, y: 700.0, angle: 60.0, size: 28.0),
    ],
    'nuages': [
      RegionCross(id: 'u1', name: 'Île Céleste', x: 550.0, y: 650.0, angle: 20.0, size: 28.0),
    ],
  };
}