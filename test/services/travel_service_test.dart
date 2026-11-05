import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_time/services/travel_service.dart';

void main() {
  group('TravelService', () {
    const testUid = 'traveler-uid-1';
    late FakeFirebaseFirestore firestore;
    late TravelService travelService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      travelService = TravelService(
        firestore: firestore,
        currentUserIdResolver: () => testUid,
      );
    });

    test('setFocusActive enregistre puis nettoie la destination active et endTime', () async {
      await travelService.setFocusActive(
        true,
        plannedRoute: ['Le cercle des anciens', 'Le miroir d\'Emeraude'],
        durationMinutes: 45,
      );

      final statusRef = firestore
          .collection('users')
          .doc(testUid)
          .collection('travel')
          .doc('status');

      final activeSnap = await statusRef.get();
      expect(activeSnap.data()?['isFocusActive'], isTrue);
      expect(activeSnap.data()?['activeDestination'], 'Le miroir d\'Emeraude');
      expect(activeSnap.data()?['endTime'], isA<Timestamp>());

      await travelService.setFocusActive(false);

      final inactiveSnap = await statusRef.get();
      expect(inactiveSnap.data()?['isFocusActive'], isFalse);
      expect(inactiveSnap.data()?.containsKey('activeDestination'), isFalse);
      expect(inactiveSnap.data()?.containsKey('endTime'), isFalse);
    });

    test('recordFailedTrip archive un voyage échoué dans travel_history', () async {
      await firestore.collection('users').doc(testUid).set({
        'currentCity': 'Le village de Néris',
      });

      await travelService.recordFailedTrip(
        durationMinutes: 30,
        plannedRoute: ['Le cercle des anciens'],
      );

      final historyDocs = await firestore
          .collection('users')
          .doc(testUid)
          .collection('travel_history')
          .get();

      expect(historyDocs.docs, hasLength(1));
      final entry = historyDocs.docs.first.data();
      expect(entry['startCity'], 'Le village de Néris');
      expect(entry['endCity'], 'Le cercle des anciens');
      expect(entry['durationMinutes'], 30);
      expect(entry['isCompleted'], isFalse);
      expect(entry['isFailed'], isTrue);
      expect(entry['visitedDuringTripCount'], 0);
    });

    test('processTripResults en mode admin (totalFuelMinutes == 0) traverse tout l\'itinéraire et s\'arrête à la destination finale', () async {
      final userRef = firestore.collection('users').doc(testUid);
      await userRef.set({'currentCity': 'Le village de Néris'});

      final route = [
        'Le cercle des anciens',
        'Le miroir d\'Emeraude',
        'L\'Antre d\'émeraude',
      ];

      final stoppedCity = await travelService.processTripResults(
        totalFuelMinutes: 0,
        plannedRoute: route,
      );

      expect(stoppedCity, 'L\'Antre d\'émeraude');
      expect((await userRef.get()).data()?['currentCity'], 'L\'Antre d\'émeraude');

      final visitedDocs = await userRef.collection('visited_cities').get();
      expect(visitedDocs.docs.map((d) => d.id).toSet(), equals(route.toSet()));

      final stoppedDocs = await userRef.collection('stopped_cities').get();
      expect(stoppedDocs.docs.map((d) => d.id).toList(), ['L\'Antre d\'émeraude']);
    });

    test('processTripResults enregistre un trajet partiel (midRouteProgress) puis le complète à la reprise', () async {
      final userRef = firestore.collection('users').doc(testUid);
      await userRef.set({'currentCity': 'Le village de Néris'});

      // Liaison Le village de Néris -> L'Halte blanche = 60 minutes.
      // 1re session : seulement 25 minutes de focus.
      final firstStop = await travelService.processTripResults(
        totalFuelMinutes: 25,
        plannedRoute: ['L\'Halte blanche'],
      );

      expect(firstStop, isNull);
      expect((await userRef.get()).data()?['currentCity'], 'Le village de Néris');

      final statusAfterFirst = await userRef.collection('travel').doc('status').get();
      expect(statusAfterFirst.data()?['midRouteDestination'], 'L\'Halte blanche');
      expect(statusAfterFirst.data()?['midRouteProgress'], 25);

      // 2e session : reprise avec [Le village de Néris, L'Halte blanche] et 35 minutes.
      // Le service doit ignorer currentCity en tête de route et conserver les 25 min déjà faites.
      final secondStop = await travelService.processTripResults(
        totalFuelMinutes: 35,
        plannedRoute: ['Le village de Néris', 'L\'Halte blanche'],
      );

      expect(secondStop, 'L\'Halte blanche');
      expect((await userRef.get()).data()?['currentCity'], 'L\'Halte blanche');

      final statusAfterSecond = await userRef.collection('travel').doc('status').get();
      expect(statusAfterSecond.data()?['midRouteDestination'], isNull);
      expect(statusAfterSecond.data()?['midRouteProgress'], 0);

      final stoppedDocs = await userRef.collection('stopped_cities').get();
      expect(stoppedDocs.docs.map((d) => d.id).toList(), ['L\'Halte blanche']);
    });

    test('processTripResults applique la réduction ~/ 3 sur les villes déjà visitées', () async {
      final userRef = firestore.collection('users').doc(testUid);
      await userRef.set({'currentCity': 'Le village de Néris'});
      // 'Le cercle des anciens' est déjà visitée -> coût 30 ~/ 3 = 10 min
      await userRef.collection('visited_cities').doc('Le cercle des anciens').set({});

      // Avec 40 min de focus : 10 min pour 'Le cercle des anciens' + 30 min pour 'Le miroir d\'Emeraude'
      final finalStop = await travelService.processTripResults(
        totalFuelMinutes: 40,
        plannedRoute: ['Le cercle des anciens', 'Le miroir d\'Emeraude'],
      );

      expect(finalStop, 'Le miroir d\'Emeraude');
      expect((await userRef.get()).data()?['currentCity'], 'Le miroir d\'Emeraude');
    });

    test('ne fait aucune écriture si aucun utilisateur n\'est connecté', () async {
      final unauthenticatedService = TravelService(
        firestore: firestore,
        currentUserIdResolver: () => null,
      );

      await unauthenticatedService.setFocusActive(
        true,
        plannedRoute: ['Le cercle des anciens'],
        durationMinutes: 30,
      );
      await unauthenticatedService.recordFailedTrip(
        durationMinutes: 30,
        plannedRoute: ['Le cercle des anciens'],
      );
      final result = await unauthenticatedService.processTripResults(
        totalFuelMinutes: 30,
        plannedRoute: ['Le cercle des anciens'],
      );

      expect(result, isNull);
      expect((await firestore.collection('users').get()).docs, isEmpty);
    });
  });
}
