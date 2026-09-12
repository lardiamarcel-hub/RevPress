import 'package:flutter/material.dart';

import '../models/article.dart';
import '../utils/relative_time.dart';

class ArticleTile extends StatelessWidget {
  const ArticleTile({
    super.key,
    required this.article,
    required this.onTap,
    required this.onToggleFavorite,
    this.showFeedName = true,
  });

  final Article article;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final bool showFeedName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: article.lu ? FontWeight.normal : FontWeight.bold,
      color: article.lu ? theme.disabledColor : null,
    );
    return ListTile(
      onTap: onTap,
      leading: Icon(
        article.lu ? Icons.circle_outlined : Icons.circle,
        size: 10,
        color: article.lu ? theme.disabledColor : theme.colorScheme.primary,
      ),
      title: Text(article.titre, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            showFeedName
                ? '${article.feedNom} · ${formatRelativeTime(article.datePublication)}'
                : formatRelativeTime(article.datePublication),
            style: theme.textTheme.bodySmall,
          ),
          if (article.extrait.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              article.extrait,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: article.lu ? theme.disabledColor : null,
              ),
            ),
          ],
        ],
      ),
      isThreeLine: true,
      trailing: IconButton(
        tooltip: article.favori ? 'Retirer des favoris' : 'Ajouter aux favoris',
        icon: Icon(
          article.favori ? Icons.star : Icons.star_border,
          color: article.favori ? Colors.amber[700] : null,
        ),
        onPressed: onToggleFavorite,
      ),
    );
  }
}
