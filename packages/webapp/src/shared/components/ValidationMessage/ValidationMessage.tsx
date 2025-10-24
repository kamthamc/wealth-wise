/**
 * Validation Message Component
 * Display inline validation feedback for form fields
 */

import type { ReactNode } from 'react';
import './ValidationMessage.css';

export interface ValidationMessageProps {
  /** Validation state */
  state?: 'error' | 'success' | 'warning' | 'info';
  /** Message text */
  message?: string;
  /** Icon to display (optional, defaults based on state) */
  icon?: ReactNode;
  /** Additional CSS classes */
  className?: string;
  /** Field ID for aria-describedby */
  fieldId?: string;
}

export function ValidationMessage({
  state = 'error',
  message,
  icon,
  className = '',
  fieldId,
}: ValidationMessageProps) {
  if (!message) return null;

  const stateClass = `validation-message--${state}`;
  const defaultIcons = {
    error: '✕',
    success: '✓',
    warning: '⚠',
    info: 'ℹ',
  };

  return (
    <div
      id={fieldId ? `${fieldId}-validation` : undefined}
      className={`validation-message ${stateClass} ${className}`.trim()}
      role={state === 'error' ? 'alert' : 'status'}
      aria-live={state === 'error' ? 'assertive' : 'polite'}
    >
      <span className="validation-message__icon" aria-hidden="true">
        {icon || defaultIcons[state]}
      </span>
      <span className="validation-message__text">{message}</span>
    </div>
  );
}
