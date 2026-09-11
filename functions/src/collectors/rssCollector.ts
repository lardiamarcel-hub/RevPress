import Parser from 'rss-parser';

import { RawFeedItem, SourceDoc } from '../types';
import { isFetchAllowed } from '../utils/robots';

const parser = new Parser({ timeout: 15000 });

/** Récupère les items d'un flux RSS officiel pour une source donnée. */
export async function collectFromRss(sourceId: string, source: SourceDoc): Promise<RawFeedItem[]> {
  if (!source.fluxRss) return [];

  const allowed = await isFetchAllowed(source.fluxRss);
  if (!allowed) {
    console.warn(`robots.txt interdit la collecte de ${source.fluxRss}, source ignorée.`);
    return [];
  }

  try {
    const feed = await parser.parseURL(source.fluxRss);
    return (feed.items || [])
      .filter((item) => !!item.link && !!item.title)
      .map((item) => ({
        titre: item.title!.trim(),
        url: item.link!,
        datePublication: item.isoDate ? new Date(item.isoDate) : new Date(),
        // On ne conserve que le titre + l'extrait fourni par le flux RSS lui-même
        // (jamais un fetch de la page complète de l'article).
        contenuBrut: `${item.title}. ${stripHtml(item.contentSnippet || item.content || '')}`.slice(0, 2000),
        sourceId,
        sourceNom: source.nom,
        accesPayant: source.accesPayant,
      }));
  } catch (error) {
    console.error(`Échec de la collecte RSS pour ${source.nom} (${source.fluxRss}):`, error);
    return [];
  }
}

function stripHtml(html: string): string {
  return html.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim();
}
