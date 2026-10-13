enum AppUserRole { admin, lise, standard }

class UserRoles {
  UserRoles._();

  static const adminEmail = 'yoprudhomme59@gmail.com';
  static const liseEmail = 'lise.adam.va@gmail.com';

  // These roles customize the client UI; backend permissions must use Firebase rules.
  static AppUserRole fromEmail(String? email) {
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail == adminEmail) return AppUserRole.admin;
    if (normalizedEmail == liseEmail) return AppUserRole.lise;
    return AppUserRole.standard;
  }

  static bool isAdmin(String? email) => fromEmail(email) == AppUserRole.admin;

  static bool isLise(String? email) => fromEmail(email) == AppUserRole.lise;
}
