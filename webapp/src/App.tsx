/**
 * WealthWise - Main Application Component
 * Local-first personal finance management application
 */

import { RouterProvider } from '@tanstack/react-router';
import { router } from './core/router';
import { useInitializeStores } from './core/stores';
import { SkipNavigation } from './shared/components';

function App() {
  // Initialize stores and database
  useInitializeStores();

  return (
    <>
      <SkipNavigation />
      <RouterProvider router={router} />
    </>
  );
}

export default App;
