/**
 * Quick Actions Component
 * Provides quick access to common tasks
 */

import { useNavigate } from '@tanstack/react-router';
import { ArrowLeftRight, Landmark, Target, Wallet } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { useAccountStore, useTransactionStore } from '@/core/stores';
import './QuickActions.css';

export function QuickActions() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { accounts } = useAccountStore();
  const { transactions } = useTransactionStore();

  const hasAccounts = accounts.length > 0;
  const hasTransactions = transactions.length > 0;

  const quickActions = [
    {
      id: 'add-transaction',
      icon: <ArrowLeftRight size={24} />,
      title: t('pages.transactions.addButton', 'Add Transaction'),
      description: t(
        'quickActions.addTransaction.description',
        'Record income or expense'
      ),
      onClick: () => navigate({ to: '/transactions' }),
      variant: hasAccounts ? 'primary' : 'disabled',
      disabled: !hasAccounts,
      tooltip: hasAccounts
        ? ''
        : t('quickActions.addTransaction.tooltip', 'Add an account first'),
    },
    {
      id: 'add-account',
      icon: <Landmark size={24} />,
      title: t('pages.accounts.addButton', 'Add Account'),
      description: t(
        'quickActions.addAccount.description',
        'Link a bank or wallet'
      ),
      onClick: () => navigate({ to: '/accounts' }),
      variant: 'default',
    },
    {
      id: 'create-budget',
      icon: <Wallet size={24} />,
      title: t('pages.budgets.addButton', 'Create Budget'),
      description: t(
        'quickActions.createBudget.description',
        'Set spending limits'
      ),
      onClick: () => navigate({ to: '/budgets' }),
      variant: hasTransactions ? 'default' : 'disabled',
      disabled: !hasTransactions,
      tooltip: hasTransactions
        ? ''
        : t('quickActions.createBudget.tooltip', 'Add transactions first'),
    },
    {
      id: 'set-goal',
      icon: <Target size={24} />,
      title: t('goals.addGoal', 'Set Goal'),
      description: t('quickActions.setGoal.description', 'Plan for the future'),
      onClick: () => navigate({ to: '/goals' }),
      variant: 'default',
    },
  ];

  return (
    <section className="quick-actions" aria-labelledby="quick-actions-title">
      <h2 id="quick-actions-title" className="quick-actions__title">
        Quick Actions
      </h2>
      <div
        className="quick-actions__grid"
        role="group"
        aria-label="Quick action buttons"
      >
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
              <p className="quick-action-card__description">
                {action.description}
              </p>
            </div>
          </button>
        ))}
      </div>
    </section>
  );
}
