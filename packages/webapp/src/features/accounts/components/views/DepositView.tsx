/**
 * Deposit Account View
 * Displays deposit-specific information for FD, RD, PPF, NSC, etc.
 */

import { DollarSign, PiggyBank, TrendingUp, Users } from 'lucide-react';
import { useMemo } from 'react';
import type { Account, DepositDetails } from '@/core/db/types';
import { Card, ProgressBar, StatCard } from '@/shared/components';
import { formatCurrency, formatDate } from '@/shared/utils';
import './DepositView.css';

export interface DepositViewProps {
  account: Account;
  depositDetails?: DepositDetails;
}

export function DepositView({ account, depositDetails }: DepositViewProps) {
  // Calculate days until maturity
  const daysUntilMaturity = useMemo(() => {
    if (!depositDetails?.maturity_date) return null;
    const maturityDate = new Date(depositDetails.maturity_date);
    const today = new Date();
    const diffTime = maturityDate.getTime() - today.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  }, [depositDetails?.maturity_date]);

  // Calculate tenure completion percentage
  const tenureCompletion = useMemo(() => {
    if (!depositDetails) return 0;
    return (
      (depositDetails.completed_months / depositDetails.tenure_months) * 100
    );
  }, [depositDetails]);

  // Calculate returns percentage
  const returnsPercentage = useMemo(() => {
    if (!depositDetails?.principal_amount) return 0;
    return (
      (depositDetails.total_interest_earned / depositDetails.principal_amount) *
      100
    );
  }, [depositDetails]);

  // Get maturity status
  const getMaturityStatus = () => {
    if (!daysUntilMaturity) return { text: 'Unknown', color: 'default' };
    if (daysUntilMaturity < 0) return { text: 'Matured', color: 'success' };
    if (daysUntilMaturity <= 30)
      return { text: 'Maturing Soon', color: 'warning' };
    return { text: 'Active', color: 'default' };
  };

  const maturityStatus = getMaturityStatus();

  if (!depositDetails) {
    return (
      <div className="deposit-view">
        <Card>
          <div className="deposit-view__empty">
            <PiggyBank size={48} />
            <h3>Deposit Details Not Available</h3>
            <p>
              Add deposit details to see interest rates, maturity information,
              and returns.
            </p>
          </div>
        </Card>
      </div>
    );
  }

  return (
    <div className="deposit-view">
      {/* Header */}
      <div className="deposit-view__header">
        <h2>Deposit Overview</h2>
        {depositDetails.bank_name && (
          <span className="deposit-view__bank">{depositDetails.bank_name}</span>
        )}
      </div>

      {/* Maturity Card */}
      <Card className="deposit-view__maturity-card">
        <div className="deposit-view__maturity-header">
          <div>
            <h3>Maturity Amount</h3>
            <p className="deposit-view__maturity-amount">
              {formatCurrency(depositDetails.maturity_amount, account.currency)}
            </p>
            <span
              className={`deposit-view__status deposit-view__status--${maturityStatus.color}`}
            >
              {maturityStatus.text}
            </span>
          </div>
          <div className="deposit-view__maturity-icon">
            <PiggyBank size={32} />
          </div>
        </div>

        {daysUntilMaturity !== null && daysUntilMaturity > 0 && (
          <div className="deposit-view__countdown">
            <div className="deposit-view__countdown-header">
              <span>Time to Maturity</span>
              <span className="deposit-view__countdown-days">
                {daysUntilMaturity} {daysUntilMaturity === 1 ? 'day' : 'days'}
              </span>
            </div>
            <ProgressBar
              value={depositDetails.completed_months}
              max={depositDetails.tenure_months}
              variant="success"
            />
            <div className="deposit-view__countdown-details">
              <span>Completed: {depositDetails.completed_months} months</span>
              <span>Remaining: {depositDetails.remaining_months} months</span>
            </div>
          </div>
        )}
      </Card>

      {/* Stats Grid */}
      <div className="deposit-view__stats">
        <StatCard
          label="Principal Amount"
          value={formatCurrency(
            depositDetails.principal_amount,
            account.currency
          )}
          icon={<DollarSign size={20} />}
        />

        <StatCard
          label="Current Value"
          value={formatCurrency(depositDetails.current_value, account.currency)}
          icon={<TrendingUp size={20} />}
        />

        <StatCard
          label="Interest Earned"
          value={formatCurrency(
            depositDetails.total_interest_earned,
            account.currency
          )}
          icon={<TrendingUp size={20} />}
          variant="success"
        />

        <StatCard
          label="Interest Rate"
          value={`${depositDetails.interest_rate}% p.a.`}
          icon={<TrendingUp size={20} />}
        />
      </div>

      {/* Deposit Details */}
      <Card>
        <h3>Deposit Details</h3>
        <div className="deposit-view__details">
          <div className="deposit-view__detail-row">
            <span>Start Date</span>
            <span className="deposit-view__detail-value">
              {formatDate(depositDetails.start_date)}
            </span>
          </div>

          <div className="deposit-view__detail-row">
            <span>Maturity Date</span>
            <span className="deposit-view__detail-value">
              {formatDate(depositDetails.maturity_date)}
            </span>
          </div>

          <div className="deposit-view__detail-row">
            <span>Tenure</span>
            <span className="deposit-view__detail-value">
              {depositDetails.tenure_months} months (
              {Math.floor(depositDetails.tenure_months / 12)} years)
            </span>
          </div>

          <div className="deposit-view__detail-row">
            <span>Interest Payout</span>
            <span className="deposit-view__detail-value">
              {depositDetails.interest_payout_frequency
                ?.replace('_', ' ')
                .charAt(0)
                .toUpperCase() +
                depositDetails.interest_payout_frequency?.slice(1) ||
                'Not specified'}
            </span>
          </div>

          {depositDetails.last_interest_date && (
            <div className="deposit-view__detail-row">
              <span>Last Interest Paid</span>
              <span className="deposit-view__detail-value">
                {formatDate(depositDetails.last_interest_date)}
              </span>
            </div>
          )}

          <div className="deposit-view__detail-row">
            <span>Completion</span>
            <span className="deposit-view__detail-value">
              {tenureCompletion.toFixed(1)}%
            </span>
          </div>

          <div className="deposit-view__detail-row">
            <span>Returns</span>
            <span className="deposit-view__detail-value deposit-view__detail-value--success">
              +{returnsPercentage.toFixed(2)}%
            </span>
          </div>
        </div>
      </Card>

      {/* Tax Information */}
      {(depositDetails.is_tax_saving || depositDetails.tds_deducted > 0) && (
        <Card>
          <h3>Tax Information</h3>
          <div className="deposit-view__tax">
            {depositDetails.is_tax_saving && (
              <div className="deposit-view__tax-item">
                <div className="deposit-view__tax-icon">🛡️</div>
                <div>
                  <span className="deposit-view__tax-label">
                    Tax Saving Scheme
                  </span>
                  {depositDetails.tax_deduction_section && (
                    <span className="deposit-view__tax-value">
                      Section {depositDetails.tax_deduction_section}
                    </span>
                  )}
                </div>
              </div>
            )}

            {depositDetails.tds_deducted > 0 && (
              <div className="deposit-view__tax-item">
                <div className="deposit-view__tax-icon">📊</div>
                <div>
                  <span className="deposit-view__tax-label">TDS Deducted</span>
                  <span className="deposit-view__tax-value">
                    {formatCurrency(
                      depositDetails.tds_deducted,
                      account.currency
                    )}
                  </span>
                </div>
              </div>
            )}
          </div>
        </Card>
      )}

      {/* Institution Details */}
      {(depositDetails.bank_name ||
        depositDetails.branch ||
        depositDetails.account_number) && (
        <Card>
          <h3>Institution Details</h3>
          <div className="deposit-view__institution">
            {depositDetails.bank_name && (
              <div className="deposit-view__institution-row">
                <span>Bank Name</span>
                <span className="deposit-view__institution-value">
                  {depositDetails.bank_name}
                </span>
              </div>
            )}

            {depositDetails.branch && (
              <div className="deposit-view__institution-row">
                <span>Branch</span>
                <span className="deposit-view__institution-value">
                  {depositDetails.branch}
                </span>
              </div>
            )}

            {depositDetails.account_number && (
              <div className="deposit-view__institution-row">
                <span>Account Number</span>
                <span className="deposit-view__institution-value">
                  {depositDetails.account_number}
                </span>
              </div>
            )}

            {depositDetails.certificate_number && (
              <div className="deposit-view__institution-row">
                <span>Certificate Number</span>
                <span className="deposit-view__institution-value">
                  {depositDetails.certificate_number}
                </span>
              </div>
            )}
          </div>
        </Card>
      )}

      {/* Nominee Details */}
      {(depositDetails.nominee_name || depositDetails.nominee_relationship) && (
        <Card>
          <h3>Nominee Information</h3>
          <div className="deposit-view__nominee">
            <Users size={24} className="deposit-view__nominee-icon" />
            <div className="deposit-view__nominee-details">
              {depositDetails.nominee_name && (
                <div>
                  <span className="deposit-view__nominee-label">
                    Nominee Name
                  </span>
                  <span className="deposit-view__nominee-value">
                    {depositDetails.nominee_name}
                  </span>
                </div>
              )}
              {depositDetails.nominee_relationship && (
                <div>
                  <span className="deposit-view__nominee-label">
                    Relationship
                  </span>
                  <span className="deposit-view__nominee-value">
                    {depositDetails.nominee_relationship}
                  </span>
                </div>
              )}
            </div>
          </div>
        </Card>
      )}

      {/* Features */}
      <Card>
        <h3>Features & Options</h3>
        <div className="deposit-view__features">
          <div
            className={`deposit-view__feature ${depositDetails.auto_renewal ? 'deposit-view__feature--active' : ''}`}
          >
            <div className="deposit-view__feature-icon">
              {depositDetails.auto_renewal ? '✅' : '❌'}
            </div>
            <span>Auto Renewal</span>
          </div>

          <div
            className={`deposit-view__feature ${depositDetails.premature_withdrawal_allowed ? 'deposit-view__feature--active' : ''}`}
          >
            <div className="deposit-view__feature-icon">
              {depositDetails.premature_withdrawal_allowed ? '✅' : '❌'}
            </div>
            <span>Premature Withdrawal</span>
          </div>

          <div
            className={`deposit-view__feature ${depositDetails.loan_against_deposit_allowed ? 'deposit-view__feature--active' : ''}`}
          >
            <div className="deposit-view__feature-icon">
              {depositDetails.loan_against_deposit_allowed ? '✅' : '❌'}
            </div>
            <span>Loan Against Deposit</span>
          </div>
        </div>
      </Card>

      {/* Notes */}
      {depositDetails.notes && (
        <Card>
          <h3>Notes</h3>
          <p className="deposit-view__notes">{depositDetails.notes}</p>
        </Card>
      )}
    </div>
  );
}
