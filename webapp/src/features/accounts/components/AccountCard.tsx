/**
 * Account Card Component
 * Displays account information in a card format
 */

import type { Account } from '@/core/db/types';
import { Badge } from '@/shared/components';
import { formatCurrency, formatRelativeTime } from '@/shared/utils';
import {
  formatAccountIdentifier,
  getAccountIcon,
  getAccountTypeColor,
  getAccountTypeName,
} from '../utils/accountHelpers';
import './AccountCard.css';

export interface AccountCardProps {
  account: Account;
  onEdit?: (account: Account) => void;
  onDelete?: (account: Account) => void;
  onClick?: (account: Account) => void;
}

export function AccountCard({
  account,
  onEdit,
  onDelete,
  onClick,
}: AccountCardProps) {
  const accountColor = getAccountTypeColor(account.type);
  const accountIcon = getAccountIcon(account.type);
  const accountTypeName = getAccountTypeName(account.type);

  const handleCardClick = (e: React.MouseEvent) => {
    // Don't trigger card click if clicking action buttons
    if ((e.target as HTMLElement).closest('.account-card__action-button')) {
      return;
    }
    onClick?.(account);
  };

  const handleEdit = (e: React.MouseEvent) => {
    e.stopPropagation();
    onEdit?.(account);
  };

  const handleDelete = (e: React.MouseEvent) => {
    e.stopPropagation();
    onDelete?.(account);
  };

  return (
    <button type="button" className="account-card" onClick={handleCardClick}>
      <div className="account-card-header">
        <div className="account-card-icon-wrapper">
          <span className="account-card-icon">{accountIcon}</span>
          <Badge variant={accountColor}>{accountTypeName}</Badge>
        </div>
        <div className="account-card-actions">
          <button
            type="button"
            onClick={handleEdit}
            className="account-card-action-btn"
            aria-label="Edit account"
          >
            ✏️
          </button>
          <button
            type="button"
            onClick={handleDelete}
            className="account-card-action-btn account-card-delete-btn"
            aria-label="Delete account"
          >
            🗑️
          </button>
        </div>
      </div>

      <div className="account-card__content">
        <h3 className="account-card__name">{account.name}</h3>
      </div>

      <p className="account-card__balance">
        {formatCurrency(account.balance, account.currency)}
      </p>

      <div className="account-card__footer">
        <div className="account-card__meta">
          <span className="account-card__account-number">
            ID: {formatAccountIdentifier(account.id)}
          </span>
          <span className="account-card__updated">
            Updated {formatRelativeTime(account.updated_at)}
          </span>
        </div>

        <div className="account-card__actions">
          {onEdit && (
            <button
              type="button"
              className="account-card__action-button"
              onClick={handleEdit}
              aria-label={`Edit ${account.name}`}
              title="Edit account"
            >
              ✏️
            </button>
          )}
          {onDelete && (
            <button
              type="button"
              className="account-card__action-button account-card__action-button--delete"
              onClick={handleDelete}
              aria-label={`Delete ${account.name}`}
              title="Delete account"
            >
              🗑️
            </button>
          )}
        </div>
      </div>
    </button>
  );
}
