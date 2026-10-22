import 'dart:ui' show Offset, Size;

class CampElementLayout {
  final Offset position; // Position en pourcentage (0.0 à 1.0) pour que ça s'adapte à l'écran
  final Size size;       // Taille de base en pixels fixes
  final double scale;    // Multiplicateur simple pour grossir/réduire

  const CampElementLayout({
    required this.position,
    required this.size,
    this.scale = 1.0,
  });

  CampElementLayout copyWith({Offset? position, Size? size, double? scale}) {
    return CampElementLayout(
      position: position ?? this.position,
      size: size ?? this.size,
      scale: scale ?? this.scale,
    );
  }

  Map<String, double> toMap() => {
    'x': position.dx,
    'y': position.dy,
    'width': size.width,
    'height': size.height,
    'scale': scale,
  };

  factory CampElementLayout.fromMap(Map<String, dynamic> map) {
    return CampElementLayout(
      position: Offset(
        (map['x'] as num?)?.toDouble() ?? 0,
        (map['y'] as num?)?.toDouble() ?? 0,
      ),
      size: Size(
        (map['width'] as num?)?.toDouble() ?? 0,
        (map['height'] as num?)?.toDouble() ?? 0,
      ),
      scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class CampLayoutConfig {
  final CampElementLayout tent;
  final CampElementLayout campfire;
  final CampElementLayout character;
  final CampElementLayout animalEnclosure;

  const CampLayoutConfig({
    required this.tent,
    required this.campfire,
    required this.character,
    required this.animalEnclosure,
  });

  static const CampLayoutConfig defaults = CampLayoutConfig(
    // Tente : position en %, taille en pixels fixes, scale pour ajuster
    tent: CampElementLayout(
      position: Offset(-0.05, 0.43),
      size: Size(160, 140), // 👈 Taille en pixels fixes
      scale: 1,           // 👈 Multiplicateur (augmente pour grossir)
    ),
    // Feu de camp
    campfire: CampElementLayout(
      position: Offset(0.42, 0.50),
      size: Size(64, 64),
      scale: 1.0,
    ),
    // Personnage sur le chemin
    character: CampElementLayout(
      position: Offset(0.3, 0.4), 
      size: Size(80, 120),  // 👈 Taille en pixels fixes de base
      scale: 3,           // 👈 Modifie ce nombre pour l'agrandir ou le réduire facilement !
    ),
    // L'enclos
    animalEnclosure: CampElementLayout(
      position: Offset(0.62, 0.47),
      size: Size(180, 150), // Taille en pixels fixes
      scale: 0.8,           // Multiplicateur
    ),
  );

  CampLayoutConfig copyWith({
    CampElementLayout? tent,
    CampElementLayout? campfire,
    CampElementLayout? character,
    CampElementLayout? animalEnclosure,
  }) {
    return CampLayoutConfig(
      tent: tent ?? this.tent,
      campfire: campfire ?? this.campfire,
      character: character ?? this.character,
      animalEnclosure: animalEnclosure ?? this.animalEnclosure,
    );
  }

  Map<String, dynamic> toMap() => {
    'tent': tent.toMap(),
    'campfire': campfire.toMap(),
    'character': character.toMap(),
    'animalEnclosure': animalEnclosure.toMap(),
  };

  factory CampLayoutConfig.fromMap(Map<String, dynamic> map) {
    CampElementLayout element(String key, CampElementLayout fallback) {
      final value = map[key];
      return value is Map<String, dynamic>
          ? CampElementLayout.fromMap(value)
          : fallback;
    }

    return CampLayoutConfig(
      tent: element('tent', defaults.tent),
      campfire: element('campfire', defaults.campfire),
      character: element('character', defaults.character),
      animalEnclosure: element('animalEnclosure', defaults.animalEnclosure),
    );
  }
}