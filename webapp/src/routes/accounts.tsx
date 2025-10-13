/**
 * Accounts route
 * Manage bank accounts, credit cards, and other accounts
 */

import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/accounts')({
  component: AccountsPage,
})

function AccountsPage() {
  return (
    <div className="container" style={{ paddingTop: 'var(--spacing-8)' }}>
      <main id="main-content">
        <h1>Accounts</h1>
        <p>Manage your bank accounts, credit cards, and wallets</p>

        <div style={{ marginTop: 'var(--spacing-6)' }}>
          <h2>Coming Soon</h2>
          <ul style={{ listStyle: 'disc', paddingLeft: 'var(--spacing-6)' }}>
            <li>Add new accounts</li>
            <li>View account balances</li>
            <li>Edit account details</li>
            <li>Deactivate accounts</li>
            <li>Account type filtering</li>
          </ul>
        </div>
      </main>
    </div>
  )
}
