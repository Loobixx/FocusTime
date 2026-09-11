import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/city_network.dart';
import 'active_timer_screen.dart';

class SelectDestinationScreen extends StatefulWidget {
  final int selectedDurationMinutes;

  const SelectDestinationScreen({super.key, required this.selectedDurationMinutes});

  @override
  State<SelectDestinationScreen> createState() => _SelectDestinationScreenState();
}

class _SelectDestinationScreenState extends State<SelectDestinationScreen> {
  String _currentCity = 'Valenciennes';
  Set<String> _visitedCities = {};
  
  String? _midRouteDestination;
  int _midRouteProgress = 0;

  List<String> _plannedRoute = [];
  int _plannedTime = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Récupérer la ville actuelle
      final doc = await userRef.get();
      if (doc.exists && doc.data()!.containsKey('currentCity')) {
        _currentCity = doc.data()!['currentCity'];
      }

      // Récupérer le trajet en pause
      final statusDoc = await userRef.collection('travel').doc('status').get();
      if (statusDoc.exists) {
        _midRouteDestination = statusDoc.data()?['midRouteDestination'];
        _midRouteProgress = statusDoc.data()?['midRouteProgress'] ?? 0;
      }

      // Villes visitées
      final visitedSnapshot = await userRef.collection('visited_cities').get();
      
      setState(() {
        _visitedCities = visitedSnapshot.docs.map((d) => d.id).toSet();
        
        // Si un trajet est en pause, on l'ajoute obligatoirement en premier
        if (_midRouteDestination != null) {
          int fullTime = CityNetwork.getAvailableDestinations(_currentCity)[_midRouteDestination!] ?? 0;
          
          // NOUVEAU : Application de la réduction si déjà visitée
          if (_visitedCities.contains(_midRouteDestination)) {
            fullTime = fullTime ~/ 5;
          }
          
          int timeRemainingForThisCity = fullTime - _midRouteProgress;
          
          _plannedRoute.add(_midRouteDestination!);
          _plannedTime += timeRemainingForThisCity;
        }
        _isLoading = false;
      });
    }
  }

  void _undoLastCity() {
    // On empêche d'annuler la ville en cours de route (elle est obligatoire)
    if (_plannedRoute.isEmpty || (_plannedRoute.length == 1 && _midRouteDestination != null)) return;
    
    setState(() {
      _plannedRoute.removeLast();
      
      // Recalcul du temps
      _plannedTime = 0;
      String current = _currentCity;
      
      for (String city in _plannedRoute) {
        int fullTime = CityNetwork.getAvailableDestinations(current)[city] ?? 0;
        
        // NOUVEAU : Réduction du temps pour le recalcul
        if (_visitedCities.contains(city)) {
          fullTime = fullTime ~/ 5;
        }

        if (city == _midRouteDestination && current == _currentCity) {
          _plannedTime += (fullTime - _midRouteProgress);
        } else {
          _plannedTime += fullTime;
        }
        current = city;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF143063);
    const focusOrange = Color(0xFFFF8C00);

    String currentReferenceCity = _plannedRoute.isEmpty ? _currentCity : _plannedRoute.last;
    final Map<String, int> nextDestinations = CityNetwork.getAvailableDestinations(currentReferenceCity);

    return Scaffold(
      appBar: AppBar(title: const Text('Préparer le voyage'), backgroundColor: darkBlue, foregroundColor: Colors.white),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: darkBlue.withValues(alpha: 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Carburant (Focus)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('${widget.selectedDurationMinutes} min', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkBlue)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Trajet planifié', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('$_plannedTime min', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _plannedTime > widget.selectedDurationMinutes ? Colors.red : focusOrange)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Itinéraire :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue)),
                          if (_plannedRoute.length > (_midRouteDestination != null ? 1 : 0))
                            IconButton(icon: const Icon(Icons.undo, color: Colors.red), onPressed: _undoLastCity)
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0, runSpacing: 8.0,
                        children: [
                          Chip(label: Text(_currentCity), backgroundColor: darkBlue, labelStyle: const TextStyle(color: Colors.white)),
                          ..._plannedRoute.map((city) {
                            bool isMandatory = (city == _midRouteDestination);
                            return Chip(
                              label: Text(isMandatory ? '$city (En cours)' : city),
                              backgroundColor: isMandatory ? Colors.purple : focusOrange.withValues(alpha: 0.8),
                              labelStyle: const TextStyle(color: Colors.white),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: nextDestinations.length,
                    itemBuilder: (context, index) {
                        String destination = nextDestinations.keys.elementAt(index);
                        int travelTime = nextDestinations[destination]!;
                        bool isVisited = _visitedCities.contains(destination);

                        // NOUVEAU : On divise le temps affiché et ajouté par 5
                        if (isVisited) {
                          travelTime = travelTime ~/ 5;
                        }

                        return Card(
                        child: ListTile(
                          leading: Icon(isVisited ? Icons.check_circle : Icons.location_city, color: isVisited ? Colors.green : focusOrange),
                          title: Text(destination, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('$travelTime minutes', style: const TextStyle(color: Colors.grey)),
                          trailing: const Icon(Icons.add_circle_outline, color: darkBlue),
                          onTap: () {
                            if (_plannedTime >= widget.selectedDurationMinutes) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tu as utilisé tout ton carburant ! 🚗'), backgroundColor: Colors.redAccent, duration: Duration(seconds: 2)),
                              );
                              return;
                            }
                            setState(() {
                              _plannedRoute.add(destination);
                              _plannedTime += travelTime;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _plannedRoute.isNotEmpty ? focusOrange : Colors.grey, padding: const EdgeInsets.symmetric(vertical: 18)),
                      onPressed: _plannedRoute.isEmpty ? null : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActiveTimerScreen(
                              plannedRoute: _plannedRoute,
                              durationMinutes: widget.selectedDurationMinutes,
                            ),
                          ),
                        );
                      },
                      child: const Text('DÉMARRER LE VOYAGE', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}