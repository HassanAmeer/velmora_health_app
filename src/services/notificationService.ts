import { addDoc, collection, serverTimestamp } from 'firebase/firestore';
import { db } from './firebase';

export interface NotificationData {
    title: string;
    body: string;
    type: string;
    isRead: boolean;
    timestamp: any;
}

export const sendNotificationToFirestore = async (uid: string, data: NotificationData) => {
    await addDoc(
        collection(db, 'users', uid, 'notifications'),
        {
            ...data,
            timestamp: serverTimestamp(),
        }
    );
};

// NOTE: Sending FCM directly from the frontend is NOT recommended for production
// because it requires a server key or service account secrets.
// Recommended approach: Add a document to a 'notification_triggers' collection
// and let a Firebase Cloud Function handle the actual FCM sending.
export const triggerFCM = async (token: string, title: string, body: string) => {
    console.log(`FCM trigger logic for token: ${token}`);
    // implementation would go here (e.g., calling a Cloud Function)
};
