import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'character_options.dart';

class CharacterCustomizerScreen extends StatefulWidget {
  const CharacterCustomizerScreen({super.key});

  @override
  State<CharacterCustomizerScreen> createState() => _CharacterCustomizerScreenState();
}

class _CharacterCustomizerScreenState extends State<CharacterCustomizerScreen> {
  String _selectedCharacterId = 'nuit';
  bool _loading = true;
  bool _saving = false;
  
  // 👈 NOUVEAU : Liste dynamique des personnages débloqués dans Firestore
  List<String> _unlockedCharacters = ['nuit']; 
  
  @override
  void initState() {
    super.initState();
    _loadCharacter();
  }

  Future<void> _loadCharacter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    String loadedCharacterId = (data?['characterId'] as String?) ?? 'nuit';

    setState(() {
      _selectedCharacterId = loadedCharacterId;
      // 👈 NOUVEAU : Récupération de la liste des déblocages depuis Firestore
      _unlockedCharacters = List<String>.from(data?['unlockedCharacters'] ?? ['nuit']);
      _loading = false;
    });
  }

  Future<void> _saveCharacter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final selectedChar = CharacterOptionsList.characters.firstWhere(
      (c) => c.id == _selectedCharacterId,
      orElse: () => CharacterOptionsList.characters.first,
    );

    // 👈 NOUVEAU : On vérifie avec la liste Firestore, plus avec character.isUnlocked
    if (!_unlockedCharacters.contains(selectedChar.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce personnage n\'est pas encore débloqué !')),
      );
      return;
    }

    setState(() => _saving = true);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'characterId': _selectedCharacterId,
      'characterColor': selectedChar.themeColor.toARGB32(),
    });

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    final currentChar = CharacterOptionsList.characters.firstWhere(
      (c) => c.id == _selectedCharacterId,
      orElse: () => CharacterOptionsList.characters.first,
    );

    // 👈 NOUVEAU : Variable locale pour savoir si le personnage au centre est débloqué
    final isCurrentCharUnlocked = _unlockedCharacters.contains(currentChar.id);

    return Scaffold(
      body: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/biome/fond1.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: darkBlue),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      const Text(
                        'Mon Personnage',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkBlue),
                      ),
                      const SizedBox(height: 20),
                      
                      // Aperçu du personnage (Silhouette noire si verrouillé, image normale si débloqué)
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: currentChar.themeColor, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: currentChar.themeColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: isCurrentCharUnlocked // 👈 Utilise la vérification Firestore
                              ? Image.asset(currentChar.imagePath, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.person, size: 70, color: Colors.grey))
                              : Container(
                                  color: Colors.black, // Silhouette noire
                                  child: const Icon(Icons.lock, color: Colors.white, size: 40),
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            const Text('Choix du personnage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBlue)),
                            const SizedBox(height: 10),
                            
                            // Liste horizontale des personnages
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: CharacterOptionsList.characters.length,
                                itemBuilder: (context, index) {
                                  final character = CharacterOptionsList.characters[index];
                                  final bool isSelected = _selectedCharacterId == character.id;
                                  
                                  // 👈 NOUVEAU : Vérifie si le biome courant est dans la liste de l'utilisateur
                                  final bool isUnlocked = _unlockedCharacters.contains(character.id); 

                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      if (isUnlocked) {
                                        setState(() => _selectedCharacterId = character.id);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('🔒 ${character.name} est verrouillé !')),
                                        );
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 16),
                                      child: Column(
                                        children: [
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                width: 65,
                                                height: 65,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected ? character.themeColor : Colors.transparent,
                                                    width: 3.5,
                                                  ),
                                                ),
                                                child: ClipOval(
                                                  child: isUnlocked // 👈 Utilise la vérification Firestore
                                                      ? Image.asset(character.imagePath, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.person))
                                                      : Container(
                                                          color: Colors.black,
                                                          child: const Icon(Icons.lock, color: Colors.white, size: 24),
                                                        ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            character.name.split(' ')[0], // Affiche juste le premier mot pour que ce soit court
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isUnlocked ? darkBlue : Colors.grey, // 👈 Utilise la vérification Firestore
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrentCharUnlocked ? focusOrange : Colors.grey, // 👈 Utilise la vérification Firestore
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 0,
                            ),
                            onPressed: (_saving || !isCurrentCharUnlocked) // 👈 Utilise la vérification Firestore
                                ? null
                                : () {
                                    HapticFeedback.mediumImpact();
                                    _saveCharacter();
                                  },
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    isCurrentCharUnlocked ? 'Enregistrer' : '🔒 Personnage verrouillé', // 👈 Utilise la vérification Firestore
                                    style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}