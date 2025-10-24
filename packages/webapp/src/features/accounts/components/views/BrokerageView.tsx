/**
 * Brokerage Account View
 * Displays investment account information including holdings, P&L, and portfolio allocation
 */

import {
  BarChart3,
  DollarSign,
  PieChart,
  TrendingDown,
  TrendingUp,
} from 'lucide-react';
import { useMemo } from 'react';
import type { Account, BrokerageDetails } from '@/core/db/types';
import { Card, StatCard } from '@/shared/components';
import { formatCurrency } from '@/shared/utils';
import './BrokerageView.css';

export interface BrokerageViewProps {
  account: Account;
  brokerageDetails?: BrokerageDetails;
}

export function BrokerageView({
  account,
  brokerageDetails,
}: BrokerageViewProps) {
  // Calculate total holdings
  const totalHoldings = useMemo(() => {
    if (!brokerageDetails) return 0;
    return (
      brokerageDetails.equity_holdings +
      brokerageDetails.mutual_fund_holdings +
      brokerageDetails.bond_holdings +
      brokerageDetails.etf_holdings
    );
  }, [brokerageDetails]);

  // Get returns color
  const getReturnsColor = (returns: number) => {
    if (returns > 0) return 'success';
    if (returns < 0) return 'danger';
    return 'default';
  };

  if (!brokerageDetails) {
    return (
      <div className="brokerage-view">
        <Card>
          <div className="brokerage-view__empty">
            <TrendingUp size={48} />
            <h3>Brokerage Details Not Available</h3>
            <p>
              Add brokerage details to track your investments, holdings, and
              returns.
            </p>
          </div>
        </Card>
      </div>
    );
  }

  const returnsColor = getReturnsColor(brokerageDetails.total_returns);

  return (
    <div className="brokerage-view">
      {/* Header */}
      <div className="brokerage-view__header">
        <h2>Investment Portfolio</h2>
        {brokerageDetails.broker_name && (
          <span className="brokerage-view__broker">
            {brokerageDetails.broker_name}
          </span>
        )}
      </div>

      {/* Portfolio Value Card */}
      <Card
        className={`brokerage-view__portfolio-card brokerage-view__portfolio-card--${returnsColor}`}
      >
        <div className="brokerage-view__portfolio-header">
          <div>
            <h3>Current Portfolio Value</h3>
            <p className="brokerage-view__portfolio-value">
              {formatCurrency(brokerageDetails.current_value, account.currency)}
            </p>
            <div className="brokerage-view__portfolio-returns">
              {brokerageDetails.total_returns >= 0 ? (
                <TrendingUp size={20} />
              ) : (
                <TrendingDown size={20} />
              )}
              <span>
                {brokerageDetails.total_returns >= 0 ? '+' : ''}
                {formatCurrency(
                  brokerageDetails.total_returns,
                  account.currency
                )}
              </span>
              <span className="brokerage-view__portfolio-percentage">
                ({brokerageDetails.total_returns_percentage >= 0 ? '+' : ''}
                {brokerageDetails.total_returns_percentage.toFixed(2)}%)
              </span>
            </div>
          </div>
          <div className="brokerage-view__portfolio-icon">
            <TrendingUp size={32} />
          </div>
        </div>
      </Card>

      {/* Stats Grid */}
      <div className="brokerage-view__stats">
        <StatCard
          label="Invested Value"
          value={formatCurrency(
            brokerageDetails.invested_value,
            account.currency
          )}
          icon={<DollarSign size={20} />}
        />

        <StatCard
          label="Realized Gains"
          value={formatCurrency(
            brokerageDetails.realized_gains,
            account.currency
          )}
          icon={<TrendingUp size={20} />}
          variant={getReturnsColor(brokerageDetails.realized_gains)}
        />

        <StatCard
          label="Unrealized Gains"
          value={formatCurrency(
            brokerageDetails.unrealized_gains,
            account.currency
          )}
          icon={<BarChart3 size={20} />}
          variant={getReturnsColor(brokerageDetails.unrealized_gains)}
        />

        <StatCard
          label="Total Holdings"
          value={totalHoldings.toString()}
          icon={<PieChart size={20} />}
        />
      </div>

      {/* Holdings Breakdown */}
      <Card>
        <h3>Holdings Breakdown</h3>
        <div className="brokerage-view__holdings">
          <div className="brokerage-view__holding-item">
            <div className="brokerage-view__holding-info">
              <div className="brokerage-view__holding-icon brokerage-view__holding-icon--equity">
                📈
              </div>
              <div>
                <span className="brokerage-view__holding-label">Equity</span>
                <span className="brokerage-view__holding-sublabel">
                  Stocks & Shares
                </span>
              </div>
            </div>
            <span className="brokerage-view__holding-count">
              {brokerageDetails.equity_holdings}{' '}
              {brokerageDetails.equity_holdings === 1 ? 'holding' : 'holdings'}
            </span>
          </div>

          <div className="brokerage-view__holding-item">
            <div className="brokerage-view__holding-info">
              <div className="brokerage-view__holding-icon brokerage-view__holding-icon--mf">
                📊
              </div>
              <div>
                <span className="brokerage-view__holding-label">
                  Mutual Funds
                </span>
                <span className="brokerage-view__holding-sublabel">
                  Managed Investments
                </span>
              </div>
            </div>
            <span className="brokerage-view__holding-count">
              {brokerageDetails.mutual_fund_holdings}{' '}
              {brokerageDetails.mutual_fund_holdings === 1 ? 'fund' : 'funds'}
            </span>
          </div>

          <div className="brokerage-view__holding-item">
            <div className="brokerage-view__holding-info">
              <div className="brokerage-view__holding-icon brokerage-view__holding-icon--bond">
                🏦
              </div>
              <div>
                <span className="brokerage-view__holding-label">Bonds</span>
                <span className="brokerage-view__holding-sublabel">
                  Fixed Income
                </span>
              </div>
            </div>
            <span className="brokerage-view__holding-count">
              {brokerageDetails.bond_holdings}{' '}
              {brokerageDetails.bond_holdings === 1 ? 'bond' : 'bonds'}
            </span>
          </div>

          <div className="brokerage-view__holding-item">
            <div className="brokerage-view__holding-info">
              <div className="brokerage-view__holding-icon brokerage-view__holding-icon--etf">
                💼
              </div>
              <div>
                <span className="brokerage-view__holding-label">ETFs</span>
                <span className="brokerage-view__holding-sublabel">
                  Exchange Traded Funds
                </span>
              </div>
            </div>
            <span className="brokerage-view__holding-count">
              {brokerageDetails.etf_holdings}{' '}
              {brokerageDetails.etf_holdings === 1 ? 'ETF' : 'ETFs'}
            </span>
          </div>
        </div>
      </Card>

      {/* Account Details */}
      <Card>
        <h3>Account Information</h3>
        <div className="brokerage-view__details">
          <div className="brokerage-view__detail-row">
            <span>Broker</span>
            <span className="brokerage-view__detail-value">
              {brokerageDetails.broker_name}
            </span>
          </div>

          {brokerageDetails.account_type && (
            <div className="brokerage-view__detail-row">
              <span>Account Type</span>
              <span className="brokerage-view__detail-value">
                {brokerageDetails.account_type.charAt(0).toUpperCase() +
                  brokerageDetails.account_type.slice(1)}
              </span>
            </div>
          )}

          {brokerageDetails.account_number && (
            <div className="brokerage-view__detail-row">
              <span>Account Number</span>
              <span className="brokerage-view__detail-value">
                {brokerageDetails.account_number}
              </span>
            </div>
          )}

          {brokerageDetails.demat_account_number && (
            <div className="brokerage-view__detail-row">
              <span>Demat Account</span>
              <span className="brokerage-view__detail-value">
                {brokerageDetails.demat_account_number}
              </span>
            </div>
          )}

          {brokerageDetails.trading_account_number && (
            <div className="brokerage-view__detail-row">
              <span>Trading Account</span>
              <span className="brokerage-view__detail-value">
                {brokerageDetails.trading_account_number}
              </span>
            </div>
          )}

          <div className="brokerage-view__detail-row">
            <span>Status</span>
            <span
              className={`brokerage-view__detail-badge brokerage-view__detail-badge--${brokerageDetails.status}`}
            >
              {brokerageDetails.status.charAt(0).toUpperCase() +
                brokerageDetails.status.slice(1)}
            </span>
          </div>
        </div>
      </Card>

      {/* Trading Settings */}
      <Card>
        <h3>Trading Preferences</h3>
        <div className="brokerage-view__settings">
          <div
            className={`brokerage-view__setting ${brokerageDetails.auto_square_off ? 'brokerage-view__setting--active' : ''}`}
          >
            <div className="brokerage-view__setting-icon">
              {brokerageDetails.auto_square_off ? '✅' : '❌'}
            </div>
            <div>
              <span className="brokerage-view__setting-label">
                Auto Square Off
              </span>
              <span className="brokerage-view__setting-sublabel">
                Automatic position closing
              </span>
            </div>
          </div>

          <div
            className={`brokerage-view__setting ${brokerageDetails.margin_enabled ? 'brokerage-view__setting--active' : ''}`}
          >
            <div className="brokerage-view__setting-icon">
              {brokerageDetails.margin_enabled ? '✅' : '❌'}
            </div>
            <div>
              <span className="brokerage-view__setting-label">
                Margin Trading
              </span>
              <span className="brokerage-view__setting-sublabel">
                Leverage enabled for trading
              </span>
            </div>
          </div>
        </div>
      </Card>

      {/* Notes */}
      {brokerageDetails.notes && (
        <Card>
          <h3>Notes</h3>
          <p className="brokerage-view__notes">{brokerageDetails.notes}</p>
        </Card>
      )}
    </div>
  );
}
