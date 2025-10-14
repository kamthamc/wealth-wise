/**
 * Select Component
 * Accessible dropdown select with label and error states
 */

import type { SelectHTMLAttributes } from 'react';
import './Select.css';

export interface SelectOption {
  value: string;
  label: string;
  disabled?: boolean;
}

export interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label?: string;
  error?: string;
  helperText?: string;
  options: SelectOption[];
  placeholder?: string;
}

export function Select({
  label,
  error,
  helperText,
  options,
  placeholder,
  id,
  className = '',
  disabled,
  required,
  ...props
}: SelectProps) {
  // Generate unique ID if not provided
  const selectId = id || `select-${Math.random().toString(36).slice(2, 11)}`;
  const errorId = `${selectId}-error`;
  const helperId = `${selectId}-helper`;

  const hasError = Boolean(error);
  const hasHelper = Boolean(helperText);

  const classes = [
    'select-wrapper',
    hasError && 'select-wrapper--error',
    disabled && 'select-wrapper--disabled',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div className={classes}>
      {label && (
        <label htmlFor={selectId} className="select-label">
          {label}
          {required && (
            <abbr className="select-label__required" title="required">
              *
            </abbr>
          )}
        </label>
      )}

      <div className="select-container">
        <select
          id={selectId}
          className="select"
          disabled={disabled}
          required={required}
          aria-invalid={hasError}
          aria-describedby={
            [hasError && errorId, hasHelper && helperId]
              .filter(Boolean)
              .join(' ') || undefined
          }
          {...props}
        >
          {placeholder && (
            <option value="" disabled>
              {placeholder}
            </option>
          )}
          {options.map((option) => (
            <option
              key={option.value}
              value={option.value}
              disabled={option.disabled}
            >
              {option.label}
            </option>
          ))}
        </select>
        <span className="select-icon" aria-hidden="true">
          ▼
        </span>
      </div>

      {error && (
        <span className="select-error" id={errorId} role="alert">
          {error}
        </span>
      )}

      {helperText && !error && (
        <span className="select-helper" id={helperId}>
          {helperText}
        </span>
      )}
    </div>
  );
}
