/// Les 5 onglets thématiques de l'application, fixes et non négociables.
enum ThemeAngle {
  investissement,
  exportations,
  monnaieAes,
  financesPubliques,
  secteurPrive,
  horsSujet,
}

extension ThemeAngleX on ThemeAngle {
  /// Identifiant stocké tel quel dans Firestore (`angleThematique`).
  String get id {
    switch (this) {
      case ThemeAngle.investissement:
        return 'investissement';
      case ThemeAngle.exportations:
        return 'exportations';
      case ThemeAngle.monnaieAes:
        return 'monnaie_aes';
      case ThemeAngle.financesPubliques:
        return 'finances_publiques';
      case ThemeAngle.secteurPrive:
        return 'secteur_prive';
      case ThemeAngle.horsSujet:
        return 'hors_sujet';
    }
  }

  String get label {
    switch (this) {
      case ThemeAngle.investissement:
        return 'Investissement';
      case ThemeAngle.exportations:
        return 'Exportations & commerce';
      case ThemeAngle.monnaieAes:
        return 'Monnaie & AES';
      case ThemeAngle.financesPubliques:
        return 'Finances publiques';
      case ThemeAngle.secteurPrive:
        return 'Secteur privé';
      case ThemeAngle.horsSujet:
        return 'Hors sujet';
    }
  }

  String get description {
    switch (this) {
      case ThemeAngle.investissement:
        return "IDE, forums d'investissement, PPP, annonces de projets, financements de bailleurs";
      case ThemeAngle.exportations:
        return 'Filières export, balance commerciale, corridors logistiques, douanes AES';
      case ThemeAngle.monnaieAes:
        return 'BCEAO, UEMOA, monnaie AES, Banque de la Confédération AES';
      case ThemeAngle.financesPubliques:
        return 'Budget, loi de finances, dette souveraine, FMI/Banque mondiale';
      case ThemeAngle.secteurPrive:
        return 'CCI-BF, COGEF, PME, fiscalité des entreprises, climat des affaires';
      case ThemeAngle.horsSujet:
        return 'Non retenu dans les 5 onglets';
    }
  }

  static ThemeAngle fromId(String id) {
    return ThemeAngle.values.firstWhere(
      (angle) => angle.id == id,
      orElse: () => ThemeAngle.horsSujet,
    );
  }

  /// Les 5 onglets affichés dans la BottomNavigationBar (hors "hors sujet").
  static const List<ThemeAngle> navigationTabs = [
    ThemeAngle.investissement,
    ThemeAngle.exportations,
    ThemeAngle.monnaieAes,
    ThemeAngle.financesPubliques,
    ThemeAngle.secteurPrive,
  ];
}
