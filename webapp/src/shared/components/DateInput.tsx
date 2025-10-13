/**
 * Date Input Component
 * Accessible date input with validation
 */

import type { InputHTMLAttributes } from 'react'
import { Input } from './Input'

export interface DateInputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label?: string
  error?: string
  helperText?: string
  min?: string
  max?: string
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
  )
}
