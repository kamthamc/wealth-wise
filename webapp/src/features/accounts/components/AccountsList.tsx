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
  EmptyState,
  Input,
  Spinner,
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

  const handleDeleteAccount = async (account: Account) => {
    if (
      window.confirm(
        `Are you sure you want to delete "${account.name}"? This action cannot be undone.`
      )
    ) {
      await deleteAccount(account.id);
      await fetchAccounts();
    }
  };

  const handleAccountClick = (account: Account) => {
    // Navigate to account details (we'll create this route later)
    navigate({ to: `/accounts/${account.id}` });
  };

  if (isLoading) {
    return (
      <div className="accounts-page__loading">
        <Spinner size="large" />
        <p style={{ color: 'var(--color-text-secondary)' }}>
          Loading accounts...
        </p>
      </div>
    );
  }

  return (
    <div className="accounts-page">
      {/* Header */}
      <div className="accounts-page__header">
        <h1 className="accounts-page__title">Accounts</h1>
        <Button onClick={() => setIsAddModalOpen(true)}>+ Add Account</Button>
      </div>

      {/* Stats */}
      <div className="accounts-page__stats">
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
      <div className="accounts-page__controls">
        <div className="accounts-page__search">
          <Input
            type="search"
            placeholder="🔍 Search accounts..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div className="accounts-page__filters">
          {FILTER_OPTIONS.map((type) => (
            <button
              key={type}
              type="button"
              className={`accounts-page__filter-button ${
                (type === 'all' && !filters.type) || filters.type === type
                  ? 'accounts-page__filter-button--active'
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
            title={
              searchQuery || filters.type
                ? 'No accounts found'
                : 'No accounts yet'
            }
            description={
              searchQuery || filters.type
                ? 'Try adjusting your filters or search query'
                : 'Get started by adding your first account'
            }
            action={
              !searchQuery && !filters.type ? (
                <Button onClick={() => setIsAddModalOpen(true)}>
                  Add Your First Account
                </Button>
              ) : undefined
            }
          />
        </div>
      ) : (
        <div className="accounts-page__grid">
          {filteredAccounts.map((account) => (
            <AccountCard
              key={account.id}
              account={account}
              onClick={handleAccountClick}
              onEdit={setEditingAccount}
              onDelete={handleDeleteAccount}
            />
          ))}
        </div>
      )}

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
    </div>
  );
}
