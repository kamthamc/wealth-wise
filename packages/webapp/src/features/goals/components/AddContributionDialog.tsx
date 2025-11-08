/**
 * Add Contribution Dialog Component
 * Modal for adding contributions to a goal
 */

import * as Dialog from '@radix-ui/react-dialog';
import { X } from 'lucide-react';
import { useState } from 'react';
import { useGoalStore } from '@/core/stores';
import {
  Button,
  DatePicker,
  Input,
  useToast,
  ValidationMessage,
} from '@/shared/components';
import {
  useValidation,
  validators,
  type ValidationResult,
} from '@/shared/hooks/useValidation';
import { formatCurrency } from '@/shared/utils';
import './AddContributionDialog.css';

interface AddContributionDialogProps {
  isOpen: boolean;
  onClose: () => void;
  goalId: string;
  onSuccess?: () => void;
}

export function AddContributionDialog({
  isOpen,
  onClose,
  goalId,
  onSuccess,
}: AddContributionDialogProps) {
  const { goals, addContribution } = useGoalStore();
  const toast = useToast();

  const goal = goals.find((g) => g.id === goalId);

  const [amount, setAmount] = useState('');
  const [date, setDate] = useState<Date>(new Date());
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Validation
  const amountValidation = useValidation(amount, {
    validate: validators.combine(
      validators.required,
      (value): ValidationResult => {
        const num = Number.parseFloat(value);
        const isValid = !Number.isNaN(num) && num > 0;
        return {
          isValid,
          message: isValid ? undefined : 'Amount must be greater than 0',
          state: isValid ? 'success' : 'error',
        };
      }
    ),
    debounceMs: 300,
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!goal) {
      toast.error('Goal not found');
      return;
    }

    const amountValue = Number.parseFloat(amount);
    if (Number.isNaN(amountValue) || amountValue <= 0) {
      toast.error('Please enter a valid amount');
      return;
    }

    setIsSubmitting(true);

    try {
      await addContribution({
        goalId,
        amount: amountValue,
        date: date.toISOString(),
        notes: notes || undefined,
      });
      toast.success(
        `Added ${formatCurrency(amountValue)} to ${goal.name}`
      );
      onSuccess?.();
      onClose();
    } catch (error) {
      console.error('Failed to add contribution:', error);
      toast.error('Failed to add contribution');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    if (!isSubmitting) {
      setAmount('');
      setNotes('');
      setDate(new Date());
      onClose();
    }
  };

  if (!goal) return null;

  const remaining = goal.target_amount - goal.current_amount;
  const progressPercent = (goal.current_amount / goal.target_amount) * 100;

  return (
    <Dialog.Root open={isOpen} onOpenChange={(open) => !open && handleClose()}>
      <Dialog.Portal>
        <Dialog.Overlay className="dialog-overlay" />
        <Dialog.Content className="dialog-content add-contribution-dialog">
          <div className="dialog-header">
            <Dialog.Title className="dialog-title">
              Add Contribution
            </Dialog.Title>
            <Dialog.Close asChild>
              <button
                className="dialog-close"
                aria-label="Close"
                disabled={isSubmitting}
              >
                <X size={20} />
              </button>
            </Dialog.Close>
          </div>

          <Dialog.Description className="dialog-description">
            Add a contribution to <strong>{goal.name}</strong>
          </Dialog.Description>

          {/* Goal Progress Summary */}
          <div className="contribution-dialog__summary">
            <div className="contribution-dialog__progress">
              <div className="contribution-dialog__progress-bar">
                <div
                  className="contribution-dialog__progress-fill"
                  style={{ width: `${Math.min(progressPercent, 100)}%` }}
                />
              </div>
              <div className="contribution-dialog__progress-text">
                <span>{formatCurrency(goal.current_amount)}</span>
                <span>of {formatCurrency(goal.target_amount)}</span>
              </div>
            </div>
            <p className="contribution-dialog__remaining">
              {formatCurrency(remaining)} remaining to reach your goal
            </p>
          </div>

          <form onSubmit={handleSubmit} className="contribution-dialog__form">
            {/* Amount */}
            <div className="form-field">
              <label htmlFor="amount" className="form-label">
                Amount <span className="form-required">*</span>
              </label>
              <Input
                id="amount"
                type="number"
                step="0.01"
                min="0"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                onBlur={amountValidation.onBlur}
                placeholder="0.00"
                disabled={isSubmitting}
                error={!amountValidation.isValid ? amountValidation.message : undefined}
              />
              <ValidationMessage
                state={amountValidation.state}
                message={amountValidation.message}
              />
              {amount && amountValidation.isValid && (
                <p className="form-hint">
                  New total: {formatCurrency(goal.current_amount + Number.parseFloat(amount))}
                </p>
              )}
            </div>

            {/* Date */}
            <div className="form-field">
              <label htmlFor="date" className="form-label">
                Contribution Date
              </label>
              <DatePicker
                value={date}
                onChange={(newDate) => newDate && setDate(newDate)}
                disabled={isSubmitting}
              />
            </div>

            {/* Notes */}
            <div className="form-field">
              <label htmlFor="notes" className="form-label">
                Notes (Optional)
              </label>
              <Input
                id="notes"
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="e.g., Monthly savings, Bonus contribution"
                disabled={isSubmitting}
              />
            </div>

            {/* Actions */}
            <div className="dialog-actions">
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
                variant="primary"
                disabled={isSubmitting || !amountValidation.isValid || !amount}
              >
                {isSubmitting ? 'Adding...' : 'Add Contribution'}
              </Button>
            </div>
          </form>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
