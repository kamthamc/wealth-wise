/**
 * App Layout Component
 * Main application layout with collapsible navigation
 */

import { Link, useMatchRoute } from '@tanstack/react-router';
import {
  ArrowLeftRight,
  BarChart3,
  Landmark,
  LayoutDashboard,
  Menu,
  Settings,
  Target,
  Wallet,
  X,
} from 'lucide-react';
import { type ReactNode, useState } from 'react';
import { LogoIcon } from '../LogoIcon';
import './AppLayout.css';

interface AppLayoutProps {
  children: ReactNode;
}

interface NavItem {
  to: string;
  icon: ReactNode;
  label: string;
}

const NAV_ITEMS: NavItem[] = [
  { to: '/dashboard', icon: <LayoutDashboard size={20} />, label: 'Dashboard' },
  { to: '/accounts', icon: <Landmark size={20} />, label: 'Accounts' },
  {
    to: '/transactions',
    icon: <ArrowLeftRight size={20} />,
    label: 'Transactions',
  },
  { to: '/budgets', icon: <Wallet size={20} />, label: 'Budgets' },
  { to: '/goals', icon: <Target size={20} />, label: 'Goals' },
  { to: '/reports', icon: <BarChart3 size={20} />, label: 'Reports' },
  { to: '/settings', icon: <Settings size={20} />, label: 'Settings' },
];

export function AppLayout({ children }: AppLayoutProps) {
  const matchRoute = useMatchRoute();
  const [isCollapsed, setIsCollapsed] = useState(false);
  const [isMobileOpen, setIsMobileOpen] = useState(false);

  return (
    <div className="app-layout">
      {/* Mobile Header with Hamburger */}
      <div className="app-layout__mobile-header">
        <button
          type="button"
          className="app-layout__hamburger"
          onClick={() => setIsMobileOpen(!isMobileOpen)}
          aria-label={isMobileOpen ? 'Close menu' : 'Open menu'}
          aria-expanded={isMobileOpen}
        >
          {isMobileOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
        <div className="app-layout__mobile-brand">
          <span className="logo-icon">
            <LogoIcon size={28} />
          </span>
          <span className="logo-text">WealthWise</span>
        </div>
      </div>

      {/* Sidebar Navigation */}
      <aside
        className={`app-layout__sidebar ${isCollapsed ? 'app-layout__sidebar--collapsed' : ''} ${isMobileOpen ? 'app-layout__sidebar--mobile-open' : ''}`}
      >
        <div className="app-layout__logo">
          <span className="logo-icon">
            <LogoIcon size={32} />
          </span>
          {!isCollapsed && <span className="logo-text">WealthWise</span>}
        </div>

        {/* Desktop Collapse Toggle */}
        <button
          type="button"
          className="app-layout__collapse-toggle"
          onClick={() => setIsCollapsed(!isCollapsed)}
          aria-label={isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          title={isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          <span className="collapse-icon">{isCollapsed ? '→' : '←'}</span>
        </button>

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
                    onClick={() => setIsMobileOpen(false)}
                    title={isCollapsed ? item.label : undefined}
                  >
                    <span className="nav-link__icon" aria-hidden="true">
                      {item.icon}
                    </span>
                    {!isCollapsed && (
                      <span className="nav-link__label">{item.label}</span>
                    )}
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>
      </aside>

      {/* Mobile Overlay */}
      {isMobileOpen && (
        <div
          className="app-layout__overlay"
          onClick={() => setIsMobileOpen(false)}
          aria-hidden="true"
        />
      )}

      {/* Main Content */}
      <main
        className={`app-layout__main ${isCollapsed ? 'app-layout__main--expanded' : ''}`}
        id="main-content"
      >
        {children}
      </main>
    </div>
  );
}
