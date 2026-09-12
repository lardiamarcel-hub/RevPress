import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/feed_repository.dart';
import '../../models/article.dart';
import '../../providers/library_provider.dart';
import '../../widgets/article_tile.dart';
import '../articles/article_detail_screen.dart';

/// Recherche plein texte dans les articles déjà téléchargés (titre, extrait,
/// nom du flux) — entièrement locale, aucune requête réseau.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Article> _results = [];
  bool _loading = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final repo = context.read<FeedRepository>();
    final results = await repo.listArticles(recherche: query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite(Article article) async {
    final repo = context.read<FeedRepository>();
    await repo.setFavorite(article.id, !article.favori);
    await _search(_controller.text);
  }

  Future<void> _openArticle(Article article) async {
    final repo = context.read<FeedRepository>();
    if (!article.lu) {
      await repo.setRead(article.id, true);
      if (mounted) context.read<LibraryProvider>().refreshUnreadCounts();
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ArticleDetailScreen(articleId: article.id)),
    );
    if (mounted) _search(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Rechercher dans les articles téléchargés…',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(
                  child: Text(
                    _controller.text.trim().isEmpty
                        ? 'Tapez un mot-clé pour chercher parmi les articles déjà téléchargés.'
                        : 'Aucun résultat.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final article = _results[index];
                    return ArticleTile(
                      article: article,
                      onTap: () => _openArticle(article),
                      onToggleFavorite: () => _toggleFavorite(article),
                    );
                  },
                ),
    );
  }
}
