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

  Future<void> recordFailedTrip({
    required int durationMinutes,
    required List<String> plannedRoute,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final currentCity = (await userRef.get()).data()?['currentCity'] ?? 'Valenciennes';

    await userRef.collection('travel_history').add({
      'date': FieldValue.serverTimestamp(),
      'startCity': currentCity,
      'endCity': plannedRoute.isNotEmpty ? plannedRoute.last : currentCity,
      'durationMinutes': durationMinutes,
      'plannedRoute': plannedRoute,
      'isCompleted': false,
      'isFailed': true,
      'visitedDuringTripCount': 0,
    });
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

    // ✨ GESTION DU MODE ADMIN (totalFuelMinutes == 0)
    if (totalFuelMinutes == 0 && plannedRoute.isNotEmpty) {
      String finalCity = plannedRoute.last;
      String startCity = (await userRef.get()).data()?['currentCity'] ?? 'Valenciennes';

      // 1. Toutes les villes du trajet sont "visitées/traversées" (pour le bonus x5)
      for (String city in plannedRoute) {
        await userRef.collection('visited_cities').doc(city).set({
          'visitedAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Seule la DERNIÈRE ville (destination finale où l'on s'arrête) donne droit aux récompenses/compagnons !
      await userRef.collection('stopped_cities').doc(finalCity).set({
        'stoppedAt': FieldValue.serverTimestamp(),
      });

      // Historique, position et nettoyage...
      await userRef.collection('travel_history').add({
        'date': FieldValue.serverTimestamp(),
        'startCity': startCity,
        'endCity': finalCity,
        'durationMinutes': 0,
        'plannedRoute': plannedRoute,
        'isCompleted': true,
        'isFailed': false,
        'visitedDuringTripCount': plannedRoute.length,
      });

      await userRef.update({'currentCity': finalCity});
      await statusRef.set({
        'isFocusActive': false,
        'midRouteDestination': FieldValue.delete(),
        'midRouteProgress': 0,
        'activeDestination': FieldValue.delete(),
        'endTime': FieldValue.delete(),
      }, SetOptions(merge: true));

      return;
    }

    // --- MODE NORMAL (Reste de ta boucle de calcul de carburant) ---
    final statusDoc = await statusRef.get();
    final statusData = statusDoc.data() ?? {};
    
    String currentCity = (await userRef.get()).data()?['currentCity'] ?? 'Valenciennes';
    String? midRouteDestination = statusData['midRouteDestination'];
    int midRouteProgress = statusData['midRouteProgress'] ?? 0;

    final visitedSnapshot = await userRef.collection('visited_cities').get();
    Set<String> visitedCities = visitedSnapshot.docs.map((d) => d.id).toSet();

    int remainingFuel = totalFuelMinutes;
    List<String> citiesToVisit = List.from(plannedRoute);
    List<String> successfullyReachedCities = []; // Pour suivre où l'on s'est arrêté

    while (remainingFuel > 0 && citiesToVisit.isNotEmpty) {
      String nextDestination = citiesToVisit.first;
      int fullTravelTime = CityNetwork.getAvailableDestinations(currentCity)[nextDestination] ?? 0;
      
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
        
        successfullyReachedCities.add(currentCity);
        
        // Ville traversée / visitée
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

    // 🏆 Si on est arrivé au bout d'au moins une ville, la dernière atteinte est celle où l'on s'arrête !
    if (successfullyReachedCities.isNotEmpty) {
      String finalStoppedCity = successfullyReachedCities.last;
      await userRef.collection('stopped_cities').doc(finalStoppedCity).set({
        'stoppedAt': FieldValue.serverTimestamp(),
      });
    }

    int visitedDuringTrip = plannedRoute.length - citiesToVisit.length;

    await userRef.collection('travel_history').add({
      'date': FieldValue.serverTimestamp(),
      'startCity': (await userRef.get()).data()?['currentCity'] ?? 'Valenciennes',
      'endCity': currentCity,
      'durationMinutes': totalFuelMinutes,
      'plannedRoute': plannedRoute,
      'isCompleted': midRouteDestination == null,
      'isFailed': false,
      'visitedDuringTripCount': visitedDuringTrip,
    });

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