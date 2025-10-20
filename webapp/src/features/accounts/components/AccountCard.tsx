/**
 * Account Card Component
 * Displays account information in a card format
 */

import { Edit2, Trash2 } from 'lucide-react';
import type { Account } from '@/core/db/types';
import { Badge } from '@/shared/components';
import { formatCurrency, formatRelativeTime } from '@/shared/utils';
import {
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
      <div className="account-card__header">
        <div className="account-card__icon-wrapper">
          <span className="account-card__icon">{accountIcon}</span>
          <Badge variant={accountColor}>{accountTypeName}</Badge>
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
              <Edit2 size={16} />
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
              <Trash2 size={16} />
            </button>
          )}
        </div>
      </div>

      <div className="account-card__content">
        <h3 className="account-card__name">{account.name}</h3>
        <p className="account-card__balance">
          {formatCurrency(account.balance, account.currency)}
        </p>
      </div>

      <div className="account-card__footer">
        <span className="account-card__updated">
          Updated {formatRelativeTime(account.updated_at)}
        </span>
      </div>
    </button>
  );
}
