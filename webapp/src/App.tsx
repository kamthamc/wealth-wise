/**
 * WealthWise - Main Application Component
 * Local-first personal finance management application
 */

import { RouterProvider } from '@tanstack/react-router';
import { useEffect } from 'react';
import './core/i18n'; // Initialize i18n
import { router } from './core/router';
import { useInitializeStores } from './core/stores';
import { useTextDirection } from './core/i18n';
import { SkipNavigation, ToastProvider } from './shared/components';

function App() {
  // Initialize stores and database
  useInitializeStores();
  
  // Get text direction for RTL support
  const direction = useTextDirection();
  
  // Apply text direction to document
  useEffect(() => {
    document.documentElement.dir = direction;
    document.documentElement.lang = direction === 'rtl' ? 'ar' : 'en-IN';
  }, [direction]);

  return (
    <ToastProvider maxToasts={3} defaultDuration={5000}>
      <SkipNavigation />
      <RouterProvider router={router} />
    </ToastProvider>
  );
}

export default App;
