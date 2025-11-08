/**
 * Transaction Linking Modal Component
 * Allows users to link transfer transactions between accounts
 */

import * as Dialog from '@radix-ui/react-dialog';
import { ArrowRight, CheckCircle, Link2, X } from 'lucide-react';
import { useMemo, useState } from 'react';
import type { Transaction } from '@/core/types';
import { useAccountStore, useTransactionStore } from '@/core/stores';
import { Button } from '@/shared/components';
import { formatCurrency, formatDate } from '@/shared/utils';
import './TransactionLinkingModal.css';

interface TransactionLinkingModalProps {
  /** Whether the dialog is open */
  isOpen: boolean;
  /** Callback when the dialog should close */
  onClose: () => void;
  /** The source transaction to link from */
  sourceTransaction: Transaction;
}

export function TransactionLinkingModal({
  isOpen,
  onClose,
  sourceTransaction,
}: TransactionLinkingModalProps) {
  const { transactions, linkTransactions } = useTransactionStore();
  const { accounts } = useAccountStore();
  const [selectedTransactionId, setSelectedTransactionId] = useState<
    string | null
  >(null);
  const [isLinking, setIsLinking] = useState(false);

  // Find potential matching transactions
  const potentialMatches = useMemo(() => {
    // Only show transfer transactions from different accounts
    return transactions
      .filter((txn) => {
        // Don't show the source transaction itself
        if (txn.id === sourceTransaction.id) return false;

        // Only show transfers
        if (txn.type !== 'transfer') return false;

        // Don't show already linked transactions
        if (txn.linked_transaction_id) return false;

        // Must be from a different account
        if (txn.account_id === sourceTransaction.account_id) return false;

        // Ideally within 1 day of source transaction
        const sourceDateMs = new Date(sourceTransaction.date).getTime();
        const txnDateMs = new Date(txn.date).getTime();
        const daysDiff =
          Math.abs(sourceDateMs - txnDateMs) / (1000 * 60 * 60 * 24);

        // Show transactions within 7 days
        return daysDiff <= 7;
      })
      .sort((a, b) => {
        // Sort by date proximity to source transaction
        const sourceDateMs = new Date(sourceTransaction.date).getTime();
        const aDiff = Math.abs(new Date(a.date).getTime() - sourceDateMs);
        const bDiff = Math.abs(new Date(b.date).getTime() - sourceDateMs);
        return aDiff - bDiff;
      });
  }, [transactions, sourceTransaction]);

  const getAccountName = (accountId: string) => {
    return accounts.find((a) => a.id === accountId)?.name || 'Unknown Account';
  };

  const handleLink = async () => {
    if (!selectedTransactionId) return;

    setIsLinking(true);
    try {
      await linkTransactions(sourceTransaction.id, selectedTransactionId);
      onClose();
    } catch (error) {
      console.error('Failed to link transactions:', error);
      alert('Failed to link transactions. Please try again.');
    } finally {
      setIsLinking(false);
    }
  };

  return (
    <Dialog.Root open={isOpen} onOpenChange={onClose}>
      <Dialog.Portal>
        <Dialog.Overlay className="transaction-linking-modal__overlay" />
        <Dialog.Content className="transaction-linking-modal__content">
          <div className="transaction-linking-modal__header">
            <Dialog.Title className="transaction-linking-modal__title">
              <Link2 size={24} />
              Link Transfer Transaction
            </Dialog.Title>
            <Dialog.Close asChild>
              <button
                className="transaction-linking-modal__close"
                aria-label="Close"
              >
                <X size={20} />
              </button>
            </Dialog.Close>
          </div>

          <div className="transaction-linking-modal__body">
            {/* Source Transaction */}
            <div className="transaction-link-preview">
              <h3 className="transaction-link-preview__title">
                Source Transaction
              </h3>
              <div className="transaction-link-card">
                <div className="transaction-link-card__header">
                  <span className="transaction-link-card__account">
                    {getAccountName(sourceTransaction.account_id)}
                  </span>
                  <span className="transaction-link-card__date">
                    {formatDate(sourceTransaction.date)}
                  </span>
                </div>
                <div className="transaction-link-card__body">
                  <p className="transaction-link-card__description">
                    {sourceTransaction.description || 'Transfer'}
                  </p>
                  <p className="transaction-link-card__amount">
                    {formatCurrency(sourceTransaction.amount)}
                  </p>
                </div>
              </div>
            </div>

            <div className="transaction-link-arrow">
              <ArrowRight size={24} />
            </div>

            {/* Potential Matches */}
            <div className="transaction-link-matches">
              <h3 className="transaction-link-matches__title">
                Select Matching Transaction
              </h3>

              {potentialMatches.length === 0 ? (
                <div className="transaction-link-matches__empty">
                  <p>No matching transfer transactions found.</p>
                  <p className="text-secondary">
                    Looking for transfers within 7 days from a different
                    account.
                  </p>
                </div>
              ) : (
                <div className="transaction-link-matches__list">
                  {potentialMatches.map((txn) => (
                    <button
                      key={txn.id}
                      type="button"
                      className={`transaction-link-card transaction-link-card--selectable ${
                        selectedTransactionId === txn.id
                          ? 'transaction-link-card--selected'
                          : ''
                      }`}
                      onClick={() => setSelectedTransactionId(txn.id)}
                    >
                      {selectedTransactionId === txn.id && (
                        <div className="transaction-link-card__check">
                          <CheckCircle size={20} />
                        </div>
                      )}
                      <div className="transaction-link-card__header">
                        <span className="transaction-link-card__account">
                          {getAccountName(txn.account_id)}
                        </span>
                        <span className="transaction-link-card__date">
                          {formatDate(txn.date)}
                        </span>
                      </div>
                      <div className="transaction-link-card__body">
                        <p className="transaction-link-card__description">
                          {txn.description || 'Transfer'}
                        </p>
                        <p className="transaction-link-card__amount">
                          {formatCurrency(txn.amount)}
                        </p>
                      </div>
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>

          <div className="transaction-linking-modal__footer">
            <Button variant="secondary" onClick={onClose}>
              Cancel
            </Button>
            <Button
              onClick={handleLink}
              disabled={!selectedTransactionId || isLinking}
            >
              <Link2 size={16} />
              {isLinking ? 'Linking...' : 'Link Transactions'}
            </Button>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
