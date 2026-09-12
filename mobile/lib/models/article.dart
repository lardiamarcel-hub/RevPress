/// Un article tel que fourni par le flux de sa source (titre, résumé/contenu
/// tel que publié, lien, date). Rien n'est réécrit ni résumé par une IA —
/// c'est exactement ce que le flux RSS/Atom du site propose à ses lecteurs.
class Article {
  const Article({
    required this.id,
    required this.feedId,
    required this.feedNom,
    required this.titre,
    required this.lien,
    required this.contenu,
    required this.datePublication,
    required this.lu,
    required this.favori,
  });

  final String id;
  final String feedId;
  final String feedNom;
  final String titre;
  final String lien;
  final String contenu;
  final DateTime datePublication;
  final bool lu;
  final bool favori;

  /// Court extrait pour l'affichage en liste (une ligne, longueur limitée).
  String get extrait {
    final oneLine = contenu.replaceAll('\n', ' ').trim();
    if (oneLine.length <= 160) return oneLine;
    return '${oneLine.substring(0, 160).trim()}…';
  }
}

/// Un article tel qu'extrait d'un flux, avant d'être inséré en base (pas
/// encore d'id local, de statut lu/favori...).
class ArticleDraft {
  const ArticleDraft({
    required this.guid,
    required this.title,
    required this.link,
    required this.snippet,
    required this.publishedAt,
  });

  final String guid;
  final String title;
  final String link;
  final String snippet;
  final DateTime publishedAt;
}
