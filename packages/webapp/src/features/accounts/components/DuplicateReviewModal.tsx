/**
 * Duplicate Review Modal
 * Shows import preview with duplicate detection and user actions
 */

import * as Dialog from '@radix-ui/react-dialog';
import { AlertCircle, CheckCircle, Info, X } from 'lucide-react';
import { useState } from 'react';
import type { DuplicateCheckResult, ParsedTransaction } from '@/core/services';
import { Button } from '@/shared/components';
import './DuplicateReviewModal.css';

export type UserAction = 'skip' | 'import' | 'update' | 'force';

export interface TransactionReviewItem {
  transaction: ParsedTransaction;
  duplicateResult: DuplicateCheckResult;
  action: UserAction;
}

export interface DuplicateReviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  onImport: (items: TransactionReviewItem[]) => Promise<void>;
  transactions: ParsedTransaction[];
  duplicateResults: DuplicateCheckResult[];
  accountName: string;
}

export function DuplicateReviewModal({
  isOpen,
  onClose,
  onImport,
  transactions,
  duplicateResults,
  accountName,
}: DuplicateReviewModalProps) {
  // Initialize review items with default actions
  const [reviewItems, setReviewItems] = useState<TransactionReviewItem[]>(() =>
    transactions.map((txn, index) => {
      const result = duplicateResults[index];
      const defaultAction: UserAction = result?.isNewTransaction
        ? 'import'
        : 'skip';

      return {
        transaction: txn,
        duplicateResult: result || {
          isNewTransaction: true,
          duplicateMatches: [],
        },
        action: defaultAction,
      };
    })
  );

  const [isImporting, setIsImporting] = useState(false);

  // Calculate summary statistics
  const newCount = reviewItems.filter(
    (item) => item.duplicateResult.isNewTransaction
  ).length;
  const exactDuplicates = reviewItems.filter(
    (item) =>
      !item.duplicateResult.isNewTransaction &&
      item.duplicateResult.bestMatch?.confidence === 'exact'
  ).length;
  const possibleDuplicates = reviewItems.filter(
    (item) =>
      !item.duplicateResult.isNewTransaction &&
      item.duplicateResult.bestMatch?.confidence !== 'exact'
  ).length;

  // Count actions
  const importCount = reviewItems.filter(
    (item) => item.action === 'import' || item.action === 'force'
  ).length;
  const skipCount = reviewItems.filter((item) => item.action === 'skip').length;
  const updateCount = reviewItems.filter(
    (item) => item.action === 'update'
  ).length;

  const handleActionChange = (index: number, action: UserAction) => {
    setReviewItems((prev) =>
      prev.map((item, i) => (i === index ? { ...item, action } : item))
    );
  };

  const handleBulkSkipDuplicates = () => {
    setReviewItems((prev) =>
      prev.map((item) =>
        !item.duplicateResult.isNewTransaction
          ? { ...item, action: 'skip' }
          : item
      )
    );
  };

  const handleBulkImportNew = () => {
    setReviewItems((prev) =>
      prev.map((item) =>
        item.duplicateResult.isNewTransaction
          ? { ...item, action: 'import' }
          : item
      )
    );
  };

  const handleImport = async () => {
    setIsImporting(true);
    try {
      await onImport(reviewItems);
    } finally {
      setIsImporting(false);
    }
  };

  const getStatusIcon = (item: TransactionReviewItem) => {
    if (item.duplicateResult.isNewTransaction) {
      return <CheckCircle className="status-icon status-icon--new" size={20} />;
    }

    const confidence = item.duplicateResult.bestMatch?.confidence;
    if (confidence === 'exact' || confidence === 'high') {
      return (
        <AlertCircle className="status-icon status-icon--duplicate" size={20} />
      );
    }

    return <Info className="status-icon status-icon--possible" size={20} />;
  };

  const getStatusLabel = (item: TransactionReviewItem) => {
    if (item.duplicateResult.isNewTransaction) {
      return 'NEW';
    }

    const confidence = item.duplicateResult.bestMatch?.confidence;
    const score = item.duplicateResult.bestMatch?.score || 0;

    if (confidence === 'exact') {
      return 'EXACT DUPLICATE';
    } else if (confidence === 'high') {
      return `DUPLICATE (${score.toFixed(0)}% match)`;
    } else {
      return `POSSIBLE DUPLICATE (${score.toFixed(0)}% match)`;
    }
  };

  const getStatusClass = (item: TransactionReviewItem) => {
    if (item.duplicateResult.isNewTransaction) {
      return 'duplicate-review__item--new';
    }

    const confidence = item.duplicateResult.bestMatch?.confidence;
    if (confidence === 'exact' || confidence === 'high') {
      return 'duplicate-review__item--duplicate';
    }

    return 'duplicate-review__item--possible';
  };

  return (
    <Dialog.Root open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <Dialog.Portal>
        <Dialog.Overlay className="modal-overlay" />
        <Dialog.Content
          className="duplicate-review__content"
          aria-describedby={undefined}
        >
          <div className="duplicate-review__header">
            <div>
              <Dialog.Title className="duplicate-review__title">
                Review Import for {accountName}
              </Dialog.Title>
              <Dialog.Description className="duplicate-review__subtitle">
                {transactions.length} transactions found - Review duplicates
                before importing
              </Dialog.Description>
            </div>
            <Dialog.Close asChild>
              <button
                type="button"
                className="duplicate-review__close"
                aria-label="Close"
              >
                <X size={20} />
              </button>
            </Dialog.Close>
          </div>

          <div className="duplicate-review__body">
            {/* Summary Statistics */}
            <div className="duplicate-review__summary">
              <div className="duplicate-review__stat duplicate-review__stat--new">
                <CheckCircle size={18} />
                <span>{newCount} New</span>
              </div>
              <div className="duplicate-review__stat duplicate-review__stat--duplicate">
                <AlertCircle size={18} />
                <span>{exactDuplicates} Exact Duplicates</span>
              </div>
              <div className="duplicate-review__stat duplicate-review__stat--possible">
                <Info size={18} />
                <span>{possibleDuplicates} Possible Duplicates</span>
              </div>
            </div>

            {/* Action Summary */}
            <div className="duplicate-review__actions-summary">
              <p>
                <strong>Selected Actions:</strong> {importCount} to import,{' '}
                {skipCount} to skip, {updateCount} to update
              </p>
              <div className="duplicate-review__bulk-actions">
                <button
                  type="button"
                  className="duplicate-review__bulk-btn"
                  onClick={handleBulkImportNew}
                  disabled={isImporting}
                >
                  Import All New
                </button>
                <button
                  type="button"
                  className="duplicate-review__bulk-btn"
                  onClick={handleBulkSkipDuplicates}
                  disabled={isImporting}
                >
                  Skip All Duplicates
                </button>
              </div>
            </div>

            {/* Transaction List */}
            <div className="duplicate-review__list">
              {reviewItems.map((item, index) => {
                // Generate stable key from transaction data
                const txnDate =
                  typeof item.transaction.date === 'string'
                    ? item.transaction.date
                    : item.transaction.date.toISOString();
                const key = `${txnDate}-${item.transaction.amount}-${index}`;

                return (
                  <div
                    key={key}
                    className={`duplicate-review__item ${getStatusClass(item)}`}
                  >
                    {/* Status Header */}
                    <div className="duplicate-review__item-header">
                      {getStatusIcon(item)}
                      <span className="duplicate-review__item-status">
                        {getStatusLabel(item)}
                      </span>
                    </div>

                    {/* Transaction Details */}
                    <div className="duplicate-review__item-details">
                      <div className="duplicate-review__item-row">
                        <span className="duplicate-review__item-label">
                          Date:
                        </span>
                        <span>
                          {typeof item.transaction.date === 'string'
                            ? item.transaction.date
                            : item.transaction.date.toLocaleDateString()}
                        </span>
                      </div>
                      <div className="duplicate-review__item-row">
                        <span className="duplicate-review__item-label">
                          Description:
                        </span>
                        <span>{item.transaction.description}</span>
                      </div>
                      <div className="duplicate-review__item-row">
                        <span className="duplicate-review__item-label">
                          Amount:
                        </span>
                        <span
                          className={`duplicate-review__amount duplicate-review__amount--${item.transaction.type}`}
                        >
                          ₹{item.transaction.amount.toLocaleString()}
                        </span>
                      </div>
                      <div className="duplicate-review__item-row">
                        <span className="duplicate-review__item-label">
                          Type:
                        </span>
                        <span
                          className={`duplicate-review__type-badge duplicate-review__type-badge--${item.transaction.type}`}
                        >
                          {item.transaction.type}
                        </span>
                      </div>
                    </div>

                    {/* Match Reasons */}
                    {!item.duplicateResult.isNewTransaction &&
                      item.duplicateResult.bestMatch && (
                        <div className="duplicate-review__match-info">
                          <p className="duplicate-review__match-title">
                            Match reasons:
                          </p>
                          <ul className="duplicate-review__match-reasons">
                            {item.duplicateResult.bestMatch.matchReasons.map(
                              (reason) => (
                                <li key={reason}>{reason}</li>
                              )
                            )}
                          </ul>
                          {item.duplicateResult.bestMatch
                            .existingTransaction && (
                            <div className="duplicate-review__existing">
                              <p className="duplicate-review__existing-title">
                                Existing transaction:
                              </p>
                              <p className="duplicate-review__existing-text">
                                {new Date(
                                  item.duplicateResult.bestMatch
                                    .existingTransaction.date
                                ).toLocaleDateString()}{' '}
                                |{' '}
                                {
                                  item.duplicateResult.bestMatch
                                    .existingTransaction.description
                                }{' '}
                                | ₹
                                {item.duplicateResult.bestMatch.existingTransaction.amount.toLocaleString()}
                              </p>
                            </div>
                          )}
                        </div>
                      )}

                    {/* Action Selector */}
                    <div className="duplicate-review__item-actions">
                      <span className="duplicate-review__action-label">
                        Action:
                      </span>
                      <select
                        className="duplicate-review__action-select"
                        value={item.action}
                        onChange={(e) =>
                          handleActionChange(
                            index,
                            e.target.value as UserAction
                          )
                        }
                        disabled={isImporting}
                        aria-label="Select action for this transaction"
                      >
                        {item.duplicateResult.isNewTransaction ? (
                          <>
                            <option value="import">Import as new</option>
                            <option value="skip">Skip (don't import)</option>
                          </>
                        ) : (
                          <>
                            <option value="skip">Skip (don't import)</option>
                            <option value="update">
                              Update existing transaction
                            </option>
                            <option value="force">
                              Force import as new anyway
                            </option>
                          </>
                        )}
                      </select>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="duplicate-review__footer">
            <Button
              variant="secondary"
              onClick={onClose}
              disabled={isImporting}
            >
              Cancel
            </Button>
            <Button
              variant="primary"
              onClick={handleImport}
              disabled={isImporting || importCount + updateCount === 0}
              isLoading={isImporting}
            >
              Import {importCount + updateCount} Transactions
            </Button>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
