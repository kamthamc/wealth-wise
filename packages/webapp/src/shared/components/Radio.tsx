/**
 * Radio Component
 * Accessible radio button group
 */

import type { InputHTMLAttributes } from 'react';
import './Radio.css';

export interface RadioOption {
  value: string;
  label: string;
  disabled?: boolean;
}

export interface RadioGroupProps {
  name: string;
  label?: string;
  options: RadioOption[];
  value?: string;
  onChange?: (value: string) => void;
  error?: string;
  helperText?: string;
  disabled?: boolean;
  required?: boolean;
  className?: string;
}

export function RadioGroup({
  name,
  label,
  options,
  value,
  onChange,
  error,
  helperText,
  disabled,
  required,
  className = '',
}: RadioGroupProps) {
  const groupId = `radio-group-${Math.random().toString(36).slice(2, 11)}`;
  const errorId = `${groupId}-error`;
  const helperId = `${groupId}-helper`;

  const hasError = Boolean(error);
  const hasHelper = Boolean(helperText);

  const classes = [
    'radio-group',
    hasError && 'radio-group--error',
    disabled && 'radio-group--disabled',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  const handleChange = (optionValue: string) => {
    if (onChange && !disabled) {
      onChange(optionValue);
    }
  };

  return (
    <div className={classes}>
      {label && (
        <div className="radio-group-label">
          {label}
          {required && (
            <abbr className="radio-group-label__required" title="required">
              *
            </abbr>
          )}
        </div>
      )}

      <div
        className="radio-group-options"
        role="radiogroup"
        aria-labelledby={label ? groupId : undefined}
        aria-invalid={hasError}
        aria-describedby={
          [hasError && errorId, hasHelper && helperId]
            .filter(Boolean)
            .join(' ') || undefined
        }
      >
        {options.map((option) => (
          <Radio
            key={option.value}
            name={name}
            value={option.value}
            label={option.label}
            checked={value === option.value}
            onChange={() => handleChange(option.value)}
            disabled={disabled || option.disabled}
          />
        ))}
      </div>

      {error && (
        <span className="radio-group-error" id={errorId} role="alert">
          {error}
        </span>
      )}

      {helperText && !error && (
        <span className="radio-group-helper" id={helperId}>
          {helperText}
        </span>
      )}
    </div>
  );
}

interface RadioProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label: string;
}

export function Radio({
  label,
  id,
  className = '',
  disabled,
  ...props
}: RadioProps) {
  const radioId = id || `radio-${Math.random().toString(36).slice(2, 11)}`;

  return (
    <div className={`radio-wrapper ${className}`}>
      <input
        type="radio"
        id={radioId}
        className="radio-input"
        disabled={disabled}
        {...props}
      />
      <label htmlFor={radioId} className="radio-label">
        {label}
      </label>
    </div>
  );
}
