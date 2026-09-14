import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CharacterCustomizerScreen extends StatefulWidget {
  const CharacterCustomizerScreen({super.key});

  @override
  State<CharacterCustomizerScreen> createState() => _CharacterCustomizerScreenState();
}

class _CharacterCustomizerScreenState extends State<CharacterCustomizerScreen> {
  Color _selectedOutfitColor = Colors.blue;
  String _selectedHat = 'Aucun';
  bool _loading = true;
  bool _saving = false;

  // ✨ NOUVEAU : J'ai ajouté les couleurs spécifiques de tes 5 régions à la palette
  final List<Color> _colors = [
    Colors.orange,          // Désert
    Colors.green,           // Montagnes
    Colors.blue,            // Eau
    Colors.deepPurple,      // Nocturne
    Colors.lightBlueAccent, // Nuages
    Colors.red,             // Extra
  ];
  
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

    Color loadedColor = Colors.blue;
    final colorValue = data?['characterColor'];
    
    // 1. On regarde si le joueur a DÉJÀ sauvegardé une couleur personnalisée
    if (colorValue is int) {
      loadedColor = Color(colorValue);
    } 
    // ✨ 2. NOUVEAU : Sinon (première fois), on prend la couleur de sa région de départ !
    else {
      final profileRegion = data?['profileRegion'] as String?;
      switch (profileRegion) {
        case 'desert': loadedColor = Colors.orange; break;
        case 'montagnes': loadedColor = Colors.green; break;
        case 'eau': loadedColor = Colors.blue; break;
        case 'nocturne': loadedColor = Colors.deepPurple; break;
        case 'nuages': loadedColor = Colors.lightBlueAccent; break;
        default: loadedColor = Colors.blue;
      }
    }

    setState(() {
      _selectedOutfitColor = loadedColor;
      _selectedHat = (data?['hat'] as String?) ?? 'Aucun';
      _loading = false;
    });
  }

  Future<void> _saveCharacter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'characterColor': _selectedOutfitColor.toARGB32(),
      'hat': _selectedHat,
    });

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context, true); // on renvoie "true" pour dire "ça a changé"
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

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
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.5),
                          border: Border.all(color: _selectedOutfitColor, width: 3),
                        ),
                        child: Center(
                          child: Icon(Icons.person, size: 80, color: _selectedOutfitColor),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            const Text('Couleur de la tenue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBlue)),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 50,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _colors.length,
                                itemBuilder: (context, index) {
                                  final color = _colors[index];
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() => _selectedOutfitColor = color);
                                    },
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _selectedOutfitColor == color ? Colors.white : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 30),
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
                              backgroundColor: focusOrange,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 0,
                            ),
                            onPressed: _saving
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
                                : const Text(
                                    'Enregistrer',
                                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
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