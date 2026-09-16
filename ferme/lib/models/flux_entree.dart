import 'depense.dart';
import 'recette.dart';

enum TypeFlux { depense, recette }

/// Wrapper commun pour afficher dépenses et recettes dans un même flux
/// chronologique (écran Suivi).
class FluxEntree {
  final TypeFlux type;
  final DateTime date;
  final double montant;
  final String libelle;
  final String note;
  final String saisiParNom;
  final Depense? depense;
  final Recette? recette;

  const FluxEntree._({
    required this.type,
    required this.date,
    required this.montant,
    required this.libelle,
    required this.note,
    required this.saisiParNom,
    this.depense,
    this.recette,
  });

  factory FluxEntree.deDepense(Depense d) => FluxEntree._(
        type: TypeFlux.depense,
        date: d.date,
        montant: d.montant,
        libelle: d.ligne,
        note: d.note,
        saisiParNom: d.saisiParNom,
        depense: d,
      );

  factory FluxEntree.deRecette(Recette r) => FluxEntree._(
        type: TypeFlux.recette,
        date: r.date,
        montant: r.montant,
        libelle: r.source,
        note: r.note,
        saisiParNom: r.saisiParNom,
        recette: r,
      );

  static List<FluxEntree> combiner(List<Depense> depenses, List<Recette> recettes) {
    final entrees = [
      ...depenses.map(FluxEntree.deDepense),
      ...recettes.map(FluxEntree.deRecette),
    ];
    entrees.sort((a, b) => b.date.compareTo(a.date));
    return entrees;
  }
}
