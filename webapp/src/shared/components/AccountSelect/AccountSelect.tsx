/**
 * Account Select Component
 * Radix UI Select for choosing accounts with search and icons
 */

import * as Select from '@radix-ui/react-select';
import { Check, ChevronDown, Search } from 'lucide-react';
import { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { Account } from '@/core/db/types';
import { formatCurrency } from '@/shared/utils';
import './AccountSelect.css';

export interface AccountSelectProps {
  /**
   * Currently selected account ID
   */
  value: string;

  /**
   * Callback when account is selected
   */
  onValueChange: (accountId: string) => void;

  /**
   * Available accounts to select from
   */
  accounts: Account[];

  /**
   * Placeholder text when no account selected
   */
  placeholder?: string;

  /**
   * Whether the select is disabled
   */
  disabled?: boolean;

  /**
   * Whether the select is required
   */
  required?: boolean;

  /**
   * Error message to display
   */
  error?: string;

  /**
   * ID for accessibility
   */
  id?: string;

  /**
   * ARIA label for accessibility
   */
  'aria-label'?: string;

  /**
   * ARIA described by for error messages
   */
  'aria-describedby'?: string;
}

export function AccountSelect({
  value,
  onValueChange,
  accounts,
  placeholder = 'Select account...',
  disabled = false,
  required = false,
  error,
  id,
  'aria-label': ariaLabel,
  'aria-describedby': ariaDescribedBy,
}: AccountSelectProps) {
  const { t } = useTranslation();
  const [searchQuery, setSearchQuery] = useState('');

  // Find selected account for display
  const selectedAccount = useMemo(
    () => accounts.find((acc) => acc.id === value),
    [accounts, value]
  );

  // Filter accounts based on search
  const filteredAccounts = useMemo(() => {
    if (!searchQuery.trim()) return accounts;

    const query = searchQuery.toLowerCase();
    return accounts.filter(
      (acc) =>
        acc.name.toLowerCase().includes(query) ||
        acc.type.toLowerCase().includes(query)
    );
  }, [accounts, searchQuery]);

  // Get account icon
  const getAccountIcon = (type: string): string => {
    const icons: Record<string, string> = {
      bank: '🏦',
      credit_card: '💳',
      upi: '📱',
      brokerage: '📈',
      cash: '💵',
      wallet: '👛',
    };
    return icons[type] || '💰';
  };

  return (
    <div className="account-select-wrapper">
      <Select.Root
        value={value}
        onValueChange={onValueChange}
        disabled={disabled}
        required={required}
      >
        <Select.Trigger
          className={`account-select__trigger ${error ? 'account-select__trigger--error' : ''}`}
          aria-label={ariaLabel}
          aria-describedby={ariaDescribedBy}
          aria-invalid={!!error}
          id={id}
        >
          <Select.Value placeholder={placeholder}>
            {selectedAccount && (
              <div className="account-select__value">
                <span className="account-select__icon">
                  {getAccountIcon(selectedAccount.type)}
                </span>
                <div className="account-select__info">
                  <span className="account-select__name">
                    {selectedAccount.name}
                  </span>
                  <span className="account-select__balance">
                    {formatCurrency(
                      selectedAccount.balance,
                      selectedAccount.currency
                    )}
                  </span>
                </div>
              </div>
            )}
          </Select.Value>
          <Select.Icon className="account-select__chevron">
            <ChevronDown size={16} />
          </Select.Icon>
        </Select.Trigger>

        <Select.Portal>
          <Select.Content className="account-select__content" position="popper">
            {/* Search Input */}
            <div className="account-select__search">
              <Search size={16} className="account-select__search-icon" />
              <input
                type="text"
                placeholder="Search accounts..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="account-select__search-input"
                onKeyDown={(e) => {
                  // Prevent Select from closing on search input interaction
                  e.stopPropagation();
                }}
              />
            </div>

            <Select.Viewport className="account-select__viewport">
              {filteredAccounts.length === 0 ? (
                <div className="account-select__empty">
                  {t('accountSelect.noResults')}
                </div>
              ) : (
                filteredAccounts.map((account) => (
                  <Select.Item
                    key={account.id}
                    value={account.id}
                    className="account-select__item"
                  >
                    <div className="account-select__item-content">
                      <span className="account-select__icon">
                        {getAccountIcon(account.type)}
                      </span>
                      <div className="account-select__info">
                        <span className="account-select__name">
                          {account.name}
                        </span>
                        <span className="account-select__type">
                          {account.type.replace('_', ' ')}
                        </span>
                      </div>
                      <span className="account-select__balance">
                        {formatCurrency(account.balance, account.currency)}
                      </span>
                    </div>
                    <Select.ItemIndicator className="account-select__indicator">
                      <Check size={16} />
                    </Select.ItemIndicator>
                  </Select.Item>
                ))
              )}
            </Select.Viewport>
          </Select.Content>
        </Select.Portal>
      </Select.Root>

      {error && <span className="account-select__error">{error}</span>}
    </div>
  );
}
