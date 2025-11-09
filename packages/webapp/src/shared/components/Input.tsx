/**
 * Input Component
 * Accessible text input with label and error states using Radix UI styling
 */

import type { ReactNode, InputHTMLAttributes } from 'react';

export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
  leftIcon?: ReactNode;
  rightIcon?: ReactNode;
}

export function Input({
  label,
  error,
  helperText,
  leftIcon,
  rightIcon,
  placeholder,
  value,
  onChange,
  disabled,
  required,
  type = 'text',
  id,
  name,
  autoComplete,
  minLength,
  ...props
}: InputProps) {
  return (
    <div>
      {label && (
        <label
          htmlFor={id}
          style={{
            display: 'block',
            fontSize: 'var(--font-size-2)',
            fontWeight: 'var(--font-weight-medium)',
            color: 'var(--color-text-secondary)',
            marginBottom: '0.5rem'
          }}
        >
          {label}
          {required && (
            <span style={{ color: 'var(--color-red-600)', marginLeft: '0.25rem' }}>
              *
            </span>
          )}
        </label>
      )}

      <div style={{ position: 'relative' }}>
        {leftIcon && (
          <div
            style={{
              position: 'absolute',
              left: '0.75rem',
              top: '50%',
              transform: 'translateY(-50%)',
              color: 'var(--color-text-tertiary)',
              zIndex: 1
            }}
          >
            {leftIcon}
          </div>
        )}

        <input
          id={id}
          name={name}
          type={type}
          placeholder={placeholder}
          value={value}
          onChange={onChange}
          disabled={disabled}
          required={required}
          autoComplete={autoComplete}
          minLength={minLength}
          style={{
            width: '100%',
            padding: '0.5rem 0.75rem',
            paddingLeft: leftIcon ? '2.5rem' : '0.75rem',
            paddingRight: rightIcon ? '2.5rem' : '0.75rem',
            border: '1px solid var(--color-border-primary)',
            borderRadius: 'var(--radius-md)',
            fontSize: 'var(--font-size-2)',
            backgroundColor: 'var(--bg-primary)',
            color: 'var(--color-text-primary)',
            outline: 'none',
            transition: 'border-color 0.2s ease',
            ...(error && { borderColor: 'var(--color-red-600)' }),
            ...(!disabled && {
              ':focus': {
                borderColor: 'var(--color-blue-600)',
                boxShadow: '0 0 0 2px var(--color-blue-100)'
              }
            })
          }}
          {...props}
        />

        {rightIcon && (
          <div
            style={{
              position: 'absolute',
              right: '0.75rem',
              top: '50%',
              transform: 'translateY(-50%)',
              color: 'var(--color-text-tertiary)',
              zIndex: 1
            }}
          >
            {rightIcon}
          </div>
        )}
      </div>

      {error && (
        <div
          style={{
            fontSize: 'var(--font-size-1)',
            color: 'var(--color-red-600)',
            marginTop: '0.25rem'
          }}
          role="alert"
        >
          {error}
        </div>
      )}

      {helperText && !error && (
        <div
          style={{
            fontSize: 'var(--font-size-1)',
            color: 'var(--color-text-tertiary)',
            marginTop: '0.25rem'
          }}
        >
          {helperText}
        </div>
      )}
    </div>
  );
}
