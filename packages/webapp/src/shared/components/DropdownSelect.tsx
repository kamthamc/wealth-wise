/**
 * Dropdown Select Component
 * Accessible dropdown using Radix UI DropdownMenu
 */

import * as DropdownMenu from '@radix-ui/react-dropdown-menu';
import { Check, ChevronDown } from 'lucide-react';
import './DropdownSelect.css';

export interface DropdownSelectOption {
  value: string;
  label: string;
  disabled?: boolean;
}

export interface DropdownSelectProps {
  label?: string;
  error?: string;
  helperText?: string;
  options: DropdownSelectOption[];
  placeholder?: string;
  value: string;
  onChange: (value: string) => void;
  id?: string;
  className?: string;
  disabled?: boolean;
  required?: boolean;
}

export function DropdownSelect({
  label,
  error,
  helperText,
  options,
  placeholder = 'Select an option...',
  value,
  onChange,
  id,
  className = '',
  disabled = false,
  required = false,
}: DropdownSelectProps) {
  const selectId =
    id || `dropdown-select-${Math.random().toString(36).slice(2, 11)}`;
  const errorId = `${selectId}-error`;
  const helperId = `${selectId}-helper`;

  const hasError = Boolean(error);
  const hasHelper = Boolean(helperText);

  const selectedOption = options.find((opt) => opt.value === value);

  const classes = [
    'dropdown-select-wrapper',
    hasError && 'dropdown-select-wrapper--error',
    disabled && 'dropdown-select-wrapper--disabled',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div className={classes}>
      {label && (
        <label htmlFor={selectId} className="dropdown-select-label">
          {label}
          {required && (
            <abbr className="dropdown-select-label__required" title="required">
              *
            </abbr>
          )}
        </label>
      )}

      <DropdownMenu.Root>
        <DropdownMenu.Trigger asChild disabled={disabled}>
          <button
            type="button"
            id={selectId}
            className="dropdown-select-trigger"
            aria-invalid={hasError}
            aria-describedby={
              [hasError && errorId, hasHelper && helperId]
                .filter(Boolean)
                .join(' ') || undefined
            }
            aria-required={required}
          >
            <span className="dropdown-select-trigger__text">
              {selectedOption?.label || placeholder}
            </span>
            <ChevronDown size={16} className="dropdown-select-trigger__icon" />
          </button>
        </DropdownMenu.Trigger>

        <DropdownMenu.Portal>
          <DropdownMenu.Content
            className="dropdown-select-content"
            align="start"
            sideOffset={5}
          >
            {options.length === 0 ? (
              <DropdownMenu.Item className="dropdown-select-item" disabled>
                No options available
              </DropdownMenu.Item>
            ) : (
              options.map((option) => (
                <DropdownMenu.Item
                  key={option.value}
                  className="dropdown-select-item"
                  onSelect={() => onChange(option.value)}
                  disabled={option.disabled}
                >
                  <span className="dropdown-select-item__label">
                    {option.label}
                  </span>
                  {value === option.value && (
                    <Check size={16} className="dropdown-select-item__check" />
                  )}
                </DropdownMenu.Item>
              ))
            )}
          </DropdownMenu.Content>
        </DropdownMenu.Portal>
      </DropdownMenu.Root>

      {error && (
        <span className="dropdown-select-error" id={errorId} role="alert">
          {error}
        </span>
      )}

      {helperText && !error && (
        <span className="dropdown-select-helper" id={helperId}>
          {helperText}
        </span>
      )}
    </div>
  );
}
