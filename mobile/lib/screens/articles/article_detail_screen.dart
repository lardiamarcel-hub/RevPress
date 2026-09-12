import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../db/feed_repository.dart';
import '../../models/article.dart';
import '../../providers/library_provider.dart';
import '../../utils/relative_time.dart';

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({super.key, required this.articleId});

  final String articleId;

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  Article? _article;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<FeedRepository>();
    final article = await repo.getArticle(widget.articleId);
    if (!mounted) return;
    setState(() {
      _article = article;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final article = _article;
    if (article == null) return;
    final repo = context.read<FeedRepository>();
    await repo.setFavorite(article.id, !article.favori);
    await _load();
  }

  Future<void> _toggleRead() async {
    final article = _article;
    if (article == null) return;
    final repo = context.read<FeedRepository>();
    await repo.setRead(article.id, !article.lu);
    if (mounted) context.read<LibraryProvider>().refreshUnreadCounts();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final article = _article;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (article != null) ...[
            IconButton(
              tooltip: article.favori ? 'Retirer des favoris' : 'Ajouter aux favoris',
              icon: Icon(
                article.favori ? Icons.star : Icons.star_border,
                color: article.favori ? Colors.amber[700] : null,
              ),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              tooltip: article.lu ? 'Marquer non lu' : 'Marquer lu',
              icon: Icon(article.lu ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined),
              onPressed: _toggleRead,
            ),
            IconButton(
              tooltip: 'Partager',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: '${article.titre}\n${article.lien}', subject: article.titre),
              ),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : article == null
              ? const Center(child: Text('Article introuvable.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(article.titre, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      '${article.feedNom} · ${formatRelativeTime(article.datePublication)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    if (article.contenu.isNotEmpty)
                      Text(article.contenu, style: Theme.of(context).textTheme.bodyLarge)
                    else
                      const Text(
                        "Cette source ne fournit pas d'extrait dans son flux.",
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => launchUrl(Uri.parse(article.lien), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text("Lire l'article complet sur le site d'origine"),
                    ),
                  ],
                ),
    );
  }
}
