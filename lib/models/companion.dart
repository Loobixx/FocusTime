// lib/models/companion.dart
import 'package:flutter/material.dart';

class Companion {
  final String id;
  final String name;
  final String unlockCity;      // La ville précise qui débloque ce compagnon
  final String region;          // 'lac', 'desert', 'montagnes', etc.
  final String assetPath;
  final Color defaultColor;

  const Companion({
    required this.id,
    required this.name,
    required this.unlockCity,
    required this.region,
    required this.assetPath,
    required this.defaultColor,
  });
}

class CompanionData {
  static const List<Companion> allCompanions = [
    Companion(
      id: 'axolotl',
      name: 'Nami l\'Axolotl',
      unlockCity: 'La Source Magique', // Sur le lac
      region: 'lac',
      assetPath: 'assets/compagnons/axolotl.png',
      defaultColor: Color(0xFF4FC3F7),
    ),
    Companion(
      id: 'fennec',
      name: 'Pikou le Fennec',
      unlockCity: 'L\'oasis de l\'exil', // Dans le désert
      region: 'desert',
      assetPath: 'assets/compagnons/fennec.png',
      defaultColor: Color(0xFFFFB74D),
    ),
    Companion(
      id: 'chamois',
      name: 'Floki le Chamois',
      unlockCity: 'Le sommet d\'azur', // Dans les montagnes
      region: 'montagnes',
      assetPath: 'assets/compagnons/chamois.png',
      defaultColor: Color(0xFF81C784),
    ),
  ];

  static Companion? getById(String? id) {
    if (id == null) return null;
    try {
      return allCompanions.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}