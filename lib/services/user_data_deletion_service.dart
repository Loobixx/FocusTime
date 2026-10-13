import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataDeletionService {
  UserDataDeletionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const userSubcollections = [
    'travel',
    'travel_history',
    'visited_cities',
    'stopped_cities',
    'history',
  ];

  final FirebaseFirestore _firestore;

  Future<void> deleteUserData(String uid) async {
    if (uid.trim().isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'User ID cannot be empty.');
    }

    final userRef = _firestore.collection('users').doc(uid);
    for (final collectionName in userSubcollections) {
      await _deleteCollectionContents(userRef.collection(collectionName));
    }

    await userRef.delete();
  }

  Future<void> _deleteCollectionContents(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection
          .orderBy(FieldPath.documentId)
          .limit(400)
          .get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }
}
