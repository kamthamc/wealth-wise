/**
 * Accounts List Component
 * Main accounts management page with filtering and search
 */

import { useNavigate } from '@tanstack/react-router';
import {
  ArrowRightLeft,
  BarChart3,
  CheckCircle,
  Coins,
  Landmark,
  Plus,
} from 'lucide-react';
import { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { Account } from '@/core/db/types';
import { useAccountStore } from '@/core/stores';
import {
  Button,
  ConfirmDialog,
  EmptyState,
  Input,
  MultiSelectFilter,
  SkeletonCard,
  SkeletonStats,
  SkeletonText,
  StatCard,
} from '@/shared/components';
import { formatCurrency } from '@/shared/utils';
import type { AccountFilters, AccountFormData, AccountType } from '../types';
import { getAccountIcon } from '../utils/accountHelpers';
import { AccountCard } from './AccountCard';
import { AccountTransferWizard } from './AccountTransferWizard';
import { AddAccountModal } from './AddAccountModal';
import './AccountsList.css';

const ACCOUNT_TYPE_OPTIONS: Array<{
  value: AccountType;
  label: string;
  icon: React.ReactNode;
}> = [
  // Banking
  { value: 'bank', label: 'Bank Account', icon: getAccountIcon('bank') },
  {
    value: 'credit_card',
    label: 'Credit Card',
    icon: getAccountIcon('credit_card'),
  },
  { value: 'upi', label: 'UPI Wallet', icon: getAccountIcon('upi') },

  // Investments
  { value: 'brokerage', label: 'Brokerage', icon: getAccountIcon('brokerage') },

  // Deposits & Savings
  {
    value: 'fixed_deposit',
    label: 'Fixed Deposit',
    icon: getAccountIcon('fixed_deposit'),
  },
  {
    value: 'recurring_deposit',
    label: 'Recurring Deposit',
    icon: getAccountIcon('recurring_deposit'),
  },
  { value: 'ppf', label: 'Public Provident Fund', icon: getAccountIcon('ppf') },
  {
    value: 'nsc',
    label: 'National Savings Certificate',
    icon: getAccountIcon('nsc'),
  },
  { value: 'kvp', label: 'Kisan Vikas Patra', icon: getAccountIcon('kvp') },
  {
    value: 'scss',
    label: 'Senior Citizen Savings Scheme',
    icon: getAccountIcon('scss'),
  },
  {
    value: 'post_office',
    label: 'Post Office Savings',
    icon: getAccountIcon('post_office'),
  },

  // Cash & Wallets
  { value: 'cash', label: 'Cash', icon: getAccountIcon('cash') },
  { value: 'wallet', label: 'Wallet', icon: getAccountIcon('wallet') },
];

export function AccountsList() {
  const navigate = useNavigate();
  const { t } = useTranslation();
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
  const [isTransferWizardOpen, setIsTransferWizardOpen] = useState(false);
  const [editingAccount, setEditingAccount] = useState<Account | undefined>();
  const [deletingAccount, setDeletingAccount] = useState<Account | undefined>();

  // Account options for multi-select filter
  const accountOptions = useMemo(
    () =>
      accounts.map((account) => ({
        value: account.id,
        label: account.name,
        icon: getAccountIcon(account.type),
      })),
    [accounts]
  );

  // Filter and search accounts
  const filteredAccounts = useMemo(() => {
    let filtered = accounts;

    // Filter by types (multi-select)
    if (filters.types && filters.types.length > 0) {
      filtered = filtered.filter((acc) => filters.types?.includes(acc.type));
    }

    // Filter by specific account IDs (multi-select)
    if (filters.accountIds && filters.accountIds.length > 0) {
      filtered = filtered.filter((acc) => filters.accountIds?.includes(acc.id));
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
    const totalBalance = accounts.reduce((sum, acc) => sum + +acc.balance, 0);
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
    navigate({
      to: `/accounts/$accountId`,
      params: { accountId: account.id },
    });
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
          <h1 className="page-title">
            {t('pages.accounts.title', 'Accounts')}
          </h1>
          <p className="page-subtitle">
            {t(
              'pages.accounts.subtitle',
              'Manage your financial accounts and track balances'
            )}
          </p>
        </div>
        <div className="page-actions">
          <Button
            onClick={() => setIsTransferWizardOpen(true)}
            variant="secondary"
            size="medium"
          >
            <ArrowRightLeft size={18} />
            {t('pages.accounts.transferButton', 'Transfer Money')}
          </Button>
          <Button
            onClick={() => setIsAddModalOpen(true)}
            variant="primary"
            size="medium"
          >
            <Plus size={18} />
            {t('pages.accounts.addButton', 'Add Account')}
          </Button>
        </div>
      </div>
      <div className="page-content">
        {/* Content starts here */}

        {/* Stats */}
        <div className="stats-grid">
          <StatCard
            label={t('pages.accounts.stats.totalBalance', 'Total Balance')}
            value={formatCurrency(stats.totalBalance)}
            icon={<Coins size={24} />}
            variant="primary"
          />
          <StatCard
            label={t('pages.accounts.stats.activeAccounts', 'Active Accounts')}
            value={stats.activeAccounts.toString()}
            icon={<CheckCircle size={24} />}
            variant="success"
          />
          <StatCard
            label={t('pages.accounts.stats.totalAccounts', 'Total Accounts')}
            value={stats.totalAccounts.toString()}
            icon={<BarChart3 size={24} />}
          />
        </div>

        {/* Controls */}
        <div className="filter-bar">
          <Input
            type="search"
            placeholder={t(
              'pages.accounts.searchPlaceholder',
              '🔍 Search accounts...'
            )}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />

          <MultiSelectFilter
            options={ACCOUNT_TYPE_OPTIONS}
            selected={filters.types || []}
            onChange={(types) => setFilters({ ...filters, types })}
            label="Account Types"
            placeholder="All account types"
            searchPlaceholder="Search account types..."
          />

          <MultiSelectFilter
            options={accountOptions}
            selected={filters.accountIds || []}
            onChange={(accountIds) => setFilters({ ...filters, accountIds })}
            label="Specific Accounts"
            placeholder="All accounts"
            searchPlaceholder="Search accounts..."
            maxDisplay={2}
          />
        </div>

        {/* Accounts Grid */}
        {filteredAccounts.length === 0 ? (
          <div className="accounts-page__empty">
            <EmptyState
              icon={<Landmark size={48} />}
              size={
                searchQuery ||
                (filters.types && filters.types.length > 0) ||
                (filters.accountIds && filters.accountIds.length > 0)
                  ? 'small'
                  : 'medium'
              }
              title={
                searchQuery ||
                (filters.types && filters.types.length > 0) ||
                (filters.accountIds && filters.accountIds.length > 0)
                  ? t('emptyState.accounts.filtered.title')
                  : t('emptyState.accounts.title')
              }
              description={
                searchQuery ||
                (filters.types && filters.types.length > 0) ||
                (filters.accountIds && filters.accountIds.length > 0)
                  ? t('emptyState.accounts.filtered.description')
                  : t('emptyState.accounts.description')
              }
              action={
                !searchQuery &&
                (!filters.types || filters.types.length === 0) &&
                (!filters.accountIds || filters.accountIds.length === 0) ? (
                  <Button onClick={() => setIsAddModalOpen(true)}>
                    Add Your First Account
                  </Button>
                ) : undefined
              }
              secondaryAction={
                !searchQuery &&
                (!filters.types || filters.types.length === 0) &&
                (!filters.accountIds || filters.accountIds.length === 0) ? (
                  <button
                    type="button"
                    className="link-button"
                    onClick={(e) => e.preventDefault()}
                  >
                    Learn about account types →
                  </button>
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
      </div>{' '}
      {/* Close page-content */}
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
      {/* Account Transfer Wizard */}
      <AccountTransferWizard
        isOpen={isTransferWizardOpen}
        onClose={() => setIsTransferWizardOpen(false)}
      />
    </div>
  );
}
