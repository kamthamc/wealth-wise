/**
 * Dashboard Layout Component
 * Main layout for the dashboard page
 */

import type { ReactNode } from 'react'
import './DashboardLayout.css'

export interface DashboardLayoutProps {
  children: ReactNode
}

export function DashboardLayout({ children }: DashboardLayoutProps) {
  return (
    <div className="dashboard-layout">
      <div className="dashboard-layout__content">{children}</div>
    </div>
  )
}
