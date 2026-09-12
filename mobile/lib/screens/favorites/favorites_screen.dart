import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/article.dart';
import '../../services/favorites_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/article_card.dart';

/// Articles enregistrés par l'utilisateur (bouton étoile sur chaque carte),
/// stockés localement sur l'appareil — disponibles même hors ligne.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: Consumer<FavoritesService>(
        builder: (context, favorites, _) {
          if (!favorites.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (favorites.ids.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Aucun article enregistré pour l'instant.\nAppuyez sur l'étoile d'un article pour le retrouver ici.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return FutureBuilder<List<Article>>(
            future: firestoreService.fetchArticlesByIds(favorites.ids.toList()),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final articles = snapshot.data!.toList()
                ..sort((a, b) => b.datePublication.compareTo(a.datePublication));
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: articles.length,
                itemBuilder: (context, index) => ArticleCard(article: articles[index], showAngleBadge: true),
              );
            },
          );
        },
      ),
    );
  }
}
