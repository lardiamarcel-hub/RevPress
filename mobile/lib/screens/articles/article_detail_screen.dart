import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../db/feed_repository.dart';
import '../../models/article.dart';
import '../../providers/library_provider.dart';
import '../../services/ai_summary_service.dart';
import '../../utils/relative_time.dart';
import '../settings/settings_screen.dart';

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({super.key, required this.articleId});

  final String articleId;

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  Article? _article;
  bool _loading = true;
  bool _generatingSummary = false;

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

  Future<void> _generateAiSummary() async {
    final article = _article;
    if (article == null) return;
    final repo = context.read<FeedRepository>();
    final apiKey = await repo.getSetting(anthropicApiKeySettingKey);
    if (!mounted) return;
    if (apiKey == null || apiKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aucune clé API Anthropic configurée.'),
          action: SnackBarAction(
            label: 'Réglages',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _generatingSummary = true);
    try {
      final summary = await AiSummaryService().summarize(
        apiKey: apiKey,
        titre: article.titre,
        contenu: article.contenu,
      );
      await repo.setAiSummary(article.id, summary);
      await _load();
    } on AiSummaryException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _generatingSummary = false);
    }
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
                    if (article.resumeIa != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_awesome, size: 16, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Text('Résumé IA', style: Theme.of(context).textTheme.labelLarge),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(article.resumeIa!),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (article.contenu.isNotEmpty)
                      Text(article.contenu, style: Theme.of(context).textTheme.bodyLarge)
                    else
                      const Text(
                        "Cette source ne fournit pas d'extrait dans son flux.",
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _generatingSummary ? null : _generateAiSummary,
                      icon: _generatingSummary
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(article.resumeIa != null ? 'Regénérer le résumé IA' : "Résumer avec l'IA"),
                    ),
                    const SizedBox(height: 12),
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
