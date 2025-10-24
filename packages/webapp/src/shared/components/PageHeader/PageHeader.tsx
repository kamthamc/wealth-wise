/**
 * Page Header Component
 * Simple page title and description header (no navigation)
 */

import type { ReactNode } from 'react';
import './PageHeader.css';

interface PageHeaderProps {
  /** Page title */
  title: string;
  /** Optional page description */
  description?: string;
  /** Optional actions to display on the right */
  actions?: ReactNode;
  /** Optional icon/emoji */
  icon?: string;
}

export function PageHeader({
  title,
  description,
  actions,
  icon,
}: PageHeaderProps) {
  return (
    <div className="page-header">
      <div className="page-header__content">
        {icon && (
          <span className="page-header__icon" aria-hidden="true">
            {icon}
          </span>
        )}
        <div className="page-header__text">
          <h1 className="page-header__title">{title}</h1>
          {description && (
            <p className="page-header__description">{description}</p>
          )}
        </div>
      </div>
      {actions && <div className="page-header__actions">{actions}</div>}
    </div>
  );
}
