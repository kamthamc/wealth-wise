/**
 * WealthWise - Main Application Component
 * Local-first personal finance management application
 */

import { RouterProvider } from '@tanstack/react-router';
import { router } from './core/router';
import { useInitializeStores } from './core/stores';
import { SkipNavigation, ToastProvider } from './shared/components';

function App() {
  // Initialize stores and database
  useInitializeStores();

  return (
    <ToastProvider maxToasts={3} defaultDuration={5000}>
      <SkipNavigation />
      <RouterProvider router={router} />
    </ToastProvider>
  );
}

export default App;
