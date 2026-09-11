import * as admin from 'firebase-admin';

import { ArticleDoc, DigestDoc, Fiabilite, ThemeAngleId, THEME_ANGLES } from '../types';

const FIABILITE_WEIGHT: Record<Fiabilite, number> = { haute: 3, moyenne: 2, faible: 1 };
const MAX_PER_ANGLE = 8;
const MAX_SYNTHESE_GLOBALE = 10;

interface ScoredArticle {
  id: string;
  angleThematique: ThemeAngleId;
  fiabilite: Fiabilite;
  datePublication: admin.firestore.Timestamp;
}

function score(article: ScoredArticle): number {
  return FIABILITE_WEIGHT[article.fiabilite] * 1000 + article.datePublication.toMillis() / 1e13;
}

/**
 * Construit le document `digests/{digestId}` à partir des articles collectés
 * dans la fenêtre de temps courante (dernières 24h en quotidien, 7 jours en
 * hebdomadaire).
 */
export async function buildDigest(
  db: admin.firestore.Firestore,
  digestId: string,
  frequence: 'quotidien' | 'hebdomadaire',
  since: Date,
): Promise<void> {
  const snap = await db
    .collection('articles')
    .where('dateCollecte', '>=', admin.firestore.Timestamp.fromDate(since))
    .get();

  const articles: (ScoredArticle & { data: ArticleDoc })[] = snap.docs.map((doc) => {
    const data = doc.data() as ArticleDoc;
    return {
      id: doc.id,
      angleThematique: data.angleThematique,
      fiabilite: data.fiabilite,
      datePublication: data.datePublication,
      data,
    };
  });

  const articlesParAngle: Record<string, string[]> = {};
  for (const angle of THEME_ANGLES) {
    articlesParAngle[angle] = articles
      .filter((a) => a.angleThematique === angle)
      .sort((a, b) => score(b) - score(a))
      .slice(0, MAX_PER_ANGLE)
      .map((a) => a.id);
  }

  const syntheseGlobale = articles
    .filter((a) => a.angleThematique !== 'hors_sujet')
    .sort((a, b) => score(b) - score(a))
    .slice(0, MAX_SYNTHESE_GLOBALE)
    .map((a) => a.id);

  const digest: DigestDoc = {
    date: admin.firestore.Timestamp.now(),
    frequence,
    articlesParAngle,
    syntheseGlobale,
    genereA: admin.firestore.Timestamp.now(),
  };

  await db.collection('digests').doc(digestId).set(digest);
}
