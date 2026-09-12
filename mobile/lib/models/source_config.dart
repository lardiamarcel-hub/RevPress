enum AccesType { gratuit, gratuitPartiel, payant }

extension AccesTypeX on AccesType {
  String get id {
    switch (this) {
      case AccesType.gratuit:
        return 'gratuit';
      case AccesType.gratuitPartiel:
        return 'gratuit_partiel';
      case AccesType.payant:
        return 'payant';
    }
  }

  String get label {
    switch (this) {
      case AccesType.gratuit:
        return 'Gratuit';
      case AccesType.gratuitPartiel:
        return 'Gratuit (partiel)';
      case AccesType.payant:
        return 'Payant';
    }
  }

  static AccesType fromId(String? id) {
    return AccesType.values.firstWhere((a) => a.id == id, orElse: () => AccesType.gratuit);
  }
}

class SourceConfig {
  final String id;
  final String nom;
  final String url;
  final AccesType acces;

  /// Identifiants des onglets couverts par cette source (parmi les 5 angles,
  /// ou `transverseOngletId` pour "tous les onglets"). Purement informatif :
  /// le classement réel de chaque article se fait par l'IA, article par
  /// article, indépendamment de ce champ.
  final List<String> onglets;
  final bool actif;

  const SourceConfig({
    required this.id,
    required this.nom,
    required this.url,
    required this.acces,
    required this.onglets,
    required this.actif,
  });

  /// Une source "payante" n'est jamais résumée : seuls titre + lien sont conservés.
  bool get accesPayant => acces == AccesType.payant;

  factory SourceConfig.fromFirestore(String id, Map<String, dynamic> data) {
    return SourceConfig(
      id: id,
      nom: data['nom'] as String? ?? id,
      url: data['url'] as String? ?? '',
      acces: AccesTypeX.fromId(data['acces'] as String?),
      onglets: List<String>.from(data['onglets'] as List? ?? const []),
      actif: data['actif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'url': url,
      'acces': acces.id,
      'onglets': onglets,
      'actif': actif,
    };
  }

  SourceConfig copyWith({
    String? nom,
    String? url,
    AccesType? acces,
    List<String>? onglets,
    bool? actif,
  }) {
    return SourceConfig(
      id: id,
      nom: nom ?? this.nom,
      url: url ?? this.url,
      acces: acces ?? this.acces,
      onglets: onglets ?? this.onglets,
      actif: actif ?? this.actif,
    );
  }
}
