import 'dart:ui';
import 'package:FocusTime/screens/select_destination_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Nécessaire pour le retour haptique

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  // On initialise à 1h (60 minutes)
  int _focusMinutes = 60;

  // Fonction pour ajouter du temps
  void _addTime(int minutesToAdd) {
    HapticFeedback.lightImpact();
    setState(() {
      _focusMinutes += minutesToAdd;
      if (_focusMinutes > 480) {
        _focusMinutes = 480; // Plafond à 8h max
      }
    });
  }

  // Fonction pour enlever du temps (minimum 30 min)
  void _removeTime(int minutesToRemove) {
    HapticFeedback.lightImpact();
    setState(() {
      _focusMinutes -= minutesToRemove;
      if (_focusMinutes < 1) {
        _focusMinutes = 1; // Plancher à 1 minute min
      }
    });
  }

  // Exemple d'utilisation quand on clique sur "Lancer le focus"

  // Formatage avec "00m" forcé quand il y a des heures (ex: "1h 00m", "1h 30m") ou juste les minutes si < 1h
  String _formatDuration(int totalMinutes) {
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } else {
      return '${minutes}m';
    }
  }

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
                // --- BOUTON DE RETOUR ---
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

                // --- TITRE ---
                const Text(
                  'FocusTime',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),

                const Spacer(),

                // --- LE MINUTEUR (Cercle noir central avec effet verre) ---
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 195,
                        height: 195,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black87,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animation fluide du texte à chaque changement de durée
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                _formatDuration(_focusMinutes),
                                key: ValueKey<int>(_focusMinutes),
                                style: const TextStyle(
                                  fontSize: 36,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- PANNEAU DE CONTRÔLE (Effet Verre pour les boutons) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            // Ligne des Ajouts (+)
                            Row(
                              children: [
                                Expanded(child: _buildTimeButton('+30m', () => _addTime(30), Colors.blue.shade700)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTimeButton('+1h', () => _addTime(60), Colors.blue.shade700)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTimeButton('+2h', () => _addTime(120), Colors.blue.shade700)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Ligne des Soustractions (-)
                            Row(
                              children: [
                                Expanded(child: _buildTimeButton('-30m', () => _removeTime(30), Colors.red.shade700)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTimeButton('-1h', () => _removeTime(60), Colors.red.shade700)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTimeButton('-2h', () => _removeTime(120), Colors.red.shade700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // --- BOUTON CONFIRMER LA DURÉE ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
                        HapticFeedback.mediumImpact();
                        
                        // Navigation vers l'écran de choix des villes connectées avec la durée choisie
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SelectDestinationScreen(
                              selectedDurationMinutes: _focusMinutes,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Confirmer la durée',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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

  // Widget personnalisé pour des boutons de taille égale grâce à Expanded
  Widget _buildTimeButton(String label, VoidCallback onPressed, Color textColor) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center, // Centre le texte parfaitement
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}