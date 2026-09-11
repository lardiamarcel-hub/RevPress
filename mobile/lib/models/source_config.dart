enum SourceCategorie {
  presseBf,
  presseEcoBf,
  institution,
  presseRegionale,
  presseAes,
  international,
}

class SourceConfig {
  final String id;
  final String nom;
  final String domaine;
  final String? fluxRss;
  final SourceCategorie categorie;
  final bool accesPayant;
  final bool actif;

  const SourceConfig({
    required this.id,
    required this.nom,
    required this.domaine,
    required this.fluxRss,
    required this.categorie,
    required this.accesPayant,
    required this.actif,
  });

  String get methodeCollecte => fluxRss != null ? 'rss' : 'google_news_rss';

  factory SourceConfig.fromFirestore(String id, Map<String, dynamic> data) {
    return SourceConfig(
      id: id,
      nom: data['nom'] as String? ?? id,
      domaine: data['domaine'] as String? ?? '',
      fluxRss: data['fluxRss'] as String?,
      categorie: _categorieFromString(data['categorie'] as String?),
      accesPayant: data['accesPayant'] as bool? ?? false,
      actif: data['actif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'domaine': domaine,
      'fluxRss': fluxRss,
      'categorie': categorie.name,
      'accesPayant': accesPayant,
      'actif': actif,
      'methodeCollecte': methodeCollecte,
    };
  }

  SourceConfig copyWith({bool? actif}) {
    return SourceConfig(
      id: id,
      nom: nom,
      domaine: domaine,
      fluxRss: fluxRss,
      categorie: categorie,
      accesPayant: accesPayant,
      actif: actif ?? this.actif,
    );
  }

  static SourceCategorie _categorieFromString(String? value) {
    return SourceCategorie.values.firstWhere(
      (c) => c.name == value,
      orElse: () => SourceCategorie.presseBf,
    );
  }
}
