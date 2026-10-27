import 'dart:async';
import 'dart:ui';
import 'package:focus_time/models/companion.dart';
import 'package:focus_time/models/camp_layout_config.dart';
import 'package:focus_time/screens/shop/shop_screen.dart';
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

  // Variables dynamiques des cosmétiques équipés
  String _currentTent = 'assets/homePageAssets/logement/base/montagne/tente.png';
  String _currentEnclosureBack = 'assets/homePageAssets/cloture/base/montagne/arriere.png';
  String _currentEnclosureFront = 'assets/homePageAssets/cloture/base/montagne/avant.png';

  List<String> _activeCompanions = [];
  List<String> _unlockedCompanions = [];
  bool _loadingCampCompanions = true;
  final CampLayoutConfig _campLayout = CampLayoutConfig.defaults;

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

      final savedTent = data?['equippedTent'] as String?;
      final savedEnclosureBack = data?['equippedEnclosureBack'] as String?;
      final savedEnclosureFront = data?['equippedEnclosureFront'] as String?;

      if (!mounted) return;
      setState(() {
        if (biome.id != _biome.id) {
          _biome = biome;
        }
        if (savedTent != null && savedTent.isNotEmpty && savedTent != _currentTent) {
          _currentTent = savedTent;
        }
        if (savedEnclosureBack != null && savedEnclosureBack.isNotEmpty && savedEnclosureBack != _currentEnclosureBack) {
          _currentEnclosureBack = savedEnclosureBack;
        }
        if (savedEnclosureFront != null && savedEnclosureFront.isNotEmpty && savedEnclosureFront != _currentEnclosureFront) {
          _currentEnclosureFront = savedEnclosureFront;
        }
      });
    });
  }

  Future<void> _loadCampCompanions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingCampCompanions = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = snapshot.data();

      final activeCompanion = data?['activeCompanion'] as String?;
      final activeCompanionsList = data?['activeCompanions'] as List<dynamic>?;
      final unlocked = data?['unlockedCompanions'];

      List<String> loadedCompanions = [];
      if (activeCompanionsList != null) {
        loadedCompanions = activeCompanionsList.whereType<String>().toList();
      } else if (activeCompanion != null && activeCompanion.isNotEmpty) {
        loadedCompanions = [activeCompanion];
      }

      if (!mounted) return;
      setState(() {
        _activeCompanions = loadedCompanions;
        _unlockedCompanions = unlocked is List ? unlocked.whereType<String>().toList() : <String>[];
        _loadingCampCompanions = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCampCompanions = false);
    }
  }

  Future<void> _updateCompanionInFirestore(List<String> companionIds) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final previousCompanions = List<String>.from(_activeCompanions);
    setState(() => _activeCompanions = companionIds);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'activeCompanions': companionIds,
        'activeCompanion': companionIds.isNotEmpty ? companionIds.first : null,
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _activeCompanions = previousCompanions);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les compagnons n’ont pas pu être sauvegardés.')),
      );
    }
  }

  Future<void> _openCompanionPen() async {
    if (_loadingCampCompanions) return;
    await HapticFeedback.lightImpact();
    if (!mounted) return;

    final selectedList = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => CompanionPenScreen(
          selectedIds: _activeCompanions,
          unlockedIds: _unlockedCompanions,
          background: _biome.background,
        ),
      ),
    );

    if (selectedList != null) {
      await _updateCompanionInFirestore(selectedList);
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
                              campCompanionAsset(companion.id),
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
    final data = doc.data();
    String charId = data?['characterId'] as String? ?? 'nuit';

    String? savedTent = data?['equippedTent'] as String?;
    final savedEnclosureBack = data?['equippedEnclosureBack'] as String?;
    final savedEnclosureFront = data?['equippedEnclosureFront'] as String?;

    Color themeColor = Colors.deepPurple;
    switch (charId) {
      case 'desert': themeColor = Colors.orange; break;
      case 'montagnes': themeColor = Colors.green; break;
      case 'lac': themeColor = Colors.blue; break;
      case 'nuages': themeColor = Colors.pinkAccent; break;
      case 'nuit':
      default: themeColor = Colors.deepPurple; break;
    }

    if (mounted) {
      setState(() {
        _characterId = charId;
        _borderColor = themeColor;
        if (savedTent != null && savedTent.isNotEmpty) {
          _currentTent = savedTent;
        }
        if (savedEnclosureBack != null && savedEnclosureBack.isNotEmpty) {
          _currentEnclosureBack = savedEnclosureBack;
        }
        if (savedEnclosureFront != null && savedEnclosureFront.isNotEmpty) {
          _currentEnclosureFront = savedEnclosureFront;
        }
      });
    }
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

  Future<void> _openShop() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopScreen(
          backgroundAsset: _biome.background,
          equippedTentAsset: _currentTent,
          equippedEnclosureBackAsset: _currentEnclosureBack,
        ),
      ),
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

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => unawaited(AudioManager().ensurePlaying()),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              child: SizedBox.expand(
                key: ValueKey(_biome.background),
                child: Image.asset(
                  _biome.background,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, _, _) => _biome.id == 'default'
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

          Positioned.fill(
            child: _buildCampSceneFullScreen(),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _openShop,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: panelColor,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: focusOrange, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: focusOrange.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.storefront_rounded, color: focusOrange, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Boutique',
                                      style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                            _loadCharacterData();
                            _loadCampCompanions();
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
                      ],
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
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                            Expanded(
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(color: (inTransit ? Colors.green.shade700 : focusOrange).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
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
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 46,
                              height: 46,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(23),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
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
                                          child: ShaderMask(
                                            shaderCallback: (Rect bounds) {
                                              return const LinearGradient(
                                                colors: [Color(0xFFFF8C00), Color(0xFFFFD54F)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ).createShader(bounds);
                                            },
                                            child: const Icon(Icons.explore_rounded, color: Colors.white, size: 28),
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
                                  if (isFocusActive && activeDestination != null) {
                                    displayPosition = '$currentCity ➔ $activeDestination';
                                  } else if (midRouteDestination != null && midRouteDestination.isNotEmpty) displayPosition = '$currentCity ➔ $midRouteDestination';

                                  return FutureBuilder<QuerySnapshot>(
                                    future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).collection('visited_cities').get(),
                                    builder: (context, visitedSnapshot) {
                                      Set<String> visitedCities = {};
                                      if (visitedSnapshot.hasData) visitedCities = visitedSnapshot.data!.docs.map((d) => d.id).toSet();

                                      int staticTimeRemaining = 0;
                                      if (!isFocusActive && midRouteDestination != null) {
                                        int fullTime = CityNetwork.getAvailableDestinations(currentCity)[midRouteDestination] ?? 0;
                                        if (visitedCities.contains(midRouteDestination)) fullTime = fullTime ~/ 3;
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
          ),
        ],
        ),
      ),
    );
  }

  Alignment _getCompanionAlignment(int index, int total) {
    if (total == 1) return const Alignment(0, -0.2);
    if (total == 2) {
      return index == 0 ? const Alignment(-0.5, -0.15) : const Alignment(0.4, -0.10);
    }
    if (total == 3) {
      if (index == 0) return const Alignment(-0.5, -0.05);
      if (index == 1) return const Alignment(0.4, 0);
      return const Alignment(0, -0.3);
    }
    const alignments = [
      Alignment(-0.5, -0.05),
      Alignment(0.4, 0),
      Alignment(0, -0.3),
      Alignment(-0.05, 0.3),
    ];
    return alignments[index];
  }

  Widget _buildCampSceneFullScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double sceneWidth = constraints.maxWidth;
        final double sceneHeight = constraints.maxHeight;

        final double campBaseWidth = sceneWidth > 450 ? 450 : sceneWidth;
        final double offsetX = (sceneWidth - campBaseWidth) / 2;

        Positioned place(CampElementLayout layout, Widget child) {
          return Positioned(
            left: offsetX + (campBaseWidth * layout.position.dx),
            top: sceneHeight * layout.position.dy,
            width: layout.size.width * layout.scale,
            height: layout.size.height * layout.scale,
            child: child,
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            place(
              _campLayout.tent,
              Image.asset(
                _currentTent,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/homePageAssets/logement/base/montagne/tente.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            place(_campLayout.campfire, const Campfire()),

            // Enclos - Fond dynamique
            place(
              _campLayout.animalEnclosure,
              Image.asset(
                _currentEnclosureBack,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/homePageAssets/cloture/base/montagne/arriere.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Compagnons
            place(
              _campLayout.animalEnclosure,
              Stack(
                children: List.generate(_activeCompanions.length, (index) {
                  return Align(
                    alignment: _getCompanionAlignment(index, _activeCompanions.length),
                    child: Transform.translate(
                      offset: const Offset(0, -15),
                      child: FractionallySizedBox(
                        widthFactor: _activeCompanions.length == 1 ? 0.45 : 0.35,
                        heightFactor: _activeCompanions.length == 1 ? 0.45 : 0.35,
                        child: Image.asset(
                          campCompanionAsset(_activeCompanions[index]),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(Icons.pets, color: Color(0xFFFF8C00)),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Enclos - Avant dynamique
            place(
              _campLayout.animalEnclosure,
              IgnorePointer(
                child: Image.asset(
                  _currentEnclosureFront,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/homePageAssets/cloture/base/montagne/avant.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            Positioned(
              left: offsetX + (campBaseWidth * (_campLayout.animalEnclosure.position.dx + 0.07)),
              top: sceneHeight * (_campLayout.animalEnclosure.position.dy + 0.10),
              width: 40,
              height: 30,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openCompanionPen,
                child: Container(decoration: BoxDecoration(color: Colors.transparent, border: Border.all(color: Colors.transparent, width: 2))),
              ),
            ),

            place(_campLayout.character, CharacterSprite(characterId: _characterId, scene: SpriteScene.world, isMoving: false)),
          ],
        );
      },
    );
  }
}
