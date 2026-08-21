import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_screen.dart'; // Vérifie bien que c'est le bon nom de fichier

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

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
                  image: AssetImage('fond1.png'), 
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
                        color: Colors.white.withOpacity(0.25), // Transparence ajustée
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
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
                                      color: darkBlue.withOpacity(0.7),
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
                          _buildMenuItem(Icons.edit, 'Modifier mon personnage', isAvailable: false), // BARRÉ
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
                          _buildMenuItem(Icons.info_outline, 'À propos de l\'application', isAvailable: false),

                          const SizedBox(height: 32),

                          // --- BOUTON SUPPRIMER ---
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)), // Petit contour rouge discret
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
  Widget _buildMenuItem(IconData icon, String title, {bool isAvailable = true}) {
    const darkBlue = Color(0xFF143063);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        // L'icône devient un peu transparente si indisponible
        leading: Icon(icon, color: isAvailable ? darkBlue : darkBlue.withOpacity(0.4), size: 26),
        title: Text(
          title,
          style: TextStyle(
            color: isAvailable ? darkBlue : darkBlue.withOpacity(0.4), // Texte grisé
            fontSize: 16,
            fontWeight: FontWeight.w500,
            // C'EST ICI QUE ÇA SE PASSE : Si pas dispo, on barre le texte
            decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: isAvailable ? darkBlue.withOpacity(0.5) : darkBlue.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        // On désactive le clic (null) si la fonctionnalité n'est pas prête
        onTap: isAvailable ? () {
          // Action quand on clique sur la ligne
        } : null, 
      ),
    );
  }
}