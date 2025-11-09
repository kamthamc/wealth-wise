/**
 * Badge Component
 * Small status indicator or label using Radix UI
 */

import type { ReactNode } from 'react';
import { Badge as RadixBadge } from '@radix-ui/themes';

export type BadgeVariant =
  | 'default'
  | 'primary'
  | 'success'
  | 'warning'
  | 'danger'
  | 'info';
export type BadgeSize = 'small' | 'medium' | 'large';

export interface BadgeProps {
  variant?: BadgeVariant;
  size?: BadgeSize;
  children: ReactNode;
  dot?: boolean;
}

export function Badge({
  variant = 'default',
  size = 'medium',
  children,
  dot = false,
}: BadgeProps) {
  // Map our variants to Radix colors
  const getRadixColor = () => {
    switch (variant) {
      case 'primary':
        return 'blue';
      case 'success':
        return 'green';
      case 'warning':
        return 'yellow';
      case 'danger':
        return 'red';
      case 'info':
        return 'blue';
      case 'default':
      default:
        return 'gray';
    }
  };

  // Map our sizes to Radix sizes
  const getRadixSize = () => {
    switch (size) {
      case 'small':
        return '1';
      case 'medium':
        return '2';
      case 'large':
        return '3';
      default:
        return '2';
    }
  };

  // Map our variants to Radix variants
  const getRadixVariant = () => {
    return variant === 'default' ? 'soft' : 'solid';
  };

  return (
    <RadixBadge
      color={getRadixColor()}
      size={getRadixSize()}
      variant={getRadixVariant()}
    >
      {dot && (
        <span
          style={{
            width: '6px',
            height: '6px',
            borderRadius: '50%',
            backgroundColor: 'currentcolor',
            marginRight: 'var(--space-1)',
            flexShrink: 0,
          }}
          aria-hidden="true"
        />
      )}
      {children}
    </RadixBadge>
  );
}
