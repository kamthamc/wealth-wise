/**
 * Add Transaction Form Component
 * Modal form for creating and editing transactions
 */

import { useId, useState, useEffect } from 'react';
import * as Dialog from '@radix-ui/react-dialog';
import { useTransactionStore } from '@/core/stores';
import { Button, CurrencyInput, Input } from '@/shared/components';
import type { TransactionFormData, TransactionType } from '../types';
import {
  getTransactionIcon,
  getTransactionTypeName,
  validateTransactionForm,
} from '../utils/transactionHelpers';
import './AddTransactionForm.css';

interface AddTransactionFormProps {
  /** Whether the dialog is open */
  isOpen: boolean;
  /** Callback when the dialog should close */
  onClose: () => void;
  /** Transaction to edit (undefined for new transaction) */
  transactionId?: string;
  /** Pre-filled account ID */
  defaultAccountId?: string;
}

const TRANSACTION_TYPES: TransactionType[] = ['income', 'expense', 'transfer'];

export function AddTransactionForm({
  isOpen,
  onClose,
  transactionId,
  defaultAccountId,
}: AddTransactionFormProps) {
  const formId = useId();
  const { transactions, createTransaction, updateTransaction } =
    useTransactionStore();

  // Form state
  const [formData, setFormData] = useState<TransactionFormData>({
    amount: 0,
    type: 'expense',
    account_id: defaultAccountId || '',
    category_id: undefined,
    description: '',
    date: new Date().toISOString().split('T')[0] || '',
    tags: [],
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Load transaction data if editing
  useEffect(() => {
    if (transactionId) {
      const transaction = transactions.find((t) => t.id === transactionId);
      if (transaction) {
        setFormData({
          amount: transaction.amount,
          type: transaction.type,
          account_id: transaction.account_id,
          category_id: transaction.category,
          description: transaction.description || '',
          date: transaction.date.toISOString().split('T')[0] || '',
          tags: transaction.tags || [],
        });
      }
    } else if (defaultAccountId) {
      setFormData((prev) => ({ ...prev, account_id: defaultAccountId }));
    }
  }, [transactionId, transactions, defaultAccountId]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validate form
    const validationErrors = validateTransactionForm(formData);
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }

    setIsSubmitting(true);
    setErrors({});

    try {
      if (transactionId) {
        await updateTransaction({
          id: transactionId,
          ...formData,
          category: formData.category_id || '',
          date: new Date(formData.date),
        });
      } else {
        await createTransaction({
          ...formData,
          category: formData.category_id || '',
          date: new Date(formData.date),
          is_recurring: false,
        });
      }
      onClose();
      resetForm();
    } catch (error) {
      setErrors({
        submit:
          error instanceof Error ? error.message : 'Failed to save transaction',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetForm = () => {
    setFormData({
      amount: 0,
      type: 'expense',
      account_id: defaultAccountId || '',
      category_id: undefined,
      description: '',
      date: new Date().toISOString().split('T')[0] || '',
      tags: [],
    });
    setErrors({});
  };

  const handleClose = () => {
    if (!isSubmitting) {
      onClose();
      resetForm();
    }
  };

  return (
    <Dialog.Root open={isOpen} onOpenChange={handleClose}>
      <Dialog.Portal>
        <Dialog.Overlay className="transaction-form__overlay" />
        <Dialog.Content className="transaction-form__content">
          <div className="transaction-form__header">
            <Dialog.Title className="transaction-form__title">
              {transactionId ? 'Edit Transaction' : 'Add Transaction'}
            </Dialog.Title>
            <Dialog.Description className="transaction-form__description">
              {transactionId
                ? 'Update transaction details'
                : 'Record a new income, expense, or transfer'}
            </Dialog.Description>
            <Dialog.Close
              className="transaction-form__close"
              aria-label="Close dialog"
            >
              ✕
            </Dialog.Close>
          </div>

          <form
            id={formId}
            className="transaction-form__form"
            onSubmit={handleSubmit}
          >
            {/* Transaction Type Selector */}
            <div className="transaction-form__field">
              <label className="transaction-form__label">
                Transaction Type
              </label>
              <div className="transaction-form__type-selector">
                {TRANSACTION_TYPES.map((type) => {
                  const isSelected = formData.type === type;
                  return (
                    <button
                      key={type}
                      type="button"
                      className={`transaction-form__type-button ${
                        isSelected
                          ? 'transaction-form__type-button--selected'
                          : ''
                      }`}
                      onClick={() =>
                        setFormData((prev) => ({ ...prev, type }))
                      }
                      aria-pressed={isSelected}
                    >
                      <span className="transaction-form__type-icon">
                        {getTransactionIcon(type)}
                      </span>
                      <span className="transaction-form__type-name">
                        {getTransactionTypeName(type)}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Amount */}
            <div className="transaction-form__field">
              <label
                htmlFor={`${formId}-amount`}
                className="transaction-form__label"
              >
                Amount *
              </label>
              <CurrencyInput
                id={`${formId}-amount`}
                value={formData.amount}
                onChange={(value) =>
                  setFormData((prev) => ({ ...prev, amount: value || 0 }))
                }
                currency="INR"
                placeholder="0.00"
                required
                aria-invalid={!!errors.amount}
                aria-describedby={
                  errors.amount ? `${formId}-amount-error` : undefined
                }
              />
              {errors.amount && (
                <span
                  id={`${formId}-amount-error`}
                  className="transaction-form__error"
                >
                  {errors.amount}
                </span>
              )}
            </div>

            {/* Account */}
            <div className="transaction-form__field">
              <label
                htmlFor={`${formId}-account`}
                className="transaction-form__label"
              >
                Account *
              </label>
              <Input
                id={`${formId}-account`}
                type="text"
                value={formData.account_id}
                onChange={(e) =>
                  setFormData((prev) => ({
                    ...prev,
                    account_id: e.target.value,
                  }))
                }
                placeholder="Enter account ID"
                required
                aria-invalid={!!errors.account_id}
                aria-describedby={
                  errors.account_id ? `${formId}-account-error` : undefined
                }
              />
              {errors.account_id && (
                <span
                  id={`${formId}-account-error`}
                  className="transaction-form__error"
                >
                  {errors.account_id}
                </span>
              )}
            </div>

            {/* Description */}
            <div className="transaction-form__field">
              <label
                htmlFor={`${formId}-description`}
                className="transaction-form__label"
              >
                Description *
              </label>
              <Input
                id={`${formId}-description`}
                type="text"
                value={formData.description}
                onChange={(e) =>
                  setFormData((prev) => ({
                    ...prev,
                    description: e.target.value,
                  }))
                }
                placeholder="What was this transaction for?"
                required
                aria-invalid={!!errors.description}
                aria-describedby={
                  errors.description
                    ? `${formId}-description-error`
                    : undefined
                }
              />
              {errors.description && (
                <span
                  id={`${formId}-description-error`}
                  className="transaction-form__error"
                >
                  {errors.description}
                </span>
              )}
            </div>

            {/* Date */}
            <div className="transaction-form__field">
              <label
                htmlFor={`${formId}-date`}
                className="transaction-form__label"
              >
                Date *
              </label>
              <Input
                id={`${formId}-date`}
                type="date"
                value={formData.date}
                onChange={(e) =>
                  setFormData((prev) => ({ ...prev, date: e.target.value }))
                }
                required
                aria-invalid={!!errors.date}
                aria-describedby={
                  errors.date ? `${formId}-date-error` : undefined
                }
              />
              {errors.date && (
                <span
                  id={`${formId}-date-error`}
                  className="transaction-form__error"
                >
                  {errors.date}
                </span>
              )}
            </div>

            {/* Category (Optional) */}
            <div className="transaction-form__field">
              <label
                htmlFor={`${formId}-category`}
                className="transaction-form__label"
              >
                Category
              </label>
              <Input
                id={`${formId}-category`}
                type="text"
                value={formData.category_id || ''}
                onChange={(e) =>
                  setFormData((prev) => ({
                    ...prev,
                    category_id: e.target.value || undefined,
                  }))
                }
                placeholder="Optional category ID"
              />
            </div>

            {/* Submit Error */}
            {errors.submit && (
              <div className="transaction-form__submit-error">
                {errors.submit}
              </div>
            )}
          </form>

          <div className="transaction-form__footer">
            <Button
              type="button"
              variant="secondary"
              onClick={handleClose}
              disabled={isSubmitting}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              form={formId}
              variant="primary"
              disabled={isSubmitting}
            >
              {isSubmitting
                ? 'Saving...'
                : transactionId
                  ? 'Update Transaction'
                  : 'Add Transaction'}
            </Button>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
