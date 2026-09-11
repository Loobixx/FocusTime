import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/city_network.dart';

class TravelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 1. Lancer ou annuler le focus (Enregistre l'état, la destination et l'heure de fin) ---
  Future<void> setFocusActive(bool isActive, {List<String>? plannedRoute, int? durationMinutes}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, dynamic> data = {
      'isFocusActive': isActive,
    };

    if (isActive && plannedRoute != null && plannedRoute.isNotEmpty && durationMinutes != null) {
      data['activeDestination'] = plannedRoute.last;
      // On calcule l'heure exacte de fin locale et on la convertit pour Firestore
      data['endTime'] = Timestamp.fromDate(DateTime.now().add(Duration(minutes: durationMinutes)));
    } else if (!isActive) {
      // Nettoyage : on supprime la destination et le temps à la fin ou si on annule
      data['activeDestination'] = FieldValue.delete();
      data['endTime'] = FieldValue.delete();
    }

    await _firestore.collection('users').doc(user.uid).collection('travel').doc('status').set(data, SetOptions(merge: true));
  }


  // --- 2. Fonction appelée à la FIN du chrono pour calculer l'avancée ---
  Future<void> processTripResults({
    required int totalFuelMinutes,
    required List<String> plannedRoute,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final statusRef = userRef.collection('travel').doc('status');

    // Récupérer l'état actuel et les villes visitées
    final statusDoc = await statusRef.get();
    final statusData = statusDoc.data() ?? {};
    
    String currentCity = (await userRef.get()).data()?['currentCity'] ?? 'Valenciennes';
    String? midRouteDestination = statusData['midRouteDestination'];
    int midRouteProgress = statusData['midRouteProgress'] ?? 0;

    // Récupérer les villes déjà connues
    final visitedSnapshot = await userRef.collection('visited_cities').get();
    Set<String> visitedCities = visitedSnapshot.docs.map((d) => d.id).toSet();

    int remainingFuel = totalFuelMinutes;
    List<String> citiesToVisit = List.from(plannedRoute);

    // Traiter le trajet ville par ville
    while (remainingFuel > 0 && citiesToVisit.isNotEmpty) {
      String nextDestination = citiesToVisit.first;
      
      int fullTravelTime = CityNetwork.getAvailableDestinations(currentCity)[nextDestination] ?? 0;
      
      // Le voyage rapide !
      // Si la ville d'arrivée est déjà connue, on divise le temps par 5
      if (visitedCities.contains(nextDestination)) {
        fullTravelTime = fullTravelTime ~/ 5; 
      }

      int timeNeeded = fullTravelTime;

      if (midRouteDestination == nextDestination) {
        timeNeeded = fullTravelTime - midRouteProgress;
      } else {
        midRouteProgress = 0; 
      }

      if (remainingFuel >= timeNeeded) {
        remainingFuel -= timeNeeded;
        currentCity = nextDestination;
        midRouteDestination = null;
        midRouteProgress = 0;
        
        await userRef.collection('visited_cities').doc(currentCity).set({
          'visitedAt': FieldValue.serverTimestamp(),
        });
        
        citiesToVisit.removeAt(0); 
      } else {
        midRouteDestination = nextDestination;
        midRouteProgress += remainingFuel; 
        remainingFuel = 0;
      }
    }

    // Sauvegarder le nouvel état
    await userRef.update({'currentCity': currentCity});
    await statusRef.set({
      'isFocusActive': false,
      'midRouteDestination': midRouteDestination,
      'midRouteProgress': midRouteProgress,
      'activeDestination': FieldValue.delete(),
      'endTime': FieldValue.delete(),
    }, SetOptions(merge: true));
  }
}