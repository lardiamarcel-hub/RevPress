import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/theme_angles.dart';

class Digest {
  final String id;
  final DateTime date;
  final String frequence;
  final Map<ThemeAngle, List<String>> articlesParAngle;
  final List<String> syntheseGlobale;

  const Digest({
    required this.id,
    required this.date,
    required this.frequence,
    required this.articlesParAngle,
    required this.syntheseGlobale,
  });

  factory Digest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawMap = (data['articlesParAngle'] as Map<String, dynamic>?) ?? {};
    final articlesParAngle = <ThemeAngle, List<String>>{
      for (final entry in rawMap.entries)
        ThemeAngleX.fromId(entry.key): List<String>.from(entry.value as List? ?? []),
    };
    return Digest(
      id: doc.id,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      frequence: data['frequence'] as String? ?? 'quotidien',
      articlesParAngle: articlesParAngle,
      syntheseGlobale: List<String>.from(data['syntheseGlobale'] as List? ?? []),
    );
  }
}
