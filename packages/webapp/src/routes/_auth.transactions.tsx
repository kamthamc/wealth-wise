/**
 * Transactions route
 * View and manage financial transactions
 */

import { createFileRoute } from '@tanstack/react-router';
import { TransactionsList } from '@/features/transactions';

export const Route = createFileRoute('/_auth/transactions')({
  component: TransactionsList,
});

