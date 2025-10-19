/**
 * App Layout Component
 * Main application layout with navigation
 */

import { Link, useMatchRoute } from '@tanstack/react-router';
import type { ReactNode } from 'react';
import './AppLayout.css';

interface AppLayoutProps {
  children: ReactNode;
}

interface NavItem {
  to: string;
  icon: string;
  label: string;
}

const NAV_ITEMS: NavItem[] = [
  { to: '/dashboard', icon: '📊', label: 'Dashboard' },
  { to: '/accounts', icon: '🏦', label: 'Accounts' },
  { to: '/transactions', icon: '💸', label: 'Transactions' },
  { to: '/budgets', icon: '💰', label: 'Budgets' },
  { to: '/goals', icon: '🎯', label: 'Goals' },
  { to: '/reports', icon: '📈', label: 'Reports' },
  { to: '/settings', icon: '⚙️', label: 'Settings' },
];

export function AppLayout({ children }: AppLayoutProps) {
  const matchRoute = useMatchRoute();

  return (
    <div className="app-layout">
      {/* Sidebar Navigation */}
      <aside className="app-layout__sidebar">
        <div className="app-layout__logo">
          <span className="logo-icon">💎</span>
          <span className="logo-text">WealthWise</span>
        </div>

        <nav className="app-layout__nav" aria-label="Main navigation">
          <ul className="nav-list">
            {NAV_ITEMS.map((item) => {
              const isActive = matchRoute({ to: item.to, fuzzy: true });
              
              return (
                <li key={item.to} className="nav-item">
                  <Link
                    to={item.to}
                    className={`nav-link ${isActive ? 'nav-link--active' : ''}`}
                    aria-current={isActive ? 'page' : undefined}
                  >
                    <span className="nav-link__icon" aria-hidden="true">
                      {item.icon}
                    </span>
                    <span className="nav-link__label">{item.label}</span>
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>
      </aside>

      {/* Main Content */}
      <main className="app-layout__main" id="main-content">
        {children}
      </main>
    </div>
  );
}
