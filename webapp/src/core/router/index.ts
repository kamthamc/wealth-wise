/**
 * Router configuration
 * Creates and exports the configured router instance
 */

import { createRouter } from '@tanstack/react-router';
import { routeTree } from '@/routeTree.gen';

// Create router instance
export const router = createRouter({
  routeTree,
  defaultPreload: 'intent',
  defaultPreloadStaleTime: 0,
});

// Register router for type safety
declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}
