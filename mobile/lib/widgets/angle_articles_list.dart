import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../providers/articles_provider.dart';
import '../services/cloud_functions_service.dart';
import 'article_card.dart';

class AngleArticlesList extends StatefulWidget {
  const AngleArticlesList({super.key});

  @override
  State<AngleArticlesList> createState() => _AngleArticlesListState();
}

class _AngleArticlesListState extends State<AngleArticlesList> {
  Fiabilite? _filtre;

  Future<void> _refresh(BuildContext context) async {
    final result = await context.read<CloudFunctionsService>().manualRefresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ArticlesProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final articles = _filtre == null
            ? provider.articles
            : provider.articles.where((a) => a.fiabilite == _filtre).toList();

        return Column(
          children: [
            _FiabiliteFilterBar(
              selected: _filtre,
              onSelected: (value) => setState(() => _filtre = value),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: articles.isEmpty ? _buildEmptyState(provider) : _buildList(articles),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(ArticlesProvider provider) {
    final message = _filtre != null
        ? "Aucun article avec ce niveau d'importance pour l'instant."
        : "Aucun article pour cette thématique pour l'instant.\nTirez vers le bas pour actualiser.";
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildList(List<Article> articles) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: articles.length,
      itemBuilder: (context, index) => ArticleCard(article: articles[index]),
    );
  }
}

class _FiabiliteFilterBar extends StatelessWidget {
  const _FiabiliteFilterBar({required this.selected, required this.onSelected});

  final Fiabilite? selected;
  final ValueChanged<Fiabilite?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip(context, null, 'Toutes'),
            const SizedBox(width: 6),
            _chip(context, Fiabilite.haute, 'Haute'),
            const SizedBox(width: 6),
            _chip(context, Fiabilite.moyenne, 'Moyenne'),
            const SizedBox(width: 6),
            _chip(context, Fiabilite.faible, 'Faible'),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, Fiabilite? value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onSelected(value),
    );
  }
}
