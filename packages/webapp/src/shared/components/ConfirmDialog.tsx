/**
 * Confirmation Dialog Component
 * A reusable confirmation dialog using Radix UI
 */

import * as Dialog from '@radix-ui/react-dialog';
import { useId } from 'react';
import { Button } from './Button';
import './ConfirmDialog.css';

export interface ConfirmDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void | Promise<void>;
  title: string;
  description: string;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: 'danger' | 'warning' | 'default';
  isLoading?: boolean;
}

export function ConfirmDialog({
  isOpen,
  onClose,
  onConfirm,
  title,
  description,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  variant = 'default',
  isLoading = false,
}: ConfirmDialogProps) {
  const titleId = useId();
  const descriptionId = useId();

  const handleConfirm = async () => {
    await onConfirm();
    onClose();
  };

  return (
    <Dialog.Root open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <Dialog.Portal>
        <Dialog.Overlay className="confirm-dialog__overlay" />
        <Dialog.Content
          className="confirm-dialog__content"
          aria-labelledby={titleId}
          aria-describedby={descriptionId}
        >
          <Dialog.Title
            id={titleId}
            className={`confirm-dialog__title confirm-dialog__title--${variant}`}
          >
            {title}
          </Dialog.Title>

          <Dialog.Description
            id={descriptionId}
            className="confirm-dialog__description"
          >
            {description}
          </Dialog.Description>

          <div className="confirm-dialog__actions">
            <Button
              variant="secondary"
              onClick={onClose}
              disabled={isLoading}
              className="confirm-dialog__button"
            >
              {cancelLabel}
            </Button>
            <Button
              variant={variant === 'danger' ? 'danger' : 'primary'}
              onClick={handleConfirm}
              isLoading={isLoading}
              className="confirm-dialog__button"
            >
              {confirmLabel}
            </Button>
          </div>

          <Dialog.Close asChild>
            <button
              type="button"
              className="confirm-dialog__close"
              aria-label="Close"
              disabled={isLoading}
            >
              ✕
            </button>
          </Dialog.Close>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
