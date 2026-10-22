import 'dart:async';
import 'dart:ui';
import 'package:focus_time/screens/focus/expedition_dialogs.dart';
import 'package:focus_time/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:focus_time/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/city_network.dart';
import '../../services/travel_service.dart';
import '../../utils/time_formatter.dart';
import '../home/home_screen.dart';
import 'dart:io' show Platform;

import '../../widgets/parallax_background.dart';
import '../../models/companion.dart';
import '../../widgets/game_sprites.dart';
import '../../config/sprite_config.dart';

class ActiveTimerScreen extends StatefulWidget {
  final List<String> plannedRoute;
  final int durationMinutes;
  final int plannedTravelMinutes;

  const ActiveTimerScreen({
    super.key,
    required this.plannedRoute,
    required this.durationMinutes,
    this.plannedTravelMinutes = 0,
  });

  @override
  State<ActiveTimerScreen> createState() => _ActiveTimerScreenState();
}

class _LegTimeline {
  final String destination;
  final int cumulativeSeconds;

  _LegTimeline({required this.destination, required this.cumulativeSeconds});
}

class _ActiveTimerScreenState extends State<ActiveTimerScreen>
    with WidgetsBindingObserver {
  late int _totalSeconds;
  late int _remainingSeconds;

  Timer? _timer;
  bool _isCompleted = false;
  bool _hasCheated = false;
  final TravelService _travelService = TravelService();
  
  // 👈 NOUVEAU : Liste pour la meute
  List<String> _activeCompanions = []; 
  
  String _characterId = 'nuit';

  bool _isWalkingBackward = false;

  int _outOfPauseExits = 0;
  int _appActiveSeconds = 0;
  Timer? _activeAppTimer;

  List<_LegTimeline> _routeMilestones = [];
  bool _isMilestonesReady = false;

  final Set<int> _triggeredMilestoneIndexes = {};
  bool _isPaused = false;
  int _pauseRemainingSeconds = 0;
  int _pauseOvertimeSeconds = 0;
  DateTime? _pauseEndTime;
  Timer? _pauseTimer;

  bool _isDialogActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();

    if (widget.durationMinutes == -1) {
      _totalSeconds = widget.plannedRoute.isNotEmpty ? widget.plannedRoute.length : 1;
    } else {
      _totalSeconds = widget.durationMinutes * 60;
    }
    _remainingSeconds = _totalSeconds;

    _travelService.setFocusActive(
      true,
      plannedRoute: widget.plannedRoute,
      durationMinutes: widget.durationMinutes,
    );

    _prepareMilestones();
    _startTimer();
    _startActiveAppTracker();
  }

  void _startActiveAppTracker() {
    _activeAppTimer?.cancel();
    _activeAppTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isPaused && !_isCompleted && !_isWalkingBackward) {
        _appActiveSeconds++;
      }
    });
  }

  Future<void> _prepareMilestones() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    if (widget.durationMinutes == -1) {
      List<String> allCompanionIds = CompanionData.allCompanions.map((c) => c.id).toList();
      await userRef.update({'unlockedCompanions': allCompanionIds});
    }

    final userDoc = await userRef.get();
    String currentCity = userDoc.data()?['currentCity'] ?? 'Le village de Néris';
    String charId = userDoc.data()?['characterId'] as String? ?? 'nuit';

    // 👈 NOUVEAU : Récupération de la liste de compagnons (jusqu'à 4)
    final activeCompanionsList = userDoc.data()?['activeCompanions'] as List<dynamic>?;
    final singleCompanion = userDoc.data()?['activeCompanion'] as String?;

    List<String> loadedCompanions = [];
    if (activeCompanionsList != null && activeCompanionsList.isNotEmpty) {
      loadedCompanions = activeCompanionsList.whereType<String>().toList();
    } else if (singleCompanion != null) {
      loadedCompanions = [singleCompanion];
    }

    if (mounted) {
      setState(() {
        _characterId = charId;
        _activeCompanions = loadedCompanions;
      });
    }

    List<_LegTimeline> milestones = [];
    int totalCumulativeSeconds = 0;
    int totalRouteSteps = widget.plannedRoute.length;

    int secondsPerStep = widget.durationMinutes == -1
        ? 1
        : (_totalSeconds ~/ (totalRouteSteps > 0 ? totalRouteSteps : 1));
    if (secondsPerStep < 1) secondsPerStep = 1;

    for (String city in widget.plannedRoute) {
      int effectiveSeconds = (widget.durationMinutes == -1)
          ? secondsPerStep
          : (CityNetwork.getAvailableDestinations(currentCity)[city] ?? 60) * 60;

      totalCumulativeSeconds += effectiveSeconds;
      milestones.add(_LegTimeline(destination: city, cumulativeSeconds: totalCumulativeSeconds));
      currentCity = city;
    }

    if (mounted) {
      setState(() {
        _routeMilestones = milestones;
        _isMilestonesReady = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!_isCompleted && !_isPaused && !_isWalkingBackward) {
        _outOfPauseExits++;
        setState(() => _isWalkingBackward = true);

        NotificationService().showNotification(
          id: 99,
          title: '🔄 Demi-tour !',
          body: 'Tu as quitté le chemin, ton personnage rebrousse chemin et perd du temps.',
        );

        _hasCheated = true;
        await _travelService.recordFailedTrip(
          durationMinutes: widget.durationMinutes,
          plannedRoute: widget.plannedRoute,
        );
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_hasCheated) {
        setState(() {
          _isWalkingBackward = false;
          _hasCheated = false;
        });
      }

      if (_isPaused && _pauseEndTime != null) {
        final now = DateTime.now();
        final diffSeconds = _pauseEndTime!.difference(now).inSeconds;

        setState(() {
          if (diffSeconds > 0) {
            _pauseRemainingSeconds = diffSeconds;
            _pauseOvertimeSeconds = 0;
          } else {
            _pauseRemainingSeconds = 0;
            _pauseOvertimeSeconds = diffSeconds.abs();
          }
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_isPaused) return;

      String? arrivedCity;

      setState(() {
        if (_isWalkingBackward) {
          _remainingSeconds++;
          if (_remainingSeconds > _totalSeconds) {
            _remainingSeconds = _totalSeconds;
          }
        } else if (_remainingSeconds > 0) {
          _remainingSeconds--;

          int elapsed = _totalSeconds - _remainingSeconds;

          for (int i = 0; i < _routeMilestones.length; i++) {
            if (elapsed >= _routeMilestones[i].cumulativeSeconds &&
                !_triggeredMilestoneIndexes.contains(i) &&
                !_isDialogActive) {
              _triggeredMilestoneIndexes.add(i);
              if (_remainingSeconds > 0) {
                arrivedCity = _routeMilestones[i].destination;
              }
              break;
            }
          }
        } else {
          _timer?.cancel();
          _finishTrip();
        }
      });

      if (arrivedCity != null && mounted) {
        _openArrivalPauseDialog(arrivedCity!);
      }
    });
  }

  void _openArrivalPauseDialog(String cityName) {
    setState(() => _isDialogActive = true);

    NotificationService().showNotification(
      id: 1,
      title: '🔥 Étape atteinte !',
      body: 'Tu es arrivé à $cityName. Installe ton campement !',
    );

    ActiveTimerDialogs.showArrivalDialog(
      context: context,
      cityName: cityName,
      onClosed: () {
        if (mounted) setState(() => _isDialogActive = false);
      },
      onSelectPause: (minutes) {
        if (!mounted) return;
        setState(() => _isDialogActive = false);
        _startPauseTimer(minutes);
      },
    );
  }

  void _startPauseTimer(int minutes) async {
    _timer?.cancel();
    final durationSec = widget.durationMinutes == -1 ? 2 : minutes * 60;

    setState(() {
      _isWalkingBackward = false;
      _isPaused = true;
      _pauseRemainingSeconds = durationSec;
      _pauseOvertimeSeconds = 0;
      _pauseEndTime = DateTime.now().add(Duration(seconds: durationSec));
    });

    _pauseTimer?.cancel();
    _pauseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_pauseRemainingSeconds > 0) {
          _pauseRemainingSeconds--;

          if (_pauseRemainingSeconds == 120 && widget.durationMinutes != -1) {
            NotificationService().showNotification(
              id: 201,
              title: '⏰ Bientôt la fin de la pause !',
              body: 'Ta pause au feu de camp se termine dans 2 minutes, prépare-toi à repartir !',
            );
          }
        } else {
          _pauseOvertimeSeconds++;
        }
      });
    });

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await NotificationService().showPauseChronometer(durationSec);
      } catch (e) {
        debugPrint('❌ Erreur affichage chrono pause: $e');
      }
    }
  }

  void _endPauseNormal() {
    _pauseTimer?.cancel();
    NotificationService().cancelNotification(200);
    NotificationService().cancelNotification(201);

    int penalty = _pauseOvertimeSeconds;

    setState(() {
      _isPaused = false;
      _pauseRemainingSeconds = 0;
      _pauseOvertimeSeconds = 0;
      _pauseEndTime = null;

      if (penalty > 0) {
        _remainingSeconds += penalty;
      }
    });

    _startTimer();

    if (penalty > 0) {
      int lateMinutes = (penalty / 60).ceil();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏳ Tu as traîné $lateMinutes min... Ce temps a été rajouté à ton voyage !'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _cancelTrip() async {
    _timer?.cancel();
    _pauseTimer?.cancel();
    _activeAppTimer?.cancel();
    NotificationService().cancelNotification(200);
    NotificationService().cancelNotification(201);

    await _travelService.setFocusActive(false);

    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
    }
  }

  Future<void> _checkAndUnlockCompanion(String arrivedCity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final companionToUnlock = CompanionData.allCompanions
        .cast<Companion?>()
        .firstWhere((c) => c?.unlockCity == arrivedCity, orElse: () => null);

    if (companionToUnlock != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await userRef.get();
      final List<dynamic> unlocked = doc.data()?['unlockedCompanions'] ?? [];

      if (!unlocked.contains(companionToUnlock.id)) {
        await userRef.update({
          'unlockedCompanions': FieldValue.arrayUnion([companionToUnlock.id]),
          'activeCompanion': companionToUnlock.id,
          'pendingCompanionReward': companionToUnlock.id,
        });
      }
    }
  }

  Future<void> _finishTrip() async {
    _timer?.cancel();
    _activeAppTimer?.cancel();
    NotificationService().cancelNotification(200);
    NotificationService().cancelNotification(201);
    NotificationService().cancelNotification(99);

    if (_isDialogActive && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isDialogActive = false);
    }

    int baseMinutes = widget.durationMinutes == -1 ? 10 : widget.durationMinutes;
    int earnedPoints = baseMinutes;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      bool isPartialTrip = widget.durationMinutes != -1 && widget.plannedTravelMinutes > widget.durationMinutes;

      if (isPartialTrip) {
        int remainingTravel = widget.plannedTravelMinutes - widget.durationMinutes;

        NotificationService().showNotification(
          id: 3,
          title: '🏕️ Campement sauvage !',
          body: 'Temps de focus écoulé. Il te reste $remainingTravel min de marche vers ${widget.plannedRoute.last}.',
        );

        await userRef.set({
          'points': FieldValue.increment(earnedPoints),
          'inTransit': true,
          'transitRemainingMinutes': remainingTravel,
          'transitRoute': widget.plannedRoute,
        }, SetOptions(merge: true));
      } else {
        NotificationService().showNotification(
          id: 3,
          title: '🎉 Fin de session !',
          body: 'Trajet terminé et enregistré ! Tu as gagné $earnedPoints points 🪙',
        );

        await userRef.set({
          'points': FieldValue.increment(earnedPoints),
          'inTransit': false,
          'transitRemainingMinutes': FieldValue.delete(),
          'transitRoute': FieldValue.delete(),
        }, SetOptions(merge: true));

        if (widget.plannedRoute.isNotEmpty) {
          final arrivedCity = widget.plannedRoute.last;
          await userRef.update({'currentCity': arrivedCity});
          await _checkAndUnlockCompanion(arrivedCity);
        }
      }
    }

    int safeDuration = widget.durationMinutes == -1 ? 0 : widget.durationMinutes;
    await _travelService.processTripResults(totalFuelMinutes: safeDuration, plannedRoute: widget.plannedRoute);

    if (mounted) {
      setState(() => _isCompleted = true);
    }
  }

  void _showExpeditionSummarySheet() {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    int focusMinutes = widget.durationMinutes == -1 ? 1 : widget.durationMinutes;
    int appActiveMinutes = (_appActiveSeconds / 60).ceil();
    int earnedPoints = focusMinutes;

    bool isPartialTrip = widget.durationMinutes != -1 && widget.plannedTravelMinutes > widget.durationMinutes;
    int remainingTravel = isPartialTrip ? (widget.plannedTravelMinutes - widget.durationMinutes) : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPartialTrip ? "🏕️ Campement en chemin" : "📜 Résumé de l'expédition",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkBlue),
            ),
            const SizedBox(height: 16),

            Text("Villes traversées / ciblées :", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.plannedRoute.map((city) => Chip(
                backgroundColor: focusOrange.withValues(alpha: 0.12),
                side: const BorderSide(color: focusOrange),
                avatar: const Icon(Icons.place, size: 16, color: focusOrange),
                label: Text(city, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: darkBlue)),
              )).toList(),
            ),

            const Divider(height: 28),

            _buildSummaryRow(Icons.timer_outlined, "Temps focus effectué", "$focusMinutes min"),

            if (isPartialTrip) ...[
              const SizedBox(height: 10),
              _buildSummaryRow(Icons.directions_walk_rounded, "Reste à parcourir", "$remainingTravel min", valueColor: Colors.orange.shade800),
            ],

            const SizedBox(height: 10),
            _buildSummaryRow(Icons.phone_android, "Temps passé sur l'app", "$appActiveMinutes min"),
            const SizedBox(height: 10),
            _buildSummaryRow(
              Icons.warning_amber_rounded,
              "Sorties hors pause",
              "$_outOfPauseExits fois",
              valueColor: _outOfPauseExits > 0 ? Colors.redAccent : Colors.green,
            ),
            const SizedBox(height: 10),
            _buildSummaryRow(Icons.monetization_on_outlined, "Points gagnés", "+$earnedPoints pts", valueColor: focusOrange),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
                },
                child: Text(
                  isPartialTrip ? "Monter le campement" : "Retour au campement",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF143063)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor ?? const Color(0xFF143063))),
      ],
    );
  }

  void _showRouteBottomSheet(BuildContext context, Color darkBlue, Color focusOrange, int currentLegIndex) {
    int travelMinutes = widget.plannedTravelMinutes;
    int restMinutes = widget.durationMinutes - travelMinutes;
    if (restMinutes < 0) restMinutes = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Plan de route complet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue)),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.plannedRoute.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String city = entry.value;

                  Color chipColor = (idx < currentLegIndex) ? Colors.green : (idx == currentLegIndex ? focusOrange : Colors.grey);
                  IconData chipIcon = (idx < currentLegIndex) ? Icons.check_circle : (idx == currentLegIndex ? Icons.navigation : Icons.radio_button_unchecked);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: chipColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: chipColor, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(chipIcon, size: 13, color: chipColor),
                        const SizedBox(width: 4),
                        Text(city, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: chipColor)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: darkBlue, size: 16),
                  const SizedBox(width: 4),
                  Text('Voyage : ${formatMinutesToHours(travelMinutes)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkBlue)),
                  if (restMinutes > 0) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.hotel, color: Color(0xFF6A1B9A), size: 16),
                    const SizedBox(width: 4),
                    Text('Repos : ${formatMinutesToHours(restMinutes)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6A1B9A))),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pauseTimer?.cancel();
    _activeAppTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  String _formatTimerDisplay({required bool isOvertime, required int seconds}) {
    final prefix = isOvertime ? "+\n" : "";
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    final h = seconds ~/ 3600;

    if (h > 0) {
      return "$prefix${h}h\n${m}m\n${s}s";
    } else {
      return "$prefix${m}m\n${s}s";
    }
  }

  String _getTimerText() {
    if (_isWalkingBackward) {
      return "DEMI-TOUR\n${_formatTimerDisplay(isOvertime: false, seconds: _remainingSeconds)}";
    }
    if (_isPaused) {
      if (_pauseOvertimeSeconds > 0) {
        return _formatTimerDisplay(isOvertime: true, seconds: _pauseOvertimeSeconds);
      } else {
        return _formatTimerDisplay(isOvertime: false, seconds: _pauseRemainingSeconds);
      }
    }
    return _formatTimerDisplay(isOvertime: false, seconds: _remainingSeconds);
  }

  Color _getTimerColor() {
    if (_isWalkingBackward) return Colors.orangeAccent;
    if (_isPaused && _pauseOvertimeSeconds > 0) return AppColors.errorOnDark;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    int elapsedSeconds = _totalSeconds - _remainingSeconds;
    String currentLegTitle = "Préparation...";
    int currentLegIndex = 0;

    if (_isMilestonesReady && _routeMilestones.isNotEmpty) {
      bool isStillTravelling = false;
      for (int i = 0; i < _routeMilestones.length; i++) {
        if (elapsedSeconds < _routeMilestones[i].cumulativeSeconds) {
          currentLegTitle = "Marche vers ${_routeMilestones[i].destination}";
          currentLegIndex = i;
          isStillTravelling = true;
          break;
        }
      }
      if (!isStillTravelling) {
        currentLegTitle = "⛺ Campement installé à ${_routeMilestones.last.destination}";
        currentLegIndex = _routeMilestones.length;
      }
    } else if (widget.plannedRoute.isNotEmpty) {
      currentLegTitle = "Marche vers ${widget.plannedRoute.first}";
    }

    double progress = (_totalSeconds > 0) ? (_remainingSeconds / _totalSeconds) : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        ActiveTimerDialogs.showAbandonDialog(context, _cancelTrip);
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: ParallaxBackground(
                isRunning: !_isPaused && !_isCompleted && !_isWalkingBackward,
                characterId: _characterId,
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.15)),
            ),

            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: InkWell(
                                  onTap: () => ActiveTimerDialogs.showAbandonDialog(context, _cancelTrip),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                    ),
                                    child: Semantics(
                                      label: 'Quitter l’expédition',
                                      excludeSemantics: true,
                                      child: Icon(Icons.arrow_back_ios_new, color: darkBlue, size: 20),
                                    ),
                                  ),
                                ),
                              ),

                              Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 40.0),
                                  child: Semantics(
                                    label: _isPaused ? 'Minuteur de pause' : 'Minuteur de marche',
                                    value: _getTimerText(),
                                    excludeSemantics: true,
                                    child: SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _isPaused || _isWalkingBackward
                                                  ? (_isWalkingBackward
                                                        ? Colors.orange.withValues(alpha: 0.2)
                                                        : (_pauseOvertimeSeconds > 0
                                                              ? Colors.red.withValues(alpha: 0.15)
                                                              : const Color(0xFF1B2A3D)))
                                                  : const Color(0xFF1E2430),
                                              border: Border.all(
                                                color: _isWalkingBackward
                                                    ? Colors.orangeAccent
                                                    : (_pauseOvertimeSeconds > 0 ? Colors.redAccent : Colors.white.withValues(alpha: 0.5)),
                                                width: 2.0,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _isWalkingBackward
                                                      ? Colors.orangeAccent.withValues(alpha: 0.4)
                                                      : (_pauseOvertimeSeconds > 0 ? Colors.redAccent.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.2)),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 200,
                                            height: 200,
                                            child: CircularProgressIndicator(
                                              value: _isPaused ? null : progress.clamp(0.0, 1.0),
                                              strokeWidth: 8,
                                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                _isWalkingBackward
                                                    ? Colors.orangeAccent
                                                    : (_isPaused
                                                          ? (_pauseOvertimeSeconds > 0 ? Colors.redAccent : Colors.blueAccent)
                                                          : focusOrange),
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.timer_outlined, size: 20, color: _getTimerColor()),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  _getTimerText(),
                                                  style: TextStyle(
                                                    fontSize: _isWalkingBackward ? 20 : 26,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getTimerColor(),
                                                    height: 1.15,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 1),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Text(
                            _isWalkingBackward
                                ? '🔄 Ton personnage rebrousse chemin !'
                                : (_isPaused
                                      ? (_pauseOvertimeSeconds > 0 ? '⚠️ Pause dépassée !' : '☕ Campement au feu de camp')
                                      : currentLegTitle),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _isWalkingBackward ? Colors.orange.shade800 : darkBlue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Spacer(flex: 3),

                        if (_isCompleted) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: focusOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.flag_rounded, size: 22),
                            label: const Text("Terminer l'exploration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            onPressed: _showExpeditionSummarySheet,
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (_isPaused)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                            label: const Text('Reprendre le voyage', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: _endPauseNormal,
                          ),

                        GestureDetector(
                          onTap: () => _showRouteBottomSheet(context, darkBlue, focusOrange, currentLegIndex),
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white, width: 1.2),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.route, color: darkBlue, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Itinéraire ($currentLegIndex/${widget.plannedRoute.length})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkBlue),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_up, color: darkBlue, size: 18),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              _isWalkingBackward
                                  ? '⚠️ Reviens sur l\'app pour reprendre ta marche en avant !'
                                  : (_isPaused
                                        ? (_pauseOvertimeSeconds > 0
                                              ? '🚨 Reviens vite à la marche, tu perds du temps !'
                                              : '🔥 En train de faire une pause au feu de camp...')
                                        : (_isCompleted
                                              ? '🎉 Expédition terminée ! Appuie pour voir le résumé.'
                                              : '🥾 Garde le cap, ne quitte pas l\'app !')),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isWalkingBackward
                                    ? Colors.orangeAccent
                                    : (_isPaused
                                          ? (_pauseOvertimeSeconds > 0 ? Colors.redAccent : Colors.lightBlueAccent)
                                          : (_isCompleted ? Colors.lightGreenAccent : const Color(0xFFFF6B6B))),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 👈 NOUVEAU : Affichage dynamique de toute la meute en expédition !
            ..._activeCompanions.asMap().entries.map((entry) {
              int index = entry.key;
              String compId = entry.value;

              double leftOffset;
              double bottomOffset;

              // Placement pour simuler une marche en meute
              switch (index) {
                case 0:
                  leftOffset = MediaQuery.of(context).size.width * 0.45;
                  bottomOffset = 168;
                  break;
                case 1:
                  leftOffset = MediaQuery.of(context).size.width * 0.6;
                  bottomOffset = 170; // Plus bas = plus au premier plan
                  break;
                case 2:
                  leftOffset = MediaQuery.of(context).size.width * 0.75;
                  bottomOffset = 172; // Plus haut = plus à l'arrière-plan
                  break;
                case 3:
                default:
                  leftOffset = MediaQuery.of(context).size.width * 0.03;
                  bottomOffset = 174;
                  break;
              }

              return Positioned(
                bottom: bottomOffset,
                left: leftOffset,
                child: CompanionSprite(
                  companionId: compId,
                  scene: SpriteScene.expedition,
                  isMoving: !_isWalkingBackward && !_isPaused && !_isCompleted,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}