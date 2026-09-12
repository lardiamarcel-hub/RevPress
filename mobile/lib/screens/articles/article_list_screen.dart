import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/feed_repository.dart';
import '../../models/article.dart';
import '../../models/article_query.dart';
import '../../providers/library_provider.dart';
import '../../widgets/article_tile.dart';
import 'article_detail_screen.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key, required this.query});

  final ArticleQuery query;

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  List<Article> _articles = [];
  bool _loading = true;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = context.read<FeedRepository>();
    final articles = await repo.listArticles(
      folderId: widget.query.scope == ArticleScope.folder ? widget.query.folderId : null,
      feedId: widget.query.scope == ArticleScope.feed ? widget.query.feedId : null,
      favoritesOnly: widget.query.scope == ArticleScope.favorites,
      unreadOnly: _unreadOnly,
    );
    if (!mounted) return;
    setState(() {
      _articles = articles;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    final library = context.read<LibraryProvider>();
    if (widget.query.scope == ArticleScope.feed && widget.query.feedId != null) {
      await library.refreshFeed(widget.query.feedId!);
    } else {
      await library.refreshAll();
    }
    await _load();
  }

  Future<void> _toggleFavorite(Article article) async {
    final repo = context.read<FeedRepository>();
    await repo.setFavorite(article.id, !article.favori);
    await _load();
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
    if (mounted) _load();
  }

  Future<void> _markAllRead() async {
    final repo = context.read<FeedRepository>();
    await repo.markAllRead(
      folderId: widget.query.scope == ArticleScope.folder ? widget.query.folderId : null,
      feedId: widget.query.scope == ArticleScope.feed ? widget.query.feedId : null,
    );
    if (mounted) context.read<LibraryProvider>().refreshUnreadCounts();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final showFeedName = widget.query.scope != ArticleScope.feed;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.query.titre),
        actions: [
          IconButton(
            tooltip: _unreadOnly ? 'Afficher tous les articles' : 'Afficher les non lus seulement',
            icon: Icon(_unreadOnly ? Icons.mark_email_unread : Icons.mark_email_unread_outlined),
            onPressed: () {
              setState(() => _unreadOnly = !_unreadOnly);
              _load();
            },
          ),
          IconButton(
            tooltip: 'Tout marquer comme lu',
            icon: const Icon(Icons.done_all),
            onPressed: _markAllRead,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _articles.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            "Aucun article ici pour l'instant.\nTirez vers le bas pour actualiser.",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _articles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final article = _articles[index];
                        return ArticleTile(
                          article: article,
                          showFeedName: showFeedName,
                          onTap: () => _openArticle(article),
                          onToggleFavorite: () => _toggleFavorite(article),
                        );
                      },
                    ),
            ),
    );
  }
}
