import 'package:cloud_firestore/cloud_firestore.dart';

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

  Stream<bool> watchAdminStatus(String? email) {
    if (email == null || email.trim().isEmpty) return Stream.value(false);

    final normalizedEmail = email.trim().toLowerCase();
    return _admins
        .doc(normalizedEmail)
        .snapshots()
        .map(
          (document) => document.exists && document.data()?['enabled'] == true,
        );
  }

  Stream<List<AdminAccount>> watchAdmins() {
    return _admins
        .orderBy(FieldPath.documentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => AdminAccount(
                  email: document.data()['email'] as String? ?? document.id,
                  enabled: document.data()['enabled'] == true,
                ),
              )
              .toList(growable: false),
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
