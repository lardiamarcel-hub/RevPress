/// Une source suggérée pour l'import en un tap. `url` est l'adresse du site
/// (pas forcément le flux exact) : elle est résolue par découverte
/// automatique au moment de l'import, comme pour tout ajout manuel.
class CuratedSource {
  const CuratedSource({
    required this.nom,
    required this.url,
    required this.dossier,
    this.accesLimite = false,
  });

  final String nom;
  final String url;
  final String dossier;
  final bool accesLimite;
}

/// Sélection de départ : presse burkinabè, institutions, presse régionale et
/// internationale utile pour une veille économique Burkina/UEMOA/AES.
/// Reprend la fiche de sources fournie par l'utilisateur. Les 3 sources dont
/// l'URL officielle restait à confirmer (ABIPEX, AMAP, ANP) n'y figurent
/// pas : elles peuvent être ajoutées manuellement dès que leur adresse est connue.
const List<CuratedSource> curatedSources = [
  // Presse burkinabè
  CuratedSource(nom: 'LeFaso.net', url: 'https://lefaso.net', dossier: 'Presse Burkina'),
  CuratedSource(nom: 'Burkina24', url: 'https://burkina24.com', dossier: 'Presse Burkina'),
  CuratedSource(nom: 'Sidwaya', url: 'https://www.sidwaya.bf', dossier: 'Presse Burkina'),
  CuratedSource(nom: "L'Observateur Paalga", url: 'https://www.lobservateur.bf', dossier: 'Presse Burkina'),
  CuratedSource(nom: 'Le Pays', url: 'https://lepays.bf', dossier: 'Presse Burkina'),
  CuratedSource(nom: "Aujourd'hui au Faso", url: 'https://www.aujourd8.net', dossier: 'Presse Burkina'),
  CuratedSource(nom: 'Wakat Séra', url: 'https://www.wakatsera.com', dossier: 'Presse Burkina'),
  CuratedSource(nom: 'FasoZine', url: 'https://www.fasozine.com', dossier: 'Presse Burkina'),

  // Presse économique spécialisée burkinabè
  CuratedSource(nom: "L'Économiste du Faso", url: 'https://www.leconomistedufaso.bf', dossier: 'Presse économique BF'),
  CuratedSource(nom: 'Les Échos du Faso', url: 'https://www.echosdufaso.com', dossier: 'Presse économique BF'),
  CuratedSource(nom: 'Investir au Burkina', url: 'https://www.investirauburkina.net', dossier: 'Presse économique BF'),

  // Institutions
  CuratedSource(nom: 'MINEFID', url: 'https://www.finances.gov.bf', dossier: 'Institutions'),
  CuratedSource(nom: 'Présidence du Faso', url: 'https://www.presidence.bf', dossier: 'Institutions'),
  CuratedSource(nom: 'BCEAO', url: 'https://www.bceao.int', dossier: 'Institutions'),
  CuratedSource(nom: 'Commission UEMOA', url: 'https://www.uemoa.int', dossier: 'Institutions'),
  CuratedSource(nom: 'BOAD', url: 'https://www.boad.org', dossier: 'Institutions'),
  CuratedSource(nom: 'BRVM', url: 'https://www.brvm.org', dossier: 'Institutions'),

  // Presse régionale / panafricaine
  CuratedSource(nom: 'Agence Ecofin', url: 'https://www.agenceecofin.com', dossier: 'Presse régionale'),
  CuratedSource(nom: 'Financial Afrik', url: 'https://www.financialafrik.com', dossier: 'Presse régionale'),
  CuratedSource(nom: 'Sika Finance', url: 'https://www.sikafinance.com', dossier: 'Presse régionale'),
  CuratedSource(nom: 'APA News', url: 'https://fr.apanews.net', dossier: 'Presse régionale'),
  CuratedSource(nom: 'La Tribune Afrique', url: 'https://afrique.latribune.fr', dossier: 'Presse régionale'),
  CuratedSource(nom: 'AllAfrica', url: 'https://allafrica.com', dossier: 'Presse régionale'),
  CuratedSource(
    nom: 'Jeune Afrique',
    url: 'https://www.jeuneafrique.com',
    dossier: 'Presse régionale',
    accesLimite: true,
  ),
  CuratedSource(
    nom: 'The Africa Report',
    url: 'https://www.theafricareport.com',
    dossier: 'Presse régionale',
    accesLimite: true,
  ),
  CuratedSource(nom: 'African Business', url: 'https://www.africanbusinessmagazine.com', dossier: 'Presse régionale'),

  // International
  CuratedSource(nom: 'Reuters Africa', url: 'https://www.reuters.com/world/africa', dossier: 'International'),
  CuratedSource(
    nom: 'Bloomberg Africa',
    url: 'https://www.bloomberg.com/africa',
    dossier: 'International',
    accesLimite: true,
  ),
  CuratedSource(
    nom: 'Financial Times Africa',
    url: 'https://www.ft.com/africa',
    dossier: 'International',
    accesLimite: true,
  ),
  CuratedSource(nom: 'The Economist', url: 'https://www.economist.com', dossier: 'International', accesLimite: true),
  CuratedSource(
    nom: 'Le Monde Afrique',
    url: 'https://www.lemonde.fr/afrique',
    dossier: 'International',
    accesLimite: true,
  ),
  CuratedSource(nom: 'Les Échos', url: 'https://www.lesechos.fr', dossier: 'International', accesLimite: true),
  CuratedSource(nom: 'Xinhua Afrique', url: 'https://french.xinhuanet.com', dossier: 'International'),
  CuratedSource(nom: 'FMI Burkina Faso', url: 'https://www.imf.org/en/countries/bfa', dossier: 'International'),
  CuratedSource(
    nom: 'Banque mondiale Burkina Faso',
    url: 'https://www.banquemondiale.org/fr/country/burkinafaso',
    dossier: 'International',
  ),
  CuratedSource(nom: 'OCDE', url: 'https://www.oecd.org', dossier: 'International'),
  CuratedSource(
    nom: 'Africa Confidential',
    url: 'https://www.africa-confidential.com',
    dossier: 'International',
    accesLimite: true,
  ),
];
