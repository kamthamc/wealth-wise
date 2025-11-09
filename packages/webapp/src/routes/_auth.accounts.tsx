/**
 * Accounts Route
 * Manage bank accounts, credit cards, and other accounts
 */

import { createFileRoute } from '@tanstack/react-router';
import { AccountsList } from '@/features/accounts';

export const Route = createFileRoute('/_auth/accounts')({
  component: AccountsList,
});

