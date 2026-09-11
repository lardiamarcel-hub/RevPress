import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article, this.showAngleBadge = false});

  final Article article;
  final bool showAngleBadge;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'fr_FR');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAngleBadge)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _FiabiliteBadge(fiabilite: article.fiabilite),
              ),
            Text(
              article.titre,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${article.source} · ${dateFormat.format(article.datePublication)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (!showAngleBadge) _FiabiliteBadge(fiabilite: article.fiabilite),
              ],
            ),
            if (article.resume != null) ...[
              const SizedBox(height: 8),
              Text(article.resume!, style: Theme.of(context).textTheme.bodyMedium),
            ] else if (article.accesPayant) ...[
              const SizedBox(height: 8),
              Text(
                'Article payant — résumé non disponible.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => launchUrl(Uri.parse(article.url), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text("Lire l'original"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiabiliteBadge extends StatelessWidget {
  const _FiabiliteBadge({required this.fiabilite});

  final Fiabilite fiabilite;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    switch (fiabilite) {
      case Fiabilite.haute:
        color = Colors.green;
        label = 'Haute importance';
        break;
      case Fiabilite.moyenne:
        color = Colors.orange;
        label = 'Importance moyenne';
        break;
      case Fiabilite.faible:
        color = Colors.grey;
        label = 'Importance faible';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
