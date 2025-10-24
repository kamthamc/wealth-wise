/**
 * Notification Service
 * Handle user notifications from Pub/Sub events
 */

import {
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  type Timestamp,
  updateDoc,
  where,
} from 'firebase/firestore';
import { db } from '../firebase/firebase';

export interface Notification {
  id: string;
  user_id: string;
  type: 'budget_alert' | 'insight' | 'report_ready' | 'export_ready';
  title: string;
  message: string;
  data?: any;
  read: boolean;
  created_at: Timestamp;
}

/**
 * Subscribe to user notifications in real-time
 */
export function subscribeToNotifications(
  userId: string,
  onNotificationsChange: (notifications: Notification[]) => void
): () => void {
  const notificationsQuery = query(
    collection(db, 'notifications'),
    where('user_id', '==', userId),
    orderBy('created_at', 'desc')
  );

  const unsubscribe = onSnapshot(notificationsQuery, (snapshot) => {
    const notifications: Notification[] = [];
    snapshot.forEach((doc) => {
      notifications.push({
        id: doc.id,
        ...doc.data(),
      } as Notification);
    });
    onNotificationsChange(notifications);
  });

  return unsubscribe;
}

/**
 * Mark notification as read
 */
export async function markNotificationAsRead(
  notificationId: string
): Promise<void> {
  const notificationRef = doc(db, 'notifications', notificationId);
  await updateDoc(notificationRef, {
    read: true,
  });
}

/**
 * Mark all notifications as read
 */
export async function markAllNotificationsAsRead(
  notifications: Notification[]
): Promise<void> {
  const updates = notifications
    .filter((n) => !n.read)
    .map((n) => markNotificationAsRead(n.id));

  await Promise.all(updates);
}

/**
 * Get unread notification count
 */
export function getUnreadCount(notifications: Notification[]): number {
  return notifications.filter((n) => !n.read).length;
}
