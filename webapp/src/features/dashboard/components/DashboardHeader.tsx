/**
 * Dashboard Header Component
 * Main navigation and branding
 */

import { Link } from '@tanstack/react-router'
import './DashboardHeader.css'

export function DashboardHeader() {
  return (
    <header className="dashboard-header">
      <div className="dashboard-header__container">
        <div className="dashboard-header__brand">
          <span className="dashboard-header__logo">💰</span>
          <h1 className="dashboard-header__title">WealthWise</h1>
        </div>

        <nav className="dashboard-header__nav" aria-label="Main navigation">
          <Link
            to="/dashboard"
            className="dashboard-header__link"
            activeProps={{ className: 'dashboard-header__link--active' }}
          >
            Dashboard
          </Link>
          <Link
            to="/accounts"
            className="dashboard-header__link"
            activeProps={{ className: 'dashboard-header__link--active' }}
          >
            Accounts
          </Link>
          <Link
            to="/transactions"
            className="dashboard-header__link"
            activeProps={{ className: 'dashboard-header__link--active' }}
          >
            Transactions
          </Link>
          <Link
            to="/budgets"
            className="dashboard-header__link"
            activeProps={{ className: 'dashboard-header__link--active' }}
          >
            Budgets
          </Link>
          <Link
            to="/goals"
            className="dashboard-header__link"
            activeProps={{ className: 'dashboard-header__link--active' }}
          >
            Goals
          </Link>
          <Link
            to="/reports"
            className="dashboard-header__link"
            activeProps={{ className: 'dashboard-header__link--active' }}
          >
            Reports
          </Link>
          <Link
            to="/settings"
            className="dashboard-header__link"
            activeProps={{ className: 'dashboard-header__link--active' }}
          >
            Settings
          </Link>
        </nav>
      </div>
    </header>
  )
}
