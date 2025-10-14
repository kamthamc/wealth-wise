/**
 * Progress Bar Component
 * Visual indicator of progress or completion
 */

import type { HTMLAttributes } from 'react';
import './ProgressBar.css';

export interface ProgressBarProps
  extends Omit<HTMLAttributes<HTMLDivElement>, 'children'> {
  value: number;
  max?: number;
  label?: string;
  showValue?: boolean;
  variant?: 'default' | 'primary' | 'success' | 'warning' | 'danger';
  size?: 'small' | 'medium' | 'large';
  animated?: boolean;
}

export function ProgressBar({
  value,
  max = 100,
  label,
  showValue = false,
  variant = 'primary',
  size = 'medium',
  animated = false,
  className = '',
  ...props
}: ProgressBarProps) {
  const percentage = Math.min(Math.max((value / max) * 100, 0), 100);

  const classes = [
    'progress-bar',
    `progress-bar--${variant}`,
    `progress-bar--${size}`,
    animated && 'progress-bar--animated',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div className={classes} {...props}>
      {(label || showValue) && (
        <div className="progress-bar__header">
          {label && <span className="progress-bar__label">{label}</span>}
          {showValue && (
            <span className="progress-bar__value">
              {value}/{max}
            </span>
          )}
        </div>
      )}

      <div
        className="progress-bar__track"
        role="progressbar"
        aria-valuenow={value}
        aria-valuemin={0}
        aria-valuemax={max}
      >
        <div className="progress-bar__fill" style={{ width: `${percentage}%` }}>
          {showValue && !label && (
            <span className="progress-bar__percentage">
              {Math.round(percentage)}%
            </span>
          )}
        </div>
      </div>
    </div>
  );
}
