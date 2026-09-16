import 'package:flutter/material.dart';

class CharacterOption {
  final String id;
  final String name;
  final Color themeColor;
  final String imagePath;
  final bool isUnlocked; // 👈 Indique si le personnage est débloqué ou non

  const CharacterOption({
    required this.id,
    required this.name,
    required this.themeColor,
    required this.imagePath,
    this.isUnlocked = false,
  });
}

class CharacterOptionsList {
  static const List<CharacterOption> characters = [
    CharacterOption(
      id: 'nuit',
      name: 'Royaume de la Nuit',
      themeColor: Colors.deepPurple,
      imagePath: 'assets/TeteProfil/nuit.jpg',
      isUnlocked: true, // Débloqué par défaut
    ),
    CharacterOption(
      id: 'desert',
      name: 'Sahur (Désert)',
      themeColor: Colors.orange,
      imagePath: 'assets/TeteProfil/desert.jpg', // Remplace par ton image quand tu l'auras
      isUnlocked: false, // À débloquer
    ),
    CharacterOption(
      id: 'montagnes',
      name: 'Orane (Montagnes)',
      themeColor: Colors.green,
      imagePath: 'assets/TeteProfil/montagnes.jpg',
      isUnlocked: false,
    ),
    CharacterOption(
      id: 'lac',
      name: 'Nayris (Lac)',
      themeColor: Colors.blue,
      imagePath: 'assets/TeteProfil/lac.jpg',
      isUnlocked: false,
    ),
    CharacterOption(
      id: 'nuages',
      name: 'Valoris (Nuages)',
      themeColor: Colors.pinkAccent,
      imagePath: 'assets/TeteProfil/nuages.jpg',
      isUnlocked: false,
    ),
  ];
}