/**
 * Transactions route
 * View and manage financial transactions
 */

import { createFileRoute } from '@tanstack/react-router';
import { TransactionsList } from '@/features/transactions';

export const Route = createFileRoute('/_auth/transactions')({
  component: TransactionsPage,
});

function TransactionsPage() {
  return (
    <div className="container">
      <main id="main-content">
        <TransactionsList />
      </main>
    </div>
  );
}
