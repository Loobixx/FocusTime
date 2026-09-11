import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:FocusTime/screens/focus_screen.dart';
import 'package:FocusTime/screens/map/map_screen.dart';
import 'package:FocusTime/screens/profil/profile_screen.dart';
import '../models/city_network.dart'; // NOUVEL IMPORT NÉCESSAIRE

class HomeScreen extends StatefulWidget {
  
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color? _borderColor;

@override
  void initState() {
    super.initState();
    _loadCharacterColor();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPseudo();
      _checkInterruptedTrip(); // On ajoute la vérification ici
    });
  }

  Future<void> _checkInterruptedTrip() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('travel')
        .doc('status')
        .get();

    // Si on lance l'appli et qu'un focus est resté actif, c'est qu'il a été interrompu !
    if (doc.exists && doc.data()?['isFocusActive'] == true) {
      // 1. On nettoie la base de données
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('travel')
          .doc('status')
          .update({
        'isFocusActive': false,
        'activeDestination': FieldValue.delete(),
        'endTime': FieldValue.delete(),
      });

      // 2. On affiche le message de perte
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🧭 Tu t\'es perdu !'),
            content: const Text('L\'application a été fermée pendant ton voyage. Ton trajet a été annulé et tu es de retour à ton point de départ.'),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Compris', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _loadCharacterColor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final colorValue = doc.data()?['characterColor'];

    if (colorValue is int && mounted) {
      setState(() => _borderColor = Color(colorValue));
    }
  }

  Future<void> _checkPseudo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final pseudo = doc.data()?['pseudo'] as String?;

    if ((pseudo == null || pseudo.trim().isEmpty) && mounted) {
      _showPseudoDialog();
    }
  }

  void _showPseudoDialog() {
    final TextEditingController pseudoController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Choisis ton pseudo'),
          content: TextField(
            controller: pseudoController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Pseudo'),
          ),
          actions: [
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

    return Scaffold(
      body: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/fond2.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                        _loadCharacterColor();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _borderColor ?? Colors.transparent,
                          width: 3,
                        ),
                      ),
                        child: const CircleAvatar(
                          backgroundColor: Colors.white70,
                          radius: 26,
                          child: Icon(Icons.person, color: Colors.grey, size: 36),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                const Text(
                  'FocusTime',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: focusOrange,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FocusScreen()),
                        );
                      },
                      child: const Text(
                        'START FOCUS',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 90),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MapScreen()),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: const Center(
                            child: Text(
                              'MAP',
                              style: TextStyle(
                                fontSize: 18,
                                color: darkBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                // --- CARTE DE VOYAGE EN BAS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .snapshots(),
                          builder: (context, userSnapshot) {
                            String currentCity = 'Valenciennes';
                            if (userSnapshot.hasData && userSnapshot.data!.exists) {
                              final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                              currentCity = data?['currentCity'] ?? 'Valenciennes';
                            }

                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .collection('travel')
                                  .doc('status')
                                  .snapshots(),
                              builder: (context, travelSnapshot) {
                                bool isFocusActive = false;
                                String? midRouteDestination;
                                String? activeDestination;
                                int midRouteProgress = 0; // Ajout pour le calcul

                                if (travelSnapshot.hasData && travelSnapshot.data!.exists) {
                                  final travelData = travelSnapshot.data!.data() as Map<String, dynamic>?;
                                  isFocusActive = travelData?['isFocusActive'] ?? false;
                                  midRouteDestination = travelData?['midRouteDestination'];
                                  activeDestination = travelData?['activeDestination'];
                                  midRouteProgress = travelData?['midRouteProgress'] ?? 0;
                                }

                                // --- GESTION DE LA POSITION ---
                                String displayPosition = currentCity;
                                if (isFocusActive && activeDestination != null) {
                                  displayPosition = '$currentCity ➔ $activeDestination';
                                } else if (midRouteDestination != null && midRouteDestination.isNotEmpty) {
                                  displayPosition = '$currentCity ➔ $midRouteDestination';
                                }

                                // --- CALCUL DU TEMPS RESTANT STATIQUE ---
                                int staticTimeRemaining = 0;
                                if (!isFocusActive && midRouteDestination != null) {
                                  int fullTime = CityNetwork.getAvailableDestinations(currentCity)[midRouteDestination] ?? 0;
                                  staticTimeRemaining = fullTime - midRouteProgress;
                                  if (staticTimeRemaining < 0) staticTimeRemaining = 0;
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Ligne 1 : Position
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Color(0xFFFF8C00), size: 22),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Position : ',
                                          style: TextStyle(fontSize: 15, color: const Color(0xFF143063).withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                                        ),
                                        Expanded(
                                          child: Text(
                                            displayPosition,
                                            style: const TextStyle(fontSize: 16, color: Color(0xFF143063), fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Ligne 2 : Statut
                                    Row(
                                      children: [
                                        Icon(
                                          isFocusActive ? Icons.warning_amber_rounded : Icons.nights_stay,
                                          color: isFocusActive ? Colors.redAccent : Colors.grey.shade600,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Statut : ',
                                          style: TextStyle(fontSize: 15, color: const Color(0xFF143063).withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          isFocusActive ? 'Focus en cours...' : 'Au repos sur le bas-côté',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isFocusActive ? Colors.redAccent : Colors.grey.shade700,
                                            fontWeight: isFocusActive ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Ligne 3 : Temps restant statique (S'affiche UNIQUEMENT si au repos sur un trajet)
                                    if (!isFocusActive && midRouteDestination != null) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.route, color: Color(0xFFFF8C00), size: 22),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Reste pour arriver : ',
                                            style: TextStyle(fontSize: 15, color: const Color(0xFF143063).withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            '$staticTimeRemaining min',
                                            style: const TextStyle(fontSize: 16, color: Color(0xFF143063), fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                );
                              },
                            );
                          },
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