/**
 * Multi-Select Filter Component
 * Reusable component for selecting multiple items with checkboxes
 */

import * as Popover from '@radix-ui/react-popover';
import { Check, ChevronDown, X } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import './MultiSelectFilter.css';

export interface MultiSelectOption<T = string> {
  value: T;
  label: string;
  icon?: React.ReactNode;
  count?: number;
}

export interface MultiSelectFilterProps<T = string> {
  options: MultiSelectOption<T>[];
  selected: T[];
  onChange: (selected: T[]) => void;
  placeholder?: string;
  label?: string;
  searchPlaceholder?: string;
  maxDisplay?: number;
  className?: string;
}

export function MultiSelectFilter<T extends string = string>({
  options,
  selected,
  onChange,
  placeholder = 'Select items...',
  label,
  searchPlaceholder = 'Search...',
  maxDisplay = 2,
  className = '',
}: MultiSelectFilterProps<T>) {
  const [isOpen, setIsOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const searchInputRef = useRef<HTMLInputElement>(null);

  // Filter options based on search
  const filteredOptions = options.filter((option) =>
    option.label.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Focus search input when popover opens
  useEffect(() => {
    if (isOpen && searchInputRef.current) {
      setTimeout(() => searchInputRef.current?.focus(), 100);
    }
  }, [isOpen]);

  // Handle option toggle
  const handleToggle = (value: T) => {
    if (selected.includes(value)) {
      onChange(selected.filter((v) => v !== value));
    } else {
      onChange([...selected, value]);
    }
  };

  // Handle select all
  const handleSelectAll = () => {
    onChange(filteredOptions.map((opt) => opt.value));
  };

  // Handle clear all
  const handleClearAll = () => {
    onChange([]);
  };

  // Get display text
  const getDisplayText = () => {
    if (selected.length === 0) {
      return placeholder;
    }

    const selectedOptions = options.filter((opt) =>
      selected.includes(opt.value)
    );

    if (selected.length === options.length) {
      return 'All selected';
    }

    if (selected.length <= maxDisplay) {
      return selectedOptions.map((opt) => opt.label).join(', ');
    }

    return `${selected.length} selected`;
  };

  return (
    <div className={`multi-select-filter ${className}`}>
      <Popover.Root open={isOpen} onOpenChange={setIsOpen}>
        <Popover.Trigger asChild>
          <button
            type="button"
            className="multi-select-filter__trigger"
            aria-label={label || 'Filter'}
          >
            {label && (
              <span className="multi-select-filter__label">{label}:</span>
            )}
            <span className="multi-select-filter__trigger-text">
              {getDisplayText()}
            </span>
            <div className="multi-select-filter__trigger-icons">
              {selected.length > 0 && (
                <span className="multi-select-filter__badge">
                  {selected.length}
                </span>
              )}
              <ChevronDown size={16} />
            </div>
          </button>
        </Popover.Trigger>

        <Popover.Portal>
          <Popover.Content
            className="multi-select-filter__content"
            align="start"
            sideOffset={5}
          >
            {/* Search */}
            <div className="multi-select-filter__search">
              <input
                ref={searchInputRef}
                type="text"
                placeholder={searchPlaceholder}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="multi-select-filter__search-input"
              />
            </div>

            {/* Actions */}
            <div className="multi-select-filter__actions">
              <button
                type="button"
                className="multi-select-filter__action-btn"
                onClick={handleSelectAll}
                disabled={filteredOptions.length === 0}
              >
                Select All
              </button>
              <button
                type="button"
                className="multi-select-filter__action-btn"
                onClick={handleClearAll}
                disabled={selected.length === 0}
              >
                Clear All
              </button>
            </div>

            {/* Options List */}
            <div className="multi-select-filter__options">
              {filteredOptions.length === 0 ? (
                <div className="multi-select-filter__empty">
                  No options found
                </div>
              ) : (
                filteredOptions.map((option) => {
                  const isSelected = selected.includes(option.value);
                  return (
                    <label
                      key={option.value}
                      className={`multi-select-filter__option ${
                        isSelected
                          ? 'multi-select-filter__option--selected'
                          : ''
                      }`}
                    >
                      <input
                        type="checkbox"
                        checked={isSelected}
                        onChange={() => handleToggle(option.value)}
                        className="multi-select-filter__checkbox"
                      />
                      <span className="multi-select-filter__checkbox-custom">
                        {isSelected && <Check size={14} />}
                      </span>
                      {option.icon && (
                        <span className="multi-select-filter__option-icon">
                          {option.icon}
                        </span>
                      )}
                      <span className="multi-select-filter__option-label">
                        {option.label}
                      </span>
                      {option.count !== undefined && (
                        <span className="multi-select-filter__option-count">
                          {option.count}
                        </span>
                      )}
                    </label>
                  );
                })
              )}
            </div>

            {/* Clear button for selected items */}
            {selected.length > 0 && (
              <div className="multi-select-filter__footer">
                <button
                  type="button"
                  className="multi-select-filter__clear-btn"
                  onClick={handleClearAll}
                >
                  <X size={14} />
                  Clear {selected.length} selected
                </button>
              </div>
            )}
          </Popover.Content>
        </Popover.Portal>
      </Popover.Root>
    </div>
  );
}
