import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/city_network.dart';
import '../services/travel_service.dart';
import '../utils/time_formatter.dart';
import 'home_screen.dart';

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

  // Gestion des pauses et des arrivées
  final Set<int> _triggeredMilestoneIndexes = {};
  bool _isPaused = false;
  int _pauseRemainingSeconds = 0;
  DateTime? _pauseEndTime;
  Timer? _pauseTimer;

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
    final statusDoc = await userRef.collection('travel').doc('status').get();
    final visitedDoc = await userRef.collection('visited_cities').get();

    String currentCity = userDoc.data()?['currentCity'] ?? 'Valenciennes';
    String? midRouteDestination = statusDoc.data()?['midRouteDestination'];
    int midRouteProgress = statusDoc.data()?['midRouteProgress'] ?? 0;
    Set<String> visitedCities = visitedDoc.docs.map((d) => d.id).toSet();

    List<_LegTimeline> milestones = [];
    int totalCumulativeSeconds = 0;

    for (String city in widget.plannedRoute) {
      int fullTime = CityNetwork.getAvailableDestinations(currentCity)[city] ?? 0;
      if (visitedCities.contains(city)) {
        fullTime = fullTime ~/ 5;
      }

      int effectiveMinutes;
      if (city == midRouteDestination) {
        effectiveMinutes = fullTime - midRouteProgress;
      } else {
        effectiveMinutes = fullTime;
      }
      if (effectiveMinutes < 0) effectiveMinutes = 0;

      totalCumulativeSeconds += effectiveMinutes * 60;
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
      // Si on est en voyage et hors pause : triche détectée
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
        _showLostDialogAndPop();
        return;
      }

      // Si retour pendant ou après une pause autorisée
      if (_isPaused && _pauseEndTime != null) {
        final now = DateTime.now();
        final diffSeconds = _pauseEndTime!.difference(now).inSeconds;

        if (diffSeconds > 0) {
          // Pause encore en cours
          setState(() {
            _pauseRemainingSeconds = diffSeconds;
          });
        } else {
          // Retard : calcul de la pénalité de temps
          final lateSeconds = diffSeconds.abs();
          _endPauseWithPenalty(lateSeconds);
        }
      }
    }
  }

  void _showLostDialogAndPop() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🧭 Tu t\'es perdu !'),
        content: const Text('Tu as quitté l\'application hors d\'un moment de pause autorisé. Ton trajet a été annulé.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Compris', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;

          // Vérification du passage à une destination
          int elapsed = (widget.durationMinutes * 60) - _remainingSeconds;
          for (int i = 0; i < _routeMilestones.length; i++) {
            if (elapsed >= _routeMilestones[i].cumulativeSeconds && !_triggeredMilestoneIndexes.contains(i)) {
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

  // --- POPUP DE PROPOSITION DE PAUSE À L'ARRIVÉE ---
  void _openArrivalPauseDialog(String cityName) {
    _timer?.cancel();
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('📍 Arrivée à $cityName !', style: const TextStyle(fontWeight: FontWeight.bold, color: darkBlue, fontSize: 18)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                Navigator.pop(dialogContext);
                _startTimer();
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu as atteint cette étape. Tu peux t\'accorder une pause ou continuer directement ton expédition :',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPauseOptionButton(dialogContext, '0 min', 0, focusOrange),
                _buildPauseOptionButton(dialogContext, '5 min', 1, focusOrange),
                _buildPauseOptionButton(dialogContext, '10 min', 10, focusOrange),
                _buildPauseOptionButton(dialogContext, '15 min', 15, focusOrange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOptionButton(BuildContext dialogCtx, String label, int minutes, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(dialogCtx);
        if (minutes == 0) {
          _startTimer();
        } else {
          _startPauseTimer(minutes);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
        ),
      ),
    );
  }

  void _startPauseTimer(int minutes) {
    final durationSec = minutes * 60;
    setState(() {
      _isPaused = true;
      _pauseRemainingSeconds = durationSec;
      _pauseEndTime = DateTime.now().add(Duration(seconds: durationSec));
    });

    _pauseTimer?.cancel();
    _pauseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_pauseRemainingSeconds > 0) {
          _pauseRemainingSeconds--;
        } else {
          _endPauseNormal();
        }
      });
    });
  }

  void _endPauseNormal() {
    _pauseTimer?.cancel();
    setState(() {
      _isPaused = false;
      _pauseRemainingSeconds = 0;
      _pauseEndTime = null;
    });
    _startTimer();
  }

  // Fin de pause avec application de la pénalité de retard
  void _endPauseWithPenalty(int lateSeconds) {
    _pauseTimer?.cancel();
    setState(() {
      _isPaused = false;
      _pauseRemainingSeconds = 0;
      _pauseEndTime = null;

      // Ajoute le temps de retard au chronomètre restant (recul dans le temps)
      _remainingSeconds += lateSeconds;
    });

    _startTimer();

    int lateMinutes = (lateSeconds / 60).ceil();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏳ Tu as dépassé ta pause de $lateMinutes min. Ce temps a été rajouté à ton voyage !'),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _cancelTrip() async {
    _timer?.cancel();
    _pauseTimer?.cancel();

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

  void _showAbandonConfirmationDialog() {
    const darkBlue = Color(0xFF143063);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Abandonner le voyage ?', style: TextStyle(fontWeight: FontWeight.bold, color: darkBlue)),
        content: const Text('Si tu quittes maintenant, toute ta progression sur cette session sera perdue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _cancelTrip();
            },
            child: const Text('Oui, abandonner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _finishTrip() async {
    setState(() => _isCompleted = true);

    await _travelService.processTripResults(
      totalFuelMinutes: widget.durationMinutes,
      plannedRoute: widget.plannedRoute,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Fin de session !'),
        content: const Text('Ton trajet et ton temps de focus ont bien été enregistrés.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Continuer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
          currentLegTitle = "Direction ${_routeMilestones[i].destination}";
          currentLegIndex = i;
          isStillTravelling = true;
          break;
        }
      }
      if (!isStillTravelling) {
        currentLegTitle = "En repos à ${_routeMilestones.last.destination}";
        currentLegIndex = _routeMilestones.length;
      }
    } else if (widget.plannedRoute.isNotEmpty) {
      currentLegTitle = "Direction ${widget.plannedRoute.first}";
    }

    int travelMinutes = widget.plannedTravelMinutes;
    int restMinutes = widget.durationMinutes - travelMinutes;
    if (restMinutes < 0) restMinutes = 0;

    double progress = (widget.durationMinutes * 60 > 0)
        ? (_remainingSeconds / (widget.durationMinutes * 60))
        : 0.0;

    return WillPopScope(
      onWillPop: () async {
        _showAbandonConfirmationDialog();
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/fond2.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
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
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: InkWell(
                              onTap: _showAbandonConfirmationDialog,
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
                        ),

                        const Spacer(flex: 1),

                        Text(
                          _isPaused ? '☕ Pause autorisée' : currentLegTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: darkBlue,
                            shadows: [Shadow(color: Colors.white70, blurRadius: 10)],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const Spacer(flex: 1),

                        // Cadran central
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 270,
                                height: 270,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.25),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 246,
                                height: 246,
                                child: CircularProgressIndicator(
                                  value: _isPaused ? null : progress.clamp(0.0, 1.0),
                                  strokeWidth: 6,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _isPaused ? Colors.blueAccent : focusOrange,
                                  ),
                                ),
                              ),
                              Container(
                                width: 215,
                                height: 215,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isPaused ? const Color(0xFF1B2A3D) : const Color(0xFF1E2430),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isPaused
                                          ? _formatLiveTime(_pauseRemainingSeconds)
                                          : _formatLiveTime(_remainingSeconds),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _isPaused ? 'FIN DE LA PAUSE' : 'TEMPS RESTANT',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

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

                        const Spacer(flex: 1),

                        // Plan de route
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Plan de route :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkBlue)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
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
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: chipColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: chipColor, width: 1.2),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(chipIcon, size: 14, color: chipColor),
                                            const SizedBox(width: 4),
                                            Text(city, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: chipColor)),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, color: darkBlue, size: 18),
                                      const SizedBox(width: 6),
                                      Text('Voyage : ${formatMinutesToHours(travelMinutes)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkBlue)),
                                      if (restMinutes > 0) ...[
                                        const SizedBox(width: 12),
                                        const Icon(Icons.hotel, color: Color(0xFF6A1B9A), size: 18),
                                        const SizedBox(width: 6),
                                        Text('Repos : ${formatMinutesToHours(restMinutes)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6A1B9A))),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const Spacer(flex: 1),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Text(
                            _isPaused
                                ? '☕ Pause en cours — Tu peux quitter l\'appli temporairement'
                                : (_isCompleted ? 'Enregistrement du trajet...' : '⚠️ Ne quitte pas cette application !'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _isPaused ? Colors.blue.shade900 : Colors.redAccent,
                              shadows: const [Shadow(color: Colors.white, blurRadius: 8)],
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