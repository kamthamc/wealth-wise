/**
 * Radio Component
 * Accessible radio button group using styled HTML elements
 */

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
}: RadioGroupProps) {
  const handleChange = (optionValue: string) => {
    if (onChange && !disabled) {
      onChange(optionValue);
    }
  };

  return (
    <div>
      {label && (
        <div
          style={{
            fontSize: 'var(--font-size-2)',
            fontWeight: 'var(--font-weight-medium)',
            color: 'var(--color-text-secondary)',
            marginBottom: 'var(--space-2)',
          }}
        >
          {label}
          {required && (
            <span style={{ color: 'var(--color-red-600)', marginLeft: '0.25rem' }}>
              *
            </span>
          )}
        </div>
      )}

      <div
        role="radiogroup"
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 'var(--space-2)',
        }}
      >
        {options.map((option) => (
          <div
            key={option.value}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 'var(--space-2)',
            }}
          >
            <input
              type="radio"
              id={`${name}-${option.value}`}
              name={name}
              value={option.value}
              checked={value === option.value}
              onChange={() => handleChange(option.value)}
              disabled={disabled || option.disabled}
              required={required}
              style={{
                width: '1rem',
                height: '1rem',
                accentColor: 'var(--color-blue-600)',
              }}
            />
            <label
              htmlFor={`${name}-${option.value}`}
              style={{
                fontSize: 'var(--font-size-2)',
                color: 'var(--color-text-primary)',
                cursor: disabled || option.disabled ? 'not-allowed' : 'pointer',
                opacity: disabled || option.disabled ? 0.6 : 1,
              }}
            >
              {option.label}
            </label>
          </div>
        ))}
      </div>

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
