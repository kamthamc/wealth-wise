/**
 * Checkbox Component
 * Accessible checkbox input with label
 */

import type { InputHTMLAttributes } from 'react'
import './Checkbox.css'

export interface CheckboxProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label: string
  error?: string
  helperText?: string
}

export function Checkbox({
  label,
  error,
  helperText,
  id,
  className = '',
  disabled,
  ...props
}: CheckboxProps) {
  // Generate unique ID if not provided
  const checkboxId = id || `checkbox-${Math.random().toString(36).slice(2, 11)}`
  const errorId = `${checkboxId}-error`
  const helperId = `${checkboxId}-helper`

  const hasError = Boolean(error)
  const hasHelper = Boolean(helperText)

  const classes = [
    'checkbox-wrapper',
    hasError && 'checkbox-wrapper--error',
    disabled && 'checkbox-wrapper--disabled',
    className,
  ]
    .filter(Boolean)
    .join(' ')

  return (
    <div className={classes}>
      <div className="checkbox-container">
        <input
          type="checkbox"
          id={checkboxId}
          className="checkbox-input"
          disabled={disabled}
          aria-invalid={hasError}
          aria-describedby={
            [hasError && errorId, hasHelper && helperId].filter(Boolean).join(' ') || undefined
          }
          {...props}
        />
        <label htmlFor={checkboxId} className="checkbox-label">
          {label}
        </label>
      </div>

      {error && (
        <span className="checkbox-error" id={errorId} role="alert">
          {error}
        </span>
      )}

      {helperText && !error && (
        <span className="checkbox-helper" id={helperId}>
          {helperText}
        </span>
      )}
    </div>
  )
}
