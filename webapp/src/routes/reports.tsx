/**
 * Reports route
 * Financial reports and analytics
 */

import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/reports')({
  component: ReportsPage,
})

function ReportsPage() {
  return (
    <div className="container" style={{ paddingTop: 'var(--spacing-8)' }}>
      <main id="main-content">
        <h1>Reports</h1>
        <p>Financial insights and analytics</p>

        <div style={{ marginTop: 'var(--spacing-6)' }}>
          <h2>Coming Soon</h2>
          <ul style={{ listStyle: 'disc', paddingLeft: 'var(--spacing-6)' }}>
            <li>Income vs Expenses</li>
            <li>Spending by category</li>
            <li>Monthly trends</li>
            <li>Net worth tracking</li>
            <li>Custom date ranges</li>
            <li>Export reports</li>
          </ul>
        </div>
      </main>
    </div>
  )
}
