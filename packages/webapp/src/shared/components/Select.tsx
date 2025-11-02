/**
 * Select Component
 * Accessible dropdown select with label and error states using Radix UI
 */

import { Select as RadixSelect } from '@radix-ui/themes';

export interface SelectOption {
  value: string;
  label: string;
  disabled?: boolean;
}

export interface SelectProps {
  label?: string;
  error?: string;
  helperText?: string;
  options: SelectOption[];
  placeholder?: string;
  value?: string;
  onValueChange?: (value: string) => void;
  onChange?: (e: React.ChangeEvent<HTMLSelectElement>) => void;
  disabled?: boolean;
  required?: boolean;
  id?: string;
  name?: string;
}

export function Select({
  label,
  error,
  helperText,
  options,
  placeholder,
  value,
  onValueChange,
  disabled,
  required,
  id,
  name,
}: SelectProps) {
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
            marginBottom: '0.5rem',
          }}
        >
          {label}
          {required && (
            <span
              style={{
                color: 'var(--color-red-600)',
                marginLeft: '0.25rem',
              }}
            >
              *
            </span>
          )}
        </label>
      )}

      <RadixSelect.Root
        value={value}
        onValueChange={onValueChange}
        disabled={disabled}
        required={required}
        name={name}
      >
        <RadixSelect.Trigger
          id={id}
          style={{
            width: '100%',
            ...(error && { borderColor: 'var(--color-red-600)' }),
          }}
        />
        <RadixSelect.Content>
          {placeholder && (
            <RadixSelect.Group>
              <RadixSelect.Item value="" disabled>
                {placeholder}
              </RadixSelect.Item>
            </RadixSelect.Group>
          )}
          <RadixSelect.Group>
            {options.map((option) => (
              <RadixSelect.Item
                key={option.value}
                value={option.value}
                disabled={option.disabled}
              >
                {option.label}
              </RadixSelect.Item>
            ))}
          </RadixSelect.Group>
        </RadixSelect.Content>
      </RadixSelect.Root>

      {error && (
        <div
          style={{
            fontSize: 'var(--font-size-1)',
            color: 'var(--color-red-600)',
            marginTop: '0.25rem',
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
            marginTop: '0.25rem',
          }}
        >
          {helperText}
        </div>
      )}
    </div>
  );
}
