import { getAnalytics } from 'firebase/analytics';
import { initializeApp } from 'firebase/app';
import { connectAuthEmulator, getAuth } from 'firebase/auth';
import { connectFirestoreEmulator, getFirestore } from 'firebase/firestore';
import { connectFunctionsEmulator, getFunctions } from 'firebase/functions';

// Firebase configuration
// For development, these can be placeholder values when using emulators
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || 'demo-api-key',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || 'demo-auth-domain',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || 'wealth-wise-dev',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || 'demo-storage',
  messagingSenderId:
    import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || '123456789',
  appId: import.meta.env.VITE_FIREBASE_APP_ID || 'demo-app-id',
  measurementId:
    import.meta.env.VITE_FIREBASE_MEASUREMENT_ID || 'demo-measurement-id',
};

// Initialize Firebase
export const app = initializeApp(firebaseConfig);

// Initialize Firebase services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const functions = getFunctions(app);

// Initialize Analytics (only in production)
export const analytics =
  typeof window !== 'undefined' && import.meta.env.PROD
    ? getAnalytics(app)
    : null;

// Connect to emulators in development
const isDevelopment = import.meta.env.DEV;

if (isDevelopment) {
  console.log('🔧 Connecting to Firebase Emulators...');

  // Connect Auth Emulator
  connectAuthEmulator(auth, 'http://localhost:9099', { disableWarnings: true });

  // Connect Firestore Emulator
  connectFirestoreEmulator(db, 'localhost', 8080);

  // Connect Functions Emulator
  connectFunctionsEmulator(functions, 'localhost', 5001);

  console.log('✅ Connected to Firebase Emulators');
  console.log('   - Auth: http://localhost:9099');
  console.log('   - Firestore: http://localhost:8080');
  console.log('   - Functions: http://localhost:5001');
  console.log('   - UI: http://localhost:4000');
}

export default app;
