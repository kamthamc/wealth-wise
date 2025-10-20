/**
 * Add Transaction Modal Component
 * Modal wrapper for the AddTransactionForm to be used inline on pages
 */

import type { ReactNode } from 'react';
import { AddTransactionForm } from './AddTransactionForm';

export interface AddTransactionModalProps {
  /** Whether the modal is open */
  isOpen: boolean;
  /** Callback when the modal should close */
  onClose: () => void;
  /** Pre-filled account ID */
  defaultAccountId?: string;
  /** Trigger button or element */
  trigger?: ReactNode;
}

export function AddTransactionModal({
  isOpen,
  onClose,
  defaultAccountId,
}: AddTransactionModalProps) {
  return (
    <AddTransactionForm
      isOpen={isOpen}
      onClose={onClose}
      defaultAccountId={defaultAccountId}
    />
  );
}
