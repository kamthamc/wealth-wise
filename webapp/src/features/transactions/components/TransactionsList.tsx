/**
 * Transactions List Component
 * Main transactions management page
 */

import { useNavigate } from '@tanstack/react-router';
import { useMemo, useState } from 'react';
import { useTransactionStore, useAccountStore } from '@/core/stores';
import {
  Button,
  EmptyState,
  Input,
  Spinner,
  StatCard,
} from '@/shared/components';
import { formatCurrency, formatDate } from '@/shared/utils';
import type { TransactionFilters, TransactionType } from '../types';
import {
  formatTransactionAmount,
  getTransactionIcon,
  getTransactionTypeName,
} from '../utils/transactionHelpers';
import { AddTransactionForm } from './AddTransactionForm';
import './TransactionsList.css';

const FILTER_OPTIONS: (TransactionType | 'all')[] = [
  'all',
  'income',
  'expense',
  'transfer',
];

export function TransactionsList() {
  const navigate = useNavigate();
  const {
    transactions,
    isLoading,
  } = useTransactionStore();
  const { accounts } = useAccountStore();

  const [filters, setFilters] = useState<TransactionFilters>({});
  const [searchQuery, setSearchQuery] = useState('');
  const [isFormOpen, setIsFormOpen] = useState(false);

  // Filter and search transactions
  const filteredTransactions = useMemo(() => {
    let filtered = transactions;

    // Filter by type
    if (filters.type) {
      filtered = filtered.filter((txn) => txn.type === filters.type);
    }

    // Filter by account
    if (filters.account_id) {
      filtered = filtered.filter((txn) => txn.account_id === filters.account_id);
    }

    // Search by description
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(
        (txn) => txn.description && txn.description.toLowerCase().includes(query)
      );
    }

    // Sort by date (newest first)
    return filtered.sort(
      (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
    );
  }, [transactions, filters, searchQuery]);

  // Calculate stats
  const stats = useMemo(() => {
    const income = transactions
      .filter((t) => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);
    const expenses = transactions
      .filter((t) => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);

    return {
      totalIncome: income,
      totalExpenses: expenses,
      netCashFlow: income - expenses,
      transactionCount: transactions.length,
    };
  }, [transactions]);

  const getAccountName = (accountId: string) => {
    const account = accounts.find((a) => a.id === accountId);
    return account?.name || 'Unknown Account';
  };

  if (isLoading) {
    return (
      <div className="transactions-page__loading">
        <Spinner size="large" />
        <p style={{ color: 'var(--color-text-secondary)' }}>
          Loading transactions...
        </p>
      </div>
    );
  }

  return (
    <div className="transactions-page">
      {/* Header */}
      <div className="transactions-page__header">
        <h1 className="transactions-page__title">Transactions</h1>
        <Button onClick={() => setIsFormOpen(true)}>+ Add Transaction</Button>
      </div>

      {/* Stats */}
      <div className="transactions-page__stats">
        <StatCard
          label="Total Income"
          value={formatCurrency(stats.totalIncome)}
          icon="💰"
          variant="success"
        />
        <StatCard
          label="Total Expenses"
          value={formatCurrency(stats.totalExpenses)}
          icon="💸"
          variant="danger"
        />
        <StatCard
          label="Net Cash Flow"
          value={formatCurrency(stats.netCashFlow)}
          icon="📊"
          variant={stats.netCashFlow >= 0 ? 'success' : 'danger'}
        />
        <StatCard
          label="Total Transactions"
          value={stats.transactionCount.toString()}
          icon="📝"
        />
      </div>

      {/* Controls */}
      <div className="transactions-page__controls">
        <div className="transactions-page__search">
          <Input
            type="search"
            placeholder="🔍 Search transactions..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="transactions-page__filters">
          {FILTER_OPTIONS.map((type) => (
            <button
              key={type}
              type="button"
              className={`transactions-page__filter-button ${
                (type === 'all' && !filters.type) || filters.type === type
                  ? 'transactions-page__filter-button--active'
                  : ''
              }`}
              onClick={() =>
                setFilters({
                  ...filters,
                  type: type === 'all' ? undefined : type,
                })
              }
            >
              {type !== 'all' && (
                <span className="transactions-page__filter-icon">
                  {getTransactionIcon(type)}
                </span>
              )}
              {type === 'all' ? 'All' : getTransactionTypeName(type)}
            </button>
          ))}
        </div>
      </div>

      {/* Transactions List */}
      {filteredTransactions.length === 0 ? (
        <div className="transactions-page__empty">
          <EmptyState
            icon="💳"
            title={
              searchQuery || filters.type
                ? 'No transactions found'
                : 'No transactions yet'
            }
            description={
              searchQuery || filters.type
                ? 'Try adjusting your filters or search query'
                : 'Get started by adding your first transaction'
            }
            action={
              !searchQuery && !filters.type ? (
                <Button onClick={() => setIsFormOpen(true)}>
                  Add Your First Transaction
                </Button>
              ) : undefined
            }
          />
        </div>
      ) : (
        <div className="transactions-page__list">
          {filteredTransactions.map((transaction) => (
            <div
              key={transaction.id}
              className="transaction-item"
              onClick={() =>
                navigate({ to: `/transactions/${transaction.id}` })
              }
            >
              <div className="transaction-item__icon">
                {getTransactionIcon(transaction.type)}
              </div>
              <div className="transaction-item__content">
                <h3 className="transaction-item__description">
                  {transaction.description}
                </h3>
                <p className="transaction-item__meta">
                  {getAccountName(transaction.account_id)} •{' '}
                  {formatDate(new Date(transaction.date))}
                </p>
              </div>
              <div
                className={`transaction-item__amount transaction-item__amount--${transaction.type}`}
              >
                {formatTransactionAmount(
                  transaction.amount,
                  transaction.type,
                  'INR'
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add Transaction Form */}
      <AddTransactionForm
        isOpen={isFormOpen}
        onClose={() => setIsFormOpen(false)}
      />
    </div>
  );
}
