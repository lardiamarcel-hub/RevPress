import '../models/source_config.dart';
import 'theme_angles.dart';

/// Liste de sources par défaut, utilisée uniquement pour référence/affichage
/// côté app. La source de vérité en production est la collection Firestore
/// `sources`, amorcée côté Cloud Functions par `seedSources` à partir du
/// miroir TypeScript `functions/src/config/defaultSources.ts`.
///
/// Reprend telle quelle la liste fournie par l'utilisateur (fiche de sources
/// « Revue de presse économique », section 2bis), plus les 3 sources
/// marquées « à confirmer » (ABIPEX, AMAP, ANP), ajoutées inactives avec une
/// URL vide en attendant que l'utilisateur la renseigne depuis Réglages.
const List<SourceConfig> defaultSources = [
  SourceConfig(id: 'lefaso_net', nom: 'LeFaso.net', url: 'https://lefaso.net', acces: AccesType.gratuit, onglets: ['investissement', 'exportations'], actif: true),
  SourceConfig(id: 'burkina24', nom: 'Burkina24', url: 'https://burkina24.com', acces: AccesType.gratuit, onglets: ['investissement', 'secteur_prive'], actif: true),
  SourceConfig(id: 'leconomiste_du_faso', nom: "L'Économiste du Faso", url: 'https://www.leconomistedufaso.bf', acces: AccesType.gratuitPartiel, onglets: ['investissement', 'exportations', 'finances_publiques', 'secteur_prive'], actif: true),
  SourceConfig(id: 'echos_du_faso', nom: 'Les Échos du Faso', url: 'https://www.echosdufaso.com', acces: AccesType.gratuit, onglets: ['exportations', 'secteur_prive'], actif: true),
  SourceConfig(id: 'investir_au_burkina', nom: 'Investir au Burkina', url: 'https://www.investirauburkina.net', acces: AccesType.gratuit, onglets: ['investissement'], actif: true),
  SourceConfig(id: 'sidwaya', nom: 'Sidwaya', url: 'https://www.sidwaya.bf', acces: AccesType.gratuit, onglets: [transverseOngletId], actif: true),
  SourceConfig(id: 'lobservateur', nom: "L'Observateur Paalga", url: 'https://www.lobservateur.bf', acces: AccesType.gratuit, onglets: [transverseOngletId], actif: true),
  SourceConfig(id: 'lepays', nom: 'Le Pays', url: 'https://lepays.bf', acces: AccesType.gratuit, onglets: [transverseOngletId], actif: true),
  SourceConfig(id: 'aujourd8', nom: "Aujourd'hui au Faso", url: 'https://www.aujourd8.net', acces: AccesType.gratuit, onglets: [transverseOngletId], actif: true),
  SourceConfig(id: 'wakatsera', nom: 'Wakat Séra', url: 'https://www.wakatsera.com', acces: AccesType.gratuit, onglets: [transverseOngletId], actif: true),
  SourceConfig(id: 'fasozine', nom: 'FasoZine', url: 'https://www.fasozine.com', acces: AccesType.gratuit, onglets: [transverseOngletId], actif: true),
  SourceConfig(id: 'minefid', nom: 'MINEFID', url: 'https://www.finances.gov.bf', acces: AccesType.gratuit, onglets: ['investissement', 'finances_publiques'], actif: true),
  SourceConfig(id: 'presidence_bf', nom: 'Présidence du Faso', url: 'https://www.presidence.bf', acces: AccesType.gratuit, onglets: ['investissement'], actif: true),
  SourceConfig(id: 'bceao', nom: 'BCEAO', url: 'https://www.bceao.int', acces: AccesType.gratuit, onglets: ['monnaie_aes'], actif: true),
  SourceConfig(id: 'uemoa', nom: 'Commission UEMOA', url: 'https://www.uemoa.int', acces: AccesType.gratuit, onglets: ['monnaie_aes'], actif: true),
  SourceConfig(id: 'boad', nom: 'BOAD', url: 'https://www.boad.org', acces: AccesType.gratuit, onglets: ['monnaie_aes'], actif: true),
  SourceConfig(id: 'brvm', nom: 'BRVM', url: 'https://www.brvm.org', acces: AccesType.gratuit, onglets: ['exportations'], actif: true),
  SourceConfig(id: 'agence_ecofin', nom: 'Agence Ecofin', url: 'https://www.agenceecofin.com', acces: AccesType.gratuitPartiel, onglets: ['investissement', 'exportations'], actif: true),
  SourceConfig(id: 'financial_afrik', nom: 'Financial Afrik', url: 'https://www.financialafrik.com', acces: AccesType.gratuit, onglets: ['investissement', 'monnaie_aes'], actif: true),
  SourceConfig(id: 'sika_finance', nom: 'Sika Finance', url: 'https://www.sikafinance.com', acces: AccesType.gratuit, onglets: ['exportations'], actif: true),
  SourceConfig(id: 'apa_news', nom: 'APA News', url: 'https://fr.apanews.net', acces: AccesType.gratuit, onglets: ['monnaie_aes'], actif: true),
  SourceConfig(id: 'la_tribune_afrique', nom: 'La Tribune Afrique', url: 'https://afrique.latribune.fr', acces: AccesType.gratuitPartiel, onglets: ['secteur_prive'], actif: true),
  SourceConfig(id: 'allafrica', nom: 'AllAfrica', url: 'https://allafrica.com', acces: AccesType.gratuit, onglets: ['monnaie_aes'], actif: true),
  SourceConfig(id: 'jeune_afrique', nom: 'Jeune Afrique', url: 'https://www.jeuneafrique.com', acces: AccesType.payant, onglets: ['secteur_prive'], actif: true),
  SourceConfig(id: 'africa_report', nom: 'The Africa Report', url: 'https://www.theafricareport.com', acces: AccesType.payant, onglets: ['secteur_prive'], actif: true),
  SourceConfig(id: 'african_business', nom: 'African Business', url: 'https://www.africanbusinessmagazine.com', acces: AccesType.gratuitPartiel, onglets: ['secteur_prive'], actif: true),
  SourceConfig(id: 'reuters_africa', nom: 'Reuters Africa', url: 'https://www.reuters.com/world/africa', acces: AccesType.gratuitPartiel, onglets: [transverseOngletId], actif: true),
  SourceConfig(id: 'bloomberg_africa', nom: 'Bloomberg Africa', url: 'https://www.bloomberg.com/africa', acces: AccesType.payant, onglets: [transverseOngletId], actif: true),
  SourceConfig(id: 'financial_times_africa', nom: 'Financial Times Africa', url: 'https://www.ft.com/africa', acces: AccesType.payant, onglets: [transverseOngletId], actif: true),
  SourceConfig(id: 'the_economist', nom: 'The Economist', url: 'https://www.economist.com', acces: AccesType.payant, onglets: [transverseOngletId], actif: true),
  // "Payant (partiel)" dans la fiche source — traité comme payant (titre + lien
  // uniquement) par prudence, l'enum de l'app ne distinguant que 3 niveaux.
  SourceConfig(id: 'le_monde_afrique', nom: 'Le Monde Afrique', url: 'https://www.lemonde.fr/afrique', acces: AccesType.payant, onglets: [transverseOngletId], actif: true),
  SourceConfig(id: 'les_echos', nom: 'Les Échos', url: 'https://www.lesechos.fr', acces: AccesType.payant, onglets: [transverseOngletId], actif: true),
  SourceConfig(id: 'xinhua_afrique', nom: 'Xinhua Afrique', url: 'https://french.xinhuanet.com', acces: AccesType.gratuit, onglets: [transverseOngletId], actif: true),
  SourceConfig(id: 'imf_bfa', nom: 'FMI Burkina Faso', url: 'https://www.imf.org/en/countries/bfa', acces: AccesType.gratuit, onglets: ['finances_publiques'], actif: true),
  SourceConfig(id: 'banque_mondiale_bf', nom: 'Banque mondiale Burkina Faso', url: 'https://www.banquemondiale.org/fr/country/burkinafaso', acces: AccesType.gratuit, onglets: ['finances_publiques'], actif: true),
  SourceConfig(id: 'ocde', nom: 'OCDE', url: 'https://www.oecd.org', acces: AccesType.gratuit, onglets: ['finances_publiques'], actif: true),
  SourceConfig(id: 'africa_confidential', nom: 'Africa Confidential', url: 'https://www.africa-confidential.com', acces: AccesType.payant, onglets: ['finances_publiques'], actif: true),

  // Sources "à confirmer" : URL officielle non trouvée lors de la revue de
  // presse — ajoutées inactives, URL vide, à compléter depuis Réglages.
  SourceConfig(id: 'abipex', nom: 'ABIPEX (URL à renseigner)', url: '', acces: AccesType.gratuit, onglets: ['investissement', 'exportations'], actif: false),
  SourceConfig(id: 'amap_mali', nom: 'AMAP — Mali (URL à renseigner)', url: '', acces: AccesType.gratuit, onglets: ['monnaie_aes'], actif: false),
  SourceConfig(id: 'anp_niger', nom: 'ANP — Niger (URL à renseigner)', url: '', acces: AccesType.gratuit, onglets: ['monnaie_aes'], actif: false),
];
