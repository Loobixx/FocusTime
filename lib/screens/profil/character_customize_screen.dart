import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CharacterCustomizerScreen extends StatefulWidget {
  const CharacterCustomizerScreen({super.key});

  @override
  State<CharacterCustomizerScreen> createState() => _CharacterCustomizerScreenState();
}

class _CharacterCustomizerScreenState extends State<CharacterCustomizerScreen> {
  // Exemple d'attributs modifiables du personnage
  Color _selectedOutfitColor = Colors.blue;
  String _selectedHat = 'Aucun';

  final List<Color> _colors = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red];
  final List<String> _hats = ['Aucun', 'Casquette', 'Chapeau magique', 'Couronne'];

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fond flouté
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

          // 2. Contenu
          SafeArea(
            child: Column(
              children: [
                // Bouton retour
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

                // --- APERÇU DU PERSONNAGE (Avatar ou Sprites 2D superposés) ---
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.5),
                    border: Border.all(color: focusOrange, width: 3),
                  ),
                  child: Center(
                    // Ici tu pourras afficher ton personnage 2D ou des images superposées selon les choix
                    child: Icon(Icons.person, size: 80, color: _selectedOutfitColor),
                  ),
                ),

                const SizedBox(height: 30),

                // --- OPTIONS DE PERSONNALISATION ---
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
                        initialValue: _selectedHat,
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

                // --- BOUTON SAUVEGARDER ---
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
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        // TODO: Enregistrer les choix (SharedPreferences / Provider)
                        Navigator.pop(context);
                      },
                      child: const Text(
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