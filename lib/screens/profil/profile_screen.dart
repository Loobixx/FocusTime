import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:FocusTime/screens/profil/about_screen.dart';
import 'package:FocusTime/screens/profil/character_customize_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _pseudo = '';
  Color? _borderColor;  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPseudo();
  }

  Future<void> _loadPseudo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    Color loadedColor = const Color(0xFFFF8C00);
    final colorValue = data?['characterColor'];
    if (colorValue is int) {
      loadedColor = Color(colorValue);
    }

    setState(() {
      _pseudo = (data?['pseudo'] as String?) ?? '';
      _borderColor = loadedColor;
      _loading = false;
    });
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
    const focusOrange = Color(0xFFFF8C00);
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
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _borderColor ?? Colors.transparent, width: 3),
                                    ),
                                    child: const CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.white70,
                                      child: Icon(Icons.person, size: 50, color: Colors.grey),
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
                          _buildMenuItem(Icons.bar_chart, 'Voir mes statistiques', isAvailable: false),
                          _buildMenuItem(Icons.calendar_month, 'Historique de concentration', isAvailable: false),
                          const SizedBox(height: 16),
                          _buildMenuItem(Icons.lock_outline, 'Changer le mot de passe', isAvailable: false),
                          _buildMenuItem(Icons.volume_up_outlined, 'Son et vibration', isAvailable: false),
                          _buildMenuItem(Icons.notifications_none, 'Son des notifications', isAvailable: false),
                          _buildMenuItem(Icons.dark_mode_outlined, 'Changer de thème', isAvailable: false),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 32),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                              ),
                            ),
                            child: const Text(
                              'Supprimer mon compte',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.lineThrough,
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
        onTap: isAvailable ? onTap : null,
      ),
    );
  }
}