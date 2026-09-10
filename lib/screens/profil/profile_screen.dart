import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_time/screens/profil/about_screen.dart';
import 'package:flutter_time/screens/profil/character_customize_screen.dart';
import '../login_screen.dart'; // Vérifie bien que c'est le bon nom de fichier

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fond flouté 
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // C'est ici que tu règles la puissance du flou
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  // Indique le chemin vers ton image
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
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25), // Transparence ajustée
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --- EN-TÊTE : Retour, Avatar, Déconnexion ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: darkBlue),
                                onPressed: () {
                                  Navigator.pop(context); // Fait revenir à la page précédente
                                },
                              ),
                              
                              // Bloc Avatar + Noms
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: focusOrange, width: 3),
                                    ),
                                    child: const CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.white70,
                                      child: Icon(Icons.person, size: 50, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Yoann',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: darkBlue,
                                    ),
                                  ),
                                  Text(
                                    'yoann.dev@exemple.com',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: darkBlue.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                              
                             IconButton(
                                icon: const Icon(Icons.exit_to_app, color: darkBlue), 
                                onPressed: () {
                                  // 1. Ici, plus tard, tu ajouteras ton code pour déconnecter Firebase ou ton API
                                  
                                  // 2. Redirection vers le Login en détruisant l'historique
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                    (Route<dynamic> route) => false, // "false" veut dire : on supprime toutes les pages précédentes
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // --- LISTE DES PARAMÈTRES ---
                          
                          // Bloc 1 : Activité
                          _buildMenuItem(Icons.edit, 'Modifier mon personnage', 
                          isAvailable: true, 
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CharacterCustomizerScreen()),
                            );
                          },), // BARRÉ
                          _buildMenuItem(Icons.bar_chart, 'Voir mes statistiques', isAvailable: false), // BARRÉ
                          _buildMenuItem(Icons.calendar_month, 'Historique de concentration', isAvailable: false), // NORMAL (dispo par défaut)

                          const SizedBox(height: 16), // Espace de séparation entre les blocs

                          // Bloc 2 : Réglages
                          _buildMenuItem(Icons.lock_outline, 'Changer le mot de passe', isAvailable: false),
                          _buildMenuItem(Icons.volume_up_outlined, 'Son et vibration', isAvailable: false),
                          _buildMenuItem(Icons.notifications_none, 'Son des notifications', isAvailable: false),
                          _buildMenuItem(Icons.dark_mode_outlined, 'Changer de thème', isAvailable: false),

                          const SizedBox(height: 16),

                          // Bloc 3 : Informations
                          _buildMenuItem(
                            Icons.info_outline, 
                            'À propos de l\'application', 
                            isAvailable: true, // Devient disponible
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AboutScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 32),

                          // --- BOUTON SUPPRIMER ---
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)), // Petit contour rouge discret
                              ),
                            ),
                            child: const Text(
                              'Supprimer mon compte',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.lineThrough
                              ),
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

  // --- FONCTION MAGIQUE POUR LES LIGNES DE MENU ---
  // Cette fonction utilise ListTile pour tout aligner parfaitement
 // --- FONCTION MAGIQUE POUR LES LIGNES DE MENU ---
  // Ajout du paramètre optionnel "isAvailable" (vrai par défaut)
  Widget _buildMenuItem(IconData icon, String title, {bool isAvailable = true, VoidCallback? onTap}) {
    const darkBlue = Color(0xFF143063);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: isAvailable ? darkBlue : darkBlue.withValues(alpha: 0.4), size: 26),
        title: Text(
          title,
          style: TextStyle(
            color: isAvailable ? darkBlue : darkBlue.withValues(alpha: 0.4),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: isAvailable ? darkBlue.withValues(alpha: 0.5) : darkBlue.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        // Utilise l'action personnalisée si elle est disponible et que le menu est actif
        onTap: isAvailable ? onTap : null, 
      ),
    );
  }
}