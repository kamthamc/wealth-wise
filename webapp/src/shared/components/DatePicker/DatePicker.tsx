/**
 * Date Picker Component
 * Radix Popover + React Day Picker for accessible date selection
 */

import * as Popover from '@radix-ui/react-popover';
import { Calendar } from 'lucide-react';
import { useState } from 'react';
import { DayPicker } from 'react-day-picker';
import { format } from 'date-fns';
import 'react-day-picker/style.css';
import './DatePicker.css';

export interface DatePickerProps {
  /**
   * Currently selected date
   */
  value: Date | undefined;

  /**
   * Callback when date is selected
   */
  onChange: (date: Date | undefined) => void;

  /**
   * Placeholder text when no date selected
   */
  placeholder?: string;

  /**
   * Whether the picker is disabled
   */
  disabled?: boolean;

  /**
   * Whether the picker is required
   */
  required?: boolean;

  /**
   * Error message to display
   */
  error?: string;

  /**
   * ID for accessibility
   */
  id?: string;

  /**
   * ARIA label for accessibility
   */
  'aria-label'?: string;

  /**
   * ARIA described by for error messages
   */
  'aria-describedby'?: string;

  /**
   * Minimum selectable date
   */
  minDate?: Date;

  /**
   * Maximum selectable date
   */
  maxDate?: Date;

  /**
   * Disabled dates
   */
  disabledDates?: Date[];

  /**
   * Format string for display (default: 'PPP' - e.g., "Apr 29, 2023")
   */
  dateFormat?: string;
}

export function DatePicker({
  value,
  onChange,
  placeholder = 'Select date...',
  disabled = false,
  required = false,
  error,
  id,
  'aria-label': ariaLabel,
  'aria-describedby': ariaDescribedBy,
  minDate,
  maxDate,
  disabledDates = [],
  dateFormat = 'PPP',
}: DatePickerProps) {
  const [isOpen, setIsOpen] = useState(false);

  const handleSelect = (date: Date | undefined) => {
    onChange(date);
    setIsOpen(false);
  };

  const displayValue = value ? format(value, dateFormat) : placeholder;

  // Build disabled matcher for DayPicker
  const disabledMatcher = [];
  if (minDate) {
    disabledMatcher.push({ before: minDate });
  }
  if (maxDate) {
    disabledMatcher.push({ after: maxDate });
  }
  if (disabledDates.length > 0) {
    disabledMatcher.push(...disabledDates);
  }

  return (
    <div className="date-picker-wrapper">
      <Popover.Root open={isOpen} onOpenChange={setIsOpen}>
        <Popover.Trigger
          className={`date-picker__trigger ${error ? 'date-picker__trigger--error' : ''} ${!value ? 'date-picker__trigger--placeholder' : ''}`}
          disabled={disabled}
          aria-label={ariaLabel}
          aria-describedby={ariaDescribedBy}
          aria-invalid={!!error}
          aria-required={required}
          id={id}
          type="button"
        >
          <Calendar className="date-picker__icon" size={16} />
          <span className="date-picker__value">{displayValue}</span>
        </Popover.Trigger>

        <Popover.Portal>
          <Popover.Content
            className="date-picker__content"
            align="start"
            sideOffset={4}
          >
            <DayPicker
              mode="single"
              selected={value}
              onSelect={handleSelect}
              disabled={disabledMatcher.length > 0 ? disabledMatcher : undefined}
              defaultMonth={value}
              showOutsideDays
              className="date-picker__calendar"
              classNames={{
                months: 'date-picker__months',
                month: 'date-picker__month',
                month_caption: 'date-picker__month-caption',
                caption_label: 'date-picker__caption-label',
                nav: 'date-picker__nav',
                button_previous: 'date-picker__nav-button date-picker__nav-button--prev',
                button_next: 'date-picker__nav-button date-picker__nav-button--next',
                month_grid: 'date-picker__month-grid',
                weekdays: 'date-picker__weekdays',
                weekday: 'date-picker__weekday',
                week: 'date-picker__week',
                day: 'date-picker__day',
                day_button: 'date-picker__day-button',
                selected: 'date-picker__day--selected',
                today: 'date-picker__day--today',
                outside: 'date-picker__day--outside',
                disabled: 'date-picker__day--disabled',
                hidden: 'date-picker__day--hidden',
              }}
            />
            <Popover.Arrow className="date-picker__arrow" />
          </Popover.Content>
        </Popover.Portal>
      </Popover.Root>

      {error && <span className="date-picker__error">{error}</span>}
    </div>
  );
}
