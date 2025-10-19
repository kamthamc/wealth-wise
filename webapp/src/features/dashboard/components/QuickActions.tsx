/**
 * Quick Actions Component
 * Provides quick access to common tasks
 */

import { useNavigate } from '@tanstack/react-router';
import { useAccountStore, useTransactionStore } from '@/core/stores';
import './QuickActions.css';

export function QuickActions() {
  const navigate = useNavigate();
  const { accounts } = useAccountStore();
  const { transactions } = useTransactionStore();

  const hasAccounts = accounts.length > 0;
  const hasTransactions = transactions.length > 0;

  const quickActions = [
    {
      id: 'add-transaction',
      icon: '💸',
      title: 'Add Transaction',
      description: 'Record income or expense',
      onClick: () => navigate({ to: '/transactions' }),
      variant: hasAccounts ? 'primary' : 'disabled',
      disabled: !hasAccounts,
      tooltip: hasAccounts ? '' : 'Add an account first',
    },
    {
      id: 'add-account',
      icon: '🏦',
      title: 'Add Account',
      description: 'Link a bank or wallet',
      onClick: () => navigate({ to: '/accounts' }),
      variant: 'default',
    },
    {
      id: 'create-budget',
      icon: '💰',
      title: 'Create Budget',
      description: 'Set spending limits',
      onClick: () => navigate({ to: '/budgets' }),
      variant: hasTransactions ? 'default' : 'disabled',
      disabled: !hasTransactions,
      tooltip: hasTransactions ? '' : 'Add transactions first',
    },
    {
      id: 'set-goal',
      icon: '🎯',
      title: 'Set Goal',
      description: 'Plan for the future',
      onClick: () => navigate({ to: '/goals' }),
      variant: 'default',
    },
  ];

  return (
    <section className="quick-actions" aria-labelledby="quick-actions-title">
      <h2 id="quick-actions-title" className="quick-actions__title">
        Quick Actions
      </h2>
      <div className="quick-actions__grid" role="group" aria-label="Quick action buttons">
        {quickActions.map((action) => (
          <button
            key={action.id}
            type="button"
            className={`quick-action-card quick-action-card--${action.variant}`}
            onClick={action.onClick}
            disabled={action.disabled}
            aria-label={`${action.title}: ${action.description}`}
            title={action.tooltip || `${action.title}: ${action.description}`}
          >
            <span className="quick-action-card__icon" aria-hidden="true">
              {action.icon}
            </span>
            <div className="quick-action-card__content">
              <h3 className="quick-action-card__title">{action.title}</h3>
              <p className="quick-action-card__description">{action.description}</p>
            </div>
          </button>
        ))}
      </div>
    </section>
  );
}
