/**
 * Enhanced Budget Form Component
 * Create/Edit budgets with multi-category support and templates
 */

import * as Dialog from '@radix-ui/react-dialog';
import * as RadioGroup from '@radix-ui/react-radio-group';
import * as Switch from '@radix-ui/react-switch';
import { Plus, Sparkles, Trash2, X } from 'lucide-react';
import { useEffect, useId, useState } from 'react';
import {
  Button,
  CategorySelect,
  CurrencyInput,
  DateInput,
  Input,
} from '@/shared/components';
import type {
  BudgetFormData,
  BudgetPeriodType,
  BudgetTemplate,
} from '../types';
import {
  calculateEndDate,
  getBudgetPeriodIcon,
  validateBudgetForm,
} from '../utils/budgetHelpers';
import './BudgetFormNew.css';

interface BudgetFormNewProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: BudgetFormData) => Promise<void>;
  budgetId?: string;
  initialData?: Partial<BudgetFormData>;
  templates?: BudgetTemplate[];
}

const PERIOD_OPTIONS: { value: BudgetPeriodType; label: string }[] = [
  { value: 'monthly', label: 'Monthly' },
  { value: 'quarterly', label: 'Quarterly' },
  { value: 'annual', label: 'Annual' },
  { value: 'custom', label: 'Custom' },
  { value: 'event', label: 'Event' },
];

export function BudgetFormNew({
  isOpen,
  onClose,
  onSubmit,
  budgetId,
  initialData,
  templates = [],
}: BudgetFormNewProps) {
  const formId = useId();
  const isEditing = Boolean(budgetId);

  // Form state
  const [formData, setFormData] = useState<BudgetFormData>({
    name: '',
    description: '',
    period_type: 'monthly',
    start_date: new Date().toISOString().split('T')[0] || '',
    end_date: undefined,
    is_recurring: false,
    rollover_enabled: false,
    categories: [
      { category: '', allocated_amount: 0, alert_threshold: 0.8, notes: '' },
    ],
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showTemplates, setShowTemplates] = useState(
    !isEditing && templates.length > 0
  );
  const [totalAllocated, setTotalAllocated] = useState(0);

  // Load initial data
  useEffect(() => {
    if (initialData) {
      setFormData({
        ...formData,
        ...initialData,
        categories: initialData.categories || formData.categories,
      });
    }
  }, [initialData]);

  // Calculate total allocated
  useEffect(() => {
    const total = formData.categories.reduce(
      (sum, cat) => sum + (cat.allocated_amount || 0),
      0
    );
    setTotalAllocated(total);
  }, [formData.categories]);

  // Update end date when period or start date changes
  useEffect(() => {
    if (formData.period_type !== 'custom' && formData.period_type !== 'event') {
      const endDate = calculateEndDate(
        new Date(formData.start_date),
        formData.period_type
      );
      setFormData((prev) => ({
        ...prev,
        end_date: endDate.toISOString().split('T')[0],
      }));
    }
  }, [formData.start_date, formData.period_type]);

  const handleFieldChange = (field: keyof BudgetFormData, value: any) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
    // Clear error for this field
    if (errors[field]) {
      setErrors((prev) => {
        const newErrors = { ...prev };
        delete newErrors[field];
        return newErrors;
      });
    }
  };

  const handleCategoryChange = (index: number, field: string, value: any) => {
    const newCategories = [...formData.categories];
    newCategories[index] = {
      ...newCategories[index],
      [field]: value,
    } as (typeof formData.categories)[0];
    setFormData((prev) => ({ ...prev, categories: newCategories }));

    // Clear error for this category
    const errorKey = `categories.${index}.${field}`;
    if (errors[errorKey]) {
      setErrors((prev) => {
        const newErrors = { ...prev };
        delete newErrors[errorKey];
        return newErrors;
      });
    }
  };

  const handleAddCategory = () => {
    setFormData((prev) => ({
      ...prev,
      categories: [
        ...prev.categories,
        { category: '', allocated_amount: 0, alert_threshold: 0.8, notes: '' },
      ],
    }));
  };

  const handleRemoveCategory = (index: number) => {
    if (formData.categories.length > 1) {
      setFormData((prev) => ({
        ...prev,
        categories: prev.categories.filter((_, i) => i !== index),
      }));
    }
  };

  const handleTemplateSelect = (template: BudgetTemplate) => {
    setFormData((prev) => ({
      ...prev,
      name: template.name,
      description: template.description,
      period_type: template.period_type,
      categories: template.categories.map((cat) => ({
        category: cat.category,
        allocated_amount: 0, // User will fill in amounts
        alert_threshold: 0.8,
        notes: '',
      })),
    }));
    setShowTemplates(false);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validate form
    const validationErrors = validateBudgetForm(formData);
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }

    setIsSubmitting(true);
    try {
      await onSubmit(formData);
      onClose();
    } catch (error) {
      console.error('Failed to save budget:', error);
      setErrors({ submit: 'Failed to save budget. Please try again.' });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    if (!isSubmitting) {
      onClose();
      // Reset form after animation
      setTimeout(() => {
        setFormData({
          name: '',
          description: '',
          period_type: 'monthly',
          start_date: new Date().toISOString().split('T')[0] || '',
          end_date: undefined,
          is_recurring: false,
          rollover_enabled: false,
          categories: [
            {
              category: '',
              allocated_amount: 0,
              alert_threshold: 0.8,
              notes: '',
            },
          ],
        });
        setErrors({});
        setShowTemplates(!isEditing && templates.length > 0);
      }, 200);
    }
  };

  return (
    <Dialog.Root open={isOpen} onOpenChange={(open) => !open && handleClose()}>
      <Dialog.Portal>
        <Dialog.Overlay className="budget-form__overlay" />
        <Dialog.Content
          className="budget-form__content"
          aria-describedby={undefined}
        >
          <div className="budget-form__header">
            <Dialog.Title className="budget-form__title">
              {isEditing ? 'Edit Budget' : 'Create Budget'}
            </Dialog.Title>
            <Dialog.Close asChild>
              <Button variant="ghost" size="small" disabled={isSubmitting}>
                <X size={18} />
              </Button>
            </Dialog.Close>
          </div>

          {showTemplates && templates.length > 0 ? (
            <div className="budget-form__templates">
              <div className="templates-header">
                <Sparkles size={20} />
                <h3>Start with a Template</h3>
              </div>
              <p className="templates-description">
                Choose a pre-configured budget template to get started quickly
              </p>
              <div className="templates-grid">
                {templates.map((template) => (
                  <button
                    key={template.name}
                    type="button"
                    className="template-card"
                    onClick={() => handleTemplateSelect(template)}
                  >
                    <div className="template-card__icon">
                      {getBudgetPeriodIcon(template.period_type)}
                    </div>
                    <div className="template-card__content">
                      <h4 className="template-card__name">{template.name}</h4>
                      <p className="template-card__description">
                        {template.description}
                      </p>
                      <div className="template-card__categories">
                        {template.categories.length} categories
                      </div>
                    </div>
                  </button>
                ))}
              </div>
              <Button
                type="button"
                variant="ghost"
                onClick={() => setShowTemplates(false)}
                className="templates-skip"
              >
                Start from scratch
              </Button>
            </div>
          ) : (
            <form
              id={formId}
              onSubmit={handleSubmit}
              className="budget-form__form"
            >
              {/* Basic Information */}
              <div className="form-section">
                <h3 className="form-section__title">Basic Information</h3>

                <Input
                  label="Budget Name"
                  value={formData.name}
                  onChange={(e) => handleFieldChange('name', e.target.value)}
                  error={errors.name}
                  placeholder="e.g., Monthly Household Budget"
                  required
                  autoFocus
                />

                <Input
                  label="Description (Optional)"
                  value={formData.description || ''}
                  onChange={(e) =>
                    handleFieldChange('description', e.target.value)
                  }
                  placeholder="Brief description of this budget"
                />
              </div>

              {/* Period Selection */}
              <div className="form-section">
                <h3 className="form-section__title">Budget Period</h3>

                <div className="period-selector">
                  <RadioGroup.Root
                    value={formData.period_type}
                    onValueChange={(value) =>
                      handleFieldChange(
                        'period_type',
                        value as BudgetPeriodType
                      )
                    }
                    className="period-options"
                  >
                    {PERIOD_OPTIONS.map((option) => (
                      <div key={option.value} className="period-option">
                        <RadioGroup.Item
                          value={option.value}
                          id={`period-${option.value}`}
                          className="period-radio"
                        >
                          <RadioGroup.Indicator className="period-radio-indicator" />
                        </RadioGroup.Item>
                        <label
                          htmlFor={`period-${option.value}`}
                          className="period-label"
                        >
                          <span className="period-icon">
                            {getBudgetPeriodIcon(option.value)}
                          </span>
                          {option.label}
                        </label>
                      </div>
                    ))}
                  </RadioGroup.Root>
                </div>

                <div className="date-inputs">
                  <DateInput
                    label="Start Date"
                    value={formData.start_date}
                    onChange={(value) => handleFieldChange('start_date', value)}
                    error={errors.start_date}
                    required
                  />
                  {(formData.period_type === 'custom' ||
                    formData.period_type === 'event') && (
                    <DateInput
                      label="End Date"
                      value={formData.end_date || ''}
                      onChange={(value) => handleFieldChange('end_date', value)}
                      error={errors.end_date}
                      required
                    />
                  )}
                </div>
              </div>

              {/* Categories */}
              <div className="form-section">
                <div className="form-section__header">
                  <h3 className="form-section__title">
                    Categories ({formData.categories.length})
                  </h3>
                  <div className="total-allocated">
                    Total: ₹{totalAllocated.toLocaleString('en-IN')}
                  </div>
                </div>

                <div className="categories-list">
                  {formData.categories.map((category, index) => (
                    <div key={index} className="category-input-group">
                      <div className="category-input-row">
                        <CategorySelect
                          label={index === 0 ? 'Category' : undefined}
                          value={category.category}
                          onChange={(value) =>
                            handleCategoryChange(index, 'category', value)
                          }
                          error={errors[`categories.${index}.category`]}
                          placeholder="Select category"
                          required
                        />
                        <CurrencyInput
                          label={index === 0 ? 'Amount' : undefined}
                          value={category.allocated_amount}
                          onChange={(value) =>
                            handleCategoryChange(
                              index,
                              'allocated_amount',
                              value
                            )
                          }
                          error={errors[`categories.${index}.allocated_amount`]}
                          required
                        />
                        {formData.categories.length > 1 && (
                          <Button
                            type="button"
                            variant="ghost"
                            size="small"
                            onClick={() => handleRemoveCategory(index)}
                            className="remove-category-btn"
                            aria-label="Remove category"
                          >
                            <Trash2 size={16} />
                          </Button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>

                <Button
                  type="button"
                  variant="secondary"
                  onClick={handleAddCategory}
                  className="add-category-btn"
                >
                  <Plus size={16} />
                  Add Category
                </Button>
              </div>

              {/* Settings */}
              <div className="form-section">
                <h3 className="form-section__title">Settings</h3>

                <div className="switch-group">
                  <div className="switch-item">
                    <div className="switch-item__content">
                      <label htmlFor="recurring" className="switch-label">
                        Recurring Budget
                      </label>
                      <p className="switch-description">
                        Automatically create next period's budget
                      </p>
                    </div>
                    <Switch.Root
                      id="recurring"
                      checked={formData.is_recurring}
                      onCheckedChange={(checked) =>
                        handleFieldChange('is_recurring', checked)
                      }
                      className="switch-root"
                    >
                      <Switch.Thumb className="switch-thumb" />
                    </Switch.Root>
                  </div>

                  <div className="switch-item">
                    <div className="switch-item__content">
                      <label htmlFor="rollover" className="switch-label">
                        Enable Rollover
                      </label>
                      <p className="switch-description">
                        Carry unused budget to next period
                      </p>
                    </div>
                    <Switch.Root
                      id="rollover"
                      checked={formData.rollover_enabled}
                      onCheckedChange={(checked) =>
                        handleFieldChange('rollover_enabled', checked)
                      }
                      className="switch-root"
                    >
                      <Switch.Thumb className="switch-thumb" />
                    </Switch.Root>
                  </div>
                </div>
              </div>

              {/* Error Message */}
              {errors.submit && (
                <div className="form-error">{errors.submit}</div>
              )}

              {/* Actions */}
              <div className="budget-form__actions">
                <Button
                  type="button"
                  variant="secondary"
                  onClick={handleClose}
                  disabled={isSubmitting}
                >
                  Cancel
                </Button>
                <Button type="submit" disabled={isSubmitting} form={formId}>
                  {isSubmitting
                    ? 'Saving...'
                    : isEditing
                      ? 'Update Budget'
                      : 'Create Budget'}
                </Button>
              </div>
            </form>
          )}
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
