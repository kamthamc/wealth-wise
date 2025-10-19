/**
 * Accounts Empty State Component
 * Helpful guide when user has no accounts
 */

import './AccountsEmptyState.css';

export interface AccountsEmptyStateProps {
  onAddAccount: () => void;
}

export function AccountsEmptyState({ onAddAccount }: AccountsEmptyStateProps) {
  return (
    <div className="accounts-empty-state" role="region" aria-labelledby="empty-state-title">
      <div className="accounts-empty-state__icon" aria-hidden="true">
        🏦
      </div>

      <h2 id="empty-state-title" className="accounts-empty-state__title">
        No Accounts Yet
      </h2>

      <p className="accounts-empty-state__description">
        Start tracking your finances by adding your first account.
        Connect your bank, wallet, or credit card to get started.
      </p>

      <div className="accounts-empty-state__benefits">
        <h3 className="accounts-empty-state__benefits-title">
          Why add accounts?
        </h3>
        <ul className="accounts-empty-state__benefits-list">
          <li className="accounts-empty-state__benefit">
            <span className="accounts-empty-state__benefit-icon" aria-hidden="true">
              ✓
            </span>
            <span className="accounts-empty-state__benefit-text">
              Track all your money in one place
            </span>
          </li>
          <li className="accounts-empty-state__benefit">
            <span className="accounts-empty-state__benefit-icon" aria-hidden="true">
              ✓
            </span>
            <span className="accounts-empty-state__benefit-text">
              Record income and expenses easily
            </span>
          </li>
          <li className="accounts-empty-state__benefit">
            <span className="accounts-empty-state__benefit-icon" aria-hidden="true">
              ✓
            </span>
            <span className="accounts-empty-state__benefit-text">
              Get insights into your spending habits
            </span>
          </li>
          <li className="accounts-empty-state__benefit">
            <span className="accounts-empty-state__benefit-icon" aria-hidden="true">
              ✓
            </span>
            <span className="accounts-empty-state__benefit-text">
              Set and achieve financial goals
            </span>
          </li>
        </ul>
      </div>

      <button
        type="button"
        className="accounts-empty-state__button"
        onClick={onAddAccount}
        aria-label="Add your first account"
      >
        <span className="accounts-empty-state__button-icon" aria-hidden="true">
          +
        </span>
        Add Your First Account
      </button>

      <div className="accounts-empty-state__tips">
        <p className="accounts-empty-state__tip">
          <strong>Tip:</strong> Start with your primary bank account or most-used
          digital wallet for best results.
        </p>
      </div>
    </div>
  );
}
