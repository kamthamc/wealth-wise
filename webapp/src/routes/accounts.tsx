/**
 * Accounts Route
 * Manage bank accounts, credit cards, and other accounts
 */

import { createFileRoute } from '@tanstack/react-router';
import { AccountsList } from '@/features/accounts';
import { DashboardLayout } from '@/features/dashboard/components';

export const Route = createFileRoute('/accounts')({
  component: AccountsPage,
});

function AccountsPage() {
  return (
    <DashboardLayout>
      <AccountsList />
    </DashboardLayout>
  );
}
