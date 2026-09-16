import 'package:cloud_firestore/cloud_firestore.dart';

class Depense {
  final String id;
  final double montant;
  final DateTime date;
  final String ligne;
  final String note;
  final String saisiParUid;
  final String saisiParNom;
  final String saisiParRole;

  const Depense({
    required this.id,
    required this.montant,
    required this.date,
    required this.ligne,
    required this.note,
    required this.saisiParUid,
    required this.saisiParNom,
    required this.saisiParRole,
  });

  factory Depense.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Depense(
      id: doc.id,
      montant: (data['montant'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      ligne: data['ligne'] as String? ?? 'autre',
      note: data['note'] as String? ?? '',
      saisiParUid: data['saisi_par_uid'] as String? ?? '',
      saisiParNom: data['saisi_par_nom'] as String? ?? '',
      saisiParRole: data['saisi_par_role'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'montant': montant,
        'date': Timestamp.fromDate(date),
        'ligne': ligne,
        'note': note,
        'saisi_par_uid': saisiParUid,
        'saisi_par_nom': saisiParNom,
        'saisi_par_role': saisiParRole,
      };
}
