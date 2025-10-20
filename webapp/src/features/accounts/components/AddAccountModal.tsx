/**
 * Add/Edit Account Modal Component
 * Form modal for creating or editing accounts
 */

import * as Dialog from '@radix-ui/react-dialog';
import {
  Banknote,
  CreditCard,
  Landmark,
  Smartphone,
  TrendingUp,
  Wallet,
} from 'lucide-react';
import { useId, useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { Account } from '@/core/db/types';
import { Button, CurrencyInput, Input } from '@/shared/components';
import type { AccountFormData, AccountType } from '../types';
import {
  getAccountTypeName,
  validateAccountForm,
} from '../utils/accountHelpers';
import './AddAccountModal.css';

export interface AddAccountModalProps {
  account?: Account;
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: AccountFormData) => void | Promise<void>;
}

const ACCOUNT_TYPES: AccountType[] = [
  'bank',
  'credit_card',
  'upi',
  'brokerage',
  'cash',
  'wallet',
];

// Icon mapping for account types
const ACCOUNT_TYPE_ICONS: Record<AccountType, React.ReactNode> = {
  bank: <Landmark size={32} />,
  credit_card: <CreditCard size={32} />,
  upi: <Smartphone size={32} />,
  brokerage: <TrendingUp size={32} />,
  cash: <Banknote size={32} />,
  wallet: <Wallet size={32} />,
};

export function AddAccountModal({
  account,
  isOpen,
  onClose,
  onSubmit,
}: AddAccountModalProps) {
  const { t } = useTranslation();

  const [formData, setFormData] = useState<AccountFormData>({
    name: account?.name || '',
    type: account?.type || 'bank',
    balance: account?.balance || 0,
    currency: account?.currency || 'INR',
    icon: account?.icon || '',
    color: account?.color || '',
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Generate unique IDs for form elements
  const nameId = useId();
  const balanceId = useId();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validate form
    const validationErrors = validateAccountForm(formData);
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }

    setIsSubmitting(true);
    try {
      await onSubmit(formData);
      handleClose();
    } catch (error) {
      console.error('Failed to save account:', error);
      setErrors({ submit: 'Failed to save account. Please try again.' });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    setFormData({
      name: '',
      type: 'bank',
      balance: 0,
      currency: 'INR',
      icon: '',
      color: '',
    });
    setErrors({});
    onClose();
  };

  const handleTypeSelect = (type: AccountType) => {
    setFormData({ ...formData, type });
    setErrors({ ...errors, type: '' });
  };

  return (
    <Dialog.Root open={isOpen} onOpenChange={(open) => !open && handleClose()}>
      <Dialog.Portal>
        <Dialog.Overlay className="modal-overlay" />
        <Dialog.Content
          className="account-modal__content"
          aria-describedby={undefined}
        >
          <form onSubmit={handleSubmit} className="account-modal__form">
            <Dialog.Title className="account-modal__title">
              {account
                ? t('pages.accounts.modal.editTitle')
                : t('pages.accounts.modal.addTitle')}
            </Dialog.Title>
            <Dialog.Description className="account-modal__subtitle">
              {account
                ? t('pages.accounts.modal.editSubtitle')
                : t('pages.accounts.modal.addSubtitle')}
            </Dialog.Description>

            {/* Account Name */}
            <div className="account-modal__form-group">
              <label
                htmlFor={nameId}
                className="account-modal__label account-modal__label--required"
              >
                {t('pages.accounts.modal.nameLabel')}
              </label>
              <Input
                id={nameId}
                type="text"
                value={formData.name}
                onChange={(e) => {
                  setFormData({ ...formData, name: e.target.value });
                  setErrors({ ...errors, name: '' });
                }}
                placeholder={t('pages.accounts.modal.namePlaceholder')}
                error={errors.name}
                autoFocus
              />
            </div>

            {/* Account Type */}
            <div className="account-modal__form-group">
              <span className="account-modal__label account-modal__label--required">
                {t('pages.accounts.modal.typeLabel')}
              </span>
              <div
                className="account-modal__type-grid"
                role="radiogroup"
                aria-label={t('pages.accounts.modal.typeLabel')}
              >
                {ACCOUNT_TYPES.map((type) => (
                  <label
                    key={type}
                    className={`account-modal__type-option ${
                      formData.type === type
                        ? 'account-modal__type-option--selected'
                        : ''
                    }`}
                  >
                    <input
                      type="radio"
                      name="account-type"
                      value={type}
                      checked={formData.type === type}
                      onChange={() => handleTypeSelect(type)}
                      className="sr-only"
                    />
                    <span className="account-modal__type-icon">
                      {ACCOUNT_TYPE_ICONS[type]}
                    </span>
                    <span className="account-modal__type-name">
                      {getAccountTypeName(type)}
                    </span>
                  </label>
                ))}
              </div>
              {errors.type && (
                <span className="account-modal__error">{errors.type}</span>
              )}
            </div>

            {/* Initial Balance */}
            <div className="account-modal__form-group">
              <label
                htmlFor={balanceId}
                className="account-modal__label account-modal__label--required"
              >
                {account
                  ? t('pages.accounts.modal.currentBalanceLabel')
                  : t('pages.accounts.modal.initialBalanceLabel')}
              </label>
              <CurrencyInput
                id={balanceId}
                value={formData.balance}
                onChange={(value) => {
                  setFormData({ ...formData, balance: value || 0 });
                  setErrors({ ...errors, balance: '' });
                }}
                currency={formData.currency}
                error={errors.balance}
              />
            </div>

            {/* Submit Error */}
            {errors.submit && (
              <div className="account-modal__error">{errors.submit}</div>
            )}

            {/* Actions */}
            <div className="account-modal__actions">
              <Button
                type="button"
                variant="secondary"
                onClick={handleClose}
                disabled={isSubmitting}
              >
                {t('common.cancel')}
              </Button>
              <Button type="submit" isLoading={isSubmitting}>
                {account
                  ? t('pages.accounts.modal.saveButton')
                  : t('pages.accounts.modal.addButton')}
              </Button>
            </div>
          </form>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
