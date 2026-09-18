import 'dart:ui';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);

    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      body: Stack(
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Image.asset(
                'assets/fond2.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
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
                      const SizedBox(width: 16),
                      const Text(
                        'Confidentialité',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                          shadows: [Shadow(color: Colors.white70, blurRadius: 8)],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Politique de confidentialité — FocusTime',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBlue),
                              ),
                              SizedBox(height: 6),
                              Text('Dernière mise à jour : 18 septembre 2026', style: TextStyle(fontSize: 12, color: Colors.black54)),
                              Divider(height: 24),
                              _Section(
                                title: '1. Responsable du traitement',
                                content: 'FocusTime est développé de manière indépendante. Contact : loobix1@gmail.com',
                              ),
                              _Section(
                                title: '2. Données collectées',
                                content: '• Compte : e-mail, identifiant Google (le cas échéant), pseudo.\n'
                                    '• Jeu et progression : historique des sessions de concentration, villes débloquées, avatar.\n'
                                    '• Technique : autorisations pour le réveil d\'écran (session active) et notifications locales (rappels de pause).\n\n'
                                    'Aucune donnée GPS réelle n\'est collectée.',
                              ),
                              _Section(
                                title: '3. Utilisation des données',
                                content: 'Vos données servent uniquement au fonctionnement de l\'application, à la sauvegarde de votre progression via Firebase et à la gestion de vos sessions.',
                              ),
                              _Section(
                                title: '4. Partage et sécurité',
                                content: 'Aucune donnée n\'est cédée à des tiers à des fins commerciales ou publicitaires. L\'hébergement sécurisé est assuré par Google Firebase.',
                              ),
                              _Section(
                                title: '5. Vos droits',
                                content: 'Conformément au RGPD, vous disposez d\'un droit d\'accès, de modification et de suppression totale de votre compte simplement en cliquant sur le bouton "Supprimer mon compte" dans les paramètres.',
                              ),
                            ],
                          ),
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

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF143063)),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}