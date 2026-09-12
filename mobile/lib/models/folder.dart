/// Un dossier regroupant des flux, comme dans Feedly (ex. « Presse Burkina »,
/// « International »). Purement organisationnel — l'utilisateur choisit lui-même
/// ses dossiers, il n'y a pas de classement automatique par IA.
class Folder {
  const Folder({required this.id, required this.nom, required this.ordre});

  final String id;
  final String nom;
  final int ordre;

  Folder copyWith({String? nom, int? ordre}) {
    return Folder(id: id, nom: nom ?? this.nom, ordre: ordre ?? this.ordre);
  }
}
