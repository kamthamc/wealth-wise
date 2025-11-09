/**
 * Add Budget Form Component
 * Modal form for creating and editing budgets with inline validation
 */

import * as Dialog from '@radix-ui/react-dialog';
import * as RadioGroup from '@radix-ui/react-radio-group';
// import * as Slider from '@radix-ui/react-slider';
import { useEffect, useId, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useBudgetStore } from '@/core/stores';
import {
  Button,
  // CategorySelect,
  DatePicker,
  Input,
  useToast,
  ValidationMessage,
} from '@/shared/components';
import { useValidation, validators } from '@/shared/hooks/useValidation';
import type { BudgetFormData, BudgetPeriodType } from '../types';
import './AddBudgetForm.css';

interface AddBudgetFormProps {
  /** Whether the dialog is open */
  isOpen: boolean;
  /** Callback when the dialog should close */
  onClose: () => void;
  /** Budget ID to edit (undefined for new budget) */
  budgetId?: string;
}

export function AddBudgetForm({
  isOpen,
  onClose,
  budgetId,
}: AddBudgetFormProps) {
  const { t } = useTranslation();
  
  const BUDGET_PERIODS: {
    value: BudgetPeriodType;
    label: string;
    icon: string;
  }[] = [
    // { value: 'daily', label: t('forms.budget.periods.daily', 'Daily'), icon: '📅' },
    // { value: 'weekly', label: t('forms.budget.periods.weekly', 'Weekly'), icon: '📆' },
    { value: 'monthly', label: t('forms.budget.periods.monthly', 'Monthly'), icon: '🗓️' },
    { value: 'quarterly', label: t('forms.budget.periods.quarterly', 'Quarterly'), icon: '📊' },
  ];
  const formId = useId();
  const { budgets /* createBudget, updateBudget */ } = useBudgetStore();
  const toast = useToast();

  // Form state
  const [formData, setFormData] = useState<BudgetFormData>({
    name: '',
    // category: '',
    period_type: 'monthly',
    start_date: new Date().toISOString().split('T')[0] || '',
    end_date: undefined,
    is_recurring: false,
    rollover_enabled: false,
    categories: [],
  });

  const [isSubmitting, setIsSubmitting] = useState(false);

  // Real-time validation
  const nameValidation = useValidation(formData.name, {
    validate: validators.combine(
      validators.required,
      validators.minLength(3),
      validators.maxLength(100)
    ),
    debounceMs: 300,
    validateOnlyAfterBlur: true,
  });

  // const categoryValidation = useValidation(formData.category, {
  //   validate: validators.combine(
  //     validators.required,
  //     validators.minLength(2),
  //     validators.maxLength(50)
  //   ),
  //   debounceMs: 300,
  //   validateOnlyAfterBlur: true,
  // });

  // const amountValidation = useValidation(formData.amount, {
  //   validate: validators.combine(
  //     validators.required,
  //     validators.positiveNumber,
  //     validators.minAmount(1)
  //   ),
  //   debounceMs: 500,
  //   validateOnlyAfterBlur: true,
  // });

  const startDateValidation = useValidation(formData.start_date, {
    validate: validators.required,
    validateOnlyAfterBlur: true,
  });

  // Load budget data if editing
  useEffect(() => {
    if (budgetId) {
      const budget = budgets.find((b) => b.id === budgetId);
      if (budget) {
        setFormData((oldData) => ({
          ...oldData,
          name: budget.name,
          // category: budget.category,
          // amount: budget.amount,
          // period: budget.period,
          start_date:
            budget.start_date instanceof Date
              ? budget.start_date.toISOString().split('T')[0] || ''
              : budget.start_date,
          end_date:
            budget.end_date instanceof Date
              ? budget.end_date.toISOString().split('T')[0]
              : budget.end_date,
          // alert_threshold: budget.alert_threshold,
          // is_active: budget.is_active,
        }));
      }
    }
  }, [budgetId, budgets]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Check all validations
    if (
      !nameValidation.isValid ||
      // !categoryValidation.isValid ||
      // !amountValidation.isValid ||
      !startDateValidation.isValid
    ) {
      toast.error(
        'Validation failed',
        'Please fix all errors before submitting'
      );
      return;
    }

    setIsSubmitting(true);

    try {
      // Convert string dates to Date objects for the API
      // const budgetInput = {
      //   ...formData,
      //   start_date: new Date(formData.start_date),
      //   end_date: formData.end_date ? new Date(formData.end_date) : undefined,
      // };

      // if (budgetId) {
      //   await updateBudget({
      //     id: budgetId,
      //     ...budgetInput,
      //   });
      //   toast.success(
      //     'Budget updated',
      //     'Your budget has been updated successfully'
      //   );
      // } else {
      //   await createBudget(budgetInput);
      //   toast.success(
      //     'Budget created',
      //     'Your budget has been created successfully'
      //   );
      // }
      onClose();
      resetForm();
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : t('forms.budget.saveError', 'Failed to save budget');
      toast.error(t('forms.budget.saveErrorTitle', 'Failed to save'), errorMessage);
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetForm = () => {
    setFormData({
      name: '',
      categories: [],
      period_type: 'monthly',
      start_date: new Date().toISOString().split('T')[0] || '',
      end_date: undefined,
      is_recurring: false,
      rollover_enabled: false,
    });
  };

  const handleClose = () => {
    if (!isSubmitting) {
      onClose();
      resetForm();
    }
  };

  const isFormValid =
    nameValidation.isValid &&
    // categoryValidation.isValid &&
    // amountValidation.isValid &&
    startDateValidation.isValid;

  return (
    <Dialog.Root open={isOpen} onOpenChange={handleClose}>
      <Dialog.Portal>
        <Dialog.Overlay className="budget-form__overlay" />
        <Dialog.Content className="budget-form__content">
          <div className="budget-form__header">
            <Dialog.Title className="budget-form__title">
              {budgetId ? t('forms.budget.editTitle', 'Edit Budget') : t('forms.budget.createTitle', 'Create Budget')}
            </Dialog.Title>
            <Dialog.Description className="budget-form__description">
              {budgetId
                ? t('forms.budget.editDescription', 'Update budget details and limits')
                : t('forms.budget.createDescription', 'Set spending limits for better financial control')}
            </Dialog.Description>
            <Dialog.Close
              className="budget-form__close"
              aria-label={t('common.close', 'Close')}
            >
              ✕
            </Dialog.Close>
          </div>

          <form
            id={formId}
            className="budget-form__form"
            onSubmit={handleSubmit}
          >
            {/* Budget Name */}
            <div className="budget-form__field">
              <label htmlFor={`${formId}-name`} className="budget-form__label">
                {t('forms.budget.nameLabel', 'Budget Name')} *
              </label>
              <Input
                id={`${formId}-name`}
                type="text"
                value={formData.name}
                onChange={(e) =>
                  setFormData((prev) => ({ ...prev, name: e.target.value }))
                }
                onBlur={nameValidation.onBlur}
                placeholder={t('forms.budget.namePlaceholder', 'e.g., Monthly Groceries')}
                required
                aria-invalid={!!nameValidation.message}
                aria-describedby={
                  nameValidation.message
                    ? `${formId}-name-validation`
                    : undefined
                }
              />
              {nameValidation.hasBlurred && (
                <ValidationMessage
                  state={nameValidation.state}
                  message={nameValidation.message}
                  fieldId={`${formId}-name`}
                />
              )}
            </div>

            {/* Category */}
            {/* <div className="budget-form__field">
              <CategorySelect
                id={`${formId}-category`}
                value={formData.categories}
                onChange={(categoryId) =>
                  setFormData((prev) => ({
                    ...prev,
                    categories: categoryId ? [categoryId] : [],
                  }))
                }
                type="expense"
                required
                error={
                  categoryValidation.hasBlurred
                    ? categoryValidation.message
                    : undefined
                }
              />
            </div> */}

            {/* Budget Amount */}
            {/* <div className="budget-form__field">
              <label
                htmlFor={`${formId}-amount`}
                className="budget-form__label"
              >
                Budget Amount *
              </label>
              <Input
                id={`${formId}-amount`}
                type="number"
                value={formData.amount}
                onChange={(e) =>
                  setFormData((prev) => ({
                    ...prev,
                    amount: Number(e.target.value),
                  }))
                }
                onBlur={amountValidation.onBlur}
                placeholder="0.00"
                required
                min="0"
                step="0.01"
                aria-invalid={!!amountValidation.message}
                aria-describedby={
                  amountValidation.message
                    ? `${formId}-amount-validation`
                    : undefined
                }
              />
              {amountValidation.hasBlurred && (
                <ValidationMessage
                  state={amountValidation.state}
                  message={amountValidation.message}
                  fieldId={`${formId}-amount`}
                />
              )}
            </div> */}

            {/* Budget Period */}
            <fieldset className="budget-form__field">
              <legend className="budget-form__label">{t('forms.budget.periodLabel', 'Budget Period')} *</legend>
              <RadioGroup.Root
                className="budget-form__radio-group"
                value={formData.period_type}
                onValueChange={(value: BudgetPeriodType) =>
                  setFormData((prev) => ({ ...prev, period: value }))
                }
                aria-label={t('forms.budget.periodLabel', 'Budget period')}
              >
                {BUDGET_PERIODS.map((period) => (
                  <div key={period.value} className="budget-form__radio-item">
                    <RadioGroup.Item
                      className="budget-form__radio-button"
                      value={period.value}
                      id={`${formId}-period-${period.value}`}
                    >
                      <RadioGroup.Indicator className="budget-form__radio-indicator" />
                    </RadioGroup.Item>
                    <label
                      className="budget-form__radio-label"
                      htmlFor={`${formId}-period-${period.value}`}
                    >
                      <span className="budget-form__radio-icon">
                        {period.icon}
                      </span>
                      {period.label}
                    </label>
                  </div>
                ))}
              </RadioGroup.Root>
            </fieldset>

            {/* Start Date */}
            <div className="budget-form__field">
              <label
                htmlFor={`${formId}-start-date`}
                className="budget-form__label"
              >
                {t('forms.budget.startDateLabel', 'Start Date')} *
              </label>
              <DatePicker
                id={`${formId}-start-date`}
                value={
                  formData.start_date
                    ? new Date(formData.start_date)
                    : undefined
                }
                onChange={(date) => {
                  setFormData((prev) => ({
                    ...prev,
                    start_date: date
                      ? date.toISOString().split('T')[0] || ''
                      : '',
                  }));
                  setTimeout(() => startDateValidation.revalidate(), 0);
                }}
                placeholder={t('forms.budget.startDatePlaceholder', 'Select start date...')}
                required
                error={
                  startDateValidation.hasBlurred
                    ? startDateValidation.message
                    : undefined
                }
                aria-describedby={
                  startDateValidation.message
                    ? `${formId}-start-date-validation`
                    : undefined
                }
                dateFormat="PPP"
              />
              {startDateValidation.hasBlurred && (
                <ValidationMessage
                  state={startDateValidation.state}
                  message={startDateValidation.message}
                  fieldId={`${formId}-start-date`}
                />
              )}
            </div>

            {/* End Date (Optional) */}
            <div className="budget-form__field">
              <label
                htmlFor={`${formId}-end-date`}
                className="budget-form__label"
              >
                {t('forms.budget.endDateLabel', 'End Date (Optional)')}
              </label>
              <DatePicker
                id={`${formId}-end-date`}
                value={
                  formData.end_date ? new Date(formData.end_date) : undefined
                }
                onChange={(date) =>
                  setFormData((prev) => ({
                    ...prev,
                    end_date: date
                      ? date.toISOString().split('T')[0]
                      : undefined,
                  }))
                }
                placeholder={t('forms.budget.endDatePlaceholder', 'No end date (ongoing)')}
                dateFormat="PPP"
              />
              <p className="budget-form__help-text">
                {t('forms.budget.endDateHelp', 'Leave empty for a recurring budget without an end date')}
              </p>
            </div>

            {/* Alert Threshold */}
            {/* <div className="budget-form__field">
              <label
                htmlFor={`${formId}-threshold`}
                className="budget-form__label"
              >
                Alert Threshold: {formData.alert_threshold}%
              </label>
              <Slider.Root
                className="budget-form__slider"
                value={[formData.alert_threshold]}
                onValueChange={([value]: number[]) =>
                  setFormData((prev) => ({
                    ...prev,
                    alert_threshold: value ?? 80,
                  }))
                }
                min={0}
                max={100}
                step={5}
                aria-label="Alert threshold percentage"
              >
                <Slider.Track className="budget-form__slider-track">
                  <Slider.Range className="budget-form__slider-range" />
                </Slider.Track>
                <Slider.Thumb className="budget-form__slider-thumb" />
              </Slider.Root>
              <p className="budget-form__help-text">
                Get notified when spending reaches this percentage of your
                budget
              </p>
            </div> */}
          </form>

          <div className="budget-form__footer">
            <Button
              type="button"
              variant="secondary"
              onClick={handleClose}
              disabled={isSubmitting}
            >
              {t('common.cancel', 'Cancel')}
            </Button>
            <Button
              type="submit"
              form={formId}
              variant="primary"
              disabled={isSubmitting || !isFormValid}
            >
              {isSubmitting
                ? t('forms.budget.saving', 'Saving...')
                : budgetId
                  ? t('forms.budget.updateButton', 'Update Budget')
                  : t('forms.budget.createButton', 'Create Budget')}
            </Button>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
