/**
 * Goals route
 * Manage financial goals and savings targets
 */

import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/goals')({
  component: GoalsPage,
})

function GoalsPage() {
  return (
    <div className="container" style={{ paddingTop: 'var(--spacing-8)' }}>
      <main id="main-content">
        <h1>Goals</h1>
        <p>Track your financial goals and savings targets</p>

        <div style={{ marginTop: 'var(--spacing-6)' }}>
          <h2>Coming Soon</h2>
          <ul style={{ listStyle: 'disc', paddingLeft: 'var(--spacing-6)' }}>
            <li>Create savings goals</li>
            <li>Track progress</li>
            <li>Set target dates</li>
            <li>Add contributions</li>
            <li>Goal priority management</li>
          </ul>
        </div>
      </main>
    </div>
  )
}
