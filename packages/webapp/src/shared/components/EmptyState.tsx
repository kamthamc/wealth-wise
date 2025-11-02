/**
 * Empty State Component
 * Display when there's no data to show with various size options using Radix design tokens
 */

import type { ReactNode } from 'react';

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
}

export function EmptyState({
  icon,
  illustration,
  title,
  description,
  action,
  secondaryAction,
  size = 'medium',
}: EmptyStateProps) {
  // Size-based styles
  const getSizeStyles = () => {
    switch (size) {
      case 'small':
        return {
          padding: 'var(--space-3)',
          iconSize: 'var(--font-size-4)',
          titleSize: 'var(--font-size-3)',
          descriptionSize: 'var(--font-size-2)',
        };
      case 'large':
        return {
          padding: 'var(--space-6)',
          iconSize: 'var(--font-size-6)',
          titleSize: 'var(--font-size-5)',
          descriptionSize: 'var(--font-size-3)',
        };
      case 'medium':
      default:
        return {
          padding: 'var(--space-4)',
          iconSize: 'var(--font-size-5)',
          titleSize: 'var(--font-size-4)',
          descriptionSize: 'var(--font-size-2)',
        };
    }
  };

  const styles = getSizeStyles();

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        textAlign: 'center',
        padding: styles.padding,
        gap: 'var(--space-3)',
        minHeight: size === 'large' ? '300px' : size === 'medium' ? '200px' : '150px',
      }}
    >
      {/* Visual Element */}
      {illustration ? (
        <div aria-hidden="true">
          <img
            src={illustration}
            alt=""
            style={{
              maxWidth: '200px',
              height: 'auto',
              opacity: 0.8,
            }}
          />
        </div>
      ) : icon ? (
        <div
          aria-hidden="true"
          style={{
            fontSize: styles.iconSize,
            color: 'var(--color-text-tertiary)',
            opacity: 0.8,
          }}
        >
          {icon}
        </div>
      ) : null}

      {/* Content */}
      <div style={{ maxWidth: '400px' }}>
        <h2
          style={{
            fontSize: styles.titleSize,
            fontWeight: 'var(--font-weight-semibold)',
            color: 'var(--color-text-primary)',
            margin: 0,
            marginBottom: description ? 'var(--space-2)' : 0,
          }}
        >
          {title}
        </h2>

        {description && (
          <p
            style={{
              fontSize: styles.descriptionSize,
              color: 'var(--color-text-secondary)',
              margin: 0,
              lineHeight: 'var(--leading-relaxed)',
            }}
          >
            {description}
          </p>
        )}
      </div>

      {/* Actions */}
      {(action || secondaryAction) && (
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--space-2)',
            alignItems: 'center',
            width: '100%',
            maxWidth: '300px',
          }}
        >
          {action && <div>{action}</div>}
          {secondaryAction && (
            <div style={{ opacity: 0.8 }}>
              {secondaryAction}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
