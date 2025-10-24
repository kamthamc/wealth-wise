/**
 * Dashboard Route
 * Main application dashboard with financial overview
 */

import { createFileRoute } from '@tanstack/react-router';
import { useIsAppReady } from '@/core/stores';
import {
  AccountBreakdown,
  BudgetProgress,
  DashboardLayout,
  GoalsProgress,
  NetWorthHero,
  PerformanceInsights,
  RecentTransactions,
} from '@/features/dashboard/components';
import { Spinner } from '@/shared/components';

export const Route = createFileRoute('/_auth/dashboard')({
  component: DashboardPage,
});

function DashboardPage() {
  const isAppReady = useIsAppReady();

  if (!isAppReady) {
    return (
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '100vh',
          gap: '1rem',
        }}
      >
        <Spinner size="large" />
        <p style={{ color: 'var(--color-text-secondary)' }}>
          Loading your financial data...
        </p>
      </div>
    );
  }

  return (
    <DashboardLayout>
      {/* Primary Metric - Net Worth Hero */}
      <NetWorthHero />

      {/* Monthly Performance Overview */}
      <PerformanceInsights />

      {/* Asset Allocation */}
      <AccountBreakdown />

      {/* Recent Activity */}
      <RecentTransactions />

      {/* Budget & Goals Progress */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: 'var(--space-6)',
          marginTop: 'var(--space-6)',
        }}
      >
        <BudgetProgress />
        <GoalsProgress />
      </div>
    </DashboardLayout>
  );
}
