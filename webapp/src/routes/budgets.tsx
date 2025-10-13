/**
 * Budgets route
 * Manage spending budgets
 */

import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/budgets')({
  component: BudgetsPage,
})

function BudgetsPage() {
  return (
    <div className="container" style={{ paddingTop: 'var(--spacing-8)' }}>
      <main id="main-content">
        <h1>Budgets</h1>
        <p>Set and track spending limits</p>

        <div style={{ marginTop: 'var(--spacing-6)' }}>
          <h2>Coming Soon</h2>
          <ul style={{ listStyle: 'disc', paddingLeft: 'var(--spacing-6)' }}>
            <li>Create budgets by category</li>
            <li>Track spending progress</li>
            <li>Set alert thresholds</li>
            <li>Monthly/yearly budgets</li>
            <li>Budget vs actual analysis</li>
          </ul>
        </div>
      </main>
    </div>
  )
}
