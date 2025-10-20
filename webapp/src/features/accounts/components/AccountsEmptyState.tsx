/**
 * Accounts Empty State Component
 * Helpful guide when user has no accounts
 */

import { CheckCircle, Landmark } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import './AccountsEmptyState.css';

export interface AccountsEmptyStateProps {
  onAddAccount: () => void;
}

export function AccountsEmptyState({ onAddAccount }: AccountsEmptyStateProps) {
  const { t } = useTranslation();

  return (
    <div
      className="accounts-empty-state"
      role="region"
      aria-labelledby="empty-state-title"
    >
      <div className="accounts-empty-state__icon" aria-hidden="true">
        <Landmark size={48} />
      </div>

      <h2 id="empty-state-title" className="accounts-empty-state__title">
        {t('emptyState.accounts.title')}
      </h2>

      <p className="accounts-empty-state__description">
        {t('emptyState.accounts.description')}
      </p>

      <div className="accounts-empty-state__benefits">
        <h3 className="accounts-empty-state__benefits-title">
          {t('emptyState.accounts.benefits.title')}
        </h3>
        <ul className="accounts-empty-state__benefits-list">
          <li className="accounts-empty-state__benefit">
            <span
              className="accounts-empty-state__benefit-icon"
              aria-hidden="true"
            >
              <CheckCircle size={20} />
            </span>
            <span className="accounts-empty-state__benefit-text">
              {t('emptyState.accounts.benefits.trackMoney')}
            </span>
          </li>
          <li className="accounts-empty-state__benefit">
            <span
              className="accounts-empty-state__benefit-icon"
              aria-hidden="true"
            >
              <CheckCircle size={20} />
            </span>
            <span className="accounts-empty-state__benefit-text">
              {t('emptyState.accounts.benefits.recordTransactions')}
            </span>
          </li>
          <li className="accounts-empty-state__benefit">
            <span
              className="accounts-empty-state__benefit-icon"
              aria-hidden="true"
            >
              <CheckCircle size={20} />
            </span>
            <span className="accounts-empty-state__benefit-text">
              {t('emptyState.accounts.benefits.insights')}
            </span>
          </li>
          <li className="accounts-empty-state__benefit">
            <span
              className="accounts-empty-state__benefit-icon"
              aria-hidden="true"
            >
              <CheckCircle size={20} />
            </span>
            <span className="accounts-empty-state__benefit-text">
              {t('emptyState.accounts.benefits.goals')}
            </span>
          </li>
        </ul>
      </div>

      <button
        type="button"
        className="accounts-empty-state__button"
        onClick={onAddAccount}
        aria-label={t('emptyState.accounts.action')}
      >
        <span className="accounts-empty-state__button-icon" aria-hidden="true">
          +
        </span>
        {t('emptyState.accounts.action')}
      </button>

      <div className="accounts-empty-state__tips">
        <p className="accounts-empty-state__tip">
          <strong>{t('emptyState.accounts.tip.label')}</strong>{' '}
          {t('emptyState.accounts.tip.message')}
        </p>
      </div>
    </div>
  );
}
