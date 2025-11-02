/**
 * Date Input Component
 * Accessible date input with validation
 */

import type { InputHTMLAttributes } from 'react';
import { Input } from './Input';

export interface DateInputProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type' | 'value'> {
  label?: string;
  error?: string;
  helperText?: string;
  min?: string;
  max?: string;
  /**
   * Explicit value type to match our shared `Input` component.
   * InputHTMLAttributes can include readonly string[] for multiple selects,
   * which is not compatible with our `Input` implementation. Narrow the
   * type here to avoid spreading incompatible props.
   */
  value?: string | number;
}

export function DateInput({
  label,
  error,
  helperText,
  min,
  max,
  disabled,
  required,
  ...props
}: DateInputProps) {
  return (
    <Input
      type="date"
      label={label}
      error={error}
      helperText={helperText}
      min={min}
      max={max}
      disabled={disabled}
      required={required}
      {...props}
    />
  );
}
