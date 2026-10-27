// lib/models/companion.dart
import 'package:flutter/material.dart';

class Companion {
  final String id;
  final String name;
  final String unlockCity;      // La ville précise qui débloque ce compagnon
  final String region;          // 'lac', 'desert', 'montagnes', etc.
  final Color defaultColor;
  final String walkDirectory;
  final int walkFrameCount;
  final String idleDirectory;
  final int idleFrameCount;
  final String? unselectedIdleDirectory;
  final int unselectedIdleFrameCount;
  final String campImagePath;

  const Companion({
    required this.id,
    required this.name,
    required this.unlockCity,
    required this.region,
    required this.defaultColor,
    required this.walkDirectory,
    this.walkFrameCount = 6,
    required this.idleDirectory,
    this.idleFrameCount = 8,
    this.unselectedIdleDirectory,
    this.unselectedIdleFrameCount = 18,
    required this.campImagePath,
  });

  List<String> animationFrames({required bool moving, required bool selected}) {
    final directory = moving
        ? walkDirectory
        : (!selected && unselectedIdleDirectory != null
              ? unselectedIdleDirectory!
              : idleDirectory);
    final frameCount = moving
        ? walkFrameCount
        : (!selected && unselectedIdleDirectory != null
              ? unselectedIdleFrameCount
              : idleFrameCount);
    return List.generate(frameCount, (index) => '$directory/$index.png');
  }
}

class CompanionData {
  static const List<Companion> allCompanions = [
    Companion(
      id: 'chien',
      name: 'Dogito',
      unlockCity: 'Le village de Néris', // Dans la forêt
      region: 'montagnes',
      defaultColor: Color(0xFFFF8A80),
      walkDirectory: 'assets/compagnons/Chien/chien_marche',
      idleDirectory: 'assets/compagnons/Chien/chien_arret',
      unselectedIdleDirectory: 'assets/compagnons/Chien/chien_arret_non_choisi',
      campImagePath: 'assets/compagnons/Chien/chien_arret/1.png',
    ),
    Companion(
      id: 'husky',
      name: 'Azur',
      unlockCity: 'Le village de Néris', // Dans la forêt
      region: 'montagnes',
      defaultColor: Color.fromARGB(255, 4, 253, 245),
      walkDirectory: 'assets/compagnons/Husky/husky_marche',
      idleDirectory: 'assets/compagnons/Husky/husky_arret',
      campImagePath: 'assets/compagnons/Husky/husky_arret/1.png',
    ),
    Companion(
      id: 'husky_beige',
      name: 'huskyto',
      unlockCity: 'Le village de Néris', // Dans la forêt
      region: 'montagnes',
      defaultColor: Color.fromARGB(255, 255, 255, 255),
      walkDirectory: 'assets/compagnons/Husky_beige/husky_beige_marche',
      idleDirectory: 'assets/compagnons/Husky_beige/husky_beige_arret',
      campImagePath: 'assets/compagnons/Husky_beige/husky_beige_arret/1.png',
    ),
    Companion(
      id: 'renard',
      name: 'Renardo',
      unlockCity: 'Le bosquet enchanté',
      region: 'montagnes',
      defaultColor: Color(0xFFFF8A00),
      walkDirectory: 'assets/compagnons/Renard/renard_marche',
      idleDirectory: 'assets/compagnons/Renard/renard_arret',
      unselectedIdleDirectory: 'assets/compagnons/Renard/renard_arret_non_choisi',
      campImagePath: 'assets/compagnons/Renard/renard_arret/0.png',
    ),
  ];

  static Companion? getById(String? id) {
    if (id == null) return null;
    final normalizedId = id.toLowerCase();
    try {
      return allCompanions.firstWhere((c) => c.id == normalizedId);
    } catch (_) {
      return null;
    }
  }
}
