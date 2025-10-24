/**
 * Firebase Authentication Store
 * Manages user authentication state and operations
 */

import type { User } from 'firebase/auth';
import {
  createUserWithEmailAndPassword,
  signOut as firebaseSignOut,
  GoogleAuthProvider,
  onAuthStateChanged,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signInWithPopup,
  updateProfile,
} from 'firebase/auth';
import { create } from 'zustand';
import { auth } from '@/core/firebase/firebase';
import { announce, announceError } from '@/shared/utils';

interface AuthState {
  // Data
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;

  // Actions
  initialize: () => void;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (
    email: string,
    password: string,
    displayName?: string
  ) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  updateUserProfile: (displayName: string, photoURL?: string) => Promise<void>;
  clearError: () => void;
}

const initialState = {
  user: null,
  isAuthenticated: false,
  isLoading: true, // Start as true to check auth state
  error: null,
};

export const useAuthStore = create<AuthState>((set) => ({
  ...initialState,

  initialize: () => {
    // Subscribe to auth state changes
    onAuthStateChanged(auth, (user) => {
      set({
        user,
        isAuthenticated: !!user,
        isLoading: false,
      });

      if (user) {
        console.log('✅ User authenticated:', user.email);
      } else {
        console.log('👤 No user authenticated');
      }
    });
  },

  signIn: async (email, password) => {
    set({ isLoading: true, error: null });
    try {
      const userCredential = await signInWithEmailAndPassword(
        auth,
        email,
        password
      );
      set({
        user: userCredential.user,
        isAuthenticated: true,
        isLoading: false,
      });
      announce(`Welcome back, ${userCredential.user.email}!`);
    } catch (error) {
      console.error('Sign in error:', error);
      let errorMessage = 'Failed to sign in';

      if (error instanceof Error) {
        if (error.message.includes('user-not-found')) {
          errorMessage = 'No account found with this email';
        } else if (error.message.includes('wrong-password')) {
          errorMessage = 'Incorrect password';
        } else if (error.message.includes('invalid-email')) {
          errorMessage = 'Invalid email address';
        } else {
          errorMessage = error.message;
        }
      }

      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
      throw error;
    }
  },

  signUp: async (email, password, displayName) => {
    set({ isLoading: true, error: null });
    try {
      const userCredential = await createUserWithEmailAndPassword(
        auth,
        email,
        password
      );

      // Update profile with display name if provided
      if (displayName && userCredential.user) {
        await updateProfile(userCredential.user, { displayName });
      }

      set({
        user: userCredential.user,
        isAuthenticated: true,
        isLoading: false,
      });
      announce(`Welcome to WealthWise, ${displayName || email}!`);
    } catch (error) {
      console.error('Sign up error:', error);
      let errorMessage = 'Failed to create account';

      if (error instanceof Error) {
        if (error.message.includes('email-already-in-use')) {
          errorMessage = 'An account with this email already exists';
        } else if (error.message.includes('weak-password')) {
          errorMessage = 'Password should be at least 6 characters';
        } else if (error.message.includes('invalid-email')) {
          errorMessage = 'Invalid email address';
        } else {
          errorMessage = error.message;
        }
      }

      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
      throw error;
    }
  },

  signInWithGoogle: async () => {
    set({ isLoading: true, error: null });
    try {
      const provider = new GoogleAuthProvider();
      const userCredential = await signInWithPopup(auth, provider);

      set({
        user: userCredential.user,
        isAuthenticated: true,
        isLoading: false,
      });
      announce(
        `Welcome, ${userCredential.user.displayName || userCredential.user.email}!`
      );
    } catch (error) {
      console.error('Google sign in error:', error);
      let errorMessage = 'Failed to sign in with Google';

      if (error instanceof Error) {
        if (error.message.includes('popup-closed-by-user')) {
          errorMessage = 'Sign in cancelled';
        } else if (error.message.includes('popup-blocked')) {
          errorMessage = 'Please allow popups for this site';
        } else {
          errorMessage = error.message;
        }
      }

      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
      throw error;
    }
  },

  signOut: async () => {
    set({ isLoading: true, error: null });
    try {
      await firebaseSignOut(auth);
      set({
        user: null,
        isAuthenticated: false,
        isLoading: false,
      });
      announce('Signed out successfully');
    } catch (error) {
      console.error('Sign out error:', error);
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to sign out';
      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
      throw error;
    }
  },

  resetPassword: async (email) => {
    set({ isLoading: true, error: null });
    try {
      await sendPasswordResetEmail(auth, email);
      set({ isLoading: false });
      announce('Password reset email sent. Please check your inbox.');
    } catch (error) {
      console.error('Password reset error:', error);
      let errorMessage = 'Failed to send reset email';

      if (error instanceof Error) {
        if (error.message.includes('user-not-found')) {
          errorMessage = 'No account found with this email';
        } else if (error.message.includes('invalid-email')) {
          errorMessage = 'Invalid email address';
        } else {
          errorMessage = error.message;
        }
      }

      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
      throw error;
    }
  },

  updateUserProfile: async (displayName, photoURL) => {
    set({ isLoading: true, error: null });
    try {
      const currentUser = auth.currentUser;
      if (!currentUser) {
        throw new Error('No user logged in');
      }

      await updateProfile(currentUser, {
        displayName,
        ...(photoURL && { photoURL }),
      });

      set({
        user: currentUser,
        isLoading: false,
      });
      announce('Profile updated successfully');
    } catch (error) {
      console.error('Profile update error:', error);
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to update profile';
      set({ error: errorMessage, isLoading: false });
      announceError(errorMessage);
      throw error;
    }
  },

  clearError: () => {
    set({ error: null });
  },
}));

// Initialize auth state listener when the store is created
useAuthStore.getState().initialize();
