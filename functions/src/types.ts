export type ThemeAngleId =
  | 'investissement'
  | 'exportations'
  | 'monnaie_aes'
  | 'finances_publiques'
  | 'secteur_prive'
  | 'hors_sujet';

export const THEME_ANGLES: ThemeAngleId[] = [
  'investissement',
  'exportations',
  'monnaie_aes',
  'finances_publiques',
  'secteur_prive',
];

export type Fiabilite = 'haute' | 'moyenne' | 'faible';

export type MethodeCollecte = 'rss' | 'google_news_rss';

export type SourceCategorie =
  | 'presseBf'
  | 'presseEcoBf'
  | 'institution'
  | 'presseRegionale'
  | 'presseAes'
  | 'international';

export interface SourceDoc {
  nom: string;
  domaine: string;
  fluxRss: string | null;
  methodeCollecte: MethodeCollecte;
  categorie: SourceCategorie;
  accesPayant: boolean;
  actif: boolean;
}

/** Un item brut récupéré depuis un flux RSS, avant classification. */
export interface RawFeedItem {
  titre: string;
  url: string;
  datePublication: Date;
  contenuBrut: string; // titre + résumé RSS, jamais l'article complet
  sourceId: string;
  sourceNom: string;
  accesPayant: boolean;
}

/** Résultat de la classification Claude pour un item brut. */
export interface ClassificationResult {
  angleThematique: ThemeAngleId;
  resume: string | null;
  fiabilite: Fiabilite;
  langueOriginale: 'fr' | 'en';
}

export interface ArticleDoc {
  titre: string;
  source: string;
  sourceId: string;
  url: string;
  datePublication: FirebaseFirestore.Timestamp;
  dateCollecte: FirebaseFirestore.Timestamp;
  angleThematique: ThemeAngleId;
  resume: string | null;
  langueOriginale: 'fr' | 'en';
  fiabilite: Fiabilite;
  accesPayant: boolean;
  eventGroupId: string | null;
}

export interface DigestDoc {
  date: FirebaseFirestore.Timestamp;
  frequence: 'quotidien' | 'hebdomadaire';
  articlesParAngle: Record<string, string[]>;
  syntheseGlobale: string[];
  genereA: FirebaseFirestore.Timestamp;
}
