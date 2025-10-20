/**
 * Dashboard Route
 * Main application dashboard with financial overview
 */

import { createFileRoute } from '@tanstack/react-router';
import { useIsAppReady } from '@/core/stores';
import {
  BudgetProgress,
  DashboardLayout,
  FinancialOverview,
  GoalsProgress,
  QuickActions,
  RecentTransactions,
  WelcomeBanner,
} from '@/features/dashboard/components';
import { QuickTransactionEntry } from '@/features/transactions';
import { Spinner } from '@/shared/components';

export const Route = createFileRoute('/dashboard')({
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
      <WelcomeBanner />
      <QuickTransactionEntry />
      <QuickActions />
      <FinancialOverview />
      <RecentTransactions />
      <BudgetProgress />
      <GoalsProgress />
    </DashboardLayout>
  );
}
