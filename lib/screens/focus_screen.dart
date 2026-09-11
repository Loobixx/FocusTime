import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'select_destination_screen.dart';
import '../utils/time_formatter.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  int _focusMinutes = 60;

  void _addTime(int minutesToAdd) {
    HapticFeedback.lightImpact();
    setState(() {
      _focusMinutes += minutesToAdd;
      if (_focusMinutes > 480) _focusMinutes = 480; // Plafond à 8h max
    });
  }

  void _removeTime(int minutesToRemove) {
    HapticFeedback.lightImpact();
    setState(() {
      _focusMinutes -= minutesToRemove;
      if (_focusMinutes < 30) _focusMinutes = 1; // Minimum 30 min
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    double progress = (_focusMinutes / 480).clamp(0.0, 1.0);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Image de fond floutée
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/fond2.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          // Voile d'ambiance pour uniformiser le contraste
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.12),
            ),
          ),

          // 2. Contenu centré
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // En-tête : Bouton retour & Titre
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new, color: darkBlue, size: 20),
                              ),
                            ),
                            const Text(
                              'FocusTime',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: darkBlue,
                                shadows: [
                                  Shadow(color: Colors.white70, blurRadius: 10),
                                ],
                              ),
                            ),
                            const SizedBox(width: 42), // Équilibre visuel
                          ],
                        ),
                      ),

                      const Spacer(flex: 1),

                      // Cadran moderne avec jauge circulaire
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Halo externe
                            Container(
                              width: 270,
                              height: 270,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.25),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                            ),
                            // Indicateur de progression orange
                            SizedBox(
                              width: 246,
                              height: 246,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 6,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(focusOrange),
                              ),
                            ),
                            // Disque intérieur sombre
                            Container(
                              width: 215,
                              height: 215,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1E2430),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      formatMinutesToHours(_focusMinutes),
                                      key: ValueKey<int>(_focusMinutes),
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'CARBURANT',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 1),

                      // Panneau de boutons de réglage (+ / -)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Ligne Ajouts (+)
                                Row(
                                  children: [
                                    Expanded(child: _buildTimeButton('+30m', () => _addTime(30), Colors.blue.shade800)),
                                    const SizedBox(width: 10),
                                    Expanded(child: _buildTimeButton('+1h', () => _addTime(60), Colors.blue.shade800)),
                                    const SizedBox(width: 10),
                                    Expanded(child: _buildTimeButton('+2h', () => _addTime(120), Colors.blue.shade800)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Ligne Retraits (-)
                                Row(
                                  children: [
                                    Expanded(child: _buildTimeButton('-30m', () => _removeTime(30), Colors.red.shade700)),
                                    const SizedBox(width: 10),
                                    Expanded(child: _buildTimeButton('-1h', () => _removeTime(60), Colors.red.shade700)),
                                    const SizedBox(width: 10),
                                    Expanded(child: _buildTimeButton('-2h', () => _removeTime(120), Colors.red.shade700)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 1),

                      // Bouton Confirmer la durée
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: focusOrange,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton(String label, VoidCallback onPressed, Color textColor) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
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