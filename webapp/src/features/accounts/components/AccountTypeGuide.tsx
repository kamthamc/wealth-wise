/**
 * Account Type Guide Component
 * Helps users choose the right account type
 */

import {
  Banknote,
  CheckCircle,
  CreditCard,
  Landmark,
  Smartphone,
  TrendingUp,
  Wallet,
} from 'lucide-react';
import type { ReactNode } from 'react';
import './AccountTypeGuide.css';

export interface AccountTypeInfo {
  type: string;
  icon: ReactNode;
  title: string;
  description: string;
  examples: string[];
  recommended?: boolean;
}

export interface AccountTypeGuideProps {
  onSelectType: (type: string) => void;
  selectedType?: string;
}

const ACCOUNT_TYPES: AccountTypeInfo[] = [
  {
    type: 'bank',
    icon: <Landmark size={32} />,
    title: 'Bank Account',
    description: 'Savings or checking accounts',
    examples: ['HDFC Savings', 'SBI Checking', 'ICICI Salary Account'],
    recommended: true,
  },
  {
    type: 'credit_card',
    icon: <CreditCard size={32} />,
    title: 'Credit Card',
    description: 'Credit cards and charge cards',
    examples: ['HDFC Credit Card', 'Axis Bank Card', 'SBI Credit Card'],
  },
  {
    type: 'upi',
    icon: <Smartphone size={32} />,
    title: 'UPI / Digital Wallet',
    description: 'Paytm, Google Pay, PhonePe',
    examples: ['Paytm Wallet', 'Google Pay', 'PhonePe'],
    recommended: true,
  },
  {
    type: 'cash',
    icon: <Banknote size={32} />,
    title: 'Cash',
    description: 'Physical cash on hand',
    examples: ['Wallet Cash', 'Home Safe', 'Pocket Money'],
  },
  {
    type: 'brokerage',
    icon: <TrendingUp size={32} />,
    title: 'Investment Account',
    description: 'Demat, mutual funds, stocks',
    examples: ['Zerodha', 'Groww', 'Upstox'],
  },
  {
    type: 'wallet',
    icon: <Wallet size={32} />,
    title: 'E-Wallet',
    description: 'Other digital wallets',
    examples: ['Amazon Pay', 'Mobikwik', 'Freecharge'],
  },
];

export function AccountTypeGuide({
  onSelectType,
  selectedType,
}: AccountTypeGuideProps) {
  return (
    <div
      className="account-type-guide"
      role="region"
      aria-labelledby="account-type-guide-title"
    >
      <h3 id="account-type-guide-title" className="account-type-guide__title">
        Choose Account Type
      </h3>
      <p className="account-type-guide__description">
        Select the type that best matches your account
      </p>

      <div
        className="account-type-guide__grid"
        role="group"
        aria-label="Account type options"
      >
        {ACCOUNT_TYPES.map((accountType) => (
          <button
            key={accountType.type}
            type="button"
            className={`account-type-card ${
              selectedType === accountType.type
                ? 'account-type-card--selected'
                : ''
            } ${accountType.recommended ? 'account-type-card--recommended' : ''}`}
            onClick={() => onSelectType(accountType.type)}
            aria-pressed={selectedType === accountType.type}
            aria-label={`${accountType.title}: ${accountType.description}`}
          >
            {accountType.recommended && (
              <span
                className="account-type-card__badge"
                aria-label="Recommended"
              >
                ⭐ Popular
              </span>
            )}

            <span className="account-type-card__icon" aria-hidden="true">
              {accountType.icon}
            </span>

            <div className="account-type-card__content">
              <h4 className="account-type-card__title">{accountType.title}</h4>
              <p className="account-type-card__description">
                {accountType.description}
              </p>
              <div className="account-type-card__examples">
                {accountType.examples.map((example, index) => (
                  <span key={index} className="account-type-card__example">
                    {example}
                  </span>
                ))}
              </div>
            </div>

            {selectedType === accountType.type && (
              <span className="account-type-card__check" aria-hidden="true">
                <CheckCircle size={20} />
              </span>
            )}
          </button>
        ))}
      </div>
    </div>
  );
}
