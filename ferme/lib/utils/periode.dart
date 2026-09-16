enum PeriodePreset { moisEnCours, campagneAgricole, tout, personnalisee }

class Periode {
  final DateTime? debut;
  final DateTime? fin;
  final PeriodePreset preset;

  const Periode({required this.debut, required this.fin, required this.preset});

  static Periode moisEnCours() {
    final maintenant = DateTime.now();
    final debut = DateTime(maintenant.year, maintenant.month, 1);
    final finMoisSuivant = DateTime(maintenant.year, maintenant.month + 1, 1);
    return Periode(
      debut: debut,
      fin: finMoisSuivant.subtract(const Duration(seconds: 1)),
      preset: PeriodePreset.moisEnCours,
    );
  }

  /// 12 derniers mois glissants, approximation simple d'une campagne agricole.
  static Periode campagneAgricole() {
    final maintenant = DateTime.now();
    final debut = DateTime(maintenant.year - 1, maintenant.month, maintenant.day);
    return Periode(debut: debut, fin: maintenant, preset: PeriodePreset.campagneAgricole);
  }

  static Periode tout() => const Periode(debut: null, fin: null, preset: PeriodePreset.tout);

  static Periode personnalisee(DateTime debut, DateTime fin) =>
      Periode(debut: debut, fin: fin, preset: PeriodePreset.personnalisee);

  String get libelle {
    switch (preset) {
      case PeriodePreset.moisEnCours:
        return 'Ce mois-ci';
      case PeriodePreset.campagneAgricole:
        return 'Campagne (12 mois)';
      case PeriodePreset.tout:
        return 'Tout';
      case PeriodePreset.personnalisee:
        return 'Période choisie';
    }
  }
}
