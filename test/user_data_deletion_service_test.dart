import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_time/services/user_data_deletion_service.dart';

void main() {
  group('UserDataDeletionService', () {
    late FakeFirebaseFirestore firestore;
    late UserDataDeletionService deletionService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      deletionService = UserDataDeletionService(firestore: firestore);
    });

    test(
      'deletes account data, including legacy and stopped-city collections',
      () async {
        final userRef = firestore.collection('users').doc('user-123');
        await userRef.set({'email': 'person@example.com'});

        for (final collectionName
            in UserDataDeletionService.userSubcollections) {
          await userRef.collection(collectionName).doc('record').set({
            'value': 1,
          });
        }

        await deletionService.deleteUserData(userRef.id);

        expect((await userRef.get()).exists, isFalse);
        for (final collectionName
            in UserDataDeletionService.userSubcollections) {
          expect(
            (await userRef.collection(collectionName).get()).docs,
            isEmpty,
            reason: '$collectionName should be deleted',
          );
        }
      },
    );

    test('deletes collections in multiple batches', () async {
      final userRef = firestore.collection('users').doc('user-with-many-trips');
      final batch = firestore.batch();
      for (var index = 0; index < 450; index++) {
        batch.set(userRef.collection('travel_history').doc('trip-$index'), {
          'index': index,
        });
      }
      await batch.commit();

      await deletionService.deleteUserData(userRef.id);

      expect(
        (await userRef.collection('travel_history').get()).docs,
        isEmpty,
      );
    });

    test('rejects an empty user ID without deleting any data', () async {
      await expectLater(
        deletionService.deleteUserData(' '),
        throwsArgumentError,
      );
      expect((await firestore.collection('users').get()).docs, isEmpty);
    });
  });
}
