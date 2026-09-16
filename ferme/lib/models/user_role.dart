enum UserRole { promoteur, superviseur, collaborateur }

extension UserRoleX on UserRole {
  String get value => name;

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.collaborateur,
    );
  }

  String get libelle {
    switch (this) {
      case UserRole.promoteur:
        return 'Promoteur';
      case UserRole.superviseur:
        return 'Superviseur';
      case UserRole.collaborateur:
        return 'Collaborateur';
    }
  }
}
