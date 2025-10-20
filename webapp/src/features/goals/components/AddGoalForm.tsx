/**
 * Add Goal Form Component
 * Modal form for creating and editing financial goals with inline validation
 */

import * as Dialog from '@radix-ui/react-dialog';
import * as RadioGroup from '@radix-ui/react-radio-group';
import { useEffect, useId, useState } from 'react';
import { useGoalStore } from '@/core/stores';
import {
  Button,
  DatePicker,
  Input,
  useToast,
  ValidationMessage,
} from '@/shared/components';
import { useValidation, validators } from '@/shared/hooks/useValidation';
import type { GoalFormData, GoalPriority } from '../types';
import './AddGoalForm.css';

interface AddGoalFormProps {
  /** Whether the dialog is open */
  isOpen: boolean;
  /** Callback when the dialog should close */
  onClose: () => void;
  /** Goal ID to edit (undefined for new goal) */
  goalId?: string;
}

const GOAL_PRIORITIES: {
  value: GoalPriority;
  label: string;
  icon: string;
  color: string;
}[] = [
  { value: 'low', label: 'Low Priority', icon: '🔵', color: '#3b82f6' },
  { value: 'medium', label: 'Medium Priority', icon: '🟡', color: '#f59e0b' },
  { value: 'high', label: 'High Priority', icon: '🔴', color: '#ef4444' },
];

const GOAL_ICONS = [
  { emoji: '🏠', name: 'Home' },
  { emoji: '🚗', name: 'Car' },
  { emoji: '✈️', name: 'Travel' },
  { emoji: '🎓', name: 'Education' },
  { emoji: '💍', name: 'Wedding' },
  { emoji: '👶', name: 'Family' },
  { emoji: '💰', name: 'Savings' },
  { emoji: '📈', name: 'Investment' },
  { emoji: '🏥', name: 'Health' },
  { emoji: '🎯', name: 'Other' },
];

export function AddGoalForm({ isOpen, onClose, goalId }: AddGoalFormProps) {
  const formId = useId();
  const { goals, createGoal, updateGoal } = useGoalStore();
  const toast = useToast();

  // Form state
  const [formData, setFormData] = useState<GoalFormData>({
    name: '',
    target_amount: 0,
    target_date: undefined,
    category: '',
    priority: 'medium',
    icon: '🎯',
    color: '#3b82f6',
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

  const categoryValidation = useValidation(formData.category, {
    validate: validators.combine(
      validators.required,
      validators.minLength(2),
      validators.maxLength(50)
    ),
    debounceMs: 300,
    validateOnlyAfterBlur: true,
  });

  const targetAmountValidation = useValidation(formData.target_amount, {
    validate: validators.combine(
      validators.required,
      validators.positiveNumber,
      validators.minAmount(100)
    ),
    debounceMs: 500,
    validateOnlyAfterBlur: true,
  });

  const targetDateValidation = useValidation(formData.target_date, {
    validate: (value) => {
      if (!value) {
        return {
          isValid: false,
          message: 'Target date is required',
          state: 'error' as const,
        };
      }

      // Validate that target date is in the future
      const targetDate = new Date(value);
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      if (targetDate < today) {
        return {
          isValid: false,
          message: 'Target date must be in the future',
          state: 'error' as const,
        };
      }

      return {
        isValid: true,
        state: 'success' as const,
      };
    },
    validateOnlyAfterBlur: true,
  });

  // Load goal data if editing
  useEffect(() => {
    if (goalId) {
      const goal = goals.find((g) => g.id === goalId);
      if (goal) {
        setFormData({
          name: goal.name,
          target_amount: goal.target_amount,
          target_date:
            goal.target_date instanceof Date
              ? goal.target_date.toISOString().split('T')[0]
              : goal.target_date,
          category: goal.category,
          priority: goal.priority,
          icon: goal.icon,
          color: goal.color,
        });
      }
    }
  }, [goalId, goals]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Check all validations
    if (
      !nameValidation.isValid ||
      !categoryValidation.isValid ||
      !targetAmountValidation.isValid ||
      !targetDateValidation.isValid
    ) {
      toast.error(
        'Validation failed',
        'Please fix all errors before submitting'
      );
      return;
    }

    setIsSubmitting(true);

    try {
      // Convert string date to Date object for the API
      const goalInput = {
        ...formData,
        target_date: formData.target_date
          ? new Date(formData.target_date)
          : undefined,
        status: 'active' as const, // New goals start as active
      };

      if (goalId) {
        await updateGoal({
          id: goalId,
          ...goalInput,
        });
        toast.success(
          'Goal updated',
          'Your goal has been updated successfully'
        );
      } else {
        await createGoal(goalInput);
        toast.success(
          'Goal created',
          'Your goal has been created successfully'
        );
      }
      onClose();
      resetForm();
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Failed to save goal';
      toast.error('Failed to save', errorMessage);
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetForm = () => {
    setFormData({
      name: '',
      target_amount: 0,
      target_date: undefined,
      category: '',
      priority: 'medium',
      icon: '🎯',
      color: '#3b82f6',
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
    categoryValidation.isValid &&
    targetAmountValidation.isValid &&
    targetDateValidation.isValid;

  return (
    <Dialog.Root open={isOpen} onOpenChange={handleClose}>
      <Dialog.Portal>
        <Dialog.Overlay className="goal-form__overlay" />
        <Dialog.Content className="goal-form__content">
          <div className="goal-form__header">
            <Dialog.Title className="goal-form__title">
              {goalId ? 'Edit Goal' : 'Create Financial Goal'}
            </Dialog.Title>
            <Dialog.Description className="goal-form__description">
              {goalId
                ? 'Update your financial goal details'
                : 'Set a savings target and track your progress'}
            </Dialog.Description>
            <Dialog.Close
              className="goal-form__close"
              aria-label="Close dialog"
            >
              ✕
            </Dialog.Close>
          </div>

          <form id={formId} className="goal-form__form" onSubmit={handleSubmit}>
            {/* Goal Name */}
            <div className="goal-form__field">
              <label htmlFor={`${formId}-name`} className="goal-form__label">
                Goal Name *
              </label>
              <Input
                id={`${formId}-name`}
                type="text"
                value={formData.name}
                onChange={(e) =>
                  setFormData((prev) => ({ ...prev, name: e.target.value }))
                }
                onBlur={nameValidation.onBlur}
                placeholder="e.g., Buy a new car"
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
            <div className="goal-form__field">
              <label
                htmlFor={`${formId}-category`}
                className="goal-form__label"
              >
                Category *
              </label>
              <Input
                id={`${formId}-category`}
                type="text"
                value={formData.category}
                onChange={(e) =>
                  setFormData((prev) => ({ ...prev, category: e.target.value }))
                }
                onBlur={categoryValidation.onBlur}
                placeholder="e.g., Transportation"
                required
                aria-invalid={!!categoryValidation.message}
                aria-describedby={
                  categoryValidation.message
                    ? `${formId}-category-validation`
                    : undefined
                }
              />
              {categoryValidation.hasBlurred && (
                <ValidationMessage
                  state={categoryValidation.state}
                  message={categoryValidation.message}
                  fieldId={`${formId}-category`}
                />
              )}
            </div>

            {/* Target Amount */}
            <div className="goal-form__field">
              <label htmlFor={`${formId}-amount`} className="goal-form__label">
                Target Amount *
              </label>
              <Input
                id={`${formId}-amount`}
                type="number"
                value={formData.target_amount}
                onChange={(e) =>
                  setFormData((prev) => ({
                    ...prev,
                    target_amount: Number(e.target.value),
                  }))
                }
                onBlur={targetAmountValidation.onBlur}
                placeholder="0.00"
                required
                min="0"
                step="0.01"
                aria-invalid={!!targetAmountValidation.message}
                aria-describedby={
                  targetAmountValidation.message
                    ? `${formId}-amount-validation`
                    : undefined
                }
              />
              {targetAmountValidation.hasBlurred && (
                <ValidationMessage
                  state={targetAmountValidation.state}
                  message={targetAmountValidation.message}
                  fieldId={`${formId}-amount`}
                />
              )}
            </div>

            {/* Target Date */}
            <div className="goal-form__field">
              <label htmlFor={`${formId}-date`} className="goal-form__label">
                Target Date *
              </label>
              <DatePicker
                id={`${formId}-date`}
                value={
                  formData.target_date
                    ? new Date(formData.target_date)
                    : undefined
                }
                onChange={(date) => {
                  setFormData((prev) => ({
                    ...prev,
                    target_date: date
                      ? date.toISOString().split('T')[0]
                      : undefined,
                  }));
                  setTimeout(() => targetDateValidation.revalidate(), 0);
                }}
                placeholder="Select target date..."
                required
                error={
                  targetDateValidation.hasBlurred
                    ? targetDateValidation.message
                    : undefined
                }
                aria-describedby={
                  targetDateValidation.message
                    ? `${formId}-date-validation`
                    : undefined
                }
                dateFormat="PPP"
              />
              {targetDateValidation.hasBlurred && (
                <ValidationMessage
                  state={targetDateValidation.state}
                  message={targetDateValidation.message}
                  fieldId={`${formId}-date`}
                />
              )}
              <p className="goal-form__help-text">
                Set a realistic deadline to help you stay motivated
              </p>
            </div>

            {/* Priority */}
            <fieldset className="goal-form__field">
              <legend className="goal-form__label">Priority</legend>
              <RadioGroup.Root
                className="goal-form__radio-group"
                value={formData.priority}
                onValueChange={(value: GoalPriority) =>
                  setFormData((prev) => ({ ...prev, priority: value }))
                }
                aria-label="Goal priority"
              >
                {GOAL_PRIORITIES.map((priority) => (
                  <div key={priority.value} className="goal-form__radio-item">
                    <RadioGroup.Item
                      className="goal-form__radio-button"
                      value={priority.value}
                      id={`${formId}-priority-${priority.value}`}
                    >
                      <RadioGroup.Indicator className="goal-form__radio-indicator" />
                    </RadioGroup.Item>
                    <label
                      className="goal-form__radio-label"
                      htmlFor={`${formId}-priority-${priority.value}`}
                    >
                      <span className="goal-form__radio-icon">
                        {priority.icon}
                      </span>
                      {priority.label}
                    </label>
                  </div>
                ))}
              </RadioGroup.Root>
            </fieldset>

            {/* Goal Icon */}
            <fieldset className="goal-form__field">
              <legend className="goal-form__label">Goal Icon</legend>
              <div className="goal-form__icon-grid">
                {GOAL_ICONS.map((iconOption) => (
                  <button
                    key={iconOption.emoji}
                    type="button"
                    className={`goal-form__icon-button ${
                      formData.icon === iconOption.emoji
                        ? 'goal-form__icon-button--selected'
                        : ''
                    }`}
                    onClick={() =>
                      setFormData((prev) => ({
                        ...prev,
                        icon: iconOption.emoji,
                      }))
                    }
                    aria-label={`${iconOption.name} icon`}
                    aria-pressed={formData.icon === iconOption.emoji}
                  >
                    <span className="goal-form__icon-emoji">
                      {iconOption.emoji}
                    </span>
                  </button>
                ))}
              </div>
            </fieldset>
          </form>

          <div className="goal-form__footer">
            <Button
              type="button"
              variant="secondary"
              onClick={handleClose}
              disabled={isSubmitting}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              form={formId}
              variant="primary"
              disabled={isSubmitting || !isFormValid}
            >
              {isSubmitting
                ? 'Saving...'
                : goalId
                  ? 'Update Goal'
                  : 'Create Goal'}
            </Button>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
