/**
 * Currency Input Component
 * Specialized input for currency values with formatting
 */

import { type InputHTMLAttributes, useState } from 'react';
import { Input } from './Input';

export interface CurrencyInputProps
  extends Omit<
    InputHTMLAttributes<HTMLInputElement>,
    'type' | 'value' | 'onChange'
  > {
  label?: string;
  error?: string;
  helperText?: string;
  value?: number;
  onChange?: (value: number | null) => void;
  currency?: string;
  locale?: string;
  allowNegative?: boolean;
}

export function CurrencyInput({
  label,
  error,
  helperText,
  value,
  onChange,
  currency = 'INR',
  locale = 'en-IN',
  allowNegative = false,
  disabled,
  required,
  ...props
}: CurrencyInputProps) {
  const [displayValue, setDisplayValue] = useState(() => {
    return value !== undefined && value !== null
      ? formatCurrency(value, locale, currency)
      : '';
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const inputValue = e.target.value;

    // Remove all non-numeric characters except decimal point and minus
    let cleanValue = inputValue.replace(/[^\d.-]/g, '');

    // Remove minus if not allowed
    if (!allowNegative) {
      cleanValue = cleanValue.replace(/-/g, '');
    }

    // Ensure only one decimal point
    const parts = cleanValue.split('.');
    if (parts.length > 2) {
      cleanValue = `${parts[0]}.${parts.slice(1).join('')}`;
    }

    // Ensure only one minus at the start
    if (allowNegative) {
      const minusCount = (cleanValue.match(/-/g) || []).length;
      if (minusCount > 1) {
        cleanValue = `-${cleanValue.replace(/-/g, '')}`;
      } else if (cleanValue.includes('-') && !cleanValue.startsWith('-')) {
        cleanValue = `-${cleanValue.replace(/-/g, '')}`;
      }
    }

    // Limit to 2 decimal places
    if (parts.length === 2 && parts[1] && parts[1].length > 2) {
      cleanValue = `${parts[0]}.${parts[1].slice(0, 2)}`;
    }

    setDisplayValue(cleanValue);

    // Parse and call onChange
    if (onChange) {
      if (cleanValue === '' || cleanValue === '-') {
        onChange(null);
      } else {
        const numericValue = Number.parseFloat(cleanValue);
        if (!Number.isNaN(numericValue)) {
          onChange(numericValue);
        }
      }
    }
  };

  const handleBlur = () => {
    // Format the value on blur
    if (displayValue && displayValue !== '-') {
      const numericValue = Number.parseFloat(displayValue);
      if (!Number.isNaN(numericValue)) {
        setDisplayValue(formatCurrency(numericValue, locale, currency));
      }
    }
  };

  const handleFocus = () => {
    // Remove formatting on focus for easier editing
    if (displayValue) {
      const numericValue = Number.parseFloat(
        displayValue.replace(/[^\d.-]/g, '')
      );
      if (!Number.isNaN(numericValue)) {
        setDisplayValue(numericValue.toString());
      }
    }
  };

  return (
    <Input
      type="text"
      inputMode="decimal"
      label={label}
      error={error}
      helperText={helperText}
      value={displayValue}
      onChange={handleChange}
      onBlur={handleBlur}
      onFocus={handleFocus}
      disabled={disabled}
      required={required}
      {...props}
    />
  );
}

function formatCurrency(
  value: number,
  locale: string,
  currency: string
): string {
  try {
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value);
  } catch {
    // Fallback if locale or currency is invalid
    return value.toFixed(2);
  }
}
