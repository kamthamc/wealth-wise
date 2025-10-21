/**
 * Add/Edit Account Modal Component
 * Form modal for creating or editing accounts
 */

import * as Dialog from '@radix-ui/react-dialog';
import * as Select from '@radix-ui/react-select';
import {
  Banknote,
  Check,
  ChevronDown,
  CreditCard,
  FileText,
  Landmark,
  Lock,
  PiggyBank,
  Smartphone,
  TrendingUp,
  Wallet,
} from 'lucide-react';
import { useId, useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { Account, InterestPayoutFrequency } from '@/core/db/types';
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
    types: [
      'fixed_deposit',
      'recurring_deposit',
      'ppf',
      'nsc',
      'kvp',
      'scss',
      'post_office',
    ] as AccountType[],
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

  // Check if selected type is a deposit account
  const DEPOSIT_TYPES: AccountType[] = [
    'fixed_deposit',
    'recurring_deposit',
    'ppf',
    'nsc',
    'kvp',
    'scss',
    'post_office',
  ];

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

  // Check if current type is a deposit
  const isDepositAccount = DEPOSIT_TYPES.includes(formData.type);

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
              <Select.Root
                value={formData.type}
                onValueChange={handleTypeSelect}
              >
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
                  <Select.Content
                    className="account-modal__type-content"
                    position="popper"
                  >
                    <Select.Viewport className="account-modal__type-viewport">
                      {ACCOUNT_TYPE_CATEGORIES.map((category, index) => (
                        <Select.Group key={category.label}>
                          {index > 0 && (
                            <Select.Separator className="account-modal__type-separator" />
                          )}
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
                                <Select.ItemText>
                                  {getAccountTypeName(type)}
                                </Select.ItemText>
                              </div>
                              <Select.ItemIndicator className="account-modal__type-item-indicator">
                                <Check size={16} />
                              </Select.ItemIndicator>
                            </Select.Item>
                          ))}
                        </Select.Group>
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

            {/* Credit Card-specific fields */}
            {formData.type === 'credit_card' && (
              <>
                {/* Credit Limit */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="cc-credit-limit"
                    className="account-modal__label account-modal__label--required"
                  >
                    Credit Limit
                  </label>
                  <CurrencyInput
                    id="cc-credit-limit"
                    value={formData.creditCardDetails?.credit_limit || 0}
                    onChange={(value) => {
                      setFormData({
                        ...formData,
                        creditCardDetails: {
                          ...formData.creditCardDetails,
                          credit_limit: value || 0,
                        },
                      });
                    }}
                    currency={formData.currency}
                    placeholder="50000"
                  />
                </div>

                {/* Billing Cycle Day */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="cc-billing-cycle"
                    className="account-modal__label"
                  >
                    Billing Cycle Day (1-31)
                  </label>
                  <Input
                    id="cc-billing-cycle"
                    type="number"
                    min="1"
                    max="31"
                    value={formData.creditCardDetails?.billing_cycle_day || ''}
                    onChange={(e) => {
                      setFormData({
                        ...formData,
                        creditCardDetails: {
                          ...formData.creditCardDetails,
                          credit_limit:
                            formData.creditCardDetails?.credit_limit || 0,
                          billing_cycle_day: parseInt(e.target.value) || undefined,
                        },
                      });
                    }}
                    placeholder="1"
                  />
                </div>

                {/* Payment Due Day */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="cc-payment-due"
                    className="account-modal__label"
                  >
                    Payment Due Day (1-31)
                  </label>
                  <Input
                    id="cc-payment-due"
                    type="number"
                    min="1"
                    max="31"
                    value={formData.creditCardDetails?.payment_due_day || ''}
                    onChange={(e) => {
                      setFormData({
                        ...formData,
                        creditCardDetails: {
                          ...formData.creditCardDetails,
                          credit_limit:
                            formData.creditCardDetails?.credit_limit || 0,
                          payment_due_day: parseInt(e.target.value) || undefined,
                        },
                      });
                    }}
                    placeholder="20"
                  />
                </div>

                {/* Card Network */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="cc-card-network"
                    className="account-modal__label"
                  >
                    Card Network
                  </label>
                  <Select.Root
                    value={formData.creditCardDetails?.card_network || 'visa'}
                    onValueChange={(value) => {
                      setFormData({
                        ...formData,
                        creditCardDetails: {
                          ...formData.creditCardDetails,
                          credit_limit:
                            formData.creditCardDetails?.credit_limit || 0,
                          card_network: value,
                        },
                      });
                    }}
                  >
                    <Select.Trigger className="account-modal__type-select">
                      <Select.Value />
                      <Select.Icon className="account-modal__type-select-chevron">
                        <ChevronDown size={16} />
                      </Select.Icon>
                    </Select.Trigger>
                    <Select.Portal>
                      <Select.Content
                        className="account-modal__type-content"
                        position="popper"
                      >
                        <Select.Viewport className="account-modal__type-viewport">
                          <Select.Item
                            value="visa"
                            className="account-modal__type-item"
                          >
                            <Select.ItemText>Visa</Select.ItemText>
                            <Select.ItemIndicator className="account-modal__type-item-indicator">
                              <Check size={16} />
                            </Select.ItemIndicator>
                          </Select.Item>
                          <Select.Item
                            value="mastercard"
                            className="account-modal__type-item"
                          >
                            <Select.ItemText>Mastercard</Select.ItemText>
                            <Select.ItemIndicator className="account-modal__type-item-indicator">
                              <Check size={16} />
                            </Select.ItemIndicator>
                          </Select.Item>
                          <Select.Item
                            value="rupay"
                            className="account-modal__type-item"
                          >
                            <Select.ItemText>RuPay</Select.ItemText>
                            <Select.ItemIndicator className="account-modal__type-item-indicator">
                              <Check size={16} />
                            </Select.ItemIndicator>
                          </Select.Item>
                          <Select.Item
                            value="amex"
                            className="account-modal__type-item"
                          >
                            <Select.ItemText>American Express</Select.ItemText>
                            <Select.ItemIndicator className="account-modal__type-item-indicator">
                              <Check size={16} />
                            </Select.ItemIndicator>
                          </Select.Item>
                        </Select.Viewport>
                      </Select.Content>
                    </Select.Portal>
                  </Select.Root>
                </div>

                {/* Interest Rate */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="cc-interest-rate"
                    className="account-modal__label"
                  >
                    Interest Rate (% per annum)
                  </label>
                  <Input
                    id="cc-interest-rate"
                    type="number"
                    step="0.01"
                    min="0"
                    max="100"
                    value={formData.creditCardDetails?.interest_rate || ''}
                    onChange={(e) => {
                      setFormData({
                        ...formData,
                        creditCardDetails: {
                          ...formData.creditCardDetails,
                          credit_limit:
                            formData.creditCardDetails?.credit_limit || 0,
                          interest_rate: parseFloat(e.target.value) || undefined,
                        },
                      });
                    }}
                    placeholder="36.0"
                  />
                </div>
              </>
            )}

            {/* Brokerage-specific fields */}
            {formData.type === 'brokerage' && (
              <>
                {/* Broker Name */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="brokerage-broker-name"
                    className="account-modal__label"
                  >
                    Broker Name
                  </label>
                  <Input
                    id="brokerage-broker-name"
                    type="text"
                    value={formData.brokerageDetails?.broker_name || ''}
                    onChange={(e) => {
                      setFormData({
                        ...formData,
                        brokerageDetails: {
                          ...formData.brokerageDetails,
                          broker_name: e.target.value,
                        },
                      });
                    }}
                    placeholder="Zerodha, Groww, etc."
                  />
                </div>

                {/* Demat Account Number */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="brokerage-demat-account"
                    className="account-modal__label"
                  >
                    Demat Account Number
                  </label>
                  <Input
                    id="brokerage-demat-account"
                    type="text"
                    value={formData.brokerageDetails?.demat_account_number || ''}
                    onChange={(e) => {
                      setFormData({
                        ...formData,
                        brokerageDetails: {
                          ...formData.brokerageDetails,
                          demat_account_number: e.target.value,
                        },
                      });
                    }}
                    placeholder="1234567890123456"
                  />
                </div>

                {/* Trading Account Number */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="brokerage-trading-account"
                    className="account-modal__label"
                  >
                    Trading Account Number
                  </label>
                  <Input
                    id="brokerage-trading-account"
                    type="text"
                    value={formData.brokerageDetails?.trading_account_number || ''}
                    onChange={(e) => {
                      setFormData({
                        ...formData,
                        brokerageDetails: {
                          ...formData.brokerageDetails,
                          trading_account_number: e.target.value,
                        },
                      });
                    }}
                    placeholder="AB1234"
                  />
                </div>

                {/* DP ID */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="brokerage-dp-id"
                    className="account-modal__label"
                  >
                    DP ID (Depository Participant ID)
                  </label>
                  <Input
                    id="brokerage-dp-id"
                    type="text"
                    value={formData.brokerageDetails?.dp_id || ''}
                    onChange={(e) => {
                      setFormData({
                        ...formData,
                        brokerageDetails: {
                          ...formData.brokerageDetails,
                          dp_id: e.target.value,
                        },
                      });
                    }}
                    placeholder="IN300***"
                  />
                </div>

                {/* Client ID */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="brokerage-client-id"
                    className="account-modal__label"
                  >
                    Client ID
                  </label>
                  <Input
                    id="brokerage-client-id"
                    type="text"
                    value={formData.brokerageDetails?.client_id || ''}
                    onChange={(e) => {
                      setFormData({
                        ...formData,
                        brokerageDetails: {
                          ...formData.brokerageDetails,
                          client_id: e.target.value,
                        },
                      });
                    }}
                    placeholder="ABC123"
                  />
                </div>
              </>
            )}

            {/* Deposit-specific fields */}
            {isDepositAccount && (
              <>
                {/* Interest Rate */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="deposit-interest-rate"
                    className="account-modal__label account-modal__label--required"
                  >
                    Interest Rate (% per annum)
                  </label>
                  <Input
                    id="deposit-interest-rate"
                    type="number"
                    step="0.01"
                    min="0"
                    max="100"
                    value={formData.depositDetails?.interest_rate || ''}
                    onChange={(e) => {
                      setFormData({
                        ...formData,
                        depositDetails: {
                          ...formData.depositDetails,
                          principal_amount: formData.balance,
                          interest_rate: parseFloat(e.target.value) || 0,
                          start_date:
                            formData.depositDetails?.start_date || new Date(),
                          tenure_months:
                            formData.depositDetails?.tenure_months || 12,
                        },
                      });
                    }}
                    placeholder="7.5"
                  />
                </div>

                {/* Tenure */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="deposit-tenure"
                    className="account-modal__label account-modal__label--required"
                  >
                    Tenure (months)
                  </label>
                  <Input
                    id="deposit-tenure"
                    type="number"
                    min="1"
                    max="600"
                    value={formData.depositDetails?.tenure_months || ''}
                    onChange={(e) => {
                      setFormData({
                        ...formData,
                        depositDetails: {
                          ...formData.depositDetails,
                          principal_amount: formData.balance,
                          interest_rate:
                            formData.depositDetails?.interest_rate || 0,
                          start_date:
                            formData.depositDetails?.start_date || new Date(),
                          tenure_months: parseInt(e.target.value) || 0,
                        },
                      });
                    }}
                    placeholder="12"
                  />
                </div>

                {/* Start Date */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="deposit-start-date"
                    className="account-modal__label account-modal__label--required"
                  >
                    Start Date
                  </label>
                  <Input
                    id="deposit-start-date"
                    type="date"
                    value={
                      formData.depositDetails?.start_date
                        ? new Date(formData.depositDetails.start_date)
                            .toISOString()
                            .split('T')[0]
                        : ''
                    }
                    onChange={(e) => {
                      setFormData({
                        ...formData,
                        depositDetails: {
                          ...formData.depositDetails,
                          principal_amount: formData.balance,
                          interest_rate:
                            formData.depositDetails?.interest_rate || 0,
                          tenure_months:
                            formData.depositDetails?.tenure_months || 12,
                          start_date: new Date(e.target.value),
                        },
                      });
                    }}
                  />
                </div>

                {/* Interest Payout Frequency */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="deposit-payout-frequency"
                    className="account-modal__label"
                  >
                    Interest Payout Frequency
                  </label>
                  <Select.Root
                    value={
                      formData.depositDetails?.interest_payout_frequency ||
                      'quarterly'
                    }
                    onValueChange={(value) => {
                      setFormData({
                        ...formData,
                        depositDetails: {
                          ...formData.depositDetails,
                          principal_amount: formData.balance,
                          interest_rate:
                            formData.depositDetails?.interest_rate || 0,
                          start_date:
                            formData.depositDetails?.start_date || new Date(),
                          tenure_months:
                            formData.depositDetails?.tenure_months || 12,
                          interest_payout_frequency:
                            value as InterestPayoutFrequency,
                        },
                      });
                    }}
                  >
                    <Select.Trigger className="account-modal__type-select">
                      <Select.Value />
                      <Select.Icon className="account-modal__type-select-chevron">
                        <ChevronDown size={16} />
                      </Select.Icon>
                    </Select.Trigger>
                    <Select.Portal>
                      <Select.Content
                        className="account-modal__type-content"
                        position="popper"
                      >
                        <Select.Viewport className="account-modal__type-viewport">
                          <Select.Item
                            value="monthly"
                            className="account-modal__type-item"
                          >
                            <Select.ItemText>Monthly</Select.ItemText>
                            <Select.ItemIndicator className="account-modal__type-item-indicator">
                              <Check size={16} />
                            </Select.ItemIndicator>
                          </Select.Item>
                          <Select.Item
                            value="quarterly"
                            className="account-modal__type-item"
                          >
                            <Select.ItemText>Quarterly</Select.ItemText>
                            <Select.ItemIndicator className="account-modal__type-item-indicator">
                              <Check size={16} />
                            </Select.ItemIndicator>
                          </Select.Item>
                          <Select.Item
                            value="annually"
                            className="account-modal__type-item"
                          >
                            <Select.ItemText>Annually</Select.ItemText>
                            <Select.ItemIndicator className="account-modal__type-item-indicator">
                              <Check size={16} />
                            </Select.ItemIndicator>
                          </Select.Item>
                          <Select.Item
                            value="maturity"
                            className="account-modal__type-item"
                          >
                            <Select.ItemText>At Maturity</Select.ItemText>
                            <Select.ItemIndicator className="account-modal__type-item-indicator">
                              <Check size={16} />
                            </Select.ItemIndicator>
                          </Select.Item>
                        </Select.Viewport>
                      </Select.Content>
                    </Select.Portal>
                  </Select.Root>
                </div>

                {/* Bank Name */}
                <div className="account-modal__form-group">
                  <label
                    htmlFor="deposit-bank-name"
                    className="account-modal__label"
                  >
                    Bank/Institution Name
                  </label>
                  <Input
                    id="deposit-bank-name"
                    type="text"
                    value={formData.depositDetails?.bank_name || ''}
                    onChange={(e) => {
                      setFormData({
                        ...formData,
                        depositDetails: {
                          ...formData.depositDetails,
                          principal_amount: formData.balance,
                          interest_rate:
                            formData.depositDetails?.interest_rate || 0,
                          start_date:
                            formData.depositDetails?.start_date || new Date(),
                          tenure_months:
                            formData.depositDetails?.tenure_months || 12,
                          bank_name: e.target.value,
                        },
                      });
                    }}
                    placeholder="HDFC Bank"
                  />
                </div>
              </>
            )}

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
