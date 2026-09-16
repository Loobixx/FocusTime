import 'dart:ui';
import 'package:focus_time/utils/time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_time/screens/focus_screen.dart';
import 'package:focus_time/screens/map/map_screen.dart';
import 'package:focus_time/screens/profil/profile_screen.dart';
import '../models/city_network.dart';
import 'package:focus_time/starter/character_selection_screen.dart'; 
import 'package:focus_time/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color _borderColor = Colors.deepPurple;
  String _characterId = 'nuit';

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
    NotificationService().scheduleDailySummaryAt20H();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✨ On lance d'abord notre nouvelle vérification
      _checkCharacterSelection(); 
    });
  }

  // ✨ LA NOUVELLE FONCTION QUI GÈRE LA REDIRECTION
  Future<void> _checkCharacterSelection() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final currentCity = doc.data()?['currentCity'] as String?;

    if ((currentCity == null || currentCity.trim().isEmpty) && mounted) {
      // 🚨 Le joueur n'a pas de ville : on remplace l'écran d'accueil par le choix du personnage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CharacterSelectionScreen()),
      );
    } else {
      // ✅ Le joueur a déjà un personnage : on peut lancer les autres vérifications (pseudo, perte de trajet)
      _checkPseudo();
      _checkInterruptedTrip();
    }
  }

  Future<void> _checkInterruptedTrip() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userRef.collection('travel').doc('status').get();

    if (doc.exists && doc.data()?['isFocusActive'] == true) {
      final data = doc.data()!;
      final destination = data['activeDestination'] as String? ?? 'Inconnue';
      final currentCity = (await userRef.get()).data()?['currentCity'] ?? 'Valenciennes';

      // 1. Enregistre la session interrompue comme échec dans l'historique
      await userRef.collection('travel_history').add({
        'date': FieldValue.serverTimestamp(),
        'startCity': currentCity,
        'endCity': destination,
        'durationMinutes': 0,
        'plannedRoute': [destination],
        'isCompleted': false,
        'isFailed': true,
        'visitedDuringTripCount': 0,
      });

      // 2. Nettoie l'état du voyage
      await userRef.collection('travel').doc('status').update({
        'isFocusActive': false,
        'activeDestination': FieldValue.delete(),
        'endTime': FieldValue.delete(),
      });

      // 3. Affiche le message de perte
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('🧭 Tu t\'es perdu !'),
            content: const Text('L\'application a été fermée pendant ton voyage. Ton trajet a été annulé et comptabilisé comme un échec.'),
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

  Future<void> _loadCharacterData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    String charId = doc.data()?['characterId'] as String? ?? 'nuit';

    Color themeColor = Colors.deepPurple;
    switch (charId) {
      case 'desert': themeColor = Colors.orange; break;
      case 'montagnes': themeColor = Colors.green; break;
      case 'lac': themeColor = Colors.blue; break;
      case 'nuages': themeColor = Colors.pinkAccent; break;
      case 'nuit': default: themeColor = Colors.deepPurple; break;
    }

    if (mounted) {
      setState(() {
        _characterId = charId;
        _borderColor = themeColor;
      });
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
                        _loadCharacterData();
                      },
                      child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _borderColor, // 👈 La couleur dynamique du personnage
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _borderColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: Image.asset(
                            'assets/TeteProfil/$_characterId.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.black, // 👈 Silhouette noire si le dessin manque
                                child: const Icon(Icons.person, color: Colors.white, size: 28),
                              );
                            },
                          ),
                        ),
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
                          color: Colors.white.withValues(alpha: 0.75), // Fond plus opaque pour le contraste
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                int midRouteProgress = 0;

                                if (travelSnapshot.hasData && travelSnapshot.data!.exists) {
                                  final travelData = travelSnapshot.data!.data() as Map<String, dynamic>?;
                                  isFocusActive = travelData?['isFocusActive'] ?? false;
                                  midRouteDestination = travelData?['midRouteDestination'];
                                  activeDestination = travelData?['activeDestination'];
                                  midRouteProgress = travelData?['midRouteProgress'] ?? 0;
                                }

                                String displayPosition = currentCity;
                                if (isFocusActive && activeDestination != null) {
                                  displayPosition = '$currentCity ➔ $activeDestination';
                                } else if (midRouteDestination != null && midRouteDestination.isNotEmpty) {
                                  displayPosition = '$currentCity ➔ $midRouteDestination';
                                }

                                return FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(FirebaseAuth.instance.currentUser?.uid)
                                      .collection('visited_cities')
                                      .get(),
                                  builder: (context, visitedSnapshot) {
                                    Set<String> visitedCities = {};
                                    if (visitedSnapshot.hasData) {
                                      visitedCities = visitedSnapshot.data!.docs.map((d) => d.id).toSet();
                                    }

                                    int staticTimeRemaining = 0;
                                    if (!isFocusActive && midRouteDestination != null) {
                                      int fullTime = CityNetwork.getAvailableDestinations(currentCity)[midRouteDestination] ?? 0;
                                      if (visitedCities.contains(midRouteDestination)) {
                                        fullTime = fullTime ~/ 5;
                                      }
                                      staticTimeRemaining = fullTime - midRouteProgress;
                                      if (staticTimeRemaining < 0) staticTimeRemaining = 0;
                                    }

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Ligne 1 : Position
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, color: Color(0xFFFF8C00), size: 24),
                                            const SizedBox(width: 10),
                                            const Text(
                                              'Position : ',
                                              style: TextStyle(fontSize: 15, color: darkBlue, fontWeight: FontWeight.w600),
                                            ),
                                            Expanded(
                                              child: Text(
                                                displayPosition,
                                                style: const TextStyle(fontSize: 16, color: darkBlue, fontWeight: FontWeight.bold),
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
                                              isFocusActive ? Icons.directions_car : Icons.nights_stay,
                                              color: isFocusActive ? Colors.green.shade600 : const Color(0xFF6A1B9A),
                                              size: 24,
                                            ),
                                            const SizedBox(width: 10),
                                            const Text(
                                              'Statut : ',
                                              style: TextStyle(fontSize: 15, color: darkBlue, fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              isFocusActive ? 'En plein voyage !' : 'Prêt à randonner',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: isFocusActive ? Colors.green.shade700 : const Color(0xFF6A1B9A),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Ligne 3 : Temps restant statique
                                        if (!isFocusActive && midRouteDestination != null) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(Icons.timer_outlined, color: Color(0xFFFF8C00), size: 24),
                                              const SizedBox(width: 10),
                                              const Text(
                                                'Reste pour arriver : ',
                                                style: TextStyle(fontSize: 15, color: darkBlue, fontWeight: FontWeight.w600),
                                              ),
                                              Text(
                                                formatMinutesToHours(staticTimeRemaining),
                                                style: const TextStyle(fontSize: 16, color: darkBlue, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    );
                                  },
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