import 'dart:async';
import 'dart:ui';
import 'package:focus_time/models/companion.dart';
import 'package:focus_time/models/camp_layout_config.dart';
import 'package:focus_time/utils/time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_time/screens/focus/focus_screen.dart';
import 'package:focus_time/screens/map/map_screen.dart';
import 'package:focus_time/screens/profile/profile_screen.dart';
import '../../models/city_network.dart';
import 'package:focus_time/starter/character_selection_screen.dart';
import 'package:focus_time/services/notification_service.dart';
import 'package:focus_time/services/audio_service.dart';
import 'package:focus_time/theme/app_theme.dart';
import 'package:focus_time/config/sprite_config.dart';
import 'package:focus_time/widgets/game_sprites.dart';
import 'package:focus_time/models/camp_biome.dart';
import 'package:focus_time/widgets/biome_backdrop.dart';
import 'package:focus_time/widgets/camp_widgets.dart';
import 'package:focus_time/screens/camp/companion_pen_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color _borderColor = Colors.deepPurple;
  String _characterId = 'nuit';

  CampBiome _biome = CampBiomes.fallback;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  
  // 👈 FIX : On met ces valeurs à null pour retirer les doublons
  String? _currentTent = null;
  String? _currentEnclosure = null;
  
  String _currentCompanionId = 'chien';
  List<String> _unlockedCompanions = [];
  bool _loadingCampCompanions = true;
  CampLayoutConfig _campLayout = CampLayoutConfig.defaults;

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
    _loadCampCompanions();
    _listenBiome();
    NotificationService().scheduleDailySummaryAt20H();
    AudioManager().initAndPlay();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCharacterSelection();
      _checkPendingCompanionReward();
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  void _listenBiome() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
          final data = snap.data();
          final biome = CampBiomes.resolve(
            city: data?['currentCity'] as String?,
            zone: data?['currentZone'] as String?,
          );
          if (!mounted || biome.id == _biome.id) return;
          setState(() => _biome = biome);
        });
  }

  Future<void> _loadCampCompanions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingCampCompanions = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snapshot.data();
      final activeCompanion = data?['activeCompanion'] as String?;
      final unlocked = data?['unlockedCompanions'];

      if (!mounted) return;
      setState(() {
        if (CompanionData.getById(activeCompanion) != null) {
          _currentCompanionId = activeCompanion!;
        }
        _unlockedCompanions = unlocked is List
            ? unlocked.whereType<String>().toList()
            : <String>[];
        _loadingCampCompanions = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCampCompanions = false);
    }
  }

  Future<void> _updateCompanionInFirestore(String companionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final previousCompanionId = _currentCompanionId;
    setState(() => _currentCompanionId = companionId);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'activeCompanion': companionId,
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _currentCompanionId = previousCompanionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le compagnon n’a pas pu être sauvegardé.')),
      );
    }
  }

  Future<void> _openCompanionPen() async {
    if (_loadingCampCompanions) return;
    await HapticFeedback.lightImpact();
    if (!mounted) return;

    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CompanionPenScreen(
          selectedId: _currentCompanionId,
          unlockedIds: _unlockedCompanions,
          background: _biome.background,
        ),
      ),
    );

    if (selected != null && selected != _currentCompanionId) {
      await _updateCompanionInFirestore(selected);
    }
  }

  Future<void> _checkPendingCompanionReward() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await userRef.get();

    String? pendingId = doc.data()?['pendingCompanionReward'] as String?;
    if (pendingId != null && pendingId.isNotEmpty) {
      await userRef.update({'pendingCompanionReward': FieldValue.delete()});

      final companion = CompanionData.allCompanions.firstWhere(
        (c) => c.id == pendingId,
        orElse: () => CompanionData.allCompanions.first,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🎉 Nouveau Compagnon !',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF143063)),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF8C00), width: 3),
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              'compagnons/${companion.id}/${companion.id}_arret.gif',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, size: 50, color: Color(0xFFFF8C00)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tu as rencontré ${companion.name} à ${companion.unlockCity} !',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF143063)),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8C00),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Génial !', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _checkCharacterSelection() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final currentCity = doc.data()?['currentCity'] as String?;

    if ((currentCity == null || currentCity.trim().isEmpty) && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CharacterSelectionScreen()));
    } else {
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
      final currentCity = (await userRef.get()).data()?['currentCity'] ?? 'Le village de Néris';

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

      await userRef.collection('travel').doc('status').update({
        'isFocusActive': false,
        'activeDestination': FieldValue.delete(),
        'endTime': FieldValue.delete(),
      });

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
      case 'nuit':
      default: themeColor = Colors.deepPurple; break;
    }

    if (mounted) setState(() { _characterId = charId; _borderColor = themeColor; });
  }

  Future<void> _checkPseudo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final pseudo = doc.data()?['pseudo'] as String?;

    if ((pseudo == null || pseudo.trim().isEmpty) && mounted) _showPseudoDialog();
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
          content: TextField(controller: pseudoController, autofocus: true, decoration: const InputDecoration(hintText: 'Pseudo')),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
              onPressed: () async {
                final value = pseudoController.text.trim();
                if (value.isEmpty) return;
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'pseudo': value});
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
        ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.75);
    const focusOrange = Color(0xFFFF8C00);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. FOND D'ÉCRAN
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              child: SizedBox.expand(
                key: ValueKey(_biome.background),
                child: Image.asset(
                  _biome.background,
                  fit: BoxFit.cover,
                  alignment: Alignment.center, 
                  errorBuilder: (_, __, ___) => _biome.id == 'default'
                      ? Image.asset(CampBiomes.fallback.background, fit: BoxFit.cover)
                      : BiomeBackdrop(zoneId: _biome.id),
                ),
              ),
            ),
          ),
          if (isDark)
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.24)),
            ),

          // 2. SCÈNE DU CAMP (Personnage et Animaux placés en plein écran)
          Positioned.fill(
            child: _buildCampSceneFullScreen(),
          ),

          // 3. INTERFACE (Boutons et Titres par-dessus)
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                        _loadCharacterData();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _borderColor, width: 3),
                          boxShadow: [BoxShadow(color: _borderColor.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)],
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: Image.asset(
                              'assets/TeteProfil/$_characterId.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black, child: const Icon(Icons.person, color: Colors.white, size: 28)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'FocusTime',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                    shadows: [Shadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                ),
                
                // Pousse les boutons tout en bas de l'écran
                const Spacer(),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                  builder: (context, snapshot) {
                    bool inTransit = false;
                    int transitRemainingMinutes = 0;
                    List<String> transitRoute = [];

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      inTransit = data?['inTransit'] ?? false;
                      transitRemainingMinutes = data?['transitRemainingMinutes'] ?? 0;
                      transitRoute = List<String>.from(data?['transitRoute'] ?? []);
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // --- 1. BOUTON FOCUS (Plus compact) ---
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: (inTransit ? Colors.green.shade700 : focusOrange).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: inTransit ? (isDark ? AppColors.transitGreenDarkTheme : Colors.green.shade500) : focusOrange,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  if (inTransit && transitRoute.isNotEmpty) {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => FocusScreen(transitRemainingMinutes: transitRemainingMinutes, transitRoute: transitRoute)));
                                  } else {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const FocusScreen()));
                                  }
                                },
                                child: Text(
                                  inTransit ? 'REPRENDRE' : 'START FOCUS',
                                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // --- 2. BOUTON CARTE (Plus compact) ---
                          Expanded(
                            flex: 2,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(23),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: panelColor.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(23),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreen(readOnly: true)));
                                      },
                                      child: Center(
                                        child: Text(
                                          'CARTE',
                                          style: TextStyle(color: darkBlue, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.8),
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
                  },
                ),

                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: panelColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isDark ? Theme.of(context).colorScheme.outline : Colors.white, width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                          builder: (context, userSnapshot) {
                            String currentCity = 'Le village de Néris';
                            if (userSnapshot.hasData && userSnapshot.data!.exists) {
                              currentCity = (userSnapshot.data!.data() as Map<String, dynamic>?)?['currentCity'] ?? currentCity;
                            }
                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).collection('travel').doc('status').snapshots(),
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
                                if (isFocusActive && activeDestination != null) displayPosition = '$currentCity ➔ $activeDestination';
                                else if (midRouteDestination != null && midRouteDestination.isNotEmpty) displayPosition = '$currentCity ➔ $midRouteDestination';

                                return FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).collection('visited_cities').get(),
                                  builder: (context, visitedSnapshot) {
                                    Set<String> visitedCities = {};
                                    if (visitedSnapshot.hasData) visitedCities = visitedSnapshot.data!.docs.map((d) => d.id).toSet();

                                    int staticTimeRemaining = 0;
                                    if (!isFocusActive && midRouteDestination != null) {
                                      int fullTime = CityNetwork.getAvailableDestinations(currentCity)[midRouteDestination] ?? 0;
                                      if (visitedCities.contains(midRouteDestination)) fullTime = fullTime ~/ 5;
                                      staticTimeRemaining = fullTime - midRouteProgress;
                                      if (staticTimeRemaining < 0) staticTimeRemaining = 0;
                                    }

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, color: Color(0xFFFF8C00), size: 24),
                                            const SizedBox(width: 10),
                                            Text('Position : ', style: TextStyle(fontSize: 15, color: darkBlue, fontWeight: FontWeight.w600)),
                                            Expanded(child: Text(displayPosition, style: TextStyle(fontSize: 16, color: darkBlue, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(isFocusActive ? Icons.directions_car : Icons.nights_stay, color: isFocusActive ? Colors.green.shade600 : const Color(0xFF6A1B9A), size: 24),
                                            const SizedBox(width: 10),
                                            Text('Statut : ', style: TextStyle(fontSize: 15, color: darkBlue, fontWeight: FontWeight.w600)),
                                            Text(isFocusActive ? 'En plein voyage !' : 'Prêt à randonner', style: TextStyle(fontSize: 15, color: isFocusActive ? Colors.green.shade700 : const Color(0xFF6A1B9A), fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        if (!isFocusActive && midRouteDestination != null) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(Icons.timer_outlined, color: Color(0xFFFF8C00), size: 24),
                                              const SizedBox(width: 10),
                                              Text('Reste pour arriver : ', style: TextStyle(fontSize: 15, color: darkBlue, fontWeight: FontWeight.w600)),
                                              Text(formatMinutesToHours(staticTimeRemaining), style: TextStyle(fontSize: 16, color: darkBlue, fontWeight: FontWeight.bold)),
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

  // --- NOUVELLE SCÈNE PLEIN ÉCRAN ---
  Widget _buildCampSceneFullScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double sceneWidth = constraints.maxWidth;
        final double sceneHeight = constraints.maxHeight;

        // Fonction 'place' basée sur des pixels fixes + le multiplicateur 'scale'
        Positioned place(CampElementLayout layout, Widget child) {
          return Positioned(
            left: sceneWidth * layout.position.dx,
            top: sceneHeight * layout.position.dy,
            width: layout.size.width * layout.scale,   // 👈 Largeur fixe x multiplicateur
            height: layout.size.height * layout.scale, // 👈 Hauteur fixe x multiplicateur
            child: child,
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. LA TENTE
            place(
              _campLayout.tent,
              Image.asset(
                'assets/HomePageAssets/Logement/tente.png',
                fit: BoxFit.contain,
              ),
            ),

            // 2. LE FEU DE CAMP
            place(
              _campLayout.campfire,
              const Campfire(),
            ),

            // 3. L'ENCLOS - PARTIE FOND (cloture.png)
            place(
              _campLayout.animalEnclosure,
              Image.asset(
                'assets/HomePageAssets/Logement/cloture.png',
                fit: BoxFit.contain,
              ),
            ),

            // 4. LE COMPAGNON
            place(
              _campLayout.animalEnclosure,
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openCompanionPen,
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.55,
                    heightFactor: 0.55,
                    child: Image.asset(
                      campCompanionAsset(_currentCompanionId),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.pets, color: Color(0xFFFF8C00)),
                    ),
                  ),
                ),
              ),
            ),

            // 5. L'ENCLOS - PARTIE AVANT (avant_de_cloture.png)
            place(
              _campLayout.animalEnclosure,
              IgnorePointer(
                child: Image.asset(
                  'assets/HomePageAssets/Logement/avant_de_cloture.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // 6. LE PERSONNAGE
            place(
              _campLayout.character,
              CharacterSprite(
                characterId: _characterId,
                scene: SpriteScene.world,
                isMoving: false,
              ),
            ),
          ],
        );
      },
    );
  }
}