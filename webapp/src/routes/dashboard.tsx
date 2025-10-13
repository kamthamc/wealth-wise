/**
 * Dashboard route
 * Main overview page
 */

import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/dashboard')({
  component: DashboardPage,
})

function DashboardPage() {
  return (
    <div className="container" style={{ paddingTop: 'var(--spacing-8)' }}>
      <main id="main-content">
        <h1>Dashboard</h1>
        <p>Financial overview and insights</p>

        <div style={{ marginTop: 'var(--spacing-6)' }}>
          <h2>Coming Soon</h2>
          <ul style={{ listStyle: 'disc', paddingLeft: 'var(--spacing-6)' }}>
            <li>Account balances summary</li>
            <li>Recent transactions</li>
            <li>Budget progress</li>
            <li>Goal tracking</li>
            <li>Spending insights</li>
          </ul>
        </div>
      </main>
    </div>
  )
}
