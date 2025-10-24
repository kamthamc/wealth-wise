import {
  createUserWithEmailAndPassword,
  signOut as firebaseSignOut,
  GoogleAuthProvider,
  onAuthStateChanged,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signInWithPopup,
  type User,
} from 'firebase/auth';
import { useEffect, useState } from 'react';
import { auth } from '../firebase/firebase';

interface AuthState {
  user: User | null;
  loading: boolean;
  error: Error | null;
}

export interface AuthContext extends AuthState {
  user: User | null;
  loading: boolean;
  error: Error | null;
  isAuthenticated: boolean;
  signIn: (email: string, password: string) => Promise<User | null>;
  signUp: (email: string, password: string) => Promise<User | null>;
  signInWithGoogle: () => Promise<User | null>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
}

export const useAuth = (): AuthContext => {
  const [state, setState] = useState<AuthState>({
    user: null,
    loading: true,
    error: null,
  });

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(
      auth,
      (user) => {
        setState({ user, loading: false, error: null });
      },
      (error) => {
        setState({ user: null, loading: false, error });
      }
    );

    return unsubscribe;
  }, []);

  const signIn = async (email: string, password: string) => {
    try {
      setState((prev) => ({ ...prev, loading: true, error: null }));
      const result = await signInWithEmailAndPassword(auth, email, password);
      setState({ user: result.user, loading: false, error: null });
      return result.user;
    } catch (error) {
      setState((prev) => ({ ...prev, loading: false, error: error as Error }));
      throw error;
    }
  };

  const signUp = async (email: string, password: string) => {
    try {
      setState((prev) => ({ ...prev, loading: true, error: null }));
      const result = await createUserWithEmailAndPassword(
        auth,
        email,
        password
      );
      setState({ user: result.user, loading: false, error: null });
      return result.user;
    } catch (error) {
      setState((prev) => ({ ...prev, loading: false, error: error as Error }));
      throw error;
    }
  };

  const signInWithGoogle = async () => {
    try {
      setState((prev) => ({ ...prev, loading: true, error: null }));
      const provider = new GoogleAuthProvider();
      const result = await signInWithPopup(auth, provider);
      setState({ user: result.user, loading: false, error: null });
      return result.user;
    } catch (error) {
      setState((prev) => ({ ...prev, loading: false, error: error as Error }));
      throw error;
    }
  };

  const signOut = async () => {
    try {
      setState((prev) => ({ ...prev, loading: true, error: null }));
      await firebaseSignOut(auth);
      setState({ user: null, loading: false, error: null });
    } catch (error) {
      setState((prev) => ({ ...prev, loading: false, error: error as Error }));
      throw error;
    }
  };

  const resetPassword = async (email: string) => {
    try {
      await sendPasswordResetEmail(auth, email);
    } catch (error) {
      throw error;
    }
  };

  return {
    user: state.user,
    loading: state.loading,
    error: state.error,
    isAuthenticated: !!state.user,
    signIn,
    signUp,
    signInWithGoogle,
    signOut,
    resetPassword,
  };
};
