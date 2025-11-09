/**
 * Progress Bar Component
 * Visual indicator of progress or completion using Radix UI
 */

import { Progress } from '@radix-ui/themes';

export interface ProgressBarProps {
  value: number;
  max?: number;
  label?: string;
  showValue?: boolean;
  variant?: 'default' | 'primary' | 'success' | 'warning' | 'danger';
  size?: 'small' | 'medium' | 'large';
}

export function ProgressBar({
  value,
  max = 100,
  label,
  showValue = false,
  variant = 'primary',
  size = 'medium',
}: ProgressBarProps) {
  const percentage = Math.min(Math.max((value / max) * 100, 0), 100);

  // Map variants to Radix colors
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
      case 'default':
      default:
        return 'gray';
    }
  };

  // Map sizes to Radix sizes
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

  return (
    <div>
      {(label || showValue) && (
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: 'var(--space-2)',
          }}
        >
          {label && (
            <span
              style={{
                fontSize: 'var(--font-size-2)',
                fontWeight: 'var(--font-weight-medium)',
                color: 'var(--color-text-primary)',
              }}
            >
              {label}
            </span>
          )}
          {showValue && (
            <span
              style={{
                fontSize: 'var(--font-size-1)',
                color: 'var(--color-text-secondary)',
              }}
            >
              {value}/{max}
            </span>
          )}
        </div>
      )}

      <Progress
        value={percentage}
        max={100}
        size={getRadixSize()}
        color={getRadixColor()}
      />
    </div>
  );
}
