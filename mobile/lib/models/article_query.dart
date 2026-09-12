enum ArticleScope { all, favorites, folder, feed }

/// Décrit quels articles afficher dans l'écran de liste : tous, favoris,
/// ceux d'un dossier, ou ceux d'un flux précis.
class ArticleQuery {
  const ArticleQuery({required this.scope, this.folderId, this.feedId, required this.titre});

  final ArticleScope scope;
  final String? folderId;
  final String? feedId;
  final String titre;

  static const all = ArticleQuery(scope: ArticleScope.all, titre: 'Tous les articles');
  static const favorites = ArticleQuery(scope: ArticleScope.favorites, titre: 'Favoris');

  factory ArticleQuery.folder(String id, String nom) =>
      ArticleQuery(scope: ArticleScope.folder, folderId: id, titre: nom);

  factory ArticleQuery.feed(String id, String nom) =>
      ArticleQuery(scope: ArticleScope.feed, feedId: id, titre: nom);
}
