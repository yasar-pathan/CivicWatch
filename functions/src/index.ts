import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

initializeApp();

const db = getFirestore();

export const sendPushOnNotificationCreate = onDocumentCreated(
  'users/{uid}/notifications/{notificationId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const uid = event.params.uid;
    const data = snap.data();

    const userDoc = await db.collection('users').doc(uid).get();
    const token = (userDoc.data()?.fcmToken ?? '').toString().trim();

    if (!token) {
      return;
    }

    const title = (data.title ?? 'Notification').toString();
    const body = (data.body ?? '').toString();

    try {
      await getMessaging().send({
        token,
        notification: {
          title,
          body,
        },
        data: {
          type: (data.type ?? 'general').toString(),
          issueId: (data.issueId ?? '').toString(),
          route: (data.route ?? '').toString(),
          notificationId: snap.id,
          recipientId: uid,
        },
      });

      await snap.ref.set(
        {
          pushSentAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } catch (error) {
      await snap.ref.set(
        {
          pushFailedAt: FieldValue.serverTimestamp(),
          pushError: String(error),
        },
        { merge: true },
      );
    }
  },
);
