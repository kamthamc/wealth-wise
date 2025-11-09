/**
 * Duplicate Review Modal
 * Shows import preview with duplicate detection and user actions
 */

import * as Dialog from '@radix-ui/react-dialog';
import { AlertCircle, CheckCircle, Info, X } from 'lucide-react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { DuplicateCheckResult } from '@/core/services';
import type { ParsedTransaction } from '@/features/accounts/utils/fileParser';
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
  const { t } = useTranslation();
  
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
          isDuplicate: false,
          matches: [],
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
      return t('pages.accounts.import.duplicateReview.status.new', 'NEW');
    }

    const confidence = item.duplicateResult.bestMatch?.confidence;
    const score = item.duplicateResult.bestMatch?.score || 0;

    if (confidence === 'exact') {
      return t(
        'pages.accounts.import.duplicateReview.status.exactDuplicate',
        'EXACT DUPLICATE'
      );
    } else if (confidence === 'high') {
      return t('pages.accounts.import.duplicateReview.status.duplicate', {
        score: score.toFixed(0),
        defaultValue: 'DUPLICATE ({{score}}% match)',
      });
    } else {
      return t('pages.accounts.import.duplicateReview.status.possibleDuplicate', {
        score: score.toFixed(0),
        defaultValue: 'POSSIBLE DUPLICATE ({{score}}% match)',
      });
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
                {t('pages.accounts.import.duplicateReview.title', {
                  accountName,
                  defaultValue: 'Review Import for {{accountName}}',
                })}
              </Dialog.Title>
              <Dialog.Description className="duplicate-review__subtitle">
                {t('pages.accounts.import.duplicateReview.subtitle', {
                  count: transactions.length,
                  defaultValue:
                    '{{count}} transactions found - Review duplicates before importing',
                })}
              </Dialog.Description>
            </div>
            <Dialog.Close asChild>
              <button
                type="button"
                className="duplicate-review__close"
                aria-label={t(
                  'pages.accounts.import.duplicateReview.closeLabel',
                  'Close'
                )}
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
                <span>
                  {t('pages.accounts.import.duplicateReview.summary.new', {
                    count: newCount,
                    defaultValue: '{{count}} New',
                  })}
                </span>
              </div>
              <div className="duplicate-review__stat duplicate-review__stat--duplicate">
                <AlertCircle size={18} />
                <span>
                  {t('pages.accounts.import.duplicateReview.summary.exactDuplicates', {
                    count: exactDuplicates,
                    defaultValue: '{{count}} Exact Duplicates',
                  })}
                </span>
              </div>
              <div className="duplicate-review__stat duplicate-review__stat--possible">
                <Info size={18} />
                <span>
                  {t('pages.accounts.import.duplicateReview.summary.possibleDuplicates', {
                    count: possibleDuplicates,
                    defaultValue: '{{count}} Possible Duplicates',
                  })}
                </span>
              </div>
            </div>

            {/* Action Summary */}
            <div className="duplicate-review__actions-summary">
              <p>
                <strong>
                  {t(
                    'pages.accounts.import.duplicateReview.actionsSummary.title',
                    'Selected Actions:'
                  )}
                </strong>{' '}
                {t('pages.accounts.import.duplicateReview.actionsSummary.description', {
                  importCount,
                  skipCount,
                  updateCount,
                  defaultValue:
                    '{{importCount}} to import, {{skipCount}} to skip, {{updateCount}} to update',
                })}
              </p>
              <div className="duplicate-review__bulk-actions">
                <button
                  type="button"
                  className="duplicate-review__bulk-btn"
                  onClick={handleBulkImportNew}
                  disabled={isImporting}
                >
                  {t(
                    'pages.accounts.import.duplicateReview.bulkActions.importNew',
                    'Import All New'
                  )}
                </button>
                <button
                  type="button"
                  className="duplicate-review__bulk-btn"
                  onClick={handleBulkSkipDuplicates}
                  disabled={isImporting}
                >
                  {t(
                    'pages.accounts.import.duplicateReview.bulkActions.skipDuplicates',
                    'Skip All Duplicates'
                  )}
                </button>
              </div>
            </div>

            {/* Transaction List */}
            <div className="duplicate-review__list">
              {reviewItems.map((item, index) => {
                // Generate stable key from transaction data
                const txnDate = item.transaction.date;
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
                          {t(
                            'pages.accounts.import.duplicateReview.labels.date',
                            'Date:'
                          )}
                        </span>
                        <span>
                          {item.transaction.date}
                        </span>
                      </div>
                      <div className="duplicate-review__item-row">
                        <span className="duplicate-review__item-label">
                          {t(
                            'pages.accounts.import.duplicateReview.labels.description',
                            'Description:'
                          )}
                        </span>
                        <span>{item.transaction.description}</span>
                      </div>
                      <div className="duplicate-review__item-row">
                        <span className="duplicate-review__item-label">
                          {t(
                            'pages.accounts.import.duplicateReview.labels.amount',
                            'Amount:'
                          )}
                        </span>
                        <span
                          className={`duplicate-review__amount duplicate-review__amount--${item.transaction.type}`}
                        >
                          ₹{item.transaction.amount.toLocaleString()}
                        </span>
                      </div>
                      <div className="duplicate-review__item-row">
                        <span className="duplicate-review__item-label">
                          {t(
                            'pages.accounts.import.duplicateReview.labels.type',
                            'Type:'
                          )}
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
                            {t(
                              'pages.accounts.import.duplicateReview.labels.matchReasons',
                              'Match reasons:'
                            )}
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
                                {t(
                                  'pages.accounts.import.duplicateReview.labels.existingTransaction',
                                  'Existing transaction:'
                                )}
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
                        {t(
                          'pages.accounts.import.duplicateReview.labels.action',
                          'Action:'
                        )}
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
                        aria-label={t(
                          'pages.accounts.import.duplicateReview.labels.selectAction',
                          'Select action for this transaction'
                        )}
                      >
                        {item.duplicateResult.isNewTransaction ? (
                          <>
                            <option value="import">
                              {t(
                                'pages.accounts.import.duplicateReview.actions.importNew',
                                'Import as new'
                              )}
                            </option>
                            <option value="skip">
                              {t(
                                'pages.accounts.import.duplicateReview.actions.skip',
                                "Skip (don't import)"
                              )}
                            </option>
                          </>
                        ) : (
                          <>
                            <option value="skip">
                              {t(
                                'pages.accounts.import.duplicateReview.actions.skip',
                                "Skip (don't import)"
                              )}
                            </option>
                            <option value="update">
                              {t(
                                'pages.accounts.import.duplicateReview.actions.update',
                                'Update existing transaction'
                              )}
                            </option>
                            <option value="force">
                              {t(
                                'pages.accounts.import.duplicateReview.actions.force',
                                'Force import as new anyway'
                              )}
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
              {t('pages.accounts.import.duplicateReview.footer.cancel', 'Cancel')}
            </Button>
            <Button
              variant="primary"
              onClick={handleImport}
              disabled={isImporting || importCount + updateCount === 0}
              isLoading={isImporting}
            >
              {t('pages.accounts.import.duplicateReview.footer.import', {
                count: importCount + updateCount,
                defaultValue: 'Import {{count}} Transactions',
              })}
            </Button>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
