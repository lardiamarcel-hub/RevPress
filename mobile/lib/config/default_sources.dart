import '../models/source_config.dart';

/// Liste de sources par défaut, utilisée uniquement pour l'écran Réglages
/// (affichage/édition). La source de vérité en production est la collection
/// Firestore `sources`, amorcée côté Cloud Functions par `seedSources`.
const List<SourceConfig> defaultSources = [
  // Presse burkinabè générale
  SourceConfig(id: 'lefaso_net', nom: 'LeFaso.net', domaine: 'lefaso.net', fluxRss: 'https://lefaso.net/spip.php?page=backend', categorie: SourceCategorie.presseBf, accesPayant: false, actif: true),
  SourceConfig(id: 'burkina24', nom: 'Burkina24', domaine: 'burkina24.com', fluxRss: 'https://burkina24.com/feed/', categorie: SourceCategorie.presseBf, accesPayant: false, actif: true),
  SourceConfig(id: 'sidwaya', nom: 'Sidwaya', domaine: 'sidwaya.bf', fluxRss: null, categorie: SourceCategorie.presseBf, accesPayant: false, actif: true),
  SourceConfig(id: 'lobservateur', nom: "L'Observateur Paalga", domaine: 'lobservateur.bf', fluxRss: null, categorie: SourceCategorie.presseBf, accesPayant: false, actif: true),
  SourceConfig(id: 'lepays', nom: 'Le Pays', domaine: 'lepays.bf', fluxRss: null, categorie: SourceCategorie.presseBf, accesPayant: false, actif: true),
  SourceConfig(id: 'aujourd8', nom: 'Aujourd\'hui au Faso', domaine: 'aujourd8.net', fluxRss: 'https://aujourd8.net/feed/', categorie: SourceCategorie.presseBf, accesPayant: false, actif: true),
  SourceConfig(id: 'wakatsera', nom: 'Wakat Séra', domaine: 'wakatsera.com', fluxRss: 'https://wakatsera.com/feed/', categorie: SourceCategorie.presseBf, accesPayant: false, actif: true),

  // Presse économique spécialisée burkinabè (prioritaire)
  SourceConfig(id: 'leconomiste_du_faso', nom: "L'Économiste du Faso", domaine: 'leconomistedufaso.bf', fluxRss: null, categorie: SourceCategorie.presseEcoBf, accesPayant: false, actif: true),
  SourceConfig(id: 'echos_du_faso', nom: 'Les Échos du Faso', domaine: 'echosdufaso.com', fluxRss: null, categorie: SourceCategorie.presseEcoBf, accesPayant: false, actif: true),
  SourceConfig(id: 'investir_au_burkina', nom: 'Investir au Burkina', domaine: 'investirauburkina.net', fluxRss: null, categorie: SourceCategorie.presseEcoBf, accesPayant: false, actif: true),

  // Institutions
  SourceConfig(id: 'minefid', nom: 'MINEFID', domaine: 'finances.gov.bf', fluxRss: null, categorie: SourceCategorie.institution, accesPayant: false, actif: true),
  SourceConfig(id: 'bceao', nom: 'BCEAO', domaine: 'bceao.int', fluxRss: null, categorie: SourceCategorie.institution, accesPayant: false, actif: true),
  SourceConfig(id: 'uemoa', nom: 'Commission UEMOA', domaine: 'uemoa.int', fluxRss: null, categorie: SourceCategorie.institution, accesPayant: false, actif: true),
  SourceConfig(id: 'boad', nom: 'BOAD', domaine: 'boad.org', fluxRss: null, categorie: SourceCategorie.institution, accesPayant: false, actif: true),
  SourceConfig(id: 'brvm', nom: 'BRVM', domaine: 'brvm.org', fluxRss: null, categorie: SourceCategorie.institution, accesPayant: false, actif: true),

  // Presse panafricaine / régionale
  SourceConfig(id: 'agence_ecofin', nom: 'Agence Ecofin', domaine: 'agenceecofin.com', fluxRss: 'https://www.agenceecofin.com/rss', categorie: SourceCategorie.presseRegionale, accesPayant: false, actif: true),
  SourceConfig(id: 'financial_afrik', nom: 'Financial Afrik', domaine: 'financialafrik.com', fluxRss: 'https://www.financialafrik.com/feed/', categorie: SourceCategorie.presseRegionale, accesPayant: false, actif: true),
  SourceConfig(id: 'sika_finance', nom: 'Sika Finance', domaine: 'sikafinance.com', fluxRss: null, categorie: SourceCategorie.presseRegionale, accesPayant: false, actif: true),
  SourceConfig(id: 'apa_news', nom: 'APA News', domaine: 'apanews.net', fluxRss: null, categorie: SourceCategorie.presseRegionale, accesPayant: false, actif: true),
  SourceConfig(id: 'la_tribune_afrique', nom: 'La Tribune Afrique', domaine: 'afrique.latribune.fr', fluxRss: null, categorie: SourceCategorie.presseRegionale, accesPayant: false, actif: true),

  // Sources payantes : titre + lien uniquement
  SourceConfig(id: 'jeune_afrique', nom: 'Jeune Afrique — Économie', domaine: 'jeuneafrique.com', fluxRss: null, categorie: SourceCategorie.international, accesPayant: true, actif: true),
  SourceConfig(id: 'africa_report', nom: 'The Africa Report', domaine: 'theafricareport.com', fluxRss: null, categorie: SourceCategorie.international, accesPayant: true, actif: true),

  // International (gratuit)
  SourceConfig(id: 'reuters_africa', nom: 'Reuters — Africa', domaine: 'reuters.com', fluxRss: null, categorie: SourceCategorie.international, accesPayant: false, actif: true),
  SourceConfig(id: 'imf_bfa', nom: 'FMI — Burkina Faso', domaine: 'imf.org', fluxRss: null, categorie: SourceCategorie.international, accesPayant: false, actif: true),
  SourceConfig(id: 'banque_mondiale_bf', nom: 'Banque mondiale — Burkina Faso', domaine: 'banquemondiale.org', fluxRss: null, categorie: SourceCategorie.international, accesPayant: false, actif: true),
];
