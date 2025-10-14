/**
 * Recent Transactions Component
 * Display recent financial transactions
 */

import {
  Badge,
  Card,
  EmptyState,
  Table,
  type TableColumn,
} from '@/shared/components';
import './RecentTransactions.css';

interface Transaction {
  id: string;
  date: string;
  description: string;
  category: string;
  amount: number;
  type: 'income' | 'expense';
}

export function RecentTransactions() {
  // TODO: Replace with real data from store
  const transactions: Transaction[] = [
    {
      id: '1',
      date: '2025-10-12',
      description: 'Salary Credit',
      category: 'Income',
      amount: 85000,
      type: 'income',
    },
    {
      id: '2',
      date: '2025-10-11',
      description: 'Grocery Shopping',
      category: 'Food & Dining',
      amount: -2450,
      type: 'expense',
    },
    {
      id: '3',
      date: '2025-10-10',
      description: 'Electricity Bill',
      category: 'Utilities',
      amount: -1820,
      type: 'expense',
    },
    {
      id: '4',
      date: '2025-10-09',
      description: 'Freelance Project',
      category: 'Income',
      amount: 15000,
      type: 'income',
    },
    {
      id: '5',
      date: '2025-10-08',
      description: 'Netflix Subscription',
      category: 'Entertainment',
      amount: -649,
      type: 'expense',
    },
  ];

  const columns: TableColumn<Transaction>[] = [
    {
      key: 'date',
      header: 'Date',
      accessor: (row) => new Date(row.date).toLocaleDateString('en-IN'),
      sortable: true,
    },
    {
      key: 'description',
      header: 'Description',
      accessor: (row) => row.description,
      sortable: true,
    },
    {
      key: 'category',
      header: 'Category',
      accessor: (row) => (
        <Badge variant="default" size="small">
          {row.category}
        </Badge>
      ),
    },
    {
      key: 'amount',
      header: 'Amount',
      accessor: (row) => (
        <span
          className={`transaction-amount ${
            row.type === 'income'
              ? 'transaction-amount--income'
              : 'transaction-amount--expense'
          }`}
        >
          {row.type === 'income' ? '+' : ''}
          {new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR',
          }).format(row.amount)}
        </span>
      ),
      align: 'right',
      sortable: true,
    },
  ];

  return (
    <section className="recent-transactions">
      <Card>
        <div className="recent-transactions__header">
          <h2 className="recent-transactions__title">Recent Transactions</h2>
          <a href="/transactions" className="recent-transactions__link">
            View All →
          </a>
        </div>

        {transactions.length > 0 ? (
          <Table
            columns={columns}
            data={transactions}
            keyExtractor={(row) => row.id}
            hoverable
            compact
          />
        ) : (
          <EmptyState
            icon="📝"
            title="No transactions yet"
            description="Start tracking your finances by adding your first transaction"
          />
        )}
      </Card>
    </section>
  );
}
