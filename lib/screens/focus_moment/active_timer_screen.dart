import 'dart:async';
import 'dart:ui';
import 'package:focus_time/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/city_network.dart';
import '../../services/travel_service.dart';
import '../../utils/time_formatter.dart';
import '../home_screen.dart';
import 'dart:io' show Platform;

import '../widgets/parallax_background.dart';
import 'active_timer_dialogs.dart';


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

class _ActiveTimerScreenState extends State<ActiveTimerScreen> with WidgetsBindingObserver {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isCompleted = false;
  bool _hasCheated = false;
  final TravelService _travelService = TravelService();

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

    _remainingSeconds = widget.durationMinutes * 60;

    _travelService.setFocusActive(
      true,
      plannedRoute: widget.plannedRoute,
      durationMinutes: widget.durationMinutes,
    );

    _prepareMilestones();
    _startTimer();
  }

 Future<void> _prepareMilestones() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    String currentCity = userDoc.data()?['currentCity'] ?? 'Valenciennes';

    List<_LegTimeline> milestones = [];
    int totalCumulativeSeconds = 0;

    int totalRouteSteps = widget.plannedRoute.length;
    int totalAllowedSeconds = CityNetwork.isDevMode ? 60 : (widget.durationMinutes * 60);
    int secondsPerStep = totalAllowedSeconds ~/ totalRouteSteps;
    if (secondsPerStep < 2) secondsPerStep = 2;

    for (String city in widget.plannedRoute) {
      int effectiveSeconds = CityNetwork.isDevMode 
          ? secondsPerStep 
          : (CityNetwork.getAvailableDestinations(currentCity)[city] ?? 60) * 60;

      totalCumulativeSeconds += effectiveSeconds;
      milestones.add(_LegTimeline(
        destination: city,
        cumulativeSeconds: totalCumulativeSeconds,
      ));

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
      if (!_isCompleted && !_hasCheated && !_isPaused) {
        _hasCheated = true; 
        _timer?.cancel();

        await _travelService.recordFailedTrip(
          durationMinutes: widget.durationMinutes,
          plannedRoute: widget.plannedRoute,
        );

        await _travelService.setFocusActive(false);
      } 
    } else if (state == AppLifecycleState.resumed) {
      if (_hasCheated) {
        ActiveTimerDialogs.showLostDialog(context, () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        });
        return;
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
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;

          int elapsed = (widget.durationMinutes * 60) - _remainingSeconds;
          for (int i = 0; i < _routeMilestones.length; i++) {
            if (elapsed >= _routeMilestones[i].cumulativeSeconds && 
                !_triggeredMilestoneIndexes.contains(i) && 
                !_isDialogActive) {
              _triggeredMilestoneIndexes.add(i);
              _openArrivalPauseDialog(_routeMilestones[i].destination);
              break;
            }
          }
        } else {
          _timer?.cancel();
          _finishTrip();
        }
      });
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
      onClosed: () => setState(() => _isDialogActive = false),
      onSelectPause: (minutes) {
        setState(() => _isDialogActive = false);
        _startPauseTimer(minutes);
      },
    );
  }
  
void _startPauseTimer(int minutes) async {
    _timer?.cancel(); 
    
    final durationSec = minutes * 60;
    setState(() {
      _isPaused = true;
      _pauseRemainingSeconds = durationSec;
      _pauseOvertimeSeconds = 0; 
      _pauseEndTime = DateTime.now().add(Duration(seconds: durationSec));
    });

    // On garde juste le chronomètre permanent (ID 200) dans la barre d'état
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await NotificationService().showPauseChronometer(durationSec);
      } catch (e) {
        debugPrint('❌ Erreur affichage chrono pause: $e');
      }
    }

    _pauseTimer?.cancel();
    _pauseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_pauseRemainingSeconds > 0) {
          _pauseRemainingSeconds--;

          // ✨ ICI : Dès qu'il reste exactement 120 secondes (2 minutes), on envoie la notification !
          if (_pauseRemainingSeconds == 120) {
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
          content: Text('⏳ Tu as traîné $lateMinutes min... Ce temps a été rajouté à ton voyage en pénalité !'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _cancelTrip() async {
    _timer?.cancel();
    _pauseTimer?.cancel();
    NotificationService().cancelNotification(200);
    NotificationService().cancelNotification(201);

    await _travelService.recordFailedTrip(
      durationMinutes: widget.durationMinutes,
      plannedRoute: widget.plannedRoute,
    );

    await _travelService.setFocusActive(false);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _finishTrip() async {
    setState(() => _isCompleted = true);
    NotificationService().cancelNotification(200);
    NotificationService().cancelNotification(201);

    NotificationService().showNotification(
      id: 3,
      title: '🎉 Fin de session !',
      body: 'Ton trajet et ton temps de focus ont bien été enregistrés.',
    );

    await _travelService.processTripResults(
      totalFuelMinutes: widget.durationMinutes,
      plannedRoute: widget.plannedRoute,
    );

    if (!mounted) return;

    ActiveTimerDialogs.showFinishDialog(context, () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pauseTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  String _formatLiveTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    String s = seconds.toString().padLeft(2, '0');
    String m = minutes.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${hours}h ${m}m ${s}s';
    } else {
      return '${m}m ${s}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    int elapsedSeconds = (widget.durationMinutes * 60) - _remainingSeconds;

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

    int travelMinutes = widget.plannedTravelMinutes;
    int restMinutes = widget.durationMinutes - travelMinutes;
    if (restMinutes < 0) restMinutes = 0;

    double progress = (widget.durationMinutes * 60 > 0)
        ? (_remainingSeconds / (widget.durationMinutes * 60))
        : 0.0;

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
              child: ParallaxBackground(isRunning: !_isPaused && !_isCompleted),
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
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                    ),
                                    child: const Icon(Icons.arrow_back_ios_new, color: darkBlue, size: 20),
                                  ),
                                ),
                              ),
                              
                              Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 40.0), 
                                  child: SizedBox(
                                    width: 200, 
                                    height: 200,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _isPaused 
                                                ? (_pauseOvertimeSeconds > 0 ? Colors.red.withValues(alpha: 0.15) : const Color(0xFF1B2A3D)) 
                                                : const Color(0xFF1E2430),
                                            border: Border.all(
                                                color: _pauseOvertimeSeconds > 0 ? Colors.redAccent : Colors.white.withValues(alpha: 0.5), 
                                                width: 2.0),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _pauseOvertimeSeconds > 0 ? Colors.redAccent.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.2),
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
                                              _isPaused 
                                                  ? (_pauseOvertimeSeconds > 0 ? Colors.redAccent : Colors.blueAccent) 
                                                  : focusOrange,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _isPaused
                                              ? (_pauseOvertimeSeconds > 0 
                                                  ? "+${_formatLiveTime(_pauseOvertimeSeconds)}".replaceAll(' ', '\n')
                                                  : _formatLiveTime(_pauseRemainingSeconds).replaceAll(' ', '\n'))
                                              : _formatLiveTime(_remainingSeconds).replaceAll(' ', '\n'),
                                          style: TextStyle(
                                            fontSize: 26, 
                                            fontWeight: FontWeight.bold,
                                            color: _pauseOvertimeSeconds > 0 ? Colors.redAccent : Colors.white,
                                            height: 1.1,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 1),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.75), 
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            _isPaused 
                                ? (_pauseOvertimeSeconds > 0 ? '⚠️ Pause dépassée !' : '☕ Campement au feu de camp') 
                                : currentLegTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: darkBlue, 
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const Spacer(flex: 5),

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

                        ClipRRect(
                          borderRadius: BorderRadius.circular(16), 
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Plan de route :', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: darkBlue)), 
                                  const SizedBox(height: 4), 
                                  Wrap(
                                    spacing: 6, 
                                    runSpacing: 4,
                                    children: widget.plannedRoute.asMap().entries.map((entry) {
                                      int idx = entry.key;
                                      String city = entry.value;

                                      Color chipColor = (idx < currentLegIndex)
                                          ? Colors.green
                                          : (idx == currentLegIndex ? focusOrange : Colors.grey);
                                      IconData chipIcon = (idx < currentLegIndex)
                                          ? Icons.check_circle
                                          : (idx == currentLegIndex ? Icons.navigation : Icons.radio_button_unchecked);

                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                                        decoration: BoxDecoration(
                                          color: chipColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: chipColor, width: 1.0),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(chipIcon, size: 11, color: chipColor), 
                                            const SizedBox(width: 3),
                                            Text(city, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: chipColor)), 
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const Divider(height: 8, thickness: 0.5), 
                                  Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, color: darkBlue, size: 14), 
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text('Voyage : ${formatMinutesToHours(travelMinutes)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: darkBlue), overflow: TextOverflow.ellipsis),
                                      ),
                                      if (restMinutes > 0) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.hotel, color: Color(0xFF6A1B9A), size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text('Repos : ${formatMinutesToHours(restMinutes)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6A1B9A)), overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65), 
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isPaused
                                  ? (_pauseOvertimeSeconds > 0 
                                      ? '🚨 Reviens vite à la marche, tu perds du temps !' 
                                      : '🔥 En train de faire une pause au feu de camp...')
                                  : (_isCompleted ? 'Enregistrement de l\'étape...' : '🥾 Garde le rythme de marche, ne quitte pas l\'app !'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isPaused 
                                    ? (_pauseOvertimeSeconds > 0 ? Colors.redAccent : Colors.lightBlueAccent) 
                                    : const Color(0xFFFF6B6B), 
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
          ],
        ),
      ),
    );
  }
}