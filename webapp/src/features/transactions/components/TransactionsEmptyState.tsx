/**
 * Transactions Empty State Component
 * Engaging empty state for transactions page
 */

import './TransactionsEmptyState.css';

interface TransactionsEmptyStateProps {
  /** Callback when user wants to add first transaction */
  onAddTransaction: () => void;
}

export function TransactionsEmptyState({ onAddTransaction }: TransactionsEmptyStateProps) {
  return (
    <div className="transactions-empty-state">
      {/* Animated Icon */}
      <div className="transactions-empty-state__icon" aria-hidden="true">
        💸
      </div>

      {/* Main Message */}
      <h2 className="transactions-empty-state__title">
        Start Tracking Your Money
      </h2>
      <p className="transactions-empty-state__description">
        Record every income and expense to gain complete control of your finances
      </p>

      {/* Benefits List */}
      <div className="transactions-empty-state__benefits">
        <div className="benefit-item">
          <span className="benefit-item__icon" aria-hidden="true">✅</span>
          <span className="benefit-item__text">See where your money goes</span>
        </div>
        <div className="benefit-item">
          <span className="benefit-item__icon" aria-hidden="true">✅</span>
          <span className="benefit-item__text">Track spending by category</span>
        </div>
        <div className="benefit-item">
          <span className="benefit-item__icon" aria-hidden="true">✅</span>
          <span className="benefit-item__text">Identify savings opportunities</span>
        </div>
        <div className="benefit-item">
          <span className="benefit-item__icon" aria-hidden="true">✅</span>
          <span className="benefit-item__text">Make informed financial decisions</span>
        </div>
      </div>

      {/* Call to Action */}
      <button
        type="button"
        className="transactions-empty-state__cta"
        onClick={onAddTransaction}
      >
        Record Your First Transaction
      </button>

      {/* Helpful Tip */}
      <div className="transactions-empty-state__tip">
        <span className="tip-icon" aria-hidden="true">💡</span>
        <p className="tip-text">
          <strong>Tip:</strong> Record transactions as they happen to build a complete financial picture
        </p>
      </div>
    </div>
  );
}
