import * as admin from 'firebase-admin';

import { DEFAULT_SOURCES } from '../config/defaultSources';

/** Amorce la collection `sources` si elle est vide. Idempotent. */
export async function seedSourcesIfEmpty(db: admin.firestore.Firestore): Promise<number> {
  const existing = await db.collection('sources').limit(1).get();
  if (!existing.empty) {
    return 0;
  }

  const batch = db.batch();
  let count = 0;
  for (const [sourceId, source] of Object.entries(DEFAULT_SOURCES)) {
    batch.set(db.collection('sources').doc(sourceId), source);
    count++;
  }
  await batch.commit();
  return count;
}
