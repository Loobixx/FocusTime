import 'dart:ui';
import 'package:flutter/material.dart';
import 'profile_screen.dart'; // Vérifie que le nom du fichier est correct

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    return Scaffold(
      body: Stack(
        children: [
        // 1. Image de fond floutée
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // C'est ici que tu règles la puissance du flou
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  // Indique le chemin vers ton image
                  image: AssetImage('assets/fond2.png'), 
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // 2. Contenu de la page
          SafeArea(
            child: Column(
              children: [
                // --- AVATAR (Haut Droit) ---
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    // GestureDetector permet de rendre n'importe quel élément cliquable
                    child: GestureDetector(
                      onTap: () {
                        // Navigation vers la page de profil avec une animation de glissement classique
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: focusOrange, width: 3),
                        ),
                        child: const CircleAvatar(
                          backgroundColor: Colors.white70,
                          radius: 26,
                          child: Icon(Icons.person, color: Colors.grey, size: 36),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),

                // --- TITRE ---
                const Text(
                  'FocusTime',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                
                const Spacer(flex: 2),

                // --- BOUTON START FOCUS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: focusOrange,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // Action pour lancer le focus
                      },
                      child: const Text(
                        'START FOCUS',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.lineThrough
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- BOUTON MAP (Effet Verre) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 90),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: InkWell(
                        onTap: () {
                          // Action pour ouvrir la map
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                          ),
                          child: const Center(
                            child: Text(
                              'MAP',
                              style: TextStyle(
                                fontSize: 18,
                                color: darkBlue,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.lineThrough
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // --- CARTE D'INFORMATIONS DU BAS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3), // Légèrement blanc transparent
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Destination actuel :',
                              style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Temps restant :',
                              style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
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