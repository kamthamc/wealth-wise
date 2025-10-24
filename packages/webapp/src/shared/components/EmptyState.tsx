/**
 * Empty State Component
 * Display when there's no data to show with various size options
 */

import type { ReactNode } from 'react';
import './EmptyState.css';

export interface EmptyStateProps {
  /** Icon or emoji to display */
  icon?: ReactNode;
  /** Optional illustration image URL */
  illustration?: string;
  /** Main title text */
  title: string;
  /** Optional description text */
  description?: string;
  /** Primary action button */
  action?: ReactNode;
  /** Secondary action (e.g., link to help docs) */
  secondaryAction?: ReactNode;
  /** Size variant */
  size?: 'small' | 'medium' | 'large';
  /** Additional CSS classes */
  className?: string;
}

export function EmptyState({
  icon,
  illustration,
  title,
  description,
  action,
  secondaryAction,
  size = 'medium',
  className = '',
}: EmptyStateProps) {
  const sizeClass = `empty-state--${size}`;

  return (
    <div className={`empty-state ${sizeClass} ${className}`.trim()}>
      {/* Visual Element */}
      {illustration ? (
        <div className="empty-state__illustration" aria-hidden="true">
          <img
            src={illustration}
            alt=""
            className="empty-state__illustration-img"
          />
        </div>
      ) : icon ? (
        <div className="empty-state__icon" aria-hidden="true">
          {icon}
        </div>
      ) : null}

      {/* Content */}
      <div className="empty-state__content">
        <h2 className="empty-state__title">{title}</h2>

        {description && (
          <p className="empty-state__description">{description}</p>
        )}
      </div>

      {/* Actions */}
      {(action || secondaryAction) && (
        <div className="empty-state__actions">
          {action && <div className="empty-state__action">{action}</div>}
          {secondaryAction && (
            <div className="empty-state__secondary-action">
              {secondaryAction}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
