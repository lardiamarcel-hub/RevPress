import * as admin from 'firebase-admin';

/** Envoie la notification FCM au topic `digest_pret` quand un digest est créé. */
export async function sendDigestReadyNotification(digestId: string): Promise<void> {
  const message: admin.messaging.Message = {
    topic: 'digest_pret',
    notification: {
      title: 'Revue Éco BF',
      body: 'Votre revue de presse économique est prête.',
    },
    data: { digestId },
  };
  await admin.messaging().send(message);
}
