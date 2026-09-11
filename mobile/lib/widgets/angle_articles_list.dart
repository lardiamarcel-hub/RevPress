import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/articles_provider.dart';
import 'article_card.dart';

class AngleArticlesList extends StatelessWidget {
  const AngleArticlesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ArticlesProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(child: Text('Erreur de chargement : ${provider.error}'));
        }
        if (provider.articles.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                "Aucun article pour cette thématique pour l'instant.\nLa prochaine collecte ajoutera de nouveaux articles.",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: provider.articles.length,
          itemBuilder: (context, index) => ArticleCard(article: provider.articles[index]),
        );
      },
    );
  }
}
