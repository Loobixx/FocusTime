import 'package:flutter_test/flutter_test.dart';
import 'package:focus_time/utils/user_roles.dart';

void main() {
  group('UserRoles', () {
    test('recognizes Lise separately from standard users', () {
      expect(UserRoles.isLise('lise.adam.va@gmail.com'), isTrue);
      expect(UserRoles.fromEmail('lise.adam.va@gmail.com'), AppUserRole.lise);
    });

    test(
      'does not infer administrator access from an email address',
      () {
        expect(UserRoles.fromEmail(null), AppUserRole.standard);
        expect(UserRoles.fromEmail(''), AppUserRole.standard);
        expect(
          UserRoles.fromEmail('yoprudhomme59@gmail.com'),
          AppUserRole.standard,
        );
        expect(
          UserRoles.fromEmail('someone@example.com'),
          AppUserRole.standard,
        );
      },
    );
  });
}
