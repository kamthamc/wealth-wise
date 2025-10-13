/**
 * Transactions route
 * View and manage financial transactions
 */

import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/transactions')({
  component: TransactionsPage,
})

function TransactionsPage() {
  return (
    <div className="container" style={{ paddingTop: 'var(--spacing-8)' }}>
      <main id="main-content">
        <h1>Transactions</h1>
        <p>Track income, expenses, and transfers</p>

        <div style={{ marginTop: 'var(--spacing-6)' }}>
          <h2>Coming Soon</h2>
          <ul style={{ listStyle: 'disc', paddingLeft: 'var(--spacing-6)' }}>
            <li>Add transactions</li>
            <li>Filter by date, category, account</li>
            <li>Search transactions</li>
            <li>Edit and delete transactions</li>
            <li>Recurring transactions</li>
            <li>Attach receipts</li>
          </ul>
        </div>
      </main>
    </div>
  )
}
