/**
 * Deposit Details Component
 * Displays detailed information for Fixed Deposits and other deposit schemes
 */

import {
  AlertCircle,
  Calendar,
  Clock,
  FileText,
  Percent,
  TrendingUp,
} from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import type { DepositDetails as DepositDetailsType } from '@/core/types';
import { useDepositStore } from '@/core/stores';
import { formatCurrency, formatDate } from '@/shared/utils';
import './DepositDetails.css';

export interface DepositDetailsProps {
  accountId: string;
  accountName: string;
  accountType: string;
}

export function DepositDetails({
  accountId,
  accountName,
  accountType,
}: DepositDetailsProps) {
  const {
    deposits,
    interestPayments,
    fetchDeposits,
    fetchInterestPayments,
    updateDepositProgress,
    isLoading,
  } = useDepositStore();

  const [selectedDeposit, setSelectedDeposit] =
    useState<DepositDetailsType | null>(null);

  // Fetch deposits for this account
  useEffect(() => {
    fetchDeposits(accountId);
  }, [accountId, fetchDeposits]);

  // Get deposit for this account
  const deposit = useMemo(() => {
    return deposits.find((d) => d.account_id === accountId) || null;
  }, [deposits, accountId]);

  // Update progress when deposit changes
  useEffect(() => {
    if (deposit) {
      updateDepositProgress(deposit.id);
      setSelectedDeposit(deposit);
    }
  }, [deposit, updateDepositProgress]);

  // Fetch interest payments when deposit is selected
  useEffect(() => {
    if (selectedDeposit) {
      fetchInterestPayments(selectedDeposit.id);
    }
  }, [selectedDeposit, fetchInterestPayments]);

  // Calculate progress percentage
  const progressPercentage = useMemo(() => {
    if (!selectedDeposit) return 0;
    return (
      (selectedDeposit.completed_months / selectedDeposit.tenure_months) * 100
    );
  }, [selectedDeposit]);

  // Calculate days until maturity
  const daysUntilMaturity = useMemo(() => {
    if (!selectedDeposit) return 0;
    const today = new Date();
    const maturity = new Date(selectedDeposit.maturity_date);
    const diffTime = maturity.getTime() - today.getTime();
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }, [selectedDeposit]);

  // Get interest payments for this deposit
  const depositInterestPayments = useMemo(() => {
    if (!selectedDeposit) return [];
    return interestPayments
      .filter((p) => p.deposit_id === selectedDeposit.id)
      .sort(
        (a, b) =>
          new Date(b.payment_date).getTime() -
          new Date(a.payment_date).getTime()
      );
  }, [selectedDeposit, interestPayments]);

  if (isLoading && !deposit) {
    return (
      <div className="deposit-details__loading">
        <div className="spinner" />
        <p>Loading deposit details...</p>
      </div>
    );
  }

  if (!deposit) {
    return (
      <div className="deposit-details__empty">
        <AlertCircle size={48} />
        <h3>No Deposit Details Found</h3>
        <p>This {accountType} account doesn't have deposit details yet.</p>
      </div>
    );
  }

  return (
    <div className="deposit-details">
      {/* Overview Section */}
      <div className="deposit-details__overview">
        <h2 className="deposit-details__title">{accountName} Details</h2>

        <div className="deposit-details__stats-grid">
          {/* Principal Amount */}
          <div className="stat-card">
            <div className="stat-card__icon">💰</div>
            <div className="stat-card__content">
              <span className="stat-card__label">Principal Amount</span>
              <span className="stat-card__value">
                {formatCurrency(deposit.principal_amount, 'INR')}
              </span>
            </div>
          </div>

          {/* Current Value */}
          <div className="stat-card stat-card--primary">
            <div className="stat-card__icon">📊</div>
            <div className="stat-card__content">
              <span className="stat-card__label">Current Value</span>
              <span className="stat-card__value">
                {formatCurrency(deposit.current_value, 'INR')}
              </span>
            </div>
          </div>

          {/* Maturity Amount */}
          <div className="stat-card stat-card--success">
            <div className="stat-card__icon">🎯</div>
            <div className="stat-card__content">
              <span className="stat-card__label">Maturity Amount</span>
              <span className="stat-card__value">
                {formatCurrency(deposit.maturity_amount, 'INR')}
              </span>
            </div>
          </div>

          {/* Interest Rate */}
          <div className="stat-card">
            <div className="stat-card__icon">
              <Percent size={24} />
            </div>
            <div className="stat-card__content">
              <span className="stat-card__label">Interest Rate</span>
              <span className="stat-card__value">
                {deposit.interest_rate}% p.a.
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Progress Section */}
      <div className="deposit-details__progress-section">
        <div className="progress-header">
          <h3>Deposit Progress</h3>
          <span className="progress-percentage">
            {progressPercentage.toFixed(1)}% Complete
          </span>
        </div>

        <div className="progress-bar">
          <div
            className="progress-bar__fill"
            style={{ width: `${Math.min(progressPercentage, 100)}%` }}
          />
        </div>

        <div className="progress-info">
          <div className="progress-info__item">
            <Clock size={16} />
            <span>
              {deposit.completed_months} of {deposit.tenure_months} months
              completed
            </span>
          </div>
          <div className="progress-info__item">
            <Calendar size={16} />
            <span>
              {daysUntilMaturity > 0
                ? `${daysUntilMaturity} days until maturity`
                : 'Matured'}
            </span>
          </div>
        </div>
      </div>

      {/* Details Grid */}
      <div className="deposit-details__info-grid">
        <div className="info-card">
          <h4>Tenure Information</h4>
          <div className="info-card__content">
            <div className="info-row">
              <span className="info-label">Start Date</span>
              <span className="info-value">
                {formatDate(deposit.start_date)}
              </span>
            </div>
            <div className="info-row">
              <span className="info-label">Maturity Date</span>
              <span className="info-value">
                {formatDate(deposit.maturity_date)}
              </span>
            </div>
            <div className="info-row">
              <span className="info-label">Total Tenure</span>
              <span className="info-value">
                {deposit.tenure_months} months (
                {(deposit.tenure_months / 12).toFixed(1)} years)
              </span>
            </div>
            <div className="info-row">
              <span className="info-label">Remaining</span>
              <span className="info-value">
                {deposit.remaining_months} months
              </span>
            </div>
          </div>
        </div>

        <div className="info-card">
          <h4>Interest Details</h4>
          <div className="info-card__content">
            <div className="info-row">
              <span className="info-label">Interest Rate</span>
              <span className="info-value">
                {deposit.interest_rate}% per annum
              </span>
            </div>
            <div className="info-row">
              <span className="info-label">Payout Frequency</span>
              <span className="info-value">
                {deposit.interest_payout_frequency}
              </span>
            </div>
            <div className="info-row">
              <span className="info-label">Total Interest Earned</span>
              <span className="info-value info-value--success">
                {formatCurrency(deposit.total_interest_earned, 'INR')}
              </span>
            </div>
            <div className="info-row">
              <span className="info-label">Expected Total Interest</span>
              <span className="info-value">
                {formatCurrency(
                  deposit.maturity_amount - deposit.principal_amount,
                  'INR'
                )}
              </span>
            </div>
          </div>
        </div>

        <div className="info-card">
          <h4>Tax Information</h4>
          <div className="info-card__content">
            <div className="info-row">
              <span className="info-label">TDS Deducted</span>
              <span className="info-value info-value--danger">
                {formatCurrency(deposit.tds_deducted, 'INR')}
              </span>
            </div>
            <div className="info-row">
              <span className="info-label">Tax Saving</span>
              <span className="info-value">
                {deposit.is_tax_saving
                  ? `Yes (${deposit.tax_deduction_section || 'N/A'})`
                  : 'No'}
              </span>
            </div>
            <div className="info-row">
              <span className="info-label">Net Interest Received</span>
              <span className="info-value">
                {formatCurrency(
                  deposit.total_interest_earned - deposit.tds_deducted,
                  'INR'
                )}
              </span>
            </div>
          </div>
        </div>

        {deposit.bank_name && (
          <div className="info-card">
            <h4>Institution Details</h4>
            <div className="info-card__content">
              {deposit.bank_name && (
                <div className="info-row">
                  <span className="info-label">Bank/Institution</span>
                  <span className="info-value">{deposit.bank_name}</span>
                </div>
              )}
              {deposit.branch && (
                <div className="info-row">
                  <span className="info-label">Branch</span>
                  <span className="info-value">{deposit.branch}</span>
                </div>
              )}
              {deposit.account_number && (
                <div className="info-row">
                  <span className="info-label">Account Number</span>
                  <span className="info-value">{deposit.account_number}</span>
                </div>
              )}
              {deposit.certificate_number && (
                <div className="info-row">
                  <span className="info-label">Certificate Number</span>
                  <span className="info-value">
                    {deposit.certificate_number}
                  </span>
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Options */}
      <div className="deposit-details__options">
        <h4>Deposit Features</h4>
        <div className="options-grid">
          <div
            className={`option-badge ${deposit.auto_renewal ? 'option-badge--active' : ''}`}
          >
            {deposit.auto_renewal ? '✓' : '✗'} Auto Renewal
          </div>
          <div
            className={`option-badge ${deposit.premature_withdrawal_allowed ? 'option-badge--active' : ''}`}
          >
            {deposit.premature_withdrawal_allowed ? '✓' : '✗'} Premature
            Withdrawal
          </div>
          <div
            className={`option-badge ${deposit.loan_against_deposit_allowed ? 'option-badge--active' : ''}`}
          >
            {deposit.loan_against_deposit_allowed ? '✓' : '✗'} Loan Against
            Deposit
          </div>
        </div>
      </div>

      {/* Interest Payments History */}
      {depositInterestPayments.length > 0 && (
        <div className="deposit-details__payments">
          <h3>
            <FileText size={20} /> Interest Payment History
          </h3>
          <div className="payments-table">
            <div className="payments-table__header">
              <span>Date</span>
              <span>Quarter/Month</span>
              <span>Interest</span>
              <span>TDS</span>
              <span>Net Amount</span>
            </div>
            {depositInterestPayments.map((payment) => (
              <div key={payment.id} className="payments-table__row">
                <span>{formatDate(payment.payment_date)}</span>
                <span>
                  {payment.quarter ? `Q${payment.quarter}` : '-'}{' '}
                  {payment.financial_year}
                </span>
                <span>{formatCurrency(payment.interest_amount, 'INR')}</span>
                <span className="amount-danger">
                  {formatCurrency(payment.tds_deducted, 'INR')}
                </span>
                <span className="amount-success">
                  {formatCurrency(payment.net_amount, 'INR')}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Status Badge */}
      <div className={`deposit-status deposit-status--${deposit.status}`}>
        {deposit.status === 'active' && <TrendingUp size={16} />}
        {deposit.status === 'matured' && '✓'}
        {/* {deposit.status === 'pre_closed' && '⚠'} */}
        <span>Status: {deposit.status.replace('_', ' ').toUpperCase()}</span>
      </div>
    </div>
  );
}
