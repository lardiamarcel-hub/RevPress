import { SourceDoc } from '../types';

/**
 * Liste de sources de départ, amorcée en base par `seedSources`. Miroir de
 * `mobile/lib/config/default_sources.dart` — la collection Firestore
 * `sources` est la source de vérité une fois amorcée ; ces deux fichiers ne
 * sont utilisés qu'à l'initialisation ou comme référence hors-ligne.
 *
 * Reprend la liste fournie par l'utilisateur (fiche de sources « Revue de
 * presse économique », section 2bis), plus les 3 sources marquées « à
 * confirmer » (ABIPEX, AMAP, ANP), ajoutées inactives avec une URL vide.
 *
 * `fluxRss` n'est renseigné que pour les quelques sources dont on connaît un
 * flux RSS officiel fonctionnel ; pour toutes les autres (et pour toute
 * source ajoutée depuis l'app), la collecte utilise automatiquement le
 * repli Google News RSS filtré par domaine.
 */
export const DEFAULT_SOURCES: Record<string, SourceDoc> = {
  lefaso_net: {
    nom: 'LeFaso.net',
    url: 'https://lefaso.net',
    acces: 'gratuit',
    onglets: ['investissement', 'exportations'],
    actif: true,
    fluxRss: 'https://lefaso.net/spip.php?page=backend',
  },
  burkina24: {
    nom: 'Burkina24',
    url: 'https://burkina24.com',
    acces: 'gratuit',
    onglets: ['investissement', 'secteur_prive'],
    actif: true,
    fluxRss: 'https://burkina24.com/feed/',
  },
  leconomiste_du_faso: {
    nom: "L'Économiste du Faso",
    url: 'https://www.leconomistedufaso.bf',
    acces: 'gratuit_partiel',
    onglets: ['investissement', 'exportations', 'finances_publiques', 'secteur_prive'],
    actif: true,
  },
  echos_du_faso: {
    nom: 'Les Échos du Faso',
    url: 'https://www.echosdufaso.com',
    acces: 'gratuit',
    onglets: ['exportations', 'secteur_prive'],
    actif: true,
  },
  investir_au_burkina: {
    nom: 'Investir au Burkina',
    url: 'https://www.investirauburkina.net',
    acces: 'gratuit',
    onglets: ['investissement'],
    actif: true,
  },
  sidwaya: {
    nom: 'Sidwaya',
    url: 'https://www.sidwaya.bf',
    acces: 'gratuit',
    onglets: ['transverse'],
    actif: true,
  },
  lobservateur: {
    nom: "L'Observateur Paalga",
    url: 'https://www.lobservateur.bf',
    acces: 'gratuit',
    onglets: ['transverse'],
    actif: true,
  },
  lepays: {
    nom: 'Le Pays',
    url: 'https://lepays.bf',
    acces: 'gratuit',
    onglets: ['transverse'],
    actif: true,
  },
  aujourd8: {
    nom: "Aujourd'hui au Faso",
    url: 'https://www.aujourd8.net',
    acces: 'gratuit',
    onglets: ['transverse'],
    actif: true,
    fluxRss: 'https://aujourd8.net/feed/',
  },
  wakatsera: {
    nom: 'Wakat Séra',
    url: 'https://www.wakatsera.com',
    acces: 'gratuit',
    onglets: ['transverse'],
    actif: true,
    fluxRss: 'https://wakatsera.com/feed/',
  },
  fasozine: {
    nom: 'FasoZine',
    url: 'https://www.fasozine.com',
    acces: 'gratuit',
    onglets: ['transverse'],
    actif: true,
  },
  minefid: {
    nom: 'MINEFID',
    url: 'https://www.finances.gov.bf',
    acces: 'gratuit',
    onglets: ['investissement', 'finances_publiques'],
    actif: true,
  },
  presidence_bf: {
    nom: 'Présidence du Faso',
    url: 'https://www.presidence.bf',
    acces: 'gratuit',
    onglets: ['investissement'],
    actif: true,
  },
  bceao: {
    nom: 'BCEAO',
    url: 'https://www.bceao.int',
    acces: 'gratuit',
    onglets: ['monnaie_aes'],
    actif: true,
  },
  uemoa: {
    nom: 'Commission UEMOA',
    url: 'https://www.uemoa.int',
    acces: 'gratuit',
    onglets: ['monnaie_aes'],
    actif: true,
  },
  boad: {
    nom: 'BOAD',
    url: 'https://www.boad.org',
    acces: 'gratuit',
    onglets: ['monnaie_aes'],
    actif: true,
  },
  brvm: {
    nom: 'BRVM',
    url: 'https://www.brvm.org',
    acces: 'gratuit',
    onglets: ['exportations'],
    actif: true,
  },
  agence_ecofin: {
    nom: 'Agence Ecofin',
    url: 'https://www.agenceecofin.com',
    acces: 'gratuit_partiel',
    onglets: ['investissement', 'exportations'],
    actif: true,
    fluxRss: 'https://www.agenceecofin.com/rss',
  },
  financial_afrik: {
    nom: 'Financial Afrik',
    url: 'https://www.financialafrik.com',
    acces: 'gratuit',
    onglets: ['investissement', 'monnaie_aes'],
    actif: true,
    fluxRss: 'https://www.financialafrik.com/feed/',
  },
  sika_finance: {
    nom: 'Sika Finance',
    url: 'https://www.sikafinance.com',
    acces: 'gratuit',
    onglets: ['exportations'],
    actif: true,
  },
  apa_news: {
    nom: 'APA News',
    url: 'https://fr.apanews.net',
    acces: 'gratuit',
    onglets: ['monnaie_aes'],
    actif: true,
  },
  la_tribune_afrique: {
    nom: 'La Tribune Afrique',
    url: 'https://afrique.latribune.fr',
    acces: 'gratuit_partiel',
    onglets: ['secteur_prive'],
    actif: true,
  },
  allafrica: {
    nom: 'AllAfrica',
    url: 'https://allafrica.com',
    acces: 'gratuit',
    onglets: ['monnaie_aes'],
    actif: true,
  },
  jeune_afrique: {
    nom: 'Jeune Afrique',
    url: 'https://www.jeuneafrique.com',
    acces: 'payant',
    onglets: ['secteur_prive'],
    actif: true,
  },
  africa_report: {
    nom: 'The Africa Report',
    url: 'https://www.theafricareport.com',
    acces: 'payant',
    onglets: ['secteur_prive'],
    actif: true,
  },
  african_business: {
    nom: 'African Business',
    url: 'https://www.africanbusinessmagazine.com',
    acces: 'gratuit_partiel',
    onglets: ['secteur_prive'],
    actif: true,
  },
  reuters_africa: {
    nom: 'Reuters Africa',
    url: 'https://www.reuters.com/world/africa',
    acces: 'gratuit_partiel',
    onglets: ['transverse'],
    actif: true,
  },
  bloomberg_africa: {
    nom: 'Bloomberg Africa',
    url: 'https://www.bloomberg.com/africa',
    acces: 'payant',
    onglets: ['transverse'],
    actif: true,
  },
  financial_times_africa: {
    nom: 'Financial Times Africa',
    url: 'https://www.ft.com/africa',
    acces: 'payant',
    onglets: ['transverse'],
    actif: true,
  },
  the_economist: {
    nom: 'The Economist',
    url: 'https://www.economist.com',
    acces: 'payant',
    onglets: ['transverse'],
    actif: true,
  },
  // "Payant (partiel)" dans la fiche source — traité comme payant (titre +
  // lien uniquement) par prudence, le type AccesType ne distinguant que 3 niveaux.
  le_monde_afrique: {
    nom: 'Le Monde Afrique',
    url: 'https://www.lemonde.fr/afrique',
    acces: 'payant',
    onglets: ['transverse'],
    actif: true,
  },
  les_echos: {
    nom: 'Les Échos',
    url: 'https://www.lesechos.fr',
    acces: 'payant',
    onglets: ['transverse'],
    actif: true,
  },
  xinhua_afrique: {
    nom: 'Xinhua Afrique',
    url: 'https://french.xinhuanet.com',
    acces: 'gratuit',
    onglets: ['transverse'],
    actif: true,
  },
  imf_bfa: {
    nom: 'FMI Burkina Faso',
    url: 'https://www.imf.org/en/countries/bfa',
    acces: 'gratuit',
    onglets: ['finances_publiques'],
    actif: true,
  },
  banque_mondiale_bf: {
    nom: 'Banque mondiale Burkina Faso',
    url: 'https://www.banquemondiale.org/fr/country/burkinafaso',
    acces: 'gratuit',
    onglets: ['finances_publiques'],
    actif: true,
  },
  ocde: {
    nom: 'OCDE',
    url: 'https://www.oecd.org',
    acces: 'gratuit',
    onglets: ['finances_publiques'],
    actif: true,
  },
  africa_confidential: {
    nom: 'Africa Confidential',
    url: 'https://www.africa-confidential.com',
    acces: 'payant',
    onglets: ['finances_publiques'],
    actif: true,
  },

  // Sources "à confirmer" : URL officielle non trouvée lors de la revue de
  // presse — ajoutées inactives, URL vide, à compléter depuis Réglages.
  abipex: {
    nom: 'ABIPEX (URL à renseigner)',
    url: '',
    acces: 'gratuit',
    onglets: ['investissement', 'exportations'],
    actif: false,
  },
  amap_mali: {
    nom: 'AMAP — Mali (URL à renseigner)',
    url: '',
    acces: 'gratuit',
    onglets: ['monnaie_aes'],
    actif: false,
  },
  anp_niger: {
    nom: 'ANP — Niger (URL à renseigner)',
    url: '',
    acces: 'gratuit',
    onglets: ['monnaie_aes'],
    actif: false,
  },
};
