/**
 * TextArea Component
 * Multi-line text input with label and error states
 */

import type { TextareaHTMLAttributes } from 'react';
import './TextArea.css';

export interface TextAreaProps
  extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
  helperText?: string;
  resize?: 'none' | 'vertical' | 'horizontal' | 'both';
}

export function TextArea({
  label,
  error,
  helperText,
  resize = 'vertical',
  id,
  className = '',
  disabled,
  required,
  ...props
}: TextAreaProps) {
  // Generate unique ID if not provided
  const textareaId =
    id || `textarea-${Math.random().toString(36).slice(2, 11)}`;
  const errorId = `${textareaId}-error`;
  const helperId = `${textareaId}-helper`;

  const hasError = Boolean(error);
  const hasHelper = Boolean(helperText);

  const classes = [
    'textarea-wrapper',
    hasError && 'textarea-wrapper--error',
    disabled && 'textarea-wrapper--disabled',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div className={classes}>
      {label && (
        <label htmlFor={textareaId} className="textarea-label">
          {label}
          {required && (
            <abbr className="textarea-label__required" title="required">
              *
            </abbr>
          )}
        </label>
      )}

      <textarea
        id={textareaId}
        className="textarea"
        style={{ resize }}
        disabled={disabled}
        required={required}
        aria-invalid={hasError}
        aria-describedby={
          [hasError && errorId, hasHelper && helperId]
            .filter(Boolean)
            .join(' ') || undefined
        }
        {...props}
      />

      {error && (
        <span className="textarea-error" id={errorId} role="alert">
          {error}
        </span>
      )}

      {helperText && !error && (
        <span className="textarea-helper" id={helperId}>
          {helperText}
        </span>
      )}
    </div>
  );
}
