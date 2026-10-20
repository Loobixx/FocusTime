import 'dart:ui';
import 'package:focus_time/models/companion.dart';
import 'package:focus_time/screens/profile/companion/companion_selection_screen.dart';
import 'package:focus_time/screens/profile/delete_profil/delete_account_dialog.dart';
import 'package:focus_time/screens/profile/politique_de_confidentialit%C3%A9/privacy_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_time/screens/profile/about_profil/about_screen.dart';
import 'package:focus_time/screens/profile/character/character_customize_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../auth/login_screen.dart';
import 'package:focus_time/screens/profile/historique/history_screen.dart';
import 'package:focus_time/screens/profile/stat/stats_screen.dart';
import 'package:focus_time/screens/profile/change_password/auth_helper.dart';
import 'package:focus_time/screens/profile/notification/notification_settings_screen.dart';
import 'package:focus_time/services/audio_service.dart';
import 'package:focus_time/services/admin_access_service.dart';
import 'package:focus_time/screens/profile/admin/admin_management_screen.dart';
import 'package:focus_time/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _pseudo = '';
  Color _borderColor = Colors.deepPurple;
  String _characterId = 'nuit';
  bool _loading = true;
  final AdminAccessService _adminAccessService = AdminAccessService();
  late final Stream<bool> _adminStatusStream;

  @override
  void initState() {
    super.initState();
    _adminStatusStream = _adminAccessService.watchAdminStatus(
      FirebaseAuth.instance.currentUser?.email,
    );
    _loadPseudo();
  }

  Future<void> _loadPseudo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    String charId = (data?['characterId'] as String?) ?? 'nuit';

    Color themeColor = Colors.deepPurple;
    switch (charId) {
      case 'desert':
        themeColor = Colors.orange;
        break;
      case 'montagnes':
        themeColor = Colors.green;
        break;
      case 'lac':
        themeColor = Colors.blue;
        break;
      case 'nuages':
        themeColor = Colors.pinkAccent;
        break;
      case 'nuit':
      default:
        themeColor = Colors.deepPurple;
        break;
    }

    if (mounted) {
      setState(() {
        _pseudo = (data?['pseudo'] as String?) ?? '';
        _characterId = charId;
        _borderColor = themeColor;
        _loading = false;
      });
    }
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color darkBlue = Theme.of(context).colorScheme.primary;
    final Color panelColor = isDark
        ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.25);
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Email inconnu';

    return Scaffold(
      body: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/biome/fond1.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (isDark)
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.24)),
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
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark
                              ? Theme.of(context).colorScheme.outline
                              : Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(30),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.arrow_back_ios, color: darkBlue),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: _borderColor, width: 3.5),
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
                                            child: Image.asset(
                                              'assets/TeteProfil/$_characterId.jpg',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.black,
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
                                        style: TextStyle(
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
                                    icon: Icon(Icons.exit_to_app, color: darkBlue),
                                    onPressed: () async {
                                      await GoogleSignIn().signOut();
                                      await FirebaseAuth.instance.signOut();

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

                              StreamBuilder<bool>(
                                stream: _adminStatusStream,
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: Text(
                                        'Statut administrateur indisponible.',
                                        style: TextStyle(color: Colors.redAccent),
                                      ),
                                    );
                                  }
                                  if (snapshot.data != true) {
                                    return const SizedBox.shrink();
                                  }
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                const SizedBox(height: 12),
                                _buildMenuItem(
                                  Icons.admin_panel_settings,
                                  'Gérer les administrateurs',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AdminManagementScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                
                                // 🟢 BOUTON 1 : TOUT DÉBLOQUER
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.admin_panel_settings),
                                  label: const Text('Admin : Tout débloquer', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () async {
                                    final uid = FirebaseAuth.instance.currentUser?.uid;
                                    if (uid == null) return;

                                    // ✨ Récupère dynamiquement TOUS les IDs de compagnons depuis companion.dart
                                    List<String> allCompanionIds = CompanionData.allCompanions.map((c) => c.id).toList();

                                    await FirebaseFirestore.instance.collection('users').doc(uid).set({
                                      'unlockedCompanions': allCompanionIds, // 🐾 Insère toute la liste automatiquement
                                      'unlockedCharacters': ['nuit', 'desert', 'montagnes', 'lac', 'nuages'],
                                      'activeCompanion': allCompanionIds.isNotEmpty ? allCompanionIds.first : 'chien', // Met le premier en actif par défaut
                                    }, SetOptions(merge: true));

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('⚡ Tous les compagnons et biomes ont été débloqués !'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),

                                // 🔴 BOUTON 2 : MODE JOUEUR CLASSIQUE
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade800,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.person_outline),
                                  label: const Text('Admin : Vue Joueur Classique', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () async {
                                    final uid = FirebaseAuth.instance.currentUser?.uid;
                                    if (uid == null) return;

                                    await FirebaseFirestore.instance.collection('users').doc(uid).set({
                                      'unlockedCompanions': [], 
                                      'unlockedCharacters': ['nuit'], 
                                      'characterId': 'nuit',
                                      'characterColor': Colors.deepPurple.toARGB32(),
                                      'activeCompanion': FieldValue.delete(),
                                    }, SetOptions(merge: true));

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('👀 Vue classique restaurée. Personnages verrouillés.'), backgroundColor: Colors.orange));
                                      _loadPseudo(); 
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),
                                    ],
                                  );
                                },
                              ),

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
                                    _loadPseudo();
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
                                },
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: AudioManager().isMutedNotifier,
                                builder: (context, isMuted, child) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(15),
                                      clipBehavior: Clip.antiAlias,
                                      child: ListTile(
                                        leading: Icon(
                                          isMuted ? Icons.volume_off : Icons.volume_up,
                                          color: darkBlue,
                                          size: 26,
                                        ),
                                        title: Text(
                                          'Musique d\'ambiance',
                                          style: TextStyle(
                                            color: darkBlue,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        trailing: Switch(
                                          value: !isMuted,
                                          activeThumbColor: const Color(0xFFFF8C00),
                                          onChanged: (_) => AudioManager().toggleMute(),
                                        ),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        onTap: () => AudioManager().toggleMute(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuItem(
                                Icons.notifications_none,
                                'Son des notifications',
                                isAvailable: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                                  );
                                },
                              ),
                              _buildMenuItem(
                                Icons.dark_mode_outlined,
                                'Changer de thème',
                                isAvailable: true,
                                onTap: _showThemeDialog,
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
                              _buildMenuItem(
                                Icons.pets,
                                'Mes Compagnons',
                                isAvailable: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CompanionSelectionScreen()),
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  side: const BorderSide(color: Colors.redAccent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                ),
                                icon: const Icon(Icons.delete_forever, color: Colors.white),
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
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apparence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeChoice(dialogContext, ThemeMode.light, 'Clair', 'Utiliser le thème clair'),
            _buildThemeChoice(dialogContext, ThemeMode.dark, 'Sombre', 'Utiliser le thème sombre'),
            _buildThemeChoice(dialogContext, ThemeMode.system, 'Selon l’appareil', 'Suivre le réglage du téléphone'),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChoice(
    BuildContext dialogContext,
    ThemeMode themeMode,
    String title,
    String subtitle,
  ) {
    final bool selected = AppThemeController.mode.value == themeMode;
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      selected: selected,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? primaryColor : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () async {
        await AppThemeController.setMode(themeMode);
        if (dialogContext.mounted) Navigator.pop(dialogContext);
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isAvailable = true, VoidCallback? onTap}) {
    final Color darkBlue = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
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
      ),
    );
  }
}
