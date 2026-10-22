// lib/models/companion.dart
import 'package:flutter/material.dart';

class Companion {
  final String id;
  final String name;
  final String unlockCity;      // La ville précise qui débloque ce compagnon
  final String region;          // 'lac', 'desert', 'montagnes', etc.
  final Color defaultColor;

  const Companion({
    required this.id,
    required this.name,
    required this.unlockCity,
    required this.region,
    required this.defaultColor,
  });
}

class CompanionData {
  static const List<Companion> allCompanions = [
    Companion(
      id: 'chien',
      name: 'Dogito',
      unlockCity: 'Le village de Néris', // Dans la forêt
      region: 'montagnes',
      defaultColor: Color(0xFFFF8A80),
    ),
    Companion(
      id: 'chat',
      name: 'Catito',
      unlockCity: 'Le village de Néris', // Dans la forêt
      region: 'montagnes',
      defaultColor: Color(0xFFFF8A80),
    ),
    Companion(
      id: 'oiseau',
      name: 'Birdito',
      unlockCity: 'Le village de Néris', // Dans la forêt
      region: 'montagnes',
      defaultColor: Color(0xFFFF8A80),
    ),
    Companion(
      id: 'lapin',
      name: 'Bunnyto',
      unlockCity: 'Le village de Néris', // Dans la forêt
      region: 'montagnes',
      defaultColor: Color(0xFFFF8A80),
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