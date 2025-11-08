/**
 * Credit Card Account View
 * Displays credit card specific information including credit limit, billing cycle, rewards, etc.
 */

import {
  Calendar,
  CreditCard,
  DollarSign,
  Gift,
  TrendingDown,
  TrendingUp,
} from 'lucide-react';
import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import type { Account } from '@/core/types';
import type { CreditCardDetails } from '@/core/db/types';
import { Card, ProgressBar, StatCard } from '@/shared/components';
import { formatCurrency, formatDate } from '@/utils';
import { usePreferences } from '@/hooks/usePreferences';
import './CreditCardView.css';

export interface CreditCardViewProps {
  account: Account;
  creditCardDetails?: CreditCardDetails;
}

export function CreditCardView({
  account,
  creditCardDetails,
}: CreditCardViewProps) {
  const { t } = useTranslation();
  const { preferences } = usePreferences();
  // Calculate credit utilization percentage
  const creditUtilization = useMemo(() => {
    if (!creditCardDetails) return 0;
    return (
      (creditCardDetails.current_balance / creditCardDetails.credit_limit) * 100
    );
  }, [creditCardDetails]);

  // Get utilization status color
  const getUtilizationColor = (utilization: number) => {
    if (utilization >= 80) return 'danger';
    if (utilization >= 50) return 'warning';
    return 'success';
  };

  // Calculate days until payment due
  const daysUntilDue = useMemo(() => {
    if (!creditCardDetails?.payment_due_date) return null;
    const dueDate = new Date(creditCardDetails.payment_due_date);
    const today = new Date();
    const diffTime = dueDate.getTime() - today.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  }, [creditCardDetails?.payment_due_date]);

  if (!creditCardDetails) {
    return (
      <div className="credit-card-view">
        <Card>
          <div className="credit-card-view__empty">
            <CreditCard size={48} />
            <h3>{t('pages.accounts.details.views.creditCard.emptyTitle', 'Credit Card Details Not Available')}</h3>
            <p>
              {t('pages.accounts.details.views.creditCard.emptyDescription', 'Add credit card details to track your spending, payments, and rewards.')}
            </p>
          </div>
        </Card>
      </div>
    );
  }

  return (
    <div className="credit-card-view">
      {/* Credit Limit Overview */}
      <div className="credit-card-view__header">
        <h2>Credit Card Overview</h2>
        {creditCardDetails.issuer_bank && (
          <span className="credit-card-view__bank">
            {creditCardDetails.issuer_bank}
          </span>
        )}
      </div>

      {/* Credit Limit Card */}
      <Card className="credit-card-view__limit-card">
        <div className="credit-card-view__limit-header">
          <div>
            <h3>Credit Limit</h3>
            <p className="credit-card-view__limit-amount">
              {formatCurrency(
                creditCardDetails.credit_limit,
                preferences?.currency || account.currency,
                preferences?.locale || 'en-IN'
              )}
            </p>
          </div>
          <div className="credit-card-view__limit-icon">
            <CreditCard size={32} />
          </div>
        </div>

        <div className="credit-card-view__utilization">
          <div className="credit-card-view__utilization-header">
            <span>Credit Utilization</span>
            <span
              className={`credit-card-view__utilization-percent credit-card-view__utilization-percent--${getUtilizationColor(creditUtilization)}`}
            >
              {creditUtilization.toFixed(1)}%
            </span>
          </div>
          <ProgressBar
            value={creditCardDetails.current_balance}
            max={creditCardDetails.credit_limit}
            variant={getUtilizationColor(creditUtilization)}
          />
          <div className="credit-card-view__utilization-details">
            <span>
              Used:{' '}
              {formatCurrency(
                creditCardDetails.current_balance,
                preferences?.currency || account.currency,
                preferences?.locale || 'en-IN'
              )}
            </span>
            <span>
              Available:{' '}
              {formatCurrency(
                creditCardDetails.available_credit,
                preferences?.currency || account.currency,
                preferences?.locale || 'en-IN'
              )}
            </span>
          </div>
        </div>
      </Card>

      {/* Stats Grid */}
      <div className="credit-card-view__stats">
        <StatCard
          label={t('pages.accounts.details.views.creditCard.currentBalance', 'Current Balance')}
          value={formatCurrency(
            creditCardDetails.current_balance,
            preferences?.currency || account.currency,
            preferences?.locale || 'en-IN'
          )}
          icon={<DollarSign size={20} />}
        />

        <StatCard
          label={t('pages.accounts.details.views.creditCard.minimumDue', 'Minimum Due')}
          value={formatCurrency(
            creditCardDetails.minimum_due,
            preferences?.currency || account.currency,
            preferences?.locale || 'en-IN'
          )}
          icon={<TrendingDown size={20} />}
          variant={creditCardDetails.minimum_due > 0 ? 'warning' : 'default'}
        />

        <StatCard
          label={t('pages.accounts.details.views.creditCard.totalDue', 'Total Due')}
          value={formatCurrency(
            creditCardDetails.total_due,
            preferences?.currency || account.currency,
            preferences?.locale || 'en-IN'
          )}
          icon={<TrendingUp size={20} />}
          variant={creditCardDetails.total_due > 0 ? 'danger' : 'default'}
        />

        <StatCard
          label={t('pages.accounts.details.views.creditCard.rewardsPoints', 'Rewards Points')}
          value={`${creditCardDetails.rewards_points.toLocaleString()} ${creditCardDetails.rewards_value > 0 ? `(≈ ${formatCurrency(creditCardDetails.rewards_value, preferences?.currency || account.currency, preferences?.locale || 'en-IN')})` : 'points'}`}
          icon={<Gift size={20} />}
          variant="success"
        />
      </div>

      {/* Billing Cycle Information */}
      <Card>
        <h3>Billing Cycle</h3>
        <div className="credit-card-view__billing">
          <div className="credit-card-view__billing-item">
            <Calendar size={20} />
            <div>
              <span className="credit-card-view__billing-label">
                Billing Cycle Day
              </span>
              <span className="credit-card-view__billing-value">
                {creditCardDetails.billing_cycle_day} of every month
              </span>
            </div>
          </div>

          {creditCardDetails.statement_date && (
            <div className="credit-card-view__billing-item">
              <Calendar size={20} />
              <div>
                <span className="credit-card-view__billing-label">
                  Last Statement Date
                </span>
                <span className="credit-card-view__billing-value">
                  {formatDate(
                    creditCardDetails.statement_date,
                    preferences?.dateFormat || 'DD/MM/YYYY',
                    preferences?.locale || 'en-IN'
                  )}
                </span>
              </div>
            </div>
          )}

          {creditCardDetails.payment_due_date && (
            <div className="credit-card-view__billing-item">
              <Calendar size={20} />
              <div>
                <span className="credit-card-view__billing-label">
                  Payment Due Date
                </span>
                <span className="credit-card-view__billing-value">
                  {formatDate(
                    creditCardDetails.payment_due_date,
                    preferences?.dateFormat || 'DD/MM/YYYY',
                    preferences?.locale || 'en-IN'
                  )}
                  {daysUntilDue !== null && (
                    <span
                      className={`credit-card-view__days-until ${daysUntilDue <= 3 ? 'credit-card-view__days-until--urgent' : ''}`}
                    >
                      {daysUntilDue > 0
                        ? `(${daysUntilDue} days left)`
                        : '(Overdue!)'}
                    </span>
                  )}
                </span>
              </div>
            </div>
          )}
        </div>
      </Card>

      {/* Card Details */}
      <Card>
        <h3>Card Details</h3>
        <div className="credit-card-view__details">
          {creditCardDetails.card_network && (
            <div className="credit-card-view__detail-row">
              <span>Network</span>
              <span className="credit-card-view__detail-value">
                {creditCardDetails.card_network.toUpperCase()}
              </span>
            </div>
          )}

          {creditCardDetails.last_four_digits && (
            <div className="credit-card-view__detail-row">
              <span>Card Number</span>
              <span className="credit-card-view__detail-value">
                •••• •••• •••• {creditCardDetails.last_four_digits}
              </span>
            </div>
          )}

          {creditCardDetails.expiry_date && (
            <div className="credit-card-view__detail-row">
              <span>Expiry Date</span>
              <span className="credit-card-view__detail-value">
                {formatDate(creditCardDetails.expiry_date, preferences?.locale || 'en-IN')}
              </span>
            </div>
          )}

          {creditCardDetails.interest_rate && (
            <div className="credit-card-view__detail-row">
              <span>Interest Rate</span>
              <span className="credit-card-view__detail-value">
                {creditCardDetails.interest_rate}% p.a.
              </span>
            </div>
          )}

          <div className="credit-card-view__detail-row">
            <span>Annual Fee</span>
            <span className="credit-card-view__detail-value">
              {creditCardDetails.annual_fee > 0
                ? formatCurrency(
                    creditCardDetails.annual_fee,
                    preferences?.currency || account.currency,
                    preferences?.locale || 'en-IN'
                  )
                : 'Free'}
            </span>
          </div>

          <div className="credit-card-view__detail-row">
            <span>Autopay</span>
            <span
              className={`credit-card-view__detail-badge ${creditCardDetails.autopay_enabled ? 'credit-card-view__detail-badge--active' : ''}`}
            >
              {creditCardDetails.autopay_enabled ? 'Enabled' : 'Disabled'}
            </span>
          </div>
        </div>
      </Card>

      {/* Rewards & Cashback */}
      {(creditCardDetails.cashback_earned > 0 ||
        creditCardDetails.rewards_points > 0) && (
        <Card>
          <h3>Rewards & Benefits</h3>
          <div className="credit-card-view__rewards">
            {creditCardDetails.cashback_earned > 0 && (
              <div className="credit-card-view__reward-item">
                <div className="credit-card-view__reward-icon">💰</div>
                <div>
                  <span className="credit-card-view__reward-label">
                    Total Cashback Earned
                  </span>
                  <span className="credit-card-view__reward-value">
                    {formatCurrency(
                      creditCardDetails.cashback_earned,
                      account.currency
                    )}
                  </span>
                </div>
              </div>
            )}

            {creditCardDetails.rewards_points > 0 && (
              <div className="credit-card-view__reward-item">
                <div className="credit-card-view__reward-icon">🎁</div>
                <div>
                  <span className="credit-card-view__reward-label">
                    Rewards Points Balance
                  </span>
                  <span className="credit-card-view__reward-value">
                    {creditCardDetails.rewards_points.toLocaleString()} points
                  </span>
                  {creditCardDetails.rewards_value > 0 && (
                    <span className="credit-card-view__reward-sublabel">
                      Estimated value:{' '}
                      {formatCurrency(
                        creditCardDetails.rewards_value,
                        account.currency
                      )}
                    </span>
                  )}
                </div>
              </div>
            )}
          </div>
        </Card>
      )}

      {/* Notes */}
      {creditCardDetails.notes && (
        <Card>
          <h3>Notes</h3>
          <p className="credit-card-view__notes">{creditCardDetails.notes}</p>
        </Card>
      )}
    </div>
  );
}
