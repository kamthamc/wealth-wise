/**
 * Recent Transactions Component
 * Display recent financial transactions
 */

import { Link } from '@tanstack/react-router';
import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
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
import { timestampToDate } from '@/core/utils/firebase';
import './RecentTransactions.css';

import type { Transaction } from '@/core/types';

export function RecentTransactions() {
  const { t } = useTranslation();
  const { transactions, isLoading } = useTransactionStore();
  const { preferences, loading: prefsLoading } = usePreferences();

  // Get the 5 most recent transactions
  const recentTransactions = useMemo(() => {
    return transactions
      .sort((a, b) => timestampToDate(b.date).getTime() - timestampToDate(a.date).getTime())
      .slice(0, 5);
  }, [transactions]);

  const columns: TableColumn<Transaction>[] = [
    {
      key: 'date',
      header: t('pages.dashboard.recentTransactions.date', 'Date'),
      accessor: (row) => formatDate(
        timestampToDate(row.date),
        preferences?.dateFormat || 'DD/MM/YYYY',
        preferences?.locale || 'en-IN'
      ),
      sortable: true,
    },
    {
      key: 'description',
      header: t('pages.dashboard.recentTransactions.description', 'Description'),
      accessor: (row) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span>{getTransactionIcon(row.type)}</span>
          <span>{row.description || t('pages.dashboard.recentTransactions.untitled', 'Untitled transaction')}</span>
        </div>
      ),
      sortable: true,
    },
    {
      key: 'category',
      header: t('pages.dashboard.recentTransactions.category', 'Category'),
      accessor: (row) => (
        <Badge variant="default" size="small">
          {row.category || t('pages.dashboard.recentTransactions.uncategorized', 'Uncategorized')}
        </Badge>
      ),
    },
    {
      key: 'amount',
      header: t('pages.dashboard.recentTransactions.amount', 'Amount'),
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
          <h2 className="recent-transactions__title">{t('pages.dashboard.recentTransactions.title', 'Recent Transactions')}</h2>
          <Link to="/transactions" className="recent-transactions__link">
            {t('pages.dashboard.recentTransactions.viewAll', 'View All')} →
          </Link>
        </div>

        {isLoading || prefsLoading ? (
          <SkeletonList items={5} />
        ) : recentTransactions.length > 0 ? (
          <Table
            columns={columns}
            data={recentTransactions as any}
            keyExtractor={(row) => row.id}
            hoverable
            compact
          />
        ) : (
          <EmptyState
            icon="📝"
            title={t('emptyState.transactions.title', 'No transactions yet')}
            description={t('emptyState.transactions.description', 'Start tracking your income and expenses by recording your first transaction')}
          />
        )}
      </Card>
    </section>
  );
}
