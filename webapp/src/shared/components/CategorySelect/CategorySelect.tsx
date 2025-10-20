/**
 * Category Select Component
 * Dropdown select for transaction categories with type filtering
 */

import { useEffect, useState } from 'react';
import {
  type Category,
  getAllCategories,
  getCategoriesByType,
} from '@/core/services/categoryService';
import { Select, type SelectOption } from '@/shared/components';

export interface CategorySelectProps {
  /** Currently selected category ID */
  value: string | undefined;
  /** Callback when category is selected */
  onChange: (categoryId: string | undefined) => void;
  /** Filter categories by type (income/expense) */
  type?: 'income' | 'expense' | 'all';
  /** Label for the select */
  label?: string;
  /** Placeholder text */
  placeholder?: string;
  /** Whether the select is required */
  required?: boolean;
  /** Whether the select is disabled */
  disabled?: boolean;
  /** Error message */
  error?: string;
  /** Helper text */
  helperText?: string;
  /** ID for accessibility */
  id?: string;
}

export function CategorySelect({
  value,
  onChange,
  type = 'all',
  label = 'Category',
  placeholder = 'Select category...',
  required = false,
  disabled = false,
  error,
  helperText,
  id,
}: CategorySelectProps) {
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const loadCategories = async () => {
      try {
        setIsLoading(true);
        let data: Category[];

        if (type === 'all') {
          data = await getAllCategories();
        } else {
          data = await getCategoriesByType(type);
        }

        setCategories(data);
      } catch (err) {
        console.error('Failed to load categories:', err);
      } finally {
        setIsLoading(false);
      }
    };

    loadCategories();
  }, [type]);

  const options: SelectOption[] = categories.map((category) => ({
    value: category.id,
    label: category.icon ? `${category.icon} ${category.name}` : category.name,
  }));

  const handleChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const newValue = e.target.value || undefined;
    onChange(newValue);
  };

  if (isLoading) {
    return (
      <Select
        label={label}
        options={[{ value: '', label: 'Loading categories...' }]}
        value=""
        disabled
        id={id}
      />
    );
  }

  return (
    <Select
      label={label}
      options={options}
      value={value || ''}
      onChange={handleChange}
      placeholder={placeholder}
      required={required}
      disabled={disabled}
      error={error}
      helperText={helperText}
      id={id}
    />
  );
}
