/**
 * Quick Transaction Entry Component
 * Fast transaction entry with smart defaults and autofill
 */

import { ArrowLeftRight, TrendingDown, TrendingUp } from 'lucide-react';
import type { ReactNode } from 'react';
import { useEffect, useState } from 'react';
import {
  type Category,
  getAllCategories,
} from '@/core/services/categoryService';
import { useAccountStore, useTransactionStore } from '@/core/stores';
import { useToast } from '@/shared/components';
import type { TransactionType } from '../types';
import './QuickTransactionEntry.css';

interface QuickTransactionEntryProps {
  /** Default transaction type */
  defaultType?: TransactionType;
  /** Default account ID */
  defaultAccountId?: string;
  /** Callback after successful submission */
  onSuccess?: () => void;
}

const TRANSACTION_TYPES: Array<{
  value: TransactionType;
  label: string;
  icon: ReactNode;
  color: string;
}> = [
  {
    value: 'expense',
    label: 'Expense',
    icon: <TrendingDown size={20} />,
    color: 'red',
  },
  {
    value: 'income',
    label: 'Income',
    icon: <TrendingUp size={20} />,
    color: 'green',
  },
  {
    value: 'transfer',
    label: 'Transfer',
    icon: <ArrowLeftRight size={20} />,
    color: 'blue',
  },
];

export function QuickTransactionEntry({
  defaultType = 'expense',
  defaultAccountId,
  onSuccess,
}: QuickTransactionEntryProps) {
  const { accounts } = useAccountStore();
  const { createTransaction } = useTransactionStore();
  const toast = useToast();

  const [type, setType] = useState<TransactionType>(defaultType);
  const [amount, setAmount] = useState('');
  const [description, setDescription] = useState('');
  const [accountId, setAccountId] = useState(defaultAccountId || '');
  const [categoryId, setCategoryId] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [categories, setCategories] = useState<Category[]>([]);

  // Load categories on mount
  useEffect(() => {
    const loadCategories = async () => {
      try {
        const data = await getAllCategories();
        setCategories(data);
      } catch (error) {
        console.error('Failed to load categories:', error);
      }
    };
    loadCategories();
  }, []);

  // Filter categories by transaction type
  const availableCategories = categories.filter((cat) => {
    if (type === 'income') return cat.type === 'income';
    if (type === 'expense') return cat.type === 'expense';
    return true;
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validation
    if (!amount || Number.parseFloat(amount) <= 0) {
      toast.error('Invalid amount', 'Please enter a valid amount');
      return;
    }
    if (!accountId) {
      toast.error('Account required', 'Please select an account');
      return;
    }
    if (!description.trim()) {
      toast.error('Description required', 'Please enter a description');
      return;
    }

    setIsSubmitting(true);

    try {
      await createTransaction({
        amount: Number.parseFloat(amount),
        type,
        account_id: accountId,
        category: categoryId,
        description: description.trim(),
        date: new Date(),
        is_recurring: false,
        tags: [],
      });

      toast.success('Transaction added', 'Your transaction has been recorded');

      // Reset form
      setAmount('');
      setDescription('');
      setCategoryId('');

      onSuccess?.();
    } catch (error) {
      toast.error('Failed to add transaction', 'Please try again');
      console.error('Transaction creation error:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="quick-transaction-entry">
      <h3 className="quick-transaction-entry__title">Quick Entry</h3>

      <form onSubmit={handleSubmit} className="quick-transaction-entry__form">
        {/* Transaction Type Selector */}
        <div className="quick-transaction-entry__type-selector">
          <label className="quick-transaction-entry__label">
            Transaction Type
            <span className="required" aria-label="required">
              *
            </span>
          </label>
          <div
            className="type-buttons"
            role="radiogroup"
            aria-label="Transaction type"
          >
            {TRANSACTION_TYPES.map((txnType) => (
              <button
                key={txnType.value}
                type="button"
                className={`type-button type-button--${txnType.color} ${
                  type === txnType.value ? 'type-button--selected' : ''
                }`}
                onClick={() => setType(txnType.value)}
                role="radio"
                aria-checked={type === txnType.value}
                aria-label={txnType.label}
              >
                <span className="type-button__icon" aria-hidden="true">
                  {txnType.icon}
                </span>
                <span className="type-button__label">{txnType.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Amount Input */}
        <div className="quick-transaction-entry__field">
          <label
            htmlFor="quick-amount"
            className="quick-transaction-entry__label"
          >
            Amount
            <span className="required" aria-label="required">
              *
            </span>
          </label>
          <input
            id="quick-amount"
            type="number"
            inputMode="decimal"
            step="0.01"
            min="0.01"
            placeholder="0.00"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="quick-transaction-entry__input quick-transaction-entry__input--amount"
            autoComplete="transaction-amount"
            required
            aria-required="true"
            aria-describedby={
              amount && Number.parseFloat(amount) <= 0
                ? 'amount-error'
                : undefined
            }
          />
          {amount && Number.parseFloat(amount) <= 0 && (
            <span
              id="amount-error"
              className="quick-transaction-entry__error"
              role="alert"
            >
              Amount must be greater than zero
            </span>
          )}
        </div>

        {/* Description Input */}
        <div className="quick-transaction-entry__field">
          <label
            htmlFor="quick-description"
            className="quick-transaction-entry__label"
          >
            Description
            <span className="required" aria-label="required">
              *
            </span>
          </label>
          <input
            id="quick-description"
            type="text"
            placeholder="What was this transaction for?"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="quick-transaction-entry__input"
            autoComplete="off"
            maxLength={200}
            required
            aria-required="true"
            aria-describedby="description-hint"
          />
          <span id="description-hint" className="quick-transaction-entry__hint">
            {description.length}/200 characters
          </span>
        </div>

        {/* Account Selector */}
        <div className="quick-transaction-entry__field">
          <label
            htmlFor="quick-account"
            className="quick-transaction-entry__label"
          >
            Account
            <span className="required" aria-label="required">
              *
            </span>
          </label>
          <select
            id="quick-account"
            value={accountId}
            onChange={(e) => setAccountId(e.target.value)}
            className="quick-transaction-entry__select quick-transaction-entry__select--with-icon"
            autoComplete="off"
            required
            aria-required="true"
          >
            <option value="">🏦 Select account...</option>
            {accounts.map((account) => (
              <option key={account.id} value={account.id}>
                {account.name} ({account.type})
              </option>
            ))}
          </select>
          {accounts.length === 0 && (
            <span className="quick-transaction-entry__hint quick-transaction-entry__hint--warning">
              ⚠️ Please add an account first
            </span>
          )}
        </div>

        {/* Category Selector */}
        <div className="quick-transaction-entry__field">
          <label
            htmlFor="quick-category"
            className="quick-transaction-entry__label"
          >
            Category
            <span className="optional">(Optional)</span>
          </label>
          <select
            id="quick-category"
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)}
            className="quick-transaction-entry__select quick-transaction-entry__select--with-icon"
            autoComplete="off"
          >
            <option value="">💭 Select category...</option>
            {availableCategories.map((category) => (
              <option key={category.id} value={category.id}>
                {category.icon} {category.name}
              </option>
            ))}
          </select>
          {availableCategories.length === 0 && (
            <span className="quick-transaction-entry__hint">
              No categories available for this transaction type
            </span>
          )}
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          className="quick-transaction-entry__submit"
          disabled={
            isSubmitting || !amount || !accountId || !description.trim()
          }
          aria-busy={isSubmitting}
        >
          {isSubmitting
            ? 'Adding...'
            : `Add ${TRANSACTION_TYPES.find((t) => t.value === type)?.label}`}
        </button>
      </form>
    </div>
  );
}
