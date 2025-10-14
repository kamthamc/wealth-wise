/**
 * Empty State Component
 * Display when there's no data to show
 */

import type { ReactNode } from 'react';
import './EmptyState.css';

export interface EmptyStateProps {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
}

export function EmptyState({
  icon,
  title,
  description,
  action,
}: EmptyStateProps) {
  return (
    <div className="empty-state">
      {icon && (
        <div className="empty-state__icon" aria-hidden="true">
          {icon}
        </div>
      )}

      <h2 className="empty-state__title">{title}</h2>

      {description && <p className="empty-state__description">{description}</p>}

      {action && <div className="empty-state__action">{action}</div>}
    </div>
  );
}
