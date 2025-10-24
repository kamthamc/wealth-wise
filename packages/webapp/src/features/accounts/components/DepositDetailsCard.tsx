/**
 * Deposit Details Card Component
 * Displays deposit-specific information like interest rate, maturity date, etc.
 */

import {
  // Building2,
  Calendar,
  Clock,
  Percent,
  TrendingUp,
  // User,
} from 'lucide-react';
import { useEffect, useState } from 'react';
import { getDepositAccountDetails } from '@/core/api/depositApi';
import { useFirebaseTransactionStore } from '@/core/stores/firebaseTransactionStore';
import './DepositDetailsCard.css';

export interface DepositDetailsCardProps {
  accountId: string;
  accountName: string;
}

interface DepositInfo {
  principal: number;
  interest_rate: number;
  tenure_months: number;
  maturity_date: string;
  maturity_amount: number;
  bank_name?: string;
  nominee_name?: string;
  nominee_relationship?: string;
  is_tax_saving?: boolean;
  auto_renewal?: boolean;
  compounding_frequency?: string;
  is_senior_citizen?: boolean;
}

interface DepositCalculation {
  principal: number;
  interestRate: number;
  maturityAmount: number;
  interestEarned: number;
  tdsAmount: number;
  netAmount: number;
  maturityDate: string;
  effectiveRate?: number;
}

const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(amount);
};

const getDaysUntilMaturity = (maturityDate: string): number => {
  const days = Math.ceil(
    (new Date(maturityDate).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
  );
  return Math.max(0, days);
};

const isDepositMatured = (maturityDate: string): boolean => {
  return new Date(maturityDate) < new Date();
};

export function DepositDetailsCard({ accountId }: DepositDetailsCardProps) {
  const [account, setAccount] = useState<any>(null);
  const [calculation, setCalculation] = useState<DepositCalculation | null>(
    null
  );
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showInterestHistory, setShowInterestHistory] = useState(false);

  const transactionStore = useFirebaseTransactionStore();
  const interestTransactions =
    transactionStore.transactions?.filter(
      (tx) => tx.account_id === accountId && tx.category === 'Interest Income'
    ) || [];

  useEffect(() => {
    const loadDepositDetails = async () => {
      try {
        setIsLoading(true);
        setError(null);

        const result = await getDepositAccountDetails(accountId);

        if (result.success) {
          setAccount(result.account);
          setCalculation(result.calculation);
        } else {
          setError('Failed to load deposit details');
        }
      } catch (err) {
        console.error('Failed to load deposit details:', err);
        setError(
          err instanceof Error ? err.message : 'Failed to load deposit details'
        );
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

  if (error) {
    return (
      <div className="deposit-details-card">
        <div className="deposit-details-card__error">{error}</div>
      </div>
    );
  }

  if (!account || !calculation) {
    return null;
  }

  const depositInfo = account.deposit_info as DepositInfo;
  const maturityDate = calculation.maturityDate;
  const daysUntilMaturity = getDaysUntilMaturity(maturityDate);
  const matured = isDepositMatured(maturityDate);

  // Calculate progress based on dates
  const startDate = new Date(account.created_at || Date.now());
  const endDate = new Date(maturityDate);
  const now = new Date();
  const totalDays =
    (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24);
  const elapsedDays =
    (now.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24);
  const progress = Math.min(100, Math.max(0, (elapsedDays / totalDays) * 100));

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
              {formatCurrency(calculation.principal)}
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
              {formatCurrency(account.balance || calculation.principal)}
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
              {calculation.interestRate}% p.a.
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
              {formatCurrency(calculation.interestEarned)}
            </span>
            {calculation.tdsAmount > 0 && (
              <span className="deposit-details-card__item-subtitle">
                TDS Deducted: {formatCurrency(calculation.tdsAmount)}
              </span>
            )}
          </div>
        </div>

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
              {formatCurrency(calculation.maturityAmount)}
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
              {new Date(maturityDate).toLocaleDateString('en-IN', {
                day: 'numeric',
                month: 'short',
                year: 'numeric',
              })}
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
        {depositInfo.tenure_months && (
          <div className="deposit-details-card__item">
            <div className="deposit-details-card__item-icon">
              <Clock size={20} />
            </div>
            <div className="deposit-details-card__item-content">
              <span className="deposit-details-card__item-label">Tenure</span>
              <span className="deposit-details-card__item-value">
                {depositInfo.tenure_months} months
              </span>
            </div>
          </div>
        )}

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
        {/* {depositDetails.bank_name && (
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
        )} */}

        {/* Nominee */}
        {/* {depositDetails.nominee_name && (
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
        )} */}
      </div>

      {/* Additional Info */}
      {/* <div className="deposit-details-card__footer">
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
      </div> */}

      {/* {depositDetails.notes && (
        <div className="deposit-details-card__notes">
          <strong>Notes:</strong> {depositDetails.notes}
        </div>
      )} */}

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
                    {new Date(tx.date.toDate()).toLocaleDateString('en-IN', {
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
