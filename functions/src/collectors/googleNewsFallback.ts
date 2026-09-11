import Parser from 'rss-parser';

import { RawFeedItem, SourceDoc } from '../types';

const parser = new Parser({ timeout: 15000 });

/**
 * Repli pour les sources sans flux RSS officiel connu : Google News RSS
 * filtré par domaine (`site:domaine`). C'est un flux Google, pas un
 * parsing HTML du site tiers, donc conforme à la contrainte de collecte.
 */
export async function collectFromGoogleNewsFallback(
  sourceId: string,
  source: SourceDoc,
): Promise<RawFeedItem[]> {
  const query = encodeURIComponent(`site:${source.domaine} economie`);
  const feedUrl = `https://news.google.com/rss/search?q=${query}&hl=fr&gl=BF&ceid=BF:fr`;

  try {
    const feed = await parser.parseURL(feedUrl);
    return (feed.items || [])
      .filter((item) => !!item.link && !!item.title)
      .map((item) => ({
        titre: item.title!.trim(),
        url: item.link!,
        datePublication: item.isoDate ? new Date(item.isoDate) : new Date(),
        contenuBrut: item.title!.trim(),
        sourceId,
        sourceNom: source.nom,
        accesPayant: source.accesPayant,
      }));
  } catch (error) {
    console.error(`Échec du repli Google News pour ${source.nom}:`, error);
    return [];
  }
}
