/**
 * Dashboard route
 * Main overview page
 */

import { createFileRoute } from '@tanstack/react-router'
import {
  BudgetProgress,
  DashboardLayout,
  FinancialOverview,
  RecentTransactions,
} from '@/features/dashboard/components'

export const Route = createFileRoute('/dashboard')({
  component: DashboardPage,
})

function DashboardPage() {
  return (
    <DashboardLayout>
      <main id="main-content">
        <h1
          style={{
            fontSize: 'var(--font-size-3xl)',
            fontWeight: 700,
            marginBottom: 'var(--spacing-xl)',
          }}
        >
          Dashboard
        </h1>

        <FinancialOverview />

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))',
            gap: 'var(--spacing-xl)',
          }}
        >
          <RecentTransactions />
          <BudgetProgress />
        </div>
      </main>
    </DashboardLayout>
  )
}
