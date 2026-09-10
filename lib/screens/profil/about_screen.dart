import 'dart:ui';
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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

          // 2. Contenu principal (La carte en verre)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --- EN-TÊTE : Retour et Titre ---
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: darkBlue),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Expanded(
                                child: Text(
                                  'À propos',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: darkBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48), // Équilibre visuel par rapport au bouton retour
                            ],
                          ),
                          const SizedBox(height: 24),

                          // --- LOGO OU ICÔNE DE L'APPLI ---
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                              border: Border.all(color: focusOrange, width: 2),
                            ),
                            child: const Icon(Icons.hourglass_empty, color: darkBlue, size: 40),
                          ),
                          const SizedBox(height: 16),

                          // --- NOM ET VERSION ---
                          const Text(
                            'FocusTime',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              fontSize: 14,
                              color: darkBlue.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // --- DESCRIPTION ---
                          Text(
                            'FocusTime est une application conçue pour t\'aider à rester productif, gérer ton temps de concentration efficacement et explorer des univers interactifs au fil de tes sessions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: darkBlue.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // --- SECTION DÉVELOPPEUR / INFOS ---
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Développé avec passion 💻',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: darkBlue,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Créé pour optimiser ton quotidien et lier productivité et aventure.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: darkBlue.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // --- COPYRIGHT ---
                          Text(
                            '© 2026 FocusTime. Tous droits réservés.',
                            style: TextStyle(
                              fontSize: 12,
                              color: darkBlue.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}