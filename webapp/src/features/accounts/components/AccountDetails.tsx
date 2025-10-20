/**
 * Account Details Component
 * Displays detailed information about a single account
 */

import { useNavigate } from '@tanstack/react-router';
import { useEffect, useMemo, useState } from 'react';
import type { Account } from '@/core/db/types';
import { useAccountStore, useTransactionStore } from '@/core/stores';
import {
  Button,
  ConfirmDialog,
  EmptyState,
  Spinner,
  StatCard,
} from '@/shared/components';
import { formatCurrency, formatDate, formatRelativeTime } from '@/shared/utils';
import type { AccountFormData } from '../types';
import {
  formatAccountIdentifier,
  getAccountIcon,
  getAccountTypeName,
} from '../utils/accountHelpers';
import { AddAccountModal } from './AddAccountModal';
import './AccountDetails.css';

export interface AccountDetailsProps {
  accountId: string;
}

export function AccountDetails({ accountId }: AccountDetailsProps) {
  const navigate = useNavigate();
  const { accounts, isLoading, fetchAccounts, updateAccount, deleteAccount } =
    useAccountStore();
  const { transactions } = useTransactionStore();

  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [account, setAccount] = useState<Account | null>(null);

  // Find the account from the store
  useEffect(() => {
    const foundAccount = accounts.find((acc) => acc.id === accountId);
    if (foundAccount) {
      setAccount(foundAccount);
    } else if (!isLoading) {
      // Account not found, might need to fetch
      fetchAccounts();
    }
  }, [accountId, accounts, isLoading, fetchAccounts]);

  // Filter transactions for this account
  const accountTransactions = useMemo(() => {
    return transactions
      .filter((txn) => txn.account_id === accountId)
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  }, [transactions, accountId]);

  // Calculate account statistics
  const accountStats = useMemo(() => {
    const now = new Date();
    const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const thisMonthTransactions = accountTransactions.filter(
      (txn) => new Date(txn.date) >= firstDayOfMonth
    );

    const income = thisMonthTransactions
      .filter((txn) => txn.type === 'income')
      .reduce((sum, txn) => sum + txn.amount, 0);

    const expenses = thisMonthTransactions
      .filter((txn) => txn.type === 'expense')
      .reduce((sum, txn) => sum + txn.amount, 0);

    return {
      totalTransactions: accountTransactions.length,
      thisMonthTotal: income - expenses,
      thisMonthIncome: income,
      thisMonthExpenses: expenses,
    };
  }, [accountTransactions]);

  const handleEditAccount = async (data: AccountFormData) => {
    if (account) {
      await updateAccount({
        ...data,
        id: account.id,
      });
      await fetchAccounts();
      setIsEditModalOpen(false);
    }
  };

  const handleDeleteAccount = async () => {
    if (account) {
      await deleteAccount(account.id);
      navigate({ to: '/accounts' });
    }
  };

  const handleBackToAccounts = () => {
    navigate({ to: '/accounts' });
  };

  // Loading state
  if (isLoading && !account) {
    return (
      <div className="account-details__loading">
        <Spinner size="large" />
        <p style={{ color: 'var(--color-text-secondary)' }}>
          Loading account details...
        </p>
      </div>
    );
  }

  // Account not found
  if (!account) {
    return (
      <div className="account-details__empty">
        <EmptyState
          icon="🔍"
          title="Account Not Found"
          description="The account you're looking for doesn't exist or has been deleted."
          action={
            <Button onClick={handleBackToAccounts}>Back to Accounts</Button>
          }
        />
      </div>
    );
  }

  const accountIcon = getAccountIcon(account.type);
  const accountTypeName = getAccountTypeName(account.type);

  return (
    <div className="account-details">
      {/* Header */}
      <div className="account-details__header">
        <Button
          variant="secondary"
          onClick={handleBackToAccounts}
          className="account-details__back-button"
        >
          ← Back to Accounts
        </Button>

        <div className="account-details__actions">
          <Button variant="secondary" onClick={() => setIsEditModalOpen(true)}>
            ✏️ Edit Account
          </Button>
          <Button variant="danger" onClick={() => setIsDeleteDialogOpen(true)}>
            🗑️ Delete Account
          </Button>
        </div>
      </div>

      {/* Account Info Card */}
      <div className="account-details__info-card">
        <div className="account-details__info-header">
          <div className="account-details__icon-wrapper">
            <span className="account-details__icon">{accountIcon}</span>
          </div>
          <div className="account-details__title-section">
            <h1 className="account-details__name">{account.name}</h1>
            <p className="account-details__type">{accountTypeName}</p>
          </div>
        </div>

        <div className="account-details__balance-section">
          <p className="account-details__balance-label">Current Balance</p>
          <h2 className="account-details__balance">
            {formatCurrency(account.balance, account.currency)}
          </h2>
        </div>

        <div className="account-details__meta-grid">
          <div className="account-details__meta-item">
            <span className="account-details__meta-label">Account ID</span>
            <span className="account-details__meta-value">
              {formatAccountIdentifier(account.id)}
            </span>
          </div>
          <div className="account-details__meta-item">
            <span className="account-details__meta-label">Currency</span>
            <span className="account-details__meta-value">
              {account.currency}
            </span>
          </div>
          <div className="account-details__meta-item">
            <span className="account-details__meta-label">Status</span>
            <span
              className={`account-details__meta-value account-details__status ${
                account.is_active
                  ? 'account-details__status--active'
                  : 'account-details__status--inactive'
              }`}
            >
              {account.is_active ? '✓ Active' : '✗ Inactive'}
            </span>
          </div>
          <div className="account-details__meta-item">
            <span className="account-details__meta-label">Last Updated</span>
            <span className="account-details__meta-value">
              {formatRelativeTime(account.updated_at)}
            </span>
          </div>
        </div>
      </div>

      {/* Statistics Section */}
      <div className="account-details__stats">
        <h2 className="account-details__section-title">Account Statistics</h2>
        <div className="account-details__stats-grid">
          <StatCard
            label="Current Balance"
            value={formatCurrency(account.balance, account.currency)}
            icon="💰"
            variant="primary"
          />
          <StatCard
            label="Total Transactions"
            value={accountStats.totalTransactions.toString()}
            icon="📊"
          />
          <StatCard
            label="This Month"
            value={formatCurrency(
              accountStats.thisMonthTotal,
              account.currency
            )}
            icon="📅"
            variant={accountStats.thisMonthTotal >= 0 ? 'success' : 'danger'}
            description={`₹${accountStats.thisMonthIncome.toFixed(2)} in, ₹${accountStats.thisMonthExpenses.toFixed(2)} out`}
          />
        </div>
      </div>

      {/* Recent Transactions Section */}
      <div className="account-details__transactions">
        <div className="account-details__section-header">
          <h2 className="account-details__section-title">
            Recent Transactions
          </h2>
          <Button
            variant="secondary"
            onClick={() =>
              navigate({ to: '/transactions', search: { accountId } })
            }
          >
            View All Transactions
          </Button>
        </div>

        {accountTransactions.length === 0 ? (
          <div className="account-details__transactions-empty">
            <EmptyState
              icon="💳"
              title="No Transactions Yet"
              description="Transactions for this account will appear here once you start recording them."
              action={
                <Button onClick={() => navigate({ to: '/transactions' })}>
                  Add First Transaction
                </Button>
              }
            />
          </div>
        ) : (
          <div className="account-details__transactions-list">
            {accountTransactions.slice(0, 10).map((txn) => (
              <div key={txn.id} className="transaction-item">
                <div className="transaction-item__icon">
                  {txn.type === 'income'
                    ? '💰'
                    : txn.type === 'expense'
                      ? '💸'
                      : '🔄'}
                </div>
                <div className="transaction-item__details">
                  <div className="transaction-item__description">
                    {txn.description}
                  </div>
                  <div className="transaction-item__date">
                    {formatDate(txn.date)}
                  </div>
                </div>
                <div
                  className={`transaction-item__amount transaction-item__amount--${txn.type}`}
                >
                  {txn.type === 'income'
                    ? '+'
                    : txn.type === 'expense'
                      ? '-'
                      : ''}
                  {formatCurrency(txn.amount, account.currency)}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Edit Modal */}
      <AddAccountModal
        account={account}
        isOpen={isEditModalOpen}
        onClose={() => setIsEditModalOpen(false)}
        onSubmit={handleEditAccount}
      />

      {/* Delete Confirmation Dialog */}
      <ConfirmDialog
        isOpen={isDeleteDialogOpen}
        onClose={() => setIsDeleteDialogOpen(false)}
        onConfirm={handleDeleteAccount}
        title="Delete Account?"
        description={`Are you sure you want to delete "${account?.name}"? This action cannot be undone and all associated data will be permanently removed.`}
        confirmLabel="Delete Account"
        cancelLabel="Cancel"
        variant="danger"
      />
    </div>
  );
}
