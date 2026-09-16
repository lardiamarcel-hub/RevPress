import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatage.dart';

class EntreeTile extends StatelessWidget {
  const EntreeTile({
    super.key,
    required this.estDepense,
    required this.montant,
    required this.libelle,
    required this.date,
    required this.note,
    this.sousTitre,
    this.onTap,
    this.onSupprimer,
  });

  final bool estDepense;
  final double montant;
  final String libelle;
  final DateTime date;
  final String note;
  final String? sousTitre;
  final VoidCallback? onTap;
  final VoidCallback? onSupprimer;

  @override
  Widget build(BuildContext context) {
    final couleur = estDepense ? AppTheme.orDepense : AppTheme.orRecette;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: couleur.withOpacity(0.12),
          child: Icon(estDepense ? Icons.arrow_downward : Icons.arrow_upward, color: couleur),
        ),
        title: Text(libelle, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            formaterDate(date),
            if (sousTitre != null && sousTitre!.isNotEmpty) sousTitre!,
            if (note.isNotEmpty) note,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${estDepense ? '-' : '+'} ${formaterMontant(montant)}',
              style: TextStyle(color: couleur, fontWeight: FontWeight.bold),
            ),
            if (onSupprimer != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onSupprimer,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}
