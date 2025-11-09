/**
 * Checkbox Component
 * Accessible checkbox input with label using Radix UI
 */

import { Checkbox as RadixCheckbox } from '@radix-ui/themes';

export interface CheckboxProps {
  label: string;
  error?: string;
  helperText?: string;
  checked?: boolean;
  onCheckedChange?: (checked: boolean) => void;
  disabled?: boolean;
  id?: string;
  name?: string;
}

export function Checkbox({
  label,
  error,
  helperText,
  checked,
  onCheckedChange,
  disabled,
  id,
  name,
  ...props
}: CheckboxProps) {
  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
        <RadixCheckbox
          id={id}
          name={name}
          checked={checked}
          onCheckedChange={onCheckedChange}
          disabled={disabled}
          {...props}
        />
        <label
          htmlFor={id}
          style={{
            fontSize: 'var(--font-size-2)',
            color: 'var(--color-text-primary)',
            cursor: disabled ? 'not-allowed' : 'pointer',
            opacity: disabled ? 0.6 : 1
          }}
        >
          {label}
        </label>
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
