/**
 * Accounts Route
 * Manage bank accounts, credit cards, and other accounts
 */

import { createFileRoute } from '@tanstack/react-router';
import { DashboardLayout } from '@/features/dashboard/components';
import { AccountsList } from '@/features/accounts';

export const Route = createFileRoute('/_auth/accounts')({
  component: AccountsPage,
  onCatch(error) {
    console.error('Error loading Accounts route:', error);
  },
  onError(err) {
    console.error('Unexpected error in Accounts route:', err);
  },
  onEnter(match) {
    console.log('Entering Accounts route:', match);
  },
  onLeave(match) {
    console.log('Leaving Accounts route:', match);
  },
});

function AccountsPage() {
  return (
    <DashboardLayout>
      <AccountsList />
    </DashboardLayout>
  );
}
