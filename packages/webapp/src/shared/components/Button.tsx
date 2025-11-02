/**
 * Button Component
 * Accessible button with multiple variants using Radix UI
 */

import type { ReactNode } from 'react';
import { Button as RadixButton } from '@radix-ui/themes';

export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';
export type ButtonSize = 'small' | 'medium' | 'large';

export interface ButtonProps {
  variant?: ButtonVariant;
  size?: ButtonSize;
  isLoading?: boolean;
  leftIcon?: ReactNode;
  rightIcon?: ReactNode;
  fullWidth?: boolean;
  children: ReactNode;
  disabled?: boolean;
  type?: 'button' | 'submit' | 'reset';
  onClick?: () => void;
}

export function Button({
  variant = 'primary',
  size = 'medium',
  isLoading = false,
  leftIcon,
  rightIcon,
  fullWidth = false,
  children,
  disabled,
  type = 'button',
  onClick,
  ...props
}: ButtonProps) {
  // Map our variants to Radix variants
  const getRadixVariant = () => {
    switch (variant) {
      case 'primary':
        return 'solid';
      case 'secondary':
        return 'soft';
      case 'ghost':
        return 'ghost';
      case 'danger':
        return 'solid';
      default:
        return 'solid';
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

  // Map our colors to Radix colors
  const getRadixColor = () => {
    if (variant === 'danger') return 'red';
    return 'blue';
  };

  return (
    <RadixButton
      type={type}
      variant={getRadixVariant()}
      size={getRadixSize()}
      color={getRadixColor()}
      disabled={disabled || isLoading}
      loading={isLoading}
      style={fullWidth ? { width: '100%' } : undefined}
      onClick={onClick}
      {...props}
    >
      {leftIcon && <span style={{ marginRight: '0.5rem' }}>{leftIcon}</span>}
      {children}
      {rightIcon && <span style={{ marginLeft: '0.5rem' }}>{rightIcon}</span>}
    </RadixButton>
  );
}
