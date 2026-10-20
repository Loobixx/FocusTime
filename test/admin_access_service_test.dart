import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_time/services/admin_access_service.dart';

void main() {
  group('AdminAccessService', () {
    late FakeFirebaseFirestore firestore;
    late AdminAccessService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = AdminAccessService(firestore: firestore);
    });

    test('reports only enabled allowlist entries as administrators', () async {
      await firestore.collection('admin_emails').doc('active@example.com').set({
        'enabled': true,
      });
      await firestore
          .collection('admin_emails')
          .doc('disabled@example.com')
          .set({'enabled': false});

      expect(
        await service.watchAdminStatus('ACTIVE@example.com').first,
        isTrue,
      );
      expect(
        await service.watchAdminStatus('disabled@example.com').first,
        isFalse,
      );
      expect(
        await service.watchAdminStatus('unknown@example.com').first,
        isFalse,
      );
      expect(await service.watchAdminStatus(null).first, isFalse);
    });

    test('allows an administrator to activate another account', () async {
      await service.setAdminStatus(
        '  New.Admin@Example.com ',
        enabled: true,
        currentAdminEmail: 'owner@example.com',
        actorUid: 'owner-uid',
      );

      final document = await firestore
          .collection('admin_emails')
          .doc('new.admin@example.com')
          .get();
      expect(document.data()?['email'], 'new.admin@example.com');
      expect(document.data()?['enabled'], isTrue);
      expect(document.data()?['updatedBy'], 'owner-uid');
    });

    test('prevents changing own status and rejects invalid addresses', () {
      expect(
        () => service.setAdminStatus(
          'OWNER@example.com',
          enabled: false,
          currentAdminEmail: 'owner@example.com',
          actorUid: 'owner-uid',
        ),
        throwsStateError,
      );
      expect(
        () => AdminAccessService.normalizeEmail('not-an-email'),
        throwsFormatException,
      );
    });

    test(
      'lists entries in a stable order including disabled accounts',
      () async {
        await firestore.collection('admin_emails').doc('zulu@example.com').set({
          'email': 'zulu@example.com',
          'enabled': false,
        });
        await firestore.collection('admin_emails').doc('alpha@example.com').set(
          {'email': 'alpha@example.com', 'enabled': true},
        );

        final admins = await service.watchAdmins().first;
        expect(admins.map((admin) => admin.email).toList(), [
          'alpha@example.com',
          'zulu@example.com',
        ]);
        expect(admins.last.enabled, isFalse);
      },
    );
  });
}
