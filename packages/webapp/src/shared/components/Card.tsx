/**
 * Card Component
 * Container component for grouping related content using Radix UI
 */

import type { ReactNode } from 'react';
import { Card as RadixCard } from '@radix-ui/themes';

export interface CardProps {
  variant?: 'default' | 'outlined' | 'elevated';
  padding?: 'none' | 'small' | 'medium' | 'large';
  interactive?: boolean;
  header?: ReactNode;
  footer?: ReactNode;
  children: ReactNode;
  className?: string;
  onClick?: () => void;
}

export function Card({
  variant = 'default',
  padding = 'medium',
  interactive = false,
  header,
  footer,
  children,
  className,
  onClick,
  ...props
}: CardProps) {
  // Map padding to Radix size
  const getSize = () => {
    switch (padding) {
      case 'none':
        return '1';
      case 'small':
        return '2';
      case 'medium':
        return '3';
      case 'large':
        return '4';
      default:
        return '3';
    }
  };

  return (
    <RadixCard
      size={getSize()}
      variant={variant === 'outlined' ? 'classic' : 'surface'}
      className={className}
      style={{
        cursor: interactive || onClick ? 'pointer' : 'default',
        transition: interactive || onClick ? 'transform 0.2s ease, box-shadow 0.2s ease' : undefined,
        ...(variant === 'elevated' && { boxShadow: 'var(--shadow-4)' })
      }}
      onClick={onClick}
      {...props}
    >
      {header && (
        <div style={{ marginBottom: 'var(--space-3)' }}>
          {header}
        </div>
      )}

      {children}

      {footer && (
        <div style={{ marginTop: 'var(--space-3)', borderTop: '1px solid var(--color-border-primary)', paddingTop: 'var(--space-3)' }}>
          {footer}
        </div>
      )}
    </RadixCard>
  );
}
