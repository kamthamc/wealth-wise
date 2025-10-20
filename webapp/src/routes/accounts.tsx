/**
 * Accounts Route
 * Manage bank accounts, credit cards, and other accounts
 */

import { createFileRoute, Outlet } from '@tanstack/react-router';
import { DashboardLayout } from '@/features/dashboard/components';

export const Route = createFileRoute('/accounts')({
  component: AccountsPage,
});

function AccountsPage() {
  return (
    <DashboardLayout>
      <Outlet />
    </DashboardLayout>
  );
}
