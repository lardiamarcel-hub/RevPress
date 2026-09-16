import 'package:cloud_firestore/cloud_firestore.dart';

const recetteSources = ['vente récolte', 'autre'];

class Recette {
  final String id;
  final double montant;
  final DateTime date;
  final String source;
  final String note;
  final String saisiParUid;
  final String saisiParNom;

  const Recette({
    required this.id,
    required this.montant,
    required this.date,
    required this.source,
    required this.note,
    required this.saisiParUid,
    required this.saisiParNom,
  });

  factory Recette.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Recette(
      id: doc.id,
      montant: (data['montant'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      source: data['source'] as String? ?? 'autre',
      note: data['note'] as String? ?? '',
      saisiParUid: data['saisi_par_uid'] as String? ?? '',
      saisiParNom: data['saisi_par_nom'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'montant': montant,
        'date': Timestamp.fromDate(date),
        'source': source,
        'note': note,
        'saisi_par_uid': saisiParUid,
        'saisi_par_nom': saisiParNom,
      };
}
