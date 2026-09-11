import { titleSimilarity } from '../utils/textSimilarity';

interface DedupInput {
  id: string;
  titre: string;
  angleThematique: string;
}

const SIMILARITY_THRESHOLD = 0.55;

/**
 * Regroupe les articles qui couvrent vraisemblablement le même évènement
 * (même angle thématique + titres très similaires). Retourne une map
 * articleId -> eventGroupId (null si l'article ne rejoint aucun groupe).
 */
export function groupByEvent(articles: DedupInput[]): Map<string, string | null> {
  const groups = new Map<string, string | null>();
  const assigned: { id: string; titre: string; angleThematique: string; groupId: string }[] = [];

  for (const article of articles) {
    const match = assigned.find(
      (a) =>
        a.angleThematique === article.angleThematique &&
        titleSimilarity(a.titre, article.titre) >= SIMILARITY_THRESHOLD,
    );

    if (match) {
      groups.set(article.id, match.groupId);
    } else {
      const groupId = `evt_${article.id}`;
      groups.set(article.id, null);
      assigned.push({ ...article, groupId });
    }
  }

  // Deuxième passe : les articles qui ont trouvé un match rejoignent le
  // groupe de leur "représentant" ; le représentant lui-même reste sans
  // eventGroupId tant qu'il est seul dans son groupe (évite de marquer
  // arbitrairement tous les articles isolés comme "groupés").
  const groupSizes = new Map<string, number>();
  for (const value of groups.values()) {
    if (value) groupSizes.set(value, (groupSizes.get(value) ?? 0) + 1);
  }
  for (const article of assigned) {
    if (groupSizes.has(article.groupId)) {
      groups.set(article.id, article.groupId);
    }
  }

  return groups;
}
