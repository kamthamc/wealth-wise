/**
 * Transaction Type Guide Component
 * Visual guide for understanding transaction types
 */

import {
  ArrowLeftRight,
  CheckCircle,
  TrendingDown,
  TrendingUp,
} from 'lucide-react';
import type { ReactNode } from 'react';
import './TransactionTypeGuide.css';

interface TransactionTypeGuideProps {
  /** Callback when user selects a type */
  onSelectType: (type: 'income' | 'expense' | 'transfer') => void;
  /** Currently selected type */
  selectedType?: 'income' | 'expense' | 'transfer';
}

interface TransactionTypeInfo {
  type: 'income' | 'expense' | 'transfer';
  icon: ReactNode;
  label: string;
  description: string;
  examples: string[];
  color: string;
}

const TRANSACTION_TYPES: TransactionTypeInfo[] = [
  {
    type: 'income',
    icon: <TrendingUp size={32} />,
    label: 'Income',
    description: 'Money coming into your accounts',
    examples: [
      'Salary',
      'Freelance payment',
      'Investment returns',
      'Gifts received',
    ],
    color: 'green',
  },
  {
    type: 'expense',
    icon: <TrendingDown size={32} />,
    label: 'Expense',
    description: 'Money going out of your accounts',
    examples: ['Rent', 'Groceries', 'Utilities', 'Shopping', 'Transportation'],
    color: 'red',
  },
  {
    type: 'transfer',
    icon: <ArrowLeftRight size={32} />,
    label: 'Transfer',
    description: 'Moving money between your accounts',
    examples: ['Bank to wallet', 'Savings to checking', 'Cash withdrawal'],
    color: 'blue',
  },
];

export function TransactionTypeGuide({
  onSelectType,
  selectedType,
}: TransactionTypeGuideProps) {
  return (
    <div className="transaction-type-guide">
      <h3 className="transaction-type-guide__title">Choose Transaction Type</h3>
      <p className="transaction-type-guide__subtitle">
        Select the type that best describes your transaction
      </p>

      <div className="transaction-type-guide__grid">
        {TRANSACTION_TYPES.map((txnType) => {
          const isSelected = selectedType === txnType.type;
          return (
            <button
              key={txnType.type}
              type="button"
              className={`type-card type-card--${txnType.color} ${
                isSelected ? 'type-card--selected' : ''
              }`}
              onClick={() => onSelectType(txnType.type)}
              aria-pressed={isSelected}
              aria-label={`${txnType.label}: ${txnType.description}`}
            >
              {/* Icon */}
              <div className="type-card__icon" aria-hidden="true">
                {txnType.icon}
              </div>

              {/* Label */}
              <h4 className="type-card__label">{txnType.label}</h4>

              {/* Description */}
              <p className="type-card__description">{txnType.description}</p>

              {/* Examples */}
              <div className="type-card__examples">
                <span className="examples-label">Examples:</span>
                <ul className="examples-list">
                  {txnType.examples.slice(0, 3).map((example) => (
                    <li key={example}>{example}</li>
                  ))}
                </ul>
              </div>

              {/* Selected Indicator */}
              {isSelected && (
                <div className="type-card__selected-badge" aria-hidden="true">
                  <CheckCircle size={16} /> Selected
                </div>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}
