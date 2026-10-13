enum AppUserRole { lise, standard }

class UserRoles {
  UserRoles._();

  static const liseEmail = 'lise.adam.va@gmail.com';

  static AppUserRole fromEmail(String? email) {
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail == liseEmail) return AppUserRole.lise;
    return AppUserRole.standard;
  }

  static bool isLise(String? email) => fromEmail(email) == AppUserRole.lise;
}
