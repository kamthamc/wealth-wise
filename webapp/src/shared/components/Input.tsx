/**
 * Input Component
 * Accessible text input with label and error states
 */

import type { InputHTMLAttributes } from 'react'
import './Input.css'

export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
  helperText?: string
  leftIcon?: React.ReactNode
  rightIcon?: React.ReactNode
}

export function Input({
  label,
  error,
  helperText,
  leftIcon,
  rightIcon,
  id,
  className = '',
  disabled,
  required,
  ...props
}: InputProps) {
  // Generate unique ID if not provided
  const inputId = id || `input-${Math.random().toString(36).slice(2, 11)}`
  const errorId = `${inputId}-error`
  const helperId = `${inputId}-helper`

  const hasError = Boolean(error)
  const hasHelper = Boolean(helperText)

  const classes = [
    'input-wrapper',
    hasError && 'input-wrapper--error',
    disabled && 'input-wrapper--disabled',
    leftIcon && 'input-wrapper--with-left-icon',
    rightIcon && 'input-wrapper--with-right-icon',
    className,
  ]
    .filter(Boolean)
    .join(' ')

  return (
    <div className={classes}>
      {label && (
        <label htmlFor={inputId} className="input-label">
          {label}
          {required && (
            <abbr className="input-label__required" title="required">
              *
            </abbr>
          )}
        </label>
      )}

      <div className="input-container">
        {leftIcon && (
          <span className="input-icon input-icon--left" aria-hidden="true">
            {leftIcon}
          </span>
        )}

        <input
          id={inputId}
          className="input"
          disabled={disabled}
          required={required}
          aria-invalid={hasError}
          aria-describedby={
            [hasError && errorId, hasHelper && helperId].filter(Boolean).join(' ') || undefined
          }
          {...props}
        />

        {rightIcon && (
          <span className="input-icon input-icon--right" aria-hidden="true">
            {rightIcon}
          </span>
        )}
      </div>

      {error && (
        <span className="input-error" id={errorId} role="alert">
          {error}
        </span>
      )}

      {helperText && !error && (
        <span className="input-helper" id={helperId}>
          {helperText}
        </span>
      )}
    </div>
  )
}
