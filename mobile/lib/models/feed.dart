/// Un flux RSS/Atom suivi par l'utilisateur : un journal, un magazine, une
/// institution... N'importe quel site avec un flux (ou un flux découvrable
/// automatiquement à partir de son adresse) peut être ajouté.
class Feed {
  const Feed({
    required this.id,
    required this.nom,
    required this.siteUrl,
    required this.fluxUrl,
    required this.folderId,
    required this.accesLimite,
    required this.ordre,
    required this.derniereMaj,
    required this.derniereErreur,
  });

  final String id;
  final String nom;
  final String siteUrl;
  final String fluxUrl;

  /// `null` = flux non classé (affiché à part dans la bibliothèque).
  final String? folderId;

  /// Indicatif seulement : la source limite généralement l'accès aux articles
  /// complets (paywall). N'empêche pas d'afficher le résumé fourni par le flux.
  final bool accesLimite;

  final int ordre;
  final DateTime? derniereMaj;
  final String? derniereErreur;

  Feed copyWith({
    String? nom,
    String? siteUrl,
    String? fluxUrl,
    Object? folderId = _unset,
    bool? accesLimite,
    int? ordre,
    Object? derniereMaj = _unset,
    Object? derniereErreur = _unset,
  }) {
    return Feed(
      id: id,
      nom: nom ?? this.nom,
      siteUrl: siteUrl ?? this.siteUrl,
      fluxUrl: fluxUrl ?? this.fluxUrl,
      folderId: identical(folderId, _unset) ? this.folderId : folderId as String?,
      accesLimite: accesLimite ?? this.accesLimite,
      ordre: ordre ?? this.ordre,
      derniereMaj: identical(derniereMaj, _unset) ? this.derniereMaj : derniereMaj as DateTime?,
      derniereErreur:
          identical(derniereErreur, _unset) ? this.derniereErreur : derniereErreur as String?,
    );
  }
}

const _unset = Object();
