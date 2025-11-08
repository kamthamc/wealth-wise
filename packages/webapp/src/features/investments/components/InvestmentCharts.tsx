/**
 * Investment Chart Components
 * Reusable chart components for investment data visualization
 */

import { useMemo } from 'react';
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  Cell,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import type { InvestmentAssetType } from '@/core/types';
import { formatCurrency } from '@/shared/utils';
import './InvestmentCharts.css';

// Chart color palette
const CHART_COLORS = {
  primary: '#3b82f6',
  success: '#10b981',
  danger: '#ef4444',
  warning: '#f59e0b',
  purple: '#8b5cf6',
  pink: '#ec4899',
  indigo: '#6366f1',
  teal: '#14b8a6',
};

const ASSET_TYPE_COLORS: Record<InvestmentAssetType, string> = {
  stock: CHART_COLORS.primary,
  mutual_fund: CHART_COLORS.success,
  etf: CHART_COLORS.purple,
  commodity: CHART_COLORS.warning,
  reit: CHART_COLORS.pink,
  bond: CHART_COLORS.indigo,
  crypto: CHART_COLORS.teal,
};

// Portfolio Performance Chart
interface PortfolioPerformanceData {
  date: string;
  value: number;
  invested: number;
}

export interface PortfolioPerformanceChartProps {
  data: PortfolioPerformanceData[];
  currency?: string;
  height?: number;
}

export function PortfolioPerformanceChart({
  data,
  currency = 'INR',
  height = 300,
}: PortfolioPerformanceChartProps) {
  return (
    <div className="investment-chart">
      <ResponsiveContainer width="100%" height={height}>
        <AreaChart
          data={data}
          margin={{ top: 10, right: 30, left: 0, bottom: 0 }}
        >
          <defs>
            <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
              <stop
                offset="5%"
                stopColor={CHART_COLORS.primary}
                stopOpacity={0.8}
              />
              <stop
                offset="95%"
                stopColor={CHART_COLORS.primary}
                stopOpacity={0}
              />
            </linearGradient>
            <linearGradient id="colorInvested" x1="0" y1="0" x2="0" y2="1">
              <stop
                offset="5%"
                stopColor={CHART_COLORS.success}
                stopOpacity={0.8}
              />
              <stop
                offset="95%"
                stopColor={CHART_COLORS.success}
                stopOpacity={0}
              />
            </linearGradient>
          </defs>
          <XAxis dataKey="date" stroke="var(--color-text-tertiary)" />
          <YAxis stroke="var(--color-text-tertiary)" />
          <Tooltip
            contentStyle={{
              backgroundColor: 'var(--color-bg-secondary)',
              border: '1px solid var(--color-border)',
              borderRadius: 'var(--radius-sm)',
            }}
            formatter={(value: number) => formatCurrency(value, currency)}
          />
          <Area
            type="monotone"
            dataKey="invested"
            stroke={CHART_COLORS.success}
            fillOpacity={1}
            fill="url(#colorInvested)"
            name="Invested"
          />
          <Area
            type="monotone"
            dataKey="value"
            stroke={CHART_COLORS.primary}
            fillOpacity={1}
            fill="url(#colorValue)"
            name="Current Value"
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}

// Asset Allocation Pie Chart
interface AssetAllocationData {
  asset_type: InvestmentAssetType;
  name: string;
  value: number;
  percentage: number;
}

export interface AssetAllocationChartProps {
  data: AssetAllocationData[];
  currency?: string;
  height?: number;
}

export function AssetAllocationChart({
  data,
  currency = 'INR',
  height = 300,
}: AssetAllocationChartProps) {
  const chartData = useMemo(() => {
    return data
      .filter((item) => item.value > 0)
      .map((item) => ({
        ...item,
        [item.asset_type]: item.value, // Add indexed signature
      }));
  }, [data]);

  return (
    <div className="investment-chart">
      <ResponsiveContainer width="100%" height={height}>
        <PieChart>
          <Pie
            data={chartData}
            cx="50%"
            cy="50%"
            labelLine={false}
            label={(entry: any) =>
              `${entry.name} ${entry.percentage.toFixed(1)}%`
            }
            outerRadius={100}
            fill="#8884d8"
            dataKey="value"
          >
            {chartData.map((entry, index) => (
              <Cell
                key={`cell-${index}`}
                fill={ASSET_TYPE_COLORS[entry.asset_type]}
              />
            ))}
          </Pie>
          <Tooltip
            formatter={(value: number) => formatCurrency(value, currency)}
          />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
}

// Holdings Performance Bar Chart
interface HoldingPerformanceData {
  symbol: string;
  name: string;
  return: number;
  returnPercentage: number;
}

export interface HoldingsPerformanceChartProps {
  data: HoldingPerformanceData[];
  currency?: string;
  height?: number;
}

export function HoldingsPerformanceChart({
  data,
  currency = 'INR',
  height = 300,
}: HoldingsPerformanceChartProps) {
  const sortedData = useMemo(() => {
    return [...data].sort((a, b) => b.returnPercentage - a.returnPercentage);
  }, [data]);

  return (
    <div className="investment-chart">
      <ResponsiveContainer width="100%" height={height}>
        <BarChart
          data={sortedData}
          margin={{ top: 10, right: 30, left: 0, bottom: 0 }}
        >
          <XAxis dataKey="symbol" stroke="var(--color-text-tertiary)" />
          <YAxis stroke="var(--color-text-tertiary)" />
          <Tooltip
            contentStyle={{
              backgroundColor: 'var(--color-bg-secondary)',
              border: '1px solid var(--color-border)',
              borderRadius: 'var(--radius-sm)',
            }}
            formatter={(value: number) => [
              formatCurrency(value, currency),
              'Return',
            ]}
          />
          <Bar dataKey="return" radius={[4, 4, 0, 0]}>
            {sortedData.map((entry, index) => (
              <Cell
                key={`cell-${index}`}
                fill={
                  entry.return >= 0 ? CHART_COLORS.success : CHART_COLORS.danger
                }
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

// Investment Price History Chart
interface PriceHistoryData {
  date: string;
  price: number;
  high?: number;
  low?: number;
}

export interface InvestmentPriceChartProps {
  data: PriceHistoryData[];
  currency?: string;
  height?: number;
  showHighLow?: boolean;
}

export function InvestmentPriceChart({
  data,
  currency = 'INR',
  height = 300,
  showHighLow = false,
}: InvestmentPriceChartProps) {
  return (
    <div className="investment-chart">
      <ResponsiveContainer width="100%" height={height}>
        <LineChart
          data={data}
          margin={{ top: 10, right: 30, left: 0, bottom: 0 }}
        >
          <XAxis dataKey="date" stroke="var(--color-text-tertiary)" />
          <YAxis stroke="var(--color-text-tertiary)" />
          <Tooltip
            contentStyle={{
              backgroundColor: 'var(--color-bg-secondary)',
              border: '1px solid var(--color-border)',
              borderRadius: 'var(--radius-sm)',
            }}
            formatter={(value: number) => formatCurrency(value, currency)}
          />
          {showHighLow && (
            <>
              <Line
                type="monotone"
                dataKey="high"
                stroke={CHART_COLORS.success}
                strokeWidth={1}
                dot={false}
                name="High"
                strokeDasharray="3 3"
              />
              <Line
                type="monotone"
                dataKey="low"
                stroke={CHART_COLORS.danger}
                strokeWidth={1}
                dot={false}
                name="Low"
                strokeDasharray="3 3"
              />
            </>
          )}
          <Line
            type="monotone"
            dataKey="price"
            stroke={CHART_COLORS.primary}
            strokeWidth={2}
            dot={false}
            name="Price"
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}

// Monthly Returns Heatmap (simplified as bar chart for now)
interface MonthlyReturnData {
  month: string;
  return: number;
  returnPercentage: number;
}

export interface MonthlyReturnsChartProps {
  data: MonthlyReturnData[];
  currency?: string;
  height?: number;
}

export function MonthlyReturnsChart({
  data,
  currency = 'INR',
  height = 200,
}: MonthlyReturnsChartProps) {
  return (
    <div className="investment-chart">
      <ResponsiveContainer width="100%" height={height}>
        <BarChart
          data={data}
          margin={{ top: 10, right: 30, left: 0, bottom: 0 }}
        >
          <XAxis dataKey="month" stroke="var(--color-text-tertiary)" />
          <YAxis stroke="var(--color-text-tertiary)" />
          <Tooltip
            contentStyle={{
              backgroundColor: 'var(--color-bg-secondary)',
              border: '1px solid var(--color-border)',
              borderRadius: 'var(--radius-sm)',
            }}
            formatter={(value: number) => [
              formatCurrency(value, currency),
              'Return',
            ]}
          />
          <Bar dataKey="return" radius={[4, 4, 0, 0]}>
            {data.map((entry, index) => (
              <Cell
                key={`cell-${index}`}
                fill={
                  entry.return >= 0 ? CHART_COLORS.success : CHART_COLORS.danger
                }
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

// Export all components
export default {
  PortfolioPerformanceChart,
  AssetAllocationChart,
  HoldingsPerformanceChart,
  InvestmentPriceChart,
  MonthlyReturnsChart,
};
