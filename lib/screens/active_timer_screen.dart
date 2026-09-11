import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/travel_service.dart';
import 'home_screen.dart';

class ActiveTimerScreen extends StatefulWidget {
  final List<String> plannedRoute;
  final int durationMinutes;

  const ActiveTimerScreen({
    super.key,
    required this.plannedRoute,
    required this.durationMinutes,
  });

  @override
  State<ActiveTimerScreen> createState() => _ActiveTimerScreenState();
}

class _ActiveTimerScreenState extends State<ActiveTimerScreen> with WidgetsBindingObserver {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isCompleted = false;
  bool _hasCheated = false; // NOUVEAU : On retient s'il a quitté l'appli
  final TravelService _travelService = TravelService();

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
    
    _startTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si l'application passe en arrière-plan
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!_isCompleted) {
        _hasCheated = true; // Il s'est perdu !
        _timer?.cancel();
        _travelService.setFocusActive(false);
      }
    } 
    // Quand il revient sur l'application
    else if (state == AppLifecycleState.resumed) {
      if (_hasCheated) {
        _showLostDialogAndPop();
      }
    }
  }

  // --- NOUVELLE FONCTION : Afficher le message d'erreur ---
  void _showLostDialogAndPop() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🧭 Tu t\'es perdu !'),
        content: const Text('Tu as quitté l\'application pendant ton voyage. Ton trajet a été annulé et tu es de retour à ton point de départ.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _finishTrip();
        }
      });
    });
  }

  void _cancelTrip() {
    _timer?.cancel();
    _travelService.setFocusActive(false);

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

    await _travelService.processTripResults(
      totalFuelMinutes: widget.durationMinutes,
      plannedRoute: widget.plannedRoute,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Fin de session !'),
        content: const Text('Ton trajet a bien été enregistré.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    String finalDestination = widget.plannedRoute.isNotEmpty ? widget.plannedRoute.last : "Inconnue";

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Stack(
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(image: AssetImage('assets/fond2.png'), fit: BoxFit.cover),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Voyage vers $finalDestination',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF143063)),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      width: 260, height: 260,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.25)),
                      child: Center(
                        child: Container(
                          width: 215, height: 215,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black87),
                          child: Center(
                            child: Text(
                              _formatTime(_remainingSeconds),
                              style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  Text(
                    _isCompleted ? 'Calcul du trajet en cours...' : 'Ne quitte pas cette application !',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 40),
                  if (!_isCompleted)
                    TextButton.icon(
                      onPressed: () => _cancelTrip(),
                      icon: const Icon(Icons.cancel, color: Colors.redAccent),
                      label: const Text(
                        'Abandonner',
                        style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}