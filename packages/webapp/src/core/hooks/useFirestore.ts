import {
  collection,
  doc,
  onSnapshot,
  query,
  type Unsubscribe,
  //   where,
} from 'firebase/firestore';
import { useEffect, useState } from 'react';
import { db } from '../firebase/firebase';
import { useAuth } from './useAuth';

interface FirestoreQueryOptions {
  collectionPath: string;
  queryConstraints?: any[];
}

/**
 * Hook to subscribe to a Firestore collection with real-time updates
 */
export function useFirestoreCollection<T>(options: FirestoreQueryOptions) {
  const { user } = useAuth();
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!user) {
      setData([]);
      setLoading(false);
      return;
    }

    setLoading(true);
    setError(null);

    let unsubscribe: Unsubscribe;

    try {
      const collectionRef = collection(
        db,
        'users',
        user.uid,
        options.collectionPath
      );
      const q = options.queryConstraints
        ? query(collectionRef, ...options.queryConstraints)
        : collectionRef;

      unsubscribe = onSnapshot(
        q,
        (snapshot) => {
          const items = snapshot.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
          })) as T[];
          setData(items);
          setLoading(false);
        },
        (err) => {
          console.error('Firestore subscription error:', err);
          setError(err);
          setLoading(false);
        }
      );
    } catch (err) {
      console.error('Error setting up Firestore subscription:', err);
      setError(err as Error);
      setLoading(false);
    }

    return () => {
      if (unsubscribe) {
        unsubscribe();
      }
    };
  }, [user, options.collectionPath, JSON.stringify(options.queryConstraints)]);

  return { data, loading, error };
}

/**
 * Hook to subscribe to a single Firestore document with real-time updates
 */
export function useFirestoreDocument<T>(
  collectionPath: string,
  documentId: string | null
) {
  const { user } = useAuth();
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!user || !documentId) {
      setData(null);
      setLoading(false);
      return;
    }

    setLoading(true);
    setError(null);

    const documentRef = doc(db, 'users', user.uid, collectionPath, documentId);

    const unsubscribe = onSnapshot(
      documentRef,
      (snapshot) => {
        if (snapshot.exists()) {
          setData({ id: snapshot.id, ...snapshot.data() } as T);
        } else {
          setData(null);
        }
        setLoading(false);
      },
      (err) => {
        console.error('Firestore document subscription error:', err);
        setError(err);
        setLoading(false);
      }
    );

    return () => unsubscribe();
  }, [user, collectionPath, documentId]);

  return { data, loading, error };
}
