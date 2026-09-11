import * as admin from 'firebase-admin';
import { defineSecret } from 'firebase-functions/params';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';

import { collectFromGoogleNewsFallback } from './collectors/googleNewsFallback';
import { collectFromRss } from './collectors/rssCollector';
import { classifyArticle } from './classification/claudeClassifier';
import { buildDigest } from './digest/buildDigest';
import { groupByEvent } from './dedup/deduplicate';
import { sendDigestReadyNotification } from './notifications/sendDigestNotification';
import { seedSourcesIfEmpty } from './scripts/seedSources';
import { ArticleDoc, RawFeedItem, SourceDoc } from './types';

admin.initializeApp();

const anthropicApiKey = defineSecret('ANTHROPIC_API_KEY');

function digestIdForDate(date: Date): string {
  return date.toISOString().slice(0, 10); // YYYY-MM-DD
}

/**
 * Collecte tous les articles des sources actives, les classe via Claude,
 * les dédoublonne, les écrit dans `articles`, puis construit le digest du
 * jour. Orchestrateur unique appelé par le planificateur ou manuellement.
 */
async function runPressReviewPipeline(): Promise<{ articlesCollectes: number; digestId: string }> {
  const db = admin.firestore();

  await seedSourcesIfEmpty(db);

  const configSnap = await db.doc('config/collecte').get();
  const config = configSnap.data() ?? {};
  const frequence: 'quotidien' | 'hebdomadaire' = config.frequence === 'hebdomadaire' ? 'hebdomadaire' : 'quotidien';

  if (frequence === 'hebdomadaire' && new Date().getUTCDay() !== 1) {
    // Fréquence hebdomadaire : on ne collecte que le lundi.
    logger.info('Collecte hebdomadaire configurée, ce n\'est pas lundi : pipeline ignoré.');
    return { articlesCollectes: 0, digestId: digestIdForDate(new Date()) };
  }

  const sourcesSnap = await db.collection('sources').where('actif', '==', true).get();
  const sources = sourcesSnap.docs.map((doc) => ({ id: doc.id, ...(doc.data() as SourceDoc) }));

  const rawItems: RawFeedItem[] = [];
  for (const source of sources) {
    const items =
      source.methodeCollecte === 'rss'
        ? await collectFromRss(source.id, source)
        : await collectFromGoogleNewsFallback(source.id, source);
    rawItems.push(...items);
  }

  logger.info(`${rawItems.length} articles bruts collectés depuis ${sources.length} sources actives.`);

  const now = admin.firestore.Timestamp.now();
  const classified: { item: RawFeedItem; docId: string; doc: ArticleDoc }[] = [];

  for (const item of rawItems) {
    try {
      const result = await classifyArticle(item);
      const docId = db.collection('articles').doc().id;
      classified.push({
        item,
        docId,
        doc: {
          titre: item.titre,
          source: item.sourceNom,
          sourceId: item.sourceId,
          url: item.url,
          datePublication: admin.firestore.Timestamp.fromDate(item.datePublication),
          dateCollecte: now,
          angleThematique: result.angleThematique,
          resume: result.resume,
          langueOriginale: result.langueOriginale,
          fiabilite: result.fiabilite,
          accesPayant: item.accesPayant,
          eventGroupId: null,
        },
      });
    } catch (error) {
      logger.error(`Classification échouée pour "${item.titre}" (${item.sourceNom}):`, error);
    }
  }

  const eventGroups = groupByEvent(
    classified.map((c) => ({ id: c.docId, titre: c.doc.titre, angleThematique: c.doc.angleThematique })),
  );

  const batch = db.batch();
  let written = 0;
  for (const c of classified) {
    if (c.doc.angleThematique === 'hors_sujet') continue; // on ne stocke que les articles pertinents
    const eventGroupId = eventGroups.get(c.docId) ?? null;
    batch.set(db.collection('articles').doc(c.docId), { ...c.doc, eventGroupId });
    written++;
  }
  await batch.commit();

  const digestId = digestIdForDate(new Date());
  const since = new Date();
  since.setUTCHours(since.getUTCHours() - (frequence === 'hebdomadaire' ? 24 * 7 : 24));
  await buildDigest(db, digestId, frequence, since);

  return { articlesCollectes: written, digestId };
}

export const dailyPressReview = onSchedule(
  {
    schedule: '0 6 * * *',
    timeZone: 'Africa/Ouagadougou',
    secrets: [anthropicApiKey],
    timeoutSeconds: 540,
    memory: '512MiB',
  },
  async () => {
    const result = await runPressReviewPipeline();
    logger.info(`Pipeline terminé : ${result.articlesCollectes} articles écrits, digest ${result.digestId}.`);
  },
);

export const onDigestCreated = onDocumentCreated('digests/{digestId}', async (event) => {
  const digestId = event.params.digestId as string;
  try {
    await sendDigestReadyNotification(digestId);
  } catch (error) {
    logger.error(`Échec de l'envoi de la notification pour le digest ${digestId}:`, error);
  }
});

export const manualRefresh = onCall({ secrets: [anthropicApiKey], timeoutSeconds: 540 }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentification requise.');
  }
  return runPressReviewPipeline();
});

export const seedSources = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentification requise.');
  }
  const count = await seedSourcesIfEmpty(admin.firestore());
  return { sourcesAjoutees: count };
});
