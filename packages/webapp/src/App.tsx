/**
 * WealthWise - Main Application Component
 * Local-first personal finance management application
 */

import { RouterProvider } from '@tanstack/react-router';
import { Suspense, useEffect } from 'react';
import './core/i18n'; // Initialize i18n
import { useTextDirection } from './core/i18n';
import { router } from './core/router';
import { useInitializeStores } from './core/stores';
import { SkipNavigation, Spinner, ToastProvider } from './shared/components';
import { useAuth } from './core/hooks/useAuth';
import { Theme } from '@radix-ui/themes';
import { QueryProvider } from './core/QueryProvider';

// Database reset utilities removed with PGlite migration

const InnerApp = () => {
  const auth = useAuth();
  return (
    <QueryProvider>
      <Theme>
        <Suspense
          fallback={
            <div
              style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                minHeight: '100vh',
                gap: '1rem',
              }}
            >
              <Spinner size="large" />
              <p style={{ color: 'var(--text-secondary)' }}>
                Loading application...
              </p>
            </div>
          }
        >
          <ToastProvider maxToasts={3} defaultDuration={5000}>
            <SkipNavigation />
            <RouterProvider router={router} context={{ auth }} />
          </ToastProvider>
        </Suspense>
      </Theme>
    </QueryProvider>
  );
};

function App() {
  // Initialize stores and database
  useInitializeStores();

  // Get text direction for RTL support
  const direction = useTextDirection();

  // Apply text direction to document
  useEffect(() => {
    document.documentElement.dir = direction;
  }, [direction]);

  return <InnerApp />;
}

export default App;
