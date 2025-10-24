/**
 * Root route configuration
 * Base layout and route tree setup
 */

import { createRootRouteWithContext, Outlet } from '@tanstack/react-router';
import { TanStackRouterDevtools } from '@tanstack/react-router-devtools';
import { AppLayout } from '@/shared/components';
import { type AuthContext } from '@/core/hooks/useAuth';

interface RootRouteContext {
  auth: AuthContext;
}

export const Route = createRootRouteWithContext<RootRouteContext>()({
  component: RootComponent,
});

function RootComponent() {
  return (
    <AppLayout>
      <Outlet />
      {import.meta.env.DEV && (
        <TanStackRouterDevtools position="bottom-right" />
      )}
    </AppLayout>
  );
}
