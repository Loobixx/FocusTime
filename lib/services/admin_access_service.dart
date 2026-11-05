import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminAccount {
  const AdminAccount({required this.email, required this.enabled});

  final String email;
  final bool enabled;
}

class AdminAccessService {
  AdminAccessService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _admins =>
      _firestore.collection('admin_emails');

  bool _canQueryProtectedAdminCollection() {
    try {
      if (Firebase.apps.isEmpty) {
        // Environnement de test unitaire avec FakeFirebaseFirestore.
        return true;
      }
      final user = FirebaseAuth.instance.currentUser;
      return user != null && user.emailVerified;
    } catch (_) {
      return true;
    }
  }

  Stream<bool> watchAdminStatus(String? email) {
    if (email == null || email.trim().isEmpty) return Stream.value(false);
    if (!_canQueryProtectedAdminCollection()) return Stream.value(false);

    final normalizedEmail = email.trim().toLowerCase();
    return _admins
        .doc(normalizedEmail)
        .snapshots()
        .transform(
          StreamTransformer<
            DocumentSnapshot<Map<String, dynamic>>,
            bool
          >.fromHandlers(
            handleData: (document, sink) {
              sink.add(
                document.exists && document.data()?['enabled'] == true,
              );
            },
            handleError: (error, stackTrace, sink) {
              if (error is FirebaseException &&
                  error.code == 'permission-denied') {
                sink.add(false);
                return;
              }
              sink.addError(error, stackTrace);
            },
          ),
        );
  }

  Stream<List<AdminAccount>> watchAdmins() {
    if (!_canQueryProtectedAdminCollection()) {
      return Stream.value(const <AdminAccount>[]);
    }

    return _admins
        .orderBy(FieldPath.documentId)
        .snapshots()
        .transform(
          StreamTransformer<
            QuerySnapshot<Map<String, dynamic>>,
            List<AdminAccount>
          >.fromHandlers(
            handleData: (snapshot, sink) {
              sink.add(
                snapshot.docs
                    .map(
                      (document) => AdminAccount(
                        email:
                            document.data()['email'] as String? ?? document.id,
                        enabled: document.data()['enabled'] == true,
                      ),
                    )
                    .toList(growable: false),
              );
            },
            handleError: (error, stackTrace, sink) {
              if (error is FirebaseException &&
                  error.code == 'permission-denied') {
                sink.add(const <AdminAccount>[]);
                return;
              }
              sink.addError(error, stackTrace);
            },
          ),
        );
  }

  Future<void> setAdminStatus(
    String email, {
    required bool enabled,
    required String currentAdminEmail,
    required String actorUid,
  }) async {
    final normalizedEmail = normalizeEmail(email);
    final normalizedCurrentAdminEmail = normalizeEmail(currentAdminEmail);
    if (normalizedEmail == normalizedCurrentAdminEmail) {
      throw StateError(
        'Vous ne pouvez pas modifier votre propre statut admin.',
      );
    }

    await _admins.doc(normalizedEmail).set({
      'email': normalizedEmail,
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': actorUid,
    }, SetOptions(merge: true));
  }

  static String normalizeEmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      throw const FormatException('Saisissez une adresse e-mail valide.');
    }
    return normalizedEmail;
  }
}
