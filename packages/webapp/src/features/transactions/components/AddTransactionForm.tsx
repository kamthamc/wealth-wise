/**
 * Add Transaction Form Component
 * Modal form for creating and editing transactions
 */

import * as Dialog from '@radix-ui/react-dialog';
import { useEffect, useId, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useAccountStore, useTransactionStore } from '@/core/stores';
import { timestampToDate } from '@/core/utils/firebase';
import {
  AccountSelect,
  Button,
  CategorySelect,
  CurrencyInput,
  DatePicker,
  Input,
  useToast,
  ValidationMessage,
} from '@/shared/components';
import { useValidation, validators } from '@/shared/hooks/useValidation';
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
  const { t } = useTranslation();
  const formId = useId();
  const { transactions, createTransaction, updateTransaction } =
    useTransactionStore();
  const { accounts } = useAccountStore();
  const toast = useToast();

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

  // Real-time validation
  const amountValidation = useValidation(formData.amount, {
    validate: validators.combine(
      validators.required,
      validators.positiveNumber,
      validators.minAmount(0.01)
    ),
    debounceMs: 500,
    validateOnlyAfterBlur: true,
  });

  const descriptionValidation = useValidation(formData.description, {
    validate: validators.combine(
      validators.required,
      validators.minLength(3),
      validators.maxLength(200)
    ),
    debounceMs: 300,
    validateOnlyAfterBlur: true,
  });

  const accountValidation = useValidation(formData.account_id, {
    validate: validators.required,
    validateOnlyAfterBlur: true,
  });

  const dateValidation = useValidation(formData.date, {
    validate: validators.required,
    validateOnlyAfterBlur: true,
  });

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
          date: timestampToDate(transaction.date).toISOString().split('T')[0] || '',
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
        await updateTransaction(transactionId, {
          ...formData,
          category: formData.category_id || '',
          date: timestampToDate(formData.date),
        } as any);
        toast.success(
          'Transaction updated',
          'Your transaction has been updated successfully'
        );
      } else {
        await createTransaction({
          ...formData,
          category: formData.category_id || '',
          date: timestampToDate(formData.date),
          is_recurring: false,
        });
        toast.success(
          'Transaction added',
          'Your transaction has been added successfully'
        );
      }
      onClose();
      resetForm();
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : t('forms.transaction.saveError', 'Failed to save transaction');
      setErrors({
        submit: errorMessage,
      });
      toast.error(t('forms.transaction.saveErrorTitle', 'Failed to save'), errorMessage);
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
              {transactionId ? t('forms.transaction.editTitle', 'Edit Transaction') : t('forms.transaction.addTitle', 'Add Transaction')}
            </Dialog.Title>
            <Dialog.Description className="transaction-form__description">
              {transactionId
                ? t('forms.transaction.editDescription', 'Update transaction details')
                : t('forms.transaction.addDescription', 'Record a new income, expense, or transfer')}
            </Dialog.Description>
            <Dialog.Close
              className="transaction-form__close"
              aria-label={t('common.close', 'Close')}
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
            <fieldset className="transaction-form__field">
              <legend className="transaction-form__label">
                {t('forms.transaction.typeLabel', 'Transaction Type')}
              </legend>
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
                      onClick={() => setFormData((prev) => ({ ...prev, type }))}
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
            </fieldset>

            {/* Amount */}
            <div className="transaction-form__field">
              <label
                htmlFor={`${formId}-amount`}
                className="transaction-form__label"
              >
                {t('forms.transaction.amountLabel', 'Amount')} *
              </label>
              <CurrencyInput
                id={`${formId}-amount`}
                value={formData.amount}
                onChange={(value) =>
                  setFormData((prev) => ({ ...prev, amount: value || 0 }))
                }
                onBlur={amountValidation.onBlur}
                currency="INR"
                placeholder={t('forms.transaction.amountPlaceholder', '0.00')}
                required
                aria-invalid={!!amountValidation.message}
                aria-describedby={
                  amountValidation.message
                    ? `${formId}-amount-validation`
                    : undefined
                }
              />
              {amountValidation.hasBlurred && (
                <ValidationMessage
                  state={amountValidation.state}
                  message={amountValidation.message}
                  fieldId={`${formId}-amount`}
                />
              )}
            </div>

            {/* Account */}
            <div className="transaction-form__field">
              <label
                htmlFor={`${formId}-account`}
                className="transaction-form__label"
              >
                {t('forms.transaction.accountLabel', 'Account')} *
              </label>
              <AccountSelect
                id={`${formId}-account`}
                value={formData.account_id}
                onValueChange={(accountId) => {
                  setFormData((prev) => ({ ...prev, account_id: accountId }));
                  // Trigger validation after selection
                  setTimeout(() => accountValidation.revalidate(), 0);
                }}
                accounts={accounts as any}
                placeholder={t('forms.transaction.accountPlaceholder', 'Select an account...')}
                required
                error={
                  accountValidation.hasBlurred
                    ? accountValidation.message
                    : undefined
                }
                aria-describedby={
                  accountValidation.message
                    ? `${formId}-account-validation`
                    : undefined
                }
              />
              {accountValidation.hasBlurred && (
                <ValidationMessage
                  state={accountValidation.state}
                  message={accountValidation.message}
                  fieldId={`${formId}-account`}
                />
              )}
            </div>

            {/* Description */}
            <div className="transaction-form__field">
              <label
                htmlFor={`${formId}-description`}
                className="transaction-form__label"
              >
                {t('forms.transaction.descriptionLabel', 'Description')} *
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
                onBlur={descriptionValidation.onBlur}
                placeholder={t('forms.transaction.descriptionPlaceholder', 'What was this transaction for?')}
                required
                aria-invalid={!!descriptionValidation.message}
                aria-describedby={
                  descriptionValidation.message
                    ? `${formId}-description-validation`
                    : undefined
                }
              />
              {descriptionValidation.hasBlurred && (
                <ValidationMessage
                  state={descriptionValidation.state}
                  message={descriptionValidation.message}
                  fieldId={`${formId}-description`}
                />
              )}
            </div>

            {/* Date */}
            <div className="transaction-form__field">
              <label
                htmlFor={`${formId}-date`}
                className="transaction-form__label"
              >
                {t('forms.transaction.dateLabel', 'Date')} *
              </label>
              <DatePicker
                id={`${formId}-date`}
                value={formData.date ? timestampToDate(formData.date) : undefined}
                onChange={(date) => {
                  setFormData((prev) => ({
                    ...prev,
                    date: date ? date.toISOString().split('T')[0] || '' : '',
                  }));
                  // Trigger validation after selection
                  setTimeout(() => dateValidation.revalidate(), 0);
                }}
                placeholder={t('forms.transaction.datePlaceholder', 'Select transaction date...')}
                required
                error={
                  dateValidation.hasBlurred ? dateValidation.message : undefined
                }
                aria-describedby={
                  dateValidation.message
                    ? `${formId}-date-validation`
                    : undefined
                }
                dateFormat="PPP"
              />
              {dateValidation.hasBlurred && (
                <ValidationMessage
                  state={dateValidation.state}
                  message={dateValidation.message}
                  fieldId={`${formId}-date`}
                />
              )}
            </div>

            {/* Category (Optional) */}
            <div className="transaction-form__field">
              <CategorySelect
                id={`${formId}-category`}
                value={formData.category_id}
                onChange={(categoryId) =>
                  setFormData((prev) => ({
                    ...prev,
                    category_id: categoryId,
                  }))
                }
                type={
                  formData.type === 'income'
                    ? 'income'
                    : formData.type === 'expense'
                      ? 'expense'
                      : 'all'
                }
                placeholder={t('forms.transaction.categoryPlaceholder', 'Select a category (optional)')}
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
              {t('common.cancel', 'Cancel')}
            </Button>
            <Button
              type="submit"
              form={formId}
              variant="primary"
              disabled={
                isSubmitting ||
                !amountValidation.isValid ||
                !descriptionValidation.isValid ||
                !accountValidation.isValid ||
                !dateValidation.isValid
              }
            >
              {isSubmitting
                ? t('forms.transaction.saving', 'Saving...')
                : transactionId
                  ? t('forms.transaction.updateButton', 'Update Transaction')
                  : t('forms.transaction.addButton', 'Add Transaction')}
            </Button>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
