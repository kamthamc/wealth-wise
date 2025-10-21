/**
 * Deposit Details Card Component
 * Displays deposit-specific information like interest rate, maturity date, etc.
 */

import {
  ArrowRight,
  Building2,
  Calendar,
  Clock,
  Percent,
  TrendingUp,
  User,
} from 'lucide-react';
import { useEffect, useState } from 'react';
import { depositDetailsRepository } from '@/core/db';
import { transactionRepository } from '@/core/db/repositories/transactions';
import type { DepositDetails, Transaction } from '@/core/db/types';
import { depositInterestService } from '@/core/services/depositInterestService';
import {
  calculateCurrentValue,
  calculateInterestEarned,
  formatCurrency,
  getDaysUntilMaturity,
  isDepositMatured,
} from '@/shared/utils/depositCalculations';
import './DepositDetailsCard.css';

export interface DepositDetailsCardProps {
  accountId: string;
  accountName: string;
}

export function DepositDetailsCard({ accountId }: DepositDetailsCardProps) {
  const [depositDetails, setDepositDetails] = useState<DepositDetails | null>(
    null
  );
  const [nextInterestDate, setNextInterestDate] = useState<Date | null>(null);
  const [interestTransactions, setInterestTransactions] = useState<
    Transaction[]
  >([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showInterestHistory, setShowInterestHistory] = useState(false);

  useEffect(() => {
    const loadDepositDetails = async () => {
      try {
        const details =
          await depositDetailsRepository.findByAccountId(accountId);
        setDepositDetails(details);

        // Load next interest date
        if (details) {
          const nextDate = await depositInterestService.getNextInterestDate(
            details.id
          );
          setNextInterestDate(nextDate);
        }

        // Load interest transactions
        const transactions =
          await transactionRepository.findByAccount(accountId);
        const interestTxns = transactions.filter(
          (tx: Transaction) => tx.category === 'Interest Income'
        );
        setInterestTransactions(interestTxns);
      } catch (error) {
        console.error('Failed to load deposit details:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadDepositDetails();
  }, [accountId]);

  if (isLoading) {
    return (
      <div className="deposit-details-card">
        <div className="deposit-details-card__loading">
          Loading deposit details...
        </div>
      </div>
    );
  }

  if (!depositDetails) {
    return null;
  }

  const currentValue = calculateCurrentValue(depositDetails);
  const interestEarned = calculateInterestEarned(depositDetails);
  const daysUntilMaturity = getDaysUntilMaturity(depositDetails.maturity_date);
  const matured = isDepositMatured(depositDetails);
  const progress =
    (depositDetails.completed_months / depositDetails.tenure_months) * 100;

  return (
    <div className="deposit-details-card">
      <h3 className="deposit-details-card__title">Deposit Information</h3>

      <div className="deposit-details-card__grid">
        {/* Principal Amount */}
        <div className="deposit-details-card__item">
          <div className="deposit-details-card__item-icon">
            <TrendingUp size={20} />
          </div>
          <div className="deposit-details-card__item-content">
            <span className="deposit-details-card__item-label">
              Principal Amount
            </span>
            <span className="deposit-details-card__item-value">
              {formatCurrency(depositDetails.principal_amount)}
            </span>
          </div>
        </div>

        {/* Current Value */}
        <div className="deposit-details-card__item">
          <div className="deposit-details-card__item-icon">
            <TrendingUp size={20} />
          </div>
          <div className="deposit-details-card__item-content">
            <span className="deposit-details-card__item-label">
              Current Value
            </span>
            <span className="deposit-details-card__item-value deposit-details-card__item-value--primary">
              {formatCurrency(currentValue)}
            </span>
          </div>
        </div>

        {/* Interest Rate */}
        <div className="deposit-details-card__item">
          <div className="deposit-details-card__item-icon">
            <Percent size={20} />
          </div>
          <div className="deposit-details-card__item-content">
            <span className="deposit-details-card__item-label">
              Interest Rate
            </span>
            <span className="deposit-details-card__item-value">
              {depositDetails.interest_rate}% p.a.
            </span>
          </div>
        </div>

        {/* Interest Earned */}
        <div className="deposit-details-card__item">
          <div className="deposit-details-card__item-icon">
            <TrendingUp size={20} />
          </div>
          <div className="deposit-details-card__item-content">
            <span className="deposit-details-card__item-label">
              Interest Earned
            </span>
            <span className="deposit-details-card__item-value deposit-details-card__item-value--success">
              {formatCurrency(interestEarned)}
            </span>
            {depositDetails.tds_deducted > 0 && (
              <span className="deposit-details-card__item-subtitle">
                TDS Deducted: {formatCurrency(depositDetails.tds_deducted)}
              </span>
            )}
          </div>
        </div>

        {/* Next Interest Payment */}
        {nextInterestDate &&
          !matured &&
          depositDetails.interest_payout_frequency !== 'maturity' && (
            <div className="deposit-details-card__item">
              <div className="deposit-details-card__item-icon">
                <ArrowRight size={20} />
              </div>
              <div className="deposit-details-card__item-content">
                <span className="deposit-details-card__item-label">
                  Next Interest Payment
                </span>
                <span className="deposit-details-card__item-value">
                  {new Date(nextInterestDate).toLocaleDateString('en-IN', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric',
                  })}
                </span>
                <span className="deposit-details-card__item-subtitle">
                  {Math.ceil(
                    (new Date(nextInterestDate).getTime() - Date.now()) /
                      (1000 * 60 * 60 * 24)
                  )}{' '}
                  days
                </span>
              </div>
            </div>
          )}

        {/* Maturity Amount */}
        <div className="deposit-details-card__item">
          <div className="deposit-details-card__item-icon">
            <TrendingUp size={20} />
          </div>
          <div className="deposit-details-card__item-content">
            <span className="deposit-details-card__item-label">
              Maturity Amount
            </span>
            <span className="deposit-details-card__item-value">
              {formatCurrency(depositDetails.maturity_amount)}
            </span>
          </div>
        </div>

        {/* Maturity Date */}
        <div className="deposit-details-card__item">
          <div className="deposit-details-card__item-icon">
            <Calendar size={20} />
          </div>
          <div className="deposit-details-card__item-content">
            <span className="deposit-details-card__item-label">
              Maturity Date
            </span>
            <span className="deposit-details-card__item-value">
              {new Date(depositDetails.maturity_date).toLocaleDateString(
                'en-IN',
                {
                  day: 'numeric',
                  month: 'short',
                  year: 'numeric',
                }
              )}
            </span>
            {!matured && (
              <span className="deposit-details-card__item-subtitle">
                {daysUntilMaturity} days remaining
              </span>
            )}
            {matured && (
              <span className="deposit-details-card__item-subtitle deposit-details-card__item-subtitle--warning">
                Matured
              </span>
            )}
          </div>
        </div>

        {/* Tenure */}
        <div className="deposit-details-card__item">
          <div className="deposit-details-card__item-icon">
            <Clock size={20} />
          </div>
          <div className="deposit-details-card__item-content">
            <span className="deposit-details-card__item-label">Tenure</span>
            <span className="deposit-details-card__item-value">
              {depositDetails.tenure_months} months
            </span>
            <span className="deposit-details-card__item-subtitle">
              {depositDetails.completed_months} completed,{' '}
              {depositDetails.remaining_months} remaining
            </span>
          </div>
        </div>

        {/* Progress Bar */}
        <div className="deposit-details-card__item deposit-details-card__item--full">
          <div className="deposit-details-card__progress">
            <div className="deposit-details-card__progress-label">
              <span>Progress</span>
              <span>{Math.round(progress)}%</span>
            </div>
            <div className="deposit-details-card__progress-bar">
              <div
                className="deposit-details-card__progress-fill"
                style={{ width: `${progress}%` }}
              />
            </div>
          </div>
        </div>

        {/* Bank Name */}
        {depositDetails.bank_name && (
          <div className="deposit-details-card__item">
            <div className="deposit-details-card__item-icon">
              <Building2 size={20} />
            </div>
            <div className="deposit-details-card__item-content">
              <span className="deposit-details-card__item-label">
                Bank/Institution
              </span>
              <span className="deposit-details-card__item-value">
                {depositDetails.bank_name}
              </span>
            </div>
          </div>
        )}

        {/* Nominee */}
        {depositDetails.nominee_name && (
          <div className="deposit-details-card__item">
            <div className="deposit-details-card__item-icon">
              <User size={20} />
            </div>
            <div className="deposit-details-card__item-content">
              <span className="deposit-details-card__item-label">Nominee</span>
              <span className="deposit-details-card__item-value">
                {depositDetails.nominee_name}
              </span>
              {depositDetails.nominee_relationship && (
                <span className="deposit-details-card__item-subtitle">
                  {depositDetails.nominee_relationship}
                </span>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Additional Info */}
      <div className="deposit-details-card__footer">
        {depositDetails.is_tax_saving && (
          <span className="deposit-details-card__badge deposit-details-card__badge--success">
            Tax Saving
            {depositDetails.tax_deduction_section &&
              ` (${depositDetails.tax_deduction_section})`}
          </span>
        )}
        {depositDetails.auto_renewal && (
          <span className="deposit-details-card__badge">
            Auto-Renewal Enabled
          </span>
        )}
        <span className="deposit-details-card__badge deposit-details-card__badge--info">
          {depositDetails.interest_payout_frequency.charAt(0).toUpperCase() +
            depositDetails.interest_payout_frequency.slice(1)}{' '}
          Interest
        </span>
      </div>

      {depositDetails.notes && (
        <div className="deposit-details-card__notes">
          <strong>Notes:</strong> {depositDetails.notes}
        </div>
      )}

      {/* Interest Payment History */}
      {interestTransactions.length > 0 && (
        <div className="deposit-details-card__history">
          <div className="deposit-details-card__history-header">
            <h4 className="deposit-details-card__history-title">
              Interest Payment History ({interestTransactions.length})
            </h4>
            <button
              type="button"
              className="deposit-details-card__history-toggle"
              onClick={() => setShowInterestHistory(!showInterestHistory)}
              aria-expanded={showInterestHistory}
            >
              {showInterestHistory ? 'Hide' : 'Show'} History
            </button>
          </div>

          {showInterestHistory && (
            <div className="deposit-details-card__history-list">
              {interestTransactions.map((tx) => (
                <div key={tx.id} className="deposit-details-card__history-item">
                  <div className="deposit-details-card__history-item-date">
                    {new Date(tx.date).toLocaleDateString('en-IN', {
                      day: 'numeric',
                      month: 'short',
                      year: 'numeric',
                    })}
                  </div>
                  <div className="deposit-details-card__history-item-description">
                    {tx.description || 'Interest Credit'}
                  </div>
                  <div className="deposit-details-card__history-item-amount">
                    {formatCurrency(tx.amount)}
                  </div>
                </div>
              ))}
              <div className="deposit-details-card__history-total">
                <span>Total Interest Received:</span>
                <span className="deposit-details-card__history-total-amount">
                  {formatCurrency(
                    interestTransactions.reduce((sum, tx) => sum + tx.amount, 0)
                  )}
                </span>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
