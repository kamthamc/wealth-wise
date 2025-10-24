/**
 * Segmented Control Component
 * Modern iOS-style segmented control using Radix UI Tabs
 */

import * as Tabs from '@radix-ui/react-tabs';
import type { ReactNode } from 'react';
import './SegmentedControl.css';

export interface SegmentedControlOption<T extends string = string> {
  value: T;
  label: string;
  icon?: ReactNode;
  disabled?: boolean;
}

export interface SegmentedControlProps<T extends string = string> {
  options: SegmentedControlOption<T>[];
  value: T;
  onChange: (value: T) => void;
  size?: 'small' | 'medium' | 'large';
  fullWidth?: boolean;
  className?: string;
  'aria-label'?: string;
}

export function SegmentedControl<T extends string = string>({
  options,
  value,
  onChange,
  size = 'medium',
  fullWidth = false,
  className = '',
  'aria-label': ariaLabel,
}: SegmentedControlProps<T>) {
  const classes = [
    'segmented-control',
    `segmented-control--${size}`,
    fullWidth && 'segmented-control--full-width',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <Tabs.Root
      value={value}
      onValueChange={(newValue) => onChange(newValue as T)}
      className={classes}
      aria-label={ariaLabel || 'Segmented control'}
    >
      <Tabs.List className="segmented-control__list">
        {options.map((option) => (
          <Tabs.Trigger
            key={option.value}
            value={option.value}
            disabled={option.disabled}
            className="segmented-control__option"
            data-state={value === option.value ? 'active' : 'inactive'}
          >
            {option.icon && (
              <span className="segmented-control__icon">{option.icon}</span>
            )}
            <span className="segmented-control__label">{option.label}</span>
          </Tabs.Trigger>
        ))}
      </Tabs.List>
    </Tabs.Root>
  );
}
