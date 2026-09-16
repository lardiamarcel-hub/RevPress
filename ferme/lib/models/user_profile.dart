import 'user_role.dart';

class UserProfile {
  final String uid;
  final String nom;
  final UserRole role;
  final bool actif;

  const UserProfile({
    required this.uid,
    required this.nom,
    required this.role,
    required this.actif,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      nom: (data['nom'] as String?) ?? '',
      role: UserRoleX.fromValue(data['role'] as String?),
      actif: (data['actif'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'role': role.value,
        'actif': actif,
      };
}
