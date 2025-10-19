/**
 * Accounts List Component
 * Main accounts management page with filtering and search
 */

import { useNavigate } from '@tanstack/react-router';
import { useMemo, useState } from 'react';
import type { Account } from '@/core/db/types';
import { useAccountStore } from '@/core/stores';
import {
  Button,
  ConfirmDialog,
  EmptyState,
  Input,
  SkeletonCard,
  SkeletonStats,
  SkeletonText,
  StatCard,
} from '@/shared/components';
import { formatCurrency } from '@/shared/utils';
import type { AccountFilters, AccountFormData, AccountType } from '../types';
import { getAccountIcon, getAccountTypeName } from '../utils/accountHelpers';
import { AccountCard } from './AccountCard';
import { AddAccountModal } from './AddAccountModal';
import './AccountsList.css';

const FILTER_OPTIONS: (AccountType | 'all')[] = [
  'all',
  'bank',
  'credit_card',
  'upi',
  'brokerage',
  'cash',
  'wallet',
];

export function AccountsList() {
  const navigate = useNavigate();
  const {
    accounts,
    isLoading,
    fetchAccounts,
    createAccount,
    updateAccount,
    deleteAccount,
  } = useAccountStore();

  const [filters, setFilters] = useState<AccountFilters>({});
  const [searchQuery, setSearchQuery] = useState('');
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingAccount, setEditingAccount] = useState<Account | undefined>();
  const [deletingAccount, setDeletingAccount] = useState<Account | undefined>();

  // Filter and search accounts
  const filteredAccounts = useMemo(() => {
    let filtered = accounts;

    // Filter by type
    if (filters.type) {
      filtered = filtered.filter((acc) => acc.type === filters.type);
    }

    // Search by name
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter((acc) =>
        acc.name.toLowerCase().includes(query)
      );
    }

    return filtered;
  }, [accounts, filters, searchQuery]);

  // Calculate stats
  const stats = useMemo(() => {
    const totalBalance = accounts.reduce((sum, acc) => sum + acc.balance, 0);
    const activeAccounts = accounts.filter((acc) => acc.is_active).length;

    return {
      totalBalance,
      activeAccounts,
      totalAccounts: accounts.length,
    };
  }, [accounts]);

  const handleAddAccount = async (data: AccountFormData) => {
    await createAccount({
      ...data,
      is_active: true,
    });
    setIsAddModalOpen(false);
    await fetchAccounts();
  };

  const handleEditAccount = async (data: AccountFormData) => {
    if (editingAccount) {
      await updateAccount({
        ...data,
        id: editingAccount.id,
      });
      setEditingAccount(undefined);
      await fetchAccounts();
    }
  };

  const handleDeleteAccount = async () => {
    if (deletingAccount) {
      await deleteAccount(deletingAccount.id);
      await fetchAccounts();
      setDeletingAccount(undefined);
    }
  };

  const handleAccountClick = (account: Account) => {
    // Navigate to account details (we'll create this route later)
    navigate({ to: `/accounts/${account.id}` });
  };

  if (isLoading) {
    return (
      <div className="accounts-page">
        {/* Header */}
        <div className="accounts-page__header">
          <SkeletonText width="200px" />
        </div>

        {/* Stats Skeleton */}
        <SkeletonStats count={3} />

        {/* Grid Skeleton */}
        <div className="accounts-page__grid">
          {Array.from({ length: 6 }).map((_, i) => (
            <SkeletonCard key={i} />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="page-container">
      {/* Header */}
      <div className="page-header">
        <div className="page-header-content">
          <h1 className="page-title">Accounts</h1>
          <p className="page-subtitle">Manage your financial accounts and track balances</p>
        </div>
        <div className="page-actions">
          <Button onClick={() => setIsAddModalOpen(true)}>+ Add Account</Button>
        </div>
      </div>

      <div className="page-content">{/* Content starts here */}

      {/* Stats */}
      <div className="stats-grid">
        <StatCard
          label="Total Balance"
          value={formatCurrency(stats.totalBalance)}
          icon="💰"
          variant="primary"
        />
        <StatCard
          label="Active Accounts"
          value={stats.activeAccounts.toString()}
          icon="✓"
          variant="success"
        />
        <StatCard
          label="Total Accounts"
          value={stats.totalAccounts.toString()}
          icon="📊"
        />
      </div>

      {/* Controls */}
      <div className="filter-bar">
        <Input
          type="search"
          placeholder="🔍 Search accounts..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />

        <div className="filter-group">
          {FILTER_OPTIONS.map((type) => (
            <button
              key={type}
              type="button"
              className={`filter-chip ${
                (type === 'all' && !filters.type) || filters.type === type
                  ? 'active'
                  : ''
              }`}
              onClick={() =>
                setFilters({
                  type: type === 'all' ? undefined : type,
                })
              }
            >
              {type !== 'all' && (
                <span className="accounts-page__filter-icon">
                  {getAccountIcon(type)}
                </span>
              )}
              {type === 'all' ? 'All' : getAccountTypeName(type)}
            </button>
          ))}
        </div>
      </div>

      {/* Accounts Grid */}
      {filteredAccounts.length === 0 ? (
        <div className="accounts-page__empty">
          <EmptyState
            icon="🏦"
            size={searchQuery || filters.type ? 'small' : 'medium'}
            title={
              searchQuery || filters.type
                ? 'No accounts found'
                : 'No accounts yet'
            }
            description={
              searchQuery || filters.type
                ? 'Try adjusting your filters or search query to find what you\'re looking for'
                : 'Start tracking your finances by adding your bank accounts, credit cards, and other financial accounts'
            }
            action={
              !searchQuery && !filters.type ? (
                <Button onClick={() => setIsAddModalOpen(true)}>
                  Add Your First Account
                </Button>
              ) : undefined
            }
            secondaryAction={
              !searchQuery && !filters.type ? (
                <a href="#" onClick={(e) => e.preventDefault()}>
                  Learn about account types →
                </a>
              ) : undefined
            }
          />
        </div>
      ) : (
        <div className="cards-grid">
          {filteredAccounts.map((account) => (
            <AccountCard
              key={account.id}
              account={account}
              onClick={handleAccountClick}
              onEdit={setEditingAccount}
              onDelete={setDeletingAccount}
            />
          ))}
        </div>
      )}
      </div> {/* Close page-content */}

      {/* Add/Edit Modal */}
      <AddAccountModal
        account={editingAccount}
        isOpen={isAddModalOpen || !!editingAccount}
        onClose={() => {
          setIsAddModalOpen(false);
          setEditingAccount(undefined);
        }}
        onSubmit={editingAccount ? handleEditAccount : handleAddAccount}
      />

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        isOpen={!!deletingAccount}
        onClose={() => setDeletingAccount(undefined)}
        onConfirm={handleDeleteAccount}
        title="Delete Account?"
        description={`Are you sure you want to delete "${deletingAccount?.name}"? This action cannot be undone and all associated data will be permanently removed.`}
        confirmLabel="Delete Account"
        cancelLabel="Cancel"
        variant="danger"
      />
    </div>
  );
}
