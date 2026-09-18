import 'dart:ui';
import 'package:focus_time/screens/profil/delete_profil/delete_account_dialog.dart';
import 'package:focus_time/screens/profil/politique_de_confidentialit%C3%A9/privacy_policy_screen.dart';
import 'package:focus_time/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_time/screens/profil/about_profil/about_screen.dart';
import 'package:focus_time/screens/profil/character/character_customize_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../login_screen.dart';
import 'package:focus_time/screens/profil/historique/history_screen.dart';
import 'package:focus_time/screens/profil/stat/stats_screen.dart';
import 'package:focus_time/screens/profil/change_password/auth_helper.dart';
import 'package:focus_time/screens/profil/notification/notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Dans tes variables d'état _ProfileScreenState :
String _pseudo = '';
Color _borderColor = Colors.deepPurple; // Violet par défaut (Nuit)
String _characterId = 'nuit';
bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPseudo();
  }



// Dans _loadPseudo() :
Future<void> _loadPseudo() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final data = doc.data();

  // On récupère l'ID du personnage (ex: 'nuit', 'desert', 'montagnes'...)
  String charId = (data?['characterId'] as String?) ?? 'nuit';
  
  // On détermine la couleur de bordure selon le personnage choisi
  Color themeColor = Colors.deepPurple;
  switch (charId) {
    case 'desert': themeColor = Colors.orange; break;
    case 'montagnes': themeColor = Colors.green; break;
    case 'lac': themeColor = Colors.blue; break;
    case 'nuages': themeColor = Colors.pinkAccent; break;
    case 'nuit': default: themeColor = Colors.deepPurple; break;
  }

  setState(() {
    _pseudo = (data?['pseudo'] as String?) ?? '';
    _characterId = charId;
    _borderColor = themeColor;
    _loading = false;
  });
}

// 🧪 Fonction pour tester la notification avec image instantanément
  Future<void> _testerNotificationTest() async {
    await NotificationService().showNotification(
      id: 999,
      title: '🔥 Test de notification riche',
      body: 'Regarde cette magnifique image de région dans la notification !',
      imageAssetPath: 'assets/Notif/Notification_1.jpg', // Tu peux tester avec 'assets/lac.png', etc.
    );
  }

  void _showChangePseudoDialog() {
    final TextEditingController pseudoController = TextEditingController(text: _pseudo);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Changer mon pseudo'),
          content: TextField(
            controller: pseudoController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Pseudo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
              onPressed: () async {
                final value = pseudoController.text.trim();
                if (value.isEmpty) return;

                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'pseudo': value});
                }

                setState(() => _pseudo = value);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Valider', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Email inconnu';

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
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: darkBlue),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              Column(
                                children: [
                                  // ✨ Avatar agrandi et mis en valeur
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _borderColor, width: 3.5), // 👈 Utilise la vraie couleur du perso
                                      boxShadow: [
                                        BoxShadow(
                                          color: _borderColor.withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: SizedBox(
                                        width: 110,
                                        height: 110,
                                        // On essaie d'afficher l'image du personnage, si elle n'existe pas encore (silhouette), on met un fond noir avec une icône
                                        child: Image.asset(
                                          'assets/TeteProfil/$_characterId.jpg',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.black, // 👈 Silhouette noire en attendant le dessin
                                              child: const Icon(Icons.person, color: Colors.white70, size: 50),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _loading
                                        ? '...'
                                        : (_pseudo.isEmpty ? 'Sans pseudo' : _pseudo),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: darkBlue,
                                    ),
                                  ),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: darkBlue.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.exit_to_app, color: darkBlue),
                                onPressed: () async {
                                  await GoogleSignIn().signOut(); // Déconnecte la session Google
                                  await FirebaseAuth.instance.signOut(); // Déconnecte Firebase

                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                                      (Route<dynamic> route) => false,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),


                          _buildMenuItem(
                            Icons.edit,
                            'Modifier mon personnage',
                            isAvailable: true,
                            onTap: () async {
                              final changed = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CharacterCustomizerScreen()),
                              );
                              if (changed == true) {
                                _loadPseudo(); // recharge pseudo + couleur
                              }
                            },
                          ),
                          _buildMenuItem(
                            Icons.badge_outlined,
                            'Changer mon pseudo',
                            isAvailable: true,
                            onTap: _showChangePseudoDialog,
                          ),
                          _buildMenuItem(
                            Icons.bar_chart,
                            'Voir mes statistiques',
                            isAvailable: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const StatsScreen()),
                              );
                            },
                          ),
                          _buildMenuItem(
                            Icons.calendar_month,
                            'Historique de concentration',
                            isAvailable: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const HistoryScreen()),
                              );
                            },
                          ),
                          _buildMenuItem(
                            Icons.lock_outline,
                            'Changer le mot de passe',
                            isAvailable: true,
                            onTap: () {
                              AuthHelper.resetPassword(context);
                            }
                          ),
                          _buildMenuItem(
                            Icons.volume_up_outlined, 
                            'Son et vibration', 
                            isAvailable: false),
                          _buildMenuItem(
                            Icons.notifications_none, 
                            'Son des notifications', 
                            isAvailable: true, 
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                              );
                          }),
                          _buildMenuItem(
                            Icons.dark_mode_outlined, 
                            'Changer de thème', 
                            isAvailable: false
                          ),
                          _buildMenuItem(
                            Icons.info_outline,
                            'À propos de l\'application',
                            isAvailable: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AboutScreen()),
                              );
                            },
                          ),
                          _buildMenuItem(
                            Icons.privacy_tip_outlined,
                            'Politique de confidentialité',
                            isAvailable: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 32),

                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935), // Rouge franc
                              foregroundColor: Colors.white,
                              elevation: 0,
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            ),
                            icon: const Icon(Icons.delete_forever, color: Color.fromARGB(255, 255, 255, 255)),
                            label: const Text(
                              'Supprimer mon compte',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => DeleteAccountDialog.show(context),
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

  Widget _buildMenuItem(IconData icon, String title, {bool isAvailable = true, VoidCallback? onTap}) {
    const darkBlue = Color(0xFF143063);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        tileColor: Colors.transparent, 
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
        onTap: isAvailable ? onTap : null,
      ),
    );
  }
}