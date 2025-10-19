/**
 * WealthWise - Main Application Component
 * Local-first personal finance management application
 */

import { RouterProvider } from '@tanstack/react-router';
import { Suspense, useEffect } from 'react';
import './core/i18n'; // Initialize i18n
import { router } from './core/router';
import { useInitializeStores } from './core/stores';
import { useTextDirection } from './core/i18n';
import { SkipNavigation, Spinner, ToastProvider } from './shared/components';

// Import database reset utilities (dev only)
if (import.meta.env.DEV) {
  import('./core/db/resetUtil');
}

function App() {
  // Initialize stores and database
  useInitializeStores();
  
  // Get text direction for RTL support
  const direction = useTextDirection();
  
  // Apply text direction to document
  useEffect(() => {
    document.documentElement.dir = direction;
  }, [direction]);

  return (
    <Suspense 
      fallback={
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '100vh',
          gap: '1rem',
        }}>
          <Spinner size="large" />
          <p style={{ color: 'var(--text-secondary)' }}>
            Loading application...
          </p>
        </div>
      }
    >
      <ToastProvider maxToasts={3} defaultDuration={5000}>
        <SkipNavigation />
        <RouterProvider router={router} />
      </ToastProvider>
    </Suspense>
  );
}

export default App;
