import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/companion.dart';
import '../../../widgets/companion_widget.dart';

class CompanionSelectionScreen extends StatefulWidget {
  const CompanionSelectionScreen({super.key});

  @override
  State<CompanionSelectionScreen> createState() => _CompanionSelectionScreenState();
}

class _CompanionSelectionScreenState extends State<CompanionSelectionScreen> {
  static const darkBlue = Color(0xFF143063);
  static const focusOrange = Color(0xFFFF8C00);

  String? _activeCompanion;
  List<String> _unlockedCompanions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserCompanions();
  }

  Future<void> _loadUserCompanions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    if (mounted) {
      setState(() {
        _activeCompanion = data?['activeCompanion'] as String?;
        _unlockedCompanions = List<String>.from(data?['unlockedCompanions'] ?? []);
        _loading = false;
      });
    }
  }

  Future<void> _setActiveCompanion(String? companionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _activeCompanion = companionId);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'activeCompanion': companionId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fond flouté
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
            child: Column(
              children: [
                // En-tête
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
                        'Mes Compagnons',
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

                // Aperçu du compagnon actif
                if (_activeCompanion != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: CompanionWidget(companionId: _activeCompanion),
                  ),
                  Text(
                    'Compagnon équipé : ${CompanionData.getById(_activeCompanion)?.name ?? ""}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: darkBlue),
                  ),
                ],

                const SizedBox(height: 16),

                // Grille des animaux disponibles et verrouillés
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: focusOrange))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: CompanionData.allCompanions.length,
                          itemBuilder: (context, index) {
                            final companion = CompanionData.allCompanions[index];
                            final isUnlocked = _unlockedCompanions.contains(companion.id);
                            final isEquipped = _activeCompanion == companion.id;

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: isUnlocked ? 0.7 : 0.35),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isEquipped ? focusOrange : Colors.white.withValues(alpha: 0.6),
                                      width: isEquipped ? 2.5 : 1.5,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: isUnlocked
                                            ? Image.asset(
                                                companion.assetPath,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.pets, size: 50, color: darkBlue),
                                              )
                                            : const Icon(Icons.lock, size: 48, color: Colors.black38),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        companion.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isUnlocked ? darkBlue : Colors.black45,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isUnlocked
                                            ? (isEquipped ? 'Équipé ✨' : 'Débloqué')
                                            : 'Trouve-le à :\n${companion.unlockCity}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isEquipped ? focusOrange : Colors.black54,
                                          fontWeight: isEquipped ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (isUnlocked && !isEquipped) ...[
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          height: 28,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: focusOrange,
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () => _setActiveCompanion(companion.id),
                                            child: const Text('Choisir', style: TextStyle(fontSize: 12, color: Colors.white)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
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