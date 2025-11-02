/**
 * Recent Transactions Component
 * Display recent financial transactions
 */

import { Link } from '@tanstack/react-router';
import { useMemo } from 'react';
import { useTransactionStore } from '@/core/stores';
import {
  getTransactionIcon,
  getTransactionTypeColor,
} from '@/features/transactions';
import {
  Badge,
  Card,
  EmptyState,
  SkeletonList,
  Table,
  type TableColumn,
} from '@/shared/components';
import { formatCurrency, formatDate } from '@/utils';
import { usePreferences } from '@/hooks/usePreferences';
import './RecentTransactions.css';

import type { Transaction } from '@/core/db/types';

export function RecentTransactions() {
  const { transactions, isLoading } = useTransactionStore();
  const { preferences, loading: prefsLoading } = usePreferences();

  // Get the 5 most recent transactions
  const recentTransactions = useMemo(() => {
    return transactions
      .sort((a, b) => b.date.getTime() - a.date.getTime())
      .slice(0, 5);
  }, [transactions]);

  const columns: TableColumn<Transaction>[] = [
    {
      key: 'date',
      header: 'Date',
      accessor: (row) => formatDate(
        new Date(row.date),
        preferences?.dateFormat || 'DD/MM/YYYY',
        preferences?.locale || 'en-IN'
      ),
      sortable: true,
    },
    {
      key: 'description',
      header: 'Description',
      accessor: (row) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span>{getTransactionIcon(row.type)}</span>
          <span>{row.description || 'Untitled transaction'}</span>
        </div>
      ),
      sortable: true,
    },
    {
      key: 'category',
      header: 'Category',
      accessor: (row) => (
        <Badge variant="default" size="small">
          {row.category || 'Uncategorized'}
        </Badge>
      ),
    },
    {
      key: 'amount',
      header: 'Amount',
      accessor: (row) => {
        const variant = getTransactionTypeColor(row.type);
        return (
          <span
            className={`transaction-amount transaction-amount--${variant}`}
            style={{
              color:
                row.type === 'income'
                  ? 'var(--color-success)'
                  : row.type === 'expense'
                    ? 'var(--color-danger)'
                    : 'var(--color-primary)',
              fontWeight: 600,
            }}
          >
            {row.type === 'income' ? '+' : row.type === 'expense' ? '-' : ''}
            {formatCurrency(
              row.amount,
              preferences?.currency || 'INR',
              preferences?.locale || 'en-IN'
            )}
          </span>
        );
      },
      align: 'right',
      sortable: true,
    },
  ];

  return (
    <section className="recent-transactions">
      <Card>
        <div className="recent-transactions__header">
          <h2 className="recent-transactions__title">Recent Transactions</h2>
          <Link to="/transactions" className="recent-transactions__link">
            View All →
          </Link>
        </div>

        {isLoading || prefsLoading ? (
          <SkeletonList items={5} />
        ) : recentTransactions.length > 0 ? (
          <Table
            columns={columns}
            data={recentTransactions}
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
