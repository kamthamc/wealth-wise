/**
 * Accounts Index Route
 * Display the list of all accounts
 */

import { createFileRoute } from '@tanstack/react-router';
import { AccountsList } from '@/features/accounts';

export const Route = createFileRoute('/accounts/')({
  component: AccountsListPage,
});

function AccountsListPage() {
  return <AccountsList />;
}
