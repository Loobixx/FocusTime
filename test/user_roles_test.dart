import 'package:flutter_test/flutter_test.dart';
import 'package:focus_time/utils/user_roles.dart';

void main() {
  group('UserRoles', () {
    test('recognizes the configured admin email case-insensitively', () {
      expect(UserRoles.isAdmin('yoprudhomme59@gmail.com'), isTrue);
      expect(UserRoles.isAdmin('  YOPRUDHOMME59@GMAIL.COM '), isTrue);
      expect(UserRoles.fromEmail('yoprudhomme59@gmail.com'), AppUserRole.admin);
    });

    test('recognizes Lise separately from the admin', () {
      expect(UserRoles.isLise('lise.adam.va@gmail.com'), isTrue);
      expect(UserRoles.fromEmail('lise.adam.va@gmail.com'), AppUserRole.lise);
      expect(UserRoles.isAdmin('lise.adam.va@gmail.com'), isFalse);
    });

    test(
      'treats missing and unrecognized email addresses as standard users',
      () {
        expect(UserRoles.fromEmail(null), AppUserRole.standard);
        expect(UserRoles.fromEmail(''), AppUserRole.standard);
        expect(
          UserRoles.fromEmail('someone@example.com'),
          AppUserRole.standard,
        );
      },
    );
  });
}
