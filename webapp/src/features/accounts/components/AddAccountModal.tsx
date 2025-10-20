/**
 * Add/Edit Account Modal Component
 * Form modal for creating or editing accounts
 */

import * as Dialog from '@radix-ui/react-dialog';
import * as Select from '@radix-ui/react-select';
import {
  Banknote,
  CreditCard,
  Landmark,
  Smartphone,
  TrendingUp,
  Wallet,
  Lock,
  FileText,
  PiggyBank,
  ChevronDown,
  Check,
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

// Icon mapping for account types (small size for dropdown)
const ACCOUNT_TYPE_ICONS: Record<AccountType, React.ReactNode> = {
  bank: <Landmark size={16} />,
  credit_card: <CreditCard size={16} />,
  upi: <Smartphone size={16} />,
  brokerage: <TrendingUp size={16} />,
  cash: <Banknote size={16} />,
  wallet: <Wallet size={16} />,
  fixed_deposit: <Lock size={16} />,
  kvp: <FileText size={16} />,
  nsc: <FileText size={16} />,
  post_office: <Landmark size={16} />,
  ppf: <Lock size={16} />,
  recurring_deposit: <PiggyBank size={16} />,
  scss: <Landmark size={16} />,
};

// Categorized account types
const ACCOUNT_TYPE_CATEGORIES = [
  {
    label: 'Banking',
    types: ['bank', 'credit_card', 'upi'] as AccountType[],
  },
  {
    label: 'Investments',
    types: ['brokerage'] as AccountType[],
  },
  {
    label: 'Deposits & Savings',
    types: ['fixed_deposit', 'recurring_deposit', 'ppf', 'nsc', 'kvp', 'scss', 'post_office'] as AccountType[],
  },
  {
    label: 'Cash & Wallets',
    types: ['cash', 'wallet'] as AccountType[],
  },
];

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
              <Select.Root value={formData.type} onValueChange={handleTypeSelect}>
                <Select.Trigger className="account-modal__type-select">
                  <Select.Value>
                    <div className="account-modal__type-select-value">
                      <span className="account-modal__type-select-icon">
                        {ACCOUNT_TYPE_ICONS[formData.type]}
                      </span>
                      <span>{getAccountTypeName(formData.type)}</span>
                    </div>
                  </Select.Value>
                  <Select.Icon className="account-modal__type-select-chevron">
                    <ChevronDown size={16} />
                  </Select.Icon>
                </Select.Trigger>
                <Select.Portal>
                  <Select.Content className="account-modal__type-content" position="popper">
                    <Select.Viewport className="account-modal__type-viewport">
                      {ACCOUNT_TYPE_CATEGORIES.map((category, index) => (
                        <div key={category.label}>
                          {index > 0 && <Select.Separator className="account-modal__type-separator" />}
                          <Select.Label className="account-modal__type-category-label">
                            {category.label}
                          </Select.Label>
                          {category.types.map((type) => (
                            <Select.Item
                              key={type}
                              value={type}
                              className="account-modal__type-item"
                            >
                              <div className="account-modal__type-item-content">
                                <span className="account-modal__type-item-icon">
                                  {ACCOUNT_TYPE_ICONS[type]}
                                </span>
                                <Select.ItemText>{getAccountTypeName(type)}</Select.ItemText>
                              </div>
                              <Select.ItemIndicator className="account-modal__type-item-indicator">
                                <Check size={16} />
                              </Select.ItemIndicator>
                            </Select.Item>
                          ))}
                        </div>
                      ))}
                    </Select.Viewport>
                  </Select.Content>
                </Select.Portal>
              </Select.Root>
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
