/**
 * Transactions List Component
 * Main transactions management page
 */

import { useNavigate } from '@tanstack/react-router';
import {
  ArrowDownCircle,
  ArrowRightLeft,
  ArrowUpCircle,
  BarChart3,
  CreditCard,
  Link2,
  Link2Off,
  ListFilter,
  Plus,
  Search,
  TrendingDown,
  TrendingUp,
} from 'lucide-react';
import { useMemo, useState } from 'react';
import type { Transaction } from '@/core/db/types';
import { useAccountStore, useTransactionStore } from '@/core/stores';
import {
  Button,
  EmptyState,
  Input,
  SegmentedControl,
  type SegmentedControlOption,
  Select,
  SkeletonList,
  SkeletonStats,
  SkeletonText,
  StatCard,
} from '@/shared/components';
import { formatCurrency, formatDate } from '@/shared/utils';
import type { TransactionType } from '../types';
import {
  formatTransactionAmount,
  getTransactionIcon,
} from '../utils/transactionHelpers';
import './TransactionsList.css';
import { AddTransactionForm } from './AddTransactionForm';
import { TransactionLinkingModal } from './TransactionLinkingModal';

// Transaction type filter options with icons
const FILTER_OPTIONS: SegmentedControlOption<TransactionType | 'all'>[] = [
  { value: 'all', label: 'All', icon: <ListFilter size={16} /> },
  { value: 'income', label: 'Income', icon: <ArrowUpCircle size={16} /> },
  { value: 'expense', label: 'Expense', icon: <ArrowDownCircle size={16} /> },
  {
    value: 'transfer',
    label: 'Transfer',
    icon: <ArrowRightLeft size={16} />,
  },
];

export function TransactionsList() {
  const navigate = useNavigate();
  const { transactions, isLoading, unlinkTransaction } = useTransactionStore();
  const { accounts } = useAccountStore();

  // Filter states (applied filters)
  const [typeFilter, setTypeFilter] = useState<TransactionType | 'all'>('all');
  const [accountFilter, setAccountFilter] = useState<string>('all');
  const [monthFilter, setMonthFilter] = useState<string>('all');
  const [yearFilter, setYearFilter] = useState<string>('all');
  const [minAmount, setMinAmount] = useState<string>('');
  const [maxAmount, setMaxAmount] = useState<string>('');
  const [searchQuery, setSearchQuery] = useState('');

  // Temporary filter states (not yet applied)
  const [tempAccountFilter, setTempAccountFilter] = useState<string>('all');
  const [tempMonthFilter, setTempMonthFilter] = useState<string>('all');
  const [tempYearFilter, setTempYearFilter] = useState<string>('all');
  const [tempMinAmount, setTempMinAmount] = useState<string>('');
  const [tempMaxAmount, setTempMaxAmount] = useState<string>('');

  // Sort state
  const [sortBy, setSortBy] = useState<
    'date-desc' | 'date-asc' | 'amount-desc' | 'amount-asc' | 'type'
  >('date-desc');

  const [isFormOpen, setIsFormOpen] = useState(false);
  const [linkingTransaction, setLinkingTransaction] =
    useState<Transaction | null>(null);
  const [showAdvancedFilters, setShowAdvancedFilters] = useState(false);

  // Apply filters handler
  const applyFilters = () => {
    setAccountFilter(tempAccountFilter);
    setYearFilter(tempYearFilter);
    setMonthFilter(tempMonthFilter);
    setMinAmount(tempMinAmount);
    setMaxAmount(tempMaxAmount);
  };

  // Reset filters handler
  const resetFilters = () => {
    setTempAccountFilter('all');
    setTempYearFilter('all');
    setTempMonthFilter('all');
    setTempMinAmount('');
    setTempMaxAmount('');
    setAccountFilter('all');
    setYearFilter('all');
    setMonthFilter('all');
    setMinAmount('');
    setMaxAmount('');
  };

  // Get unique years and months from transactions
  const availableYears = useMemo(() => {
    const years = new Set(
      transactions.map((t) => new Date(t.date).getFullYear())
    );
    return Array.from(years).sort((a, b) => b - a);
  }, [transactions]);

  const availableMonths = useMemo(() => {
    if (tempYearFilter === 'all') return [];
    const months = new Set(
      transactions
        .filter(
          (t) => new Date(t.date).getFullYear().toString() === tempYearFilter
        )
        .map((t) => new Date(t.date).getMonth())
    );
    return Array.from(months).sort((a, b) => a - b);
  }, [transactions, tempYearFilter]);

  // Filter and search transactions
  const filteredTransactions = useMemo(() => {
    let filtered = transactions;

    // Filter by type
    if (typeFilter !== 'all') {
      filtered = filtered.filter((txn) => txn.type === typeFilter);
    }

    // Filter by account
    if (accountFilter !== 'all') {
      filtered = filtered.filter((txn) => txn.account_id === accountFilter);
    }

    // Filter by year
    if (yearFilter !== 'all') {
      filtered = filtered.filter(
        (txn) => new Date(txn.date).getFullYear().toString() === yearFilter
      );
    }

    // Filter by month
    if (monthFilter !== 'all') {
      filtered = filtered.filter(
        (txn) => new Date(txn.date).getMonth().toString() === monthFilter
      );
    }

    // Filter by amount range
    if (minAmount) {
      const min = parseFloat(minAmount);
      if (!isNaN(min)) {
        filtered = filtered.filter((txn) => txn.amount >= min);
      }
    }
    if (maxAmount) {
      const max = parseFloat(maxAmount);
      if (!isNaN(max)) {
        filtered = filtered.filter((txn) => txn.amount <= max);
      }
    }

    // Search by description
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter((txn) =>
        txn.description?.toLowerCase().includes(query)
      );
    }

    // Sort transactions
    const sorted = [...filtered];
    switch (sortBy) {
      case 'date-desc':
        sorted.sort(
          (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
        );
        break;
      case 'date-asc':
        sorted.sort(
          (a, b) => new Date(a.date).getTime() - new Date(b.date).getTime()
        );
        break;
      case 'amount-desc':
        sorted.sort((a, b) => b.amount - a.amount);
        break;
      case 'amount-asc':
        sorted.sort((a, b) => a.amount - b.amount);
        break;
      case 'type':
        sorted.sort((a, b) => a.type.localeCompare(b.type));
        break;
    }

    return sorted;
  }, [
    transactions,
    typeFilter,
    accountFilter,
    yearFilter,
    monthFilter,
    minAmount,
    maxAmount,
    searchQuery,
    sortBy,
  ]);

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
      <div className="transactions-page">
        {/* Header */}
        <div className="transactions-page__header">
          <SkeletonText width="220px" />
        </div>

        {/* Stats Skeleton */}
        <SkeletonStats count={4} />

        {/* List Skeleton */}
        <SkeletonList items={10} />
      </div>
    );
  }

  return (
    <div className="page-container">
      {/* Header */}
      <div className="page-header">
        <div className="page-header-content">
          <h1 className="page-title">Transactions</h1>
          <p className="page-subtitle">Track your income and expenses</p>
        </div>
        <div className="page-actions">
          <Button onClick={() => setIsFormOpen(true)}>+ Add Transaction</Button>
        </div>
      </div>
      <div className="page-content">
        {/* Stats */}
        <div className="stats-grid">
          <StatCard
            label="Total Income"
            value={formatCurrency(stats.totalIncome)}
            icon={<TrendingUp size={24} />}
            variant="success"
          />
          <StatCard
            label="Total Expenses"
            value={formatCurrency(stats.totalExpenses)}
            icon={<TrendingDown size={24} />}
            variant="danger"
          />
          <StatCard
            label="Net Cash Flow"
            value={formatCurrency(stats.netCashFlow)}
            icon={<BarChart3 size={24} />}
            variant={stats.netCashFlow >= 0 ? 'success' : 'danger'}
          />
          <StatCard
            label="Total Transactions"
            value={stats.transactionCount.toString()}
            icon={<CreditCard size={24} />}
          />
        </div>

        {/* Controls */}
        <div className="filter-bar">
          <div className="filter-bar__search">
            <div className="filter-bar__search-icon">
              <Search size={20} />
            </div>
            <Input
              type="search"
              placeholder="Search transactions..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>

          <div className="filter-bar__controls">
            <SegmentedControl
              options={FILTER_OPTIONS}
              value={typeFilter}
              onChange={setTypeFilter}
              size="medium"
              aria-label="Filter transactions by type"
            />

            {/* Toggle Advanced Filters Button */}
            <Button
              variant="secondary"
              size="small"
              onClick={() => setShowAdvancedFilters(!showAdvancedFilters)}
            >
              {showAdvancedFilters ? 'Hide Filters' : 'More Filters'}
            </Button>
          </div>

          {/* Advanced Filters - Collapsible */}
          {showAdvancedFilters && (
            <div className="filter-bar__advanced">
              <div className="filter-bar__advanced-grid">
                {/* Account Filter */}
                <Select
                  options={[
                    { value: 'all', label: 'All Accounts' },
                    ...accounts.map((acc) => ({
                      value: acc.id,
                      label: acc.name,
                    })),
                  ]}
                  value={tempAccountFilter}
                  onChange={(e) => setTempAccountFilter(e.target.value)}
                  placeholder="Filter by account"
                />

                {/* Year Filter */}
                <Select
                  options={[
                    { value: 'all', label: 'All Years' },
                    ...availableYears.map((year) => ({
                      value: year.toString(),
                      label: year.toString(),
                    })),
                  ]}
                  value={tempYearFilter}
                  onChange={(e) => {
                    setTempYearFilter(e.target.value);
                    if (e.target.value === 'all') {
                      setTempMonthFilter('all');
                    }
                  }}
                  placeholder="Filter by year"
                />

                {/* Month Filter (conditional) */}
                {tempYearFilter !== 'all' && (
                  <Select
                    options={[
                      { value: 'all', label: 'All Months' },
                      ...availableMonths.map((month) => ({
                        value: month.toString(),
                        label: new Date(2000, month, 1).toLocaleString(
                          'default',
                          {
                            month: 'long',
                          }
                        ),
                      })),
                    ]}
                    value={tempMonthFilter}
                    onChange={(e) => setTempMonthFilter(e.target.value)}
                    placeholder="Filter by month"
                  />
                )}

                {/* Amount Range Filters */}
                <div className="filter-bar__amount-range">
                  <Input
                    type="number"
                    placeholder="Min amount"
                    value={tempMinAmount}
                    onChange={(e) => setTempMinAmount(e.target.value)}
                    className="filter-bar__amount-input"
                    min="0"
                    step="0.01"
                  />
                  <span className="filter-bar__amount-separator">to</span>
                  <Input
                    type="number"
                    placeholder="Max amount"
                    value={tempMaxAmount}
                    onChange={(e) => setTempMaxAmount(e.target.value)}
                    className="filter-bar__amount-input"
                    min="0"
                    step="0.01"
                  />
                </div>

                {/* Sort Dropdown */}
                <Select
                  options={[
                    { value: 'date-desc', label: 'Newest First' },
                    { value: 'date-asc', label: 'Oldest First' },
                    { value: 'amount-desc', label: 'Highest Amount' },
                    { value: 'amount-asc', label: 'Lowest Amount' },
                    { value: 'type', label: 'By Type' },
                  ]}
                  value={sortBy}
                  onChange={(e) =>
                    setSortBy(
                      e.target.value as
                        | 'date-desc'
                        | 'date-asc'
                        | 'amount-desc'
                        | 'amount-asc'
                        | 'type'
                    )
                  }
                  placeholder="Sort by"
                />
              </div>

              {/* Filter Actions */}
              <div className="filter-bar__actions">
                <Button variant="secondary" size="small" onClick={resetFilters}>
                  Reset
                </Button>
                <Button variant="primary" size="small" onClick={applyFilters}>
                  Apply Filters
                </Button>
              </div>
            </div>
          )}
        </div>

        {/* Transactions List */}
        {filteredTransactions.length === 0 ? (
          <div className="transactions-page__empty">
            <EmptyState
              icon={<CreditCard size={48} />}
              title={
                searchQuery || typeFilter !== 'all'
                  ? 'No transactions found'
                  : 'No transactions yet'
              }
              description={
                searchQuery || typeFilter !== 'all'
                  ? "Try adjusting your filters or search query to find the transactions you're looking for"
                  : 'Start tracking your income and expenses by recording your first transaction'
              }
              action={
                !searchQuery && typeFilter === 'all' ? (
                  <Button onClick={() => setIsFormOpen(true)}>
                    <Plus size={20} />
                    Add Your First Transaction
                  </Button>
                ) : undefined
              }
            />
          </div>
        ) : (
          <div className="transactions-page__list">
            {filteredTransactions.map((transaction) => (
              <div key={transaction.id} className="transaction-item-wrapper">
                <button
                  type="button"
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
                      {transaction.linked_transaction_id && (
                        <span className="transaction-item__linked-badge">
                          <Link2 size={14} />
                          Linked
                        </span>
                      )}
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
                </button>

                {/* Link/Unlink actions for transfer transactions */}
                {transaction.type === 'transfer' && (
                  <div className="transaction-item__actions">
                    {transaction.linked_transaction_id ? (
                      <button
                        type="button"
                        className="transaction-item__action-btn transaction-item__action-btn--unlink"
                        onClick={(e) => {
                          e.stopPropagation();
                          if (
                            confirm(
                              'Are you sure you want to unlink this transaction?'
                            )
                          ) {
                            unlinkTransaction(transaction.id);
                          }
                        }}
                        title="Unlink transaction"
                      >
                        <Link2Off size={16} />
                      </button>
                    ) : (
                      <button
                        type="button"
                        className="transaction-item__action-btn transaction-item__action-btn--link"
                        onClick={(e) => {
                          e.stopPropagation();
                          setLinkingTransaction(transaction);
                        }}
                        title="Link to another transaction"
                      >
                        <Link2 size={16} />
                      </button>
                    )}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>{' '}
      {/* Close page-content */}
      {/* Add Transaction Form */}
      <AddTransactionForm
        isOpen={isFormOpen}
        onClose={() => setIsFormOpen(false)}
      />
      {/* Transaction Linking Modal */}
      {linkingTransaction && (
        <TransactionLinkingModal
          isOpen={!!linkingTransaction}
          onClose={() => setLinkingTransaction(null)}
          sourceTransaction={linkingTransaction}
        />
      )}
    </div>
  );
}
