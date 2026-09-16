import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 Importe Firebase Auth

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 📧 Récupère l'email de l'utilisateur connecté
    final String email = FirebaseAuth.instance.currentUser?.email ?? '';

    // ✨ Personnalisation en fonction de l'email
    // (Remplace 'ton.email@gmail.com' et 'lise.email@gmail.com' par vos vraies adresses)
    bool isLise = email == 'lise.adam.va@gmail.com'; 

    // Couleurs adaptées selon la personne
    final Color darkBlue = isLise ? const Color(0xFF4A148C) : const Color(0xFF143063); // Violet pour Lise, Bleu pour toi
    final Color focusOrange = isLise ? Colors.pinkAccent : const Color(0xFFFF8C00); // Rose pour Lise, Orange pour toi

    // Textes adaptés selon la personne
    final String appSubtitle = isLise 
        ? 'Créé avec amour pour accompagner tes sessions de productivité et tes aventures magiques ❤️!'
        : 'Créé pour optimiser ton quotidien et lier productivité et aventure.';

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
                                icon: Icon(Icons.arrow_back_ios, color: darkBlue),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
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
                              const SizedBox(width: 48),
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
                            child: Icon(Icons.hourglass_empty, color: darkBlue, size: 40),
                          ),
                          const SizedBox(height: 16),

                          // --- NOM ET VERSION ---
                          Text(
                            isLise ? 'FocusTime (Version Lise)' : 'FocusTime',
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
                            isLise ? 'FocusTime est une application conçue pour t\'aider à rester productif, gérer ton temps de concentration efficacement et explorer des univers interactifs au fil de tes sessions. Je t\'aime du plus profond de mon cœur ❤️! Et je veux que grâce a cette application, tu reussisse à travailler et à te concentrer.' : 'FocusTime est une application conçue pour t\'aider à rester productif, gérer ton temps de concentration efficacement et explorer des univers interactifs au fil de tes sessions.',
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
                                Text(
                                  isLise ? 'Version Personnalisée ✨' : 'Développé avec passion 💻',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: darkBlue,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  appSubtitle,
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