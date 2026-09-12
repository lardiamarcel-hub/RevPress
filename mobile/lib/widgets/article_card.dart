import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article.dart';
import '../services/favorites_service.dart';
import '../utils/relative_time.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article, this.showAngleBadge = false});

  final Article article;
  final bool showAngleBadge;

  @override
  Widget build(BuildContext context) {
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
                    '${article.source} · ${formatRelativeTime(article.datePublication)}',
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
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse(article.url), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text("Lire l'original"),
                  ),
                ),
                Consumer<FavoritesService>(
                  builder: (context, favorites, _) {
                    final isFavorite = favorites.isFavorite(article.id);
                    return IconButton(
                      tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? Colors.amber[700] : null,
                      ),
                      onPressed: () => favorites.toggle(article.id),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Partager',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(text: '${article.titre}\n${article.url}', subject: article.titre),
                  ),
                ),
              ],
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
