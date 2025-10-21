/**
 * Account Details Component
 * Displays detailed information about a single account
 */

import { useNavigate } from '@tanstack/react-router';
import { useEffect, useMemo, useState } from 'react';
import type {
  Account,
  CreditCardDetails,
  BrokerageDetails,
  DepositDetails,
} from '@/core/db/types';
import { 
  brokerageDetailsRepository,
  creditCardDetailsRepository,
  depositDetailsRepository
} from '@/core/db/repositories';
import { useAccountStore, useTransactionStore } from '@/core/stores';
import { AddTransactionModal } from '@/features/transactions';
import {
  Button,
  ConfirmDialog,
  EmptyState,
  Spinner,
  StatCard,
  useToast,
} from '@/shared/components';
import {
  calculateAccountBalance,
  formatCurrency,
  formatDate,
  formatRelativeTime,
} from '@/shared/utils';
import type { AccountFormData } from '../types';
import {
  formatAccountIdentifier,
  getAccountIcon,
  getAccountTypeName,
  isDepositAccount,
} from '../utils/accountHelpers';
import { AccountActions } from './AccountActions';
import { AccountCharts } from './AccountCharts';
import { AddAccountModal } from './AddAccountModal';
import { ImportTransactionsModal } from './ImportTransactionsModal';
import { AccountViewFactory, hasSpecializedView } from './views';
import './AccountDetails.css';

export interface AccountDetailsProps {
  accountId: string;
}

export function AccountDetails({ accountId }: AccountDetailsProps) {
  console.log('[AccountDetails] Component rendering, accountId:', accountId);

  const navigate = useNavigate();
  const { accounts, isLoading, fetchAccounts, updateAccount, deleteAccount } =
    useAccountStore();
  const { transactions, fetchTransactions } = useTransactionStore();
  const toast = useToast();

  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [isCloseDialogOpen, setIsCloseDialogOpen] = useState(false);
  const [isAddTransactionModalOpen, setIsAddTransactionModalOpen] =
    useState(false);
  const [isImportModalOpen, setIsImportModalOpen] = useState(false);
  const [account, setAccount] = useState<Account | null>(null);

  // State for type-specific details
  const [creditCardDetails, setCreditCardDetails] = useState<CreditCardDetails | null>(null);
  const [depositDetails, setDepositDetails] = useState<DepositDetails | null>(null);
  const [brokerageDetails, setBrokerageDetails] = useState<BrokerageDetails | null>(null);

  // Fetch transactions on mount
  useEffect(() => {
    console.log('[AccountDetails] Fetching transactions...');
    fetchTransactions();
  }, [fetchTransactions]);

  // Find the account from the store
  useEffect(() => {
    console.log('[AccountDetails] Looking for account:', accountId);
    console.log('[AccountDetails] Available accounts:', accounts.length);
    console.log('[AccountDetails] Is loading:', isLoading);

    const foundAccount = accounts.find((acc) => acc.id === accountId);
    if (foundAccount) {
      console.log('[AccountDetails] Found account:', foundAccount.name);
      setAccount(foundAccount);
    } else if (!isLoading) {
      console.log('[AccountDetails] Account not found, fetching...');
      // Account not found, might need to fetch
      fetchAccounts();
    } else {
      console.log('[AccountDetails] Still loading...');
    }
  }, [accountId, accounts, isLoading, fetchAccounts]);

  // Fetch type-specific details when account is loaded
  useEffect(() => {
    if (!account) return;

    const fetchTypeSpecificDetails = async () => {
      try {
        // Fetch credit card details
        if (account.type === 'credit_card') {
          const details = await creditCardDetailsRepository.getByAccountId(account.id);
          setCreditCardDetails(details);
        }
        
        // Fetch deposit details
        else if (isDepositAccount(account.type)) {
          const details = await depositDetailsRepository.findByAccountId(account.id);
          setDepositDetails(details);
        }
        
        // Fetch brokerage details
        else if (account.type === 'brokerage') {
          const details = await brokerageDetailsRepository.getByAccountId(account.id);
          setBrokerageDetails(details);
        }
      } catch (error) {
        console.error('[AccountDetails] Error fetching type-specific details:', error);
      }
    };

    fetchTypeSpecificDetails();
  }, [account]);

  // Filter transactions for this account
  const accountTransactions = useMemo(() => {
    return transactions
      .filter((txn) => txn.account_id === accountId)
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  }, [transactions, accountId]);

  // Calculate current balance based on initial balance + transactions
  const currentBalance = useMemo(() => {
    if (!account) return 0;
    return calculateAccountBalance(account.balance, accountTransactions);
  }, [account, accountTransactions]);

  // Calculate account statistics
  const accountStats = useMemo(() => {
    const now = new Date();
    const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const thisMonthTransactions = accountTransactions.filter(
      (txn) => new Date(txn.date) >= firstDayOfMonth
    );

    const income = thisMonthTransactions
      .filter((txn) => txn.type === 'income')
      .reduce((sum, txn) => sum + (Number(txn.amount) || 0), 0);

    const expenses = thisMonthTransactions
      .filter((txn) => txn.type === 'expense')
      .reduce((sum, txn) => sum + (Number(txn.amount) || 0), 0);

    return {
      totalTransactions: accountTransactions.length,
      thisMonthTotal: Number(income - expenses) || 0,
      thisMonthIncome: Number(income) || 0,
      thisMonthExpenses: Number(expenses) || 0,
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

  const handleCloseAccount = async () => {
    if (account) {
      await updateAccount({
        name: account.name,
        type: account.type,
        balance: account.balance,
        currency: account.currency,
        id: account.id,
        is_active: false,
      });
      await fetchAccounts();
      setIsCloseDialogOpen(false);
    }
  };

  const handleReopenAccount = async () => {
    if (account) {
      await updateAccount({
        name: account.name,
        type: account.type,
        balance: account.balance,
        currency: account.currency,
        id: account.id,
        is_active: true,
      });
      await fetchAccounts();
    }
  };

  const handleAddTransaction = () => {
    setIsAddTransactionModalOpen(true);
  };

  const handleTransferMoney = () => {
    // Will be implemented with transfer wizard
    console.log('Transfer money clicked');
  };

  const handleDownloadStatement = () => {
    // Generate PDF statement
    if (!account) return;

    const fileName = `${account.name.replace(/\s+/g, '_')}_statement_${new Date().toISOString().split('T')[0]}.txt`;
    const statementText = generateStatement(account, accountTransactions);

    const blob = new Blob([statementText], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = fileName;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast.success('Statement downloaded', `Downloaded ${fileName}`);
  };

  const handleImportTransactions = () => {
    setIsImportModalOpen(true);
  };

  const handleExportTransactions = () => {
    if (!account) return;

    const fileName = `${account.name.replace(/\s+/g, '_')}_transactions_${new Date().toISOString().split('T')[0]}.csv`;
    const csv = generateCSV(accountTransactions);

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = fileName;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    toast.success(
      'Transactions exported',
      `Exported ${accountTransactions.length} transactions`
    );
  };

  // Helper function to generate statement
  const generateStatement = (
    acc: Account,
    txns: typeof accountTransactions
  ) => {
    let statement = `ACCOUNT STATEMENT\n`;
    statement += `================\n\n`;
    statement += `Account Name: ${acc.name}\n`;
    statement += `Account Type: ${getAccountTypeName(acc.type)}\n`;
    statement += `Account Number: ${formatAccountIdentifier(acc.id)}\n`;
    statement += `Current Balance: ${formatCurrency(acc.balance, acc.currency)}\n`;
    statement += `Statement Date: ${new Date().toLocaleDateString()}\n\n`;
    statement += `TRANSACTIONS\n`;
    statement += `============\n\n`;

    if (txns.length === 0) {
      statement += `No transactions found.\n`;
    } else {
      statement += `Date       | Description                | Type     | Amount\n`;
      statement += `-----------+---------------------------+----------+-----------\n`;

      txns.forEach((txn) => {
        const date = formatDate(txn.date).padEnd(10);
        const desc = (txn.description || '').substring(0, 25).padEnd(25);
        const type = txn.type.padEnd(8);
        const amount = formatCurrency(txn.amount, acc.currency);
        statement += `${date} | ${desc} | ${type} | ${amount}\n`;
      });
    }

    return statement;
  };

  // Helper function to generate CSV
  const generateCSV = (txns: typeof accountTransactions) => {
    let csv = 'date,description,amount,type,category\n';

    txns.forEach((txn) => {
      const date = txn.date.toISOString().split('T')[0];
      const description = `"${(txn.description || '').replace(/"/g, '""')}"`;
      const amount = txn.amount;
      const type = txn.type;
      const category = txn.category || '';

      csv += `${date},${description},${amount},${type},${category}\n`;
    });

    return csv;
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
  const isClosed = !account.is_active;

  return (
    <div className="account-details">
      {/* Header with back button and quick actions */}
      <div className="account-details__header">
        <div className="account-details__header-left">
          <Button
            variant="secondary"
            onClick={handleBackToAccounts}
            className="account-details__back-button"
          >
            ← Back
          </Button>
          <div className="account-details__header-info">
            <div className="account-details__header-icon">{accountIcon}</div>
            <div>
              <h1 className="account-details__header-title">{account.name}</h1>
              <p className="account-details__header-subtitle">
                {accountTypeName}
                {isClosed && (
                  <span className="account-details__closed-badge">
                    {' '}
                    • Closed
                  </span>
                )}
              </p>
            </div>
          </div>
        </div>

        <div className="account-details__header-actions">
          <Button variant="secondary" onClick={() => setIsEditModalOpen(true)}>
            Edit
          </Button>
          <Button variant="danger" onClick={() => setIsDeleteDialogOpen(true)}>
            Delete
          </Button>
        </div>
      </div>

      <div className="account-details__container">
        <div className="account-details__content">
          {/* Balance Overview - Prominent display */}
          <div className="account-details__balance-hero">
            <div className="account-details__balance-card">
              <p className="account-details__balance-label">Current Balance</p>
              <h2 className="account-details__balance-value">
                {formatCurrency(currentBalance, account.currency)}
              </h2>
              <div className="account-details__balance-meta">
                <span>
                  Initial: {formatCurrency(account.balance, account.currency)}
                </span>
                <span>•</span>
                <span>ID: {formatAccountIdentifier(account.id)}</span>
                <span>•</span>
                <span>
                  Last updated {formatRelativeTime(account.updated_at)}
                </span>
              </div>
            </div>
          </div>

          {/* Quick Actions */}
          <AccountActions
            accountId={account.id}
            accountName={account.name}
            isClosed={isClosed}
            onAddTransaction={handleAddTransaction}
            onTransferMoney={handleTransferMoney}
            onDownloadStatement={handleDownloadStatement}
            onImportTransactions={handleImportTransactions}
            onExportTransactions={handleExportTransactions}
            onCloseAccount={() => setIsCloseDialogOpen(true)}
            onReopenAccount={handleReopenAccount}
          />

          {/* Type-specific account views (Credit Card, Deposit, Brokerage) */}
          {hasSpecializedView(account.type) && (
            <AccountViewFactory
              account={account}
              creditCardDetails={creditCardDetails || undefined}
              depositDetails={depositDetails || undefined}
              brokerageDetails={brokerageDetails || undefined}
            />
          )}

          {/* Charts and Visualizations - Show for accounts without specialized views */}
          {!hasSpecializedView(account.type) && (
            <AccountCharts
              transactions={accountTransactions}
              currentBalance={currentBalance}
              currency={account.currency}
            />
          )}

          {/* Account Statistics */}
          {!hasSpecializedView(account.type) && (
            <div className="account-details__stats">
              <h2 className="account-details__section-title">
                Account Statistics
              </h2>
              <div className="account-details__stats-grid">
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
                  variant={
                    accountStats.thisMonthTotal >= 0 ? 'success' : 'danger'
                  }
                  description={`₹${(accountStats.thisMonthIncome || 0).toFixed(2)} in, ₹${(accountStats.thisMonthExpenses || 0).toFixed(2)} out`}
                />
              </div>
            </div>
          )}

          {/* Recent Transactions Section */}
          {!hasSpecializedView(account.type) && (
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
                  View All
                </Button>
              </div>

              {accountTransactions.length === 0 ? (
                <div className="account-details__transactions-empty">
                  <EmptyState
                    icon="💳"
                    title="No Transactions Yet"
                    description="Start tracking your finances by adding your first transaction."
                    action={
                      <Button onClick={handleAddTransaction}>
                        Add Transaction
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
          )}
        </div>
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

      {/* Close Account Confirmation Dialog */}
      <ConfirmDialog
        isOpen={isCloseDialogOpen}
        onClose={() => setIsCloseDialogOpen(false)}
        onConfirm={handleCloseAccount}
        title="Close Account?"
        description={`Are you sure you want to close "${account?.name}"? You can reopen it later if needed.`}
        confirmLabel="Close Account"
        cancelLabel="Cancel"
        variant="danger"
      />

      {/* Add Transaction Modal */}
      <AddTransactionModal
        isOpen={isAddTransactionModalOpen}
        onClose={() => setIsAddTransactionModalOpen(false)}
        defaultAccountId={accountId}
      />

      {/* Import Transactions Modal */}
      <ImportTransactionsModal
        isOpen={isImportModalOpen}
        onClose={() => setIsImportModalOpen(false)}
        accountId={accountId}
        accountName={account?.name || ''}
        onImportSuccess={() => {
          // Refresh transactions after successful import
          fetchTransactions();
          fetchAccounts(); // Also refresh accounts to update balances
        }}
      />
    </div>
  );
}
