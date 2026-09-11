import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/theme_angles.dart';

enum Fiabilite { haute, moyenne, faible }

Fiabilite _fiabiliteFromString(String? value) {
  switch (value) {
    case 'haute':
      return Fiabilite.haute;
    case 'faible':
      return Fiabilite.faible;
    case 'moyenne':
    default:
      return Fiabilite.moyenne;
  }
}

class Article {
  final String id;
  final String titre;
  final String source;
  final String sourceId;
  final String url;
  final DateTime datePublication;
  final DateTime dateCollecte;
  final ThemeAngle angleThematique;
  final String? resume;
  final String langueOriginale;
  final Fiabilite fiabilite;
  final bool accesPayant;
  final String? eventGroupId;

  const Article({
    required this.id,
    required this.titre,
    required this.source,
    required this.sourceId,
    required this.url,
    required this.datePublication,
    required this.dateCollecte,
    required this.angleThematique,
    required this.resume,
    required this.langueOriginale,
    required this.fiabilite,
    required this.accesPayant,
    required this.eventGroupId,
  });

  factory Article.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Article(
      id: doc.id,
      titre: data['titre'] as String? ?? '(sans titre)',
      source: data['source'] as String? ?? '',
      sourceId: data['sourceId'] as String? ?? '',
      url: data['url'] as String? ?? '',
      datePublication: (data['datePublication'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateCollecte: (data['dateCollecte'] as Timestamp?)?.toDate() ?? DateTime.now(),
      angleThematique: ThemeAngleX.fromId(data['angleThematique'] as String? ?? ''),
      resume: data['resume'] as String?,
      langueOriginale: data['langueOriginale'] as String? ?? 'fr',
      fiabilite: _fiabiliteFromString(data['fiabilite'] as String?),
      accesPayant: data['accesPayant'] as bool? ?? false,
      eventGroupId: data['eventGroupId'] as String?,
    );
  }
}
