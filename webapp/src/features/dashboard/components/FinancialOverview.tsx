/**
 * Financial Overview Component
 * Display key financial statistics
 */

import { StatCard } from '@/shared/components';
import './FinancialOverview.css';

export function FinancialOverview() {
  // TODO: Replace with real data from store
  const stats = [
    {
      label: 'Total Balance',
      value: '₹2,45,680',
      trend: { value: 12.5, label: 'vs last month', isPositive: true },
      variant: 'primary' as const,
      icon: '💰',
    },
    {
      label: 'Income',
      value: '₹85,000',
      trend: { value: 5.2, label: 'vs last month', isPositive: true },
      variant: 'success' as const,
      icon: '📈',
    },
    {
      label: 'Expenses',
      value: '₹42,350',
      trend: { value: 3.8, label: 'vs last month', isPositive: false },
      variant: 'danger' as const,
      icon: '📉',
    },
    {
      label: 'Savings Rate',
      value: '50.2%',
      description: 'On track with goals',
      variant: 'success' as const,
      icon: '🎯',
    },
  ];

  return (
    <section className="financial-overview">
      <h2 className="financial-overview__title">Financial Overview</h2>
      <div className="financial-overview__grid">
        {stats.map((stat) => (
          <StatCard
            key={stat.label}
            label={stat.label}
            value={stat.value}
            trend={stat.trend}
            description={stat.description}
            variant={stat.variant}
            icon={<span className="financial-overview__icon">{stat.icon}</span>}
          />
        ))}
      </div>
    </section>
  );
}
