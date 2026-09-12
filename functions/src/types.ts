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

export type AccesType = 'gratuit' | 'gratuit_partiel' | 'payant';

export interface SourceDoc {
  nom: string;
  /** URL du site (peut être vide pour une source "à confirmer"). */
  url: string;
  acces: AccesType;
  /** Onglets couverts (parmi THEME_ANGLES, ou "transverse") — informatif :
   *  le classement réel se fait par article, via Claude. */
  onglets: string[];
  actif: boolean;
  /**
   * Flux RSS officiel connu pour cette source (optionnel, non exposé dans
   * l'écran Réglages). Quand absent, la collecte utilise le repli Google
   * News RSS filtré par domaine (extrait de `url`).
   */
  fluxRss?: string | null;
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
