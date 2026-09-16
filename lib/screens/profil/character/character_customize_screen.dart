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
  String _selectedHat = 'Aucun';
  bool _loading = true;
  bool _saving = false;
  
  final List<String> _hats = ['Aucun', 'Casquette', 'Chapeau magique', 'Couronne'];

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
      _selectedHat = (data?['hat'] as String?) ?? 'Aucun';
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

    // Sécurité : on empêche d'enregistrer un personnage non débloqué
    if (!selectedChar.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce personnage n\'est pas encore débloqué !')),
      );
      return;
    }

    setState(() => _saving = true);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'characterId': _selectedCharacterId,
      'characterColor': selectedChar.themeColor.toARGB32(),
      'hat': _selectedHat,
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

    return Scaffold(
      body: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/fond1.png'),
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
                          child: currentChar.isUnlocked
                              ? Image.asset(currentChar.imagePath, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.person, size: 70, color: Colors.grey))
                              : Container(
                                  color: Colors.black, // 👈 Silhouette noire
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
                            
                            // Liste horizontale des 5 personnages
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: CharacterOptionsList.characters.length,
                                itemBuilder: (context, index) {
                                  final character = CharacterOptionsList.characters[index];
                                  final bool isSelected = _selectedCharacterId == character.id;

                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      if (character.isUnlocked) {
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
                                                // 🎨 ICI : On utilise la couleur du personnage si il est sélectionné, sinon transparent
                                                color: isSelected ? character.themeColor : Colors.transparent,
                                                width: 3.5,
                                              ),
                                            ),
                                            child: ClipOval(
                                              child: character.isUnlocked
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
                                              color: character.isUnlocked ? darkBlue : Colors.grey,
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
                            const Text('Accessoire / Chapeau', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBlue)),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _hats.contains(_selectedHat) ? _selectedHat : 'Aucun',
                              dropdownColor: Colors.white.withValues(alpha: 0.9),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.7),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              ),
                              items: _hats.map((hat) {
                                return DropdownMenuItem(value: hat, child: Text(hat, style: const TextStyle(color: darkBlue)));
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  HapticFeedback.lightImpact();
                                  setState(() => _selectedHat = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentChar.isUnlocked ? focusOrange : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 0,
                            ),
                            onPressed: (_saving || !currentChar.isUnlocked)
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
                                    currentChar.isUnlocked ? 'Enregistrer' : '🔒 Personnage verrouillé',
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