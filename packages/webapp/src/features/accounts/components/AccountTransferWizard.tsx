/**
 * Account Transfer Wizard Component
 * Step-by-step wizard for transferring money between accounts with dual-entry bookkeeping
 */

import * as Dialog from '@radix-ui/react-dialog';
import { ArrowRight, Check, CheckCircle2 } from 'lucide-react';
import { useState } from 'react';
import { useAccountStore, useTransactionStore } from '@/core/stores';
import { Button, Input, Select } from '@/shared/components';
import { formatCurrency } from '@/shared/utils';
import './AccountTransferWizard.css';

interface AccountTransferWizardProps {
  isOpen: boolean;
  onClose: () => void;
  defaultFromAccount?: string;
  defaultToAccount?: string;
}

type WizardStep = 'accounts' | 'amount' | 'details' | 'confirm';

export function AccountTransferWizard({
  isOpen,
  onClose,
  defaultFromAccount = '',
  defaultToAccount = '',
}: AccountTransferWizardProps) {
  const { accounts } = useAccountStore();
  const { createTransaction, linkTransactions } = useTransactionStore();

  // Wizard state
  const [currentStep, setCurrentStep] = useState<WizardStep>('accounts');
  const [isProcessing, setIsProcessing] = useState(false);

  // Transfer data
  const [fromAccountId, setFromAccountId] = useState(defaultFromAccount);
  const [toAccountId, setToAccountId] = useState(defaultToAccount);
  const [amount, setAmount] = useState('');
  const [description, setDescription] = useState('');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [notes, setNotes] = useState('');

  // Reset form
  const resetForm = () => {
    setCurrentStep('accounts');
    setFromAccountId(defaultFromAccount);
    setToAccountId(defaultToAccount);
    setAmount('');
    setDescription('');
    setDate(new Date().toISOString().split('T')[0]);
    setNotes('');
    setIsProcessing(false);
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  // Validation
  const canProceedFromAccounts =
    fromAccountId && toAccountId && fromAccountId !== toAccountId;
  const canProceedFromAmount = amount && parseFloat(amount) > 0;
  const canProceedFromDetails = description.trim().length > 0;

  // Get account info
  const fromAccount = accounts.find((a) => a.id === fromAccountId);
  const toAccount = accounts.find((a) => a.id === toAccountId);
  const transferAmount = parseFloat(amount) || 0;

  // Handle transfer execution
  const handleTransfer = async () => {
    if (
      !canProceedFromAccounts ||
      !canProceedFromAmount ||
      !canProceedFromDetails
    ) {
      return;
    }

    try {
      setIsProcessing(true);

      // Create withdrawal transaction (from account)
      const withdrawalTransaction = await createTransaction({
        account_id: fromAccountId,
        type: 'transfer',
        category: 'Transfer Out',
        amount: transferAmount,
        description: description || 'Account Transfer',
        date: new Date(date || new Date().toISOString()),
        tags: ['transfer'],
        is_recurring: false,
      });

      if (!withdrawalTransaction) {
        throw new Error('Failed to create withdrawal transaction');
      }

      // Create deposit transaction (to account)
      const depositTransaction = await createTransaction({
        account_id: toAccountId,
        type: 'transfer',
        category: 'Transfer In',
        amount: transferAmount,
        description: description || 'Account Transfer',
        date: new Date(date || new Date().toISOString()),
        tags: ['transfer'],
        is_recurring: false,
      });

      if (!depositTransaction) {
        throw new Error('Failed to create deposit transaction');
      }

      // Link the two transactions
      await linkTransactions(withdrawalTransaction.id, depositTransaction.id);

      // Success!
      alert(
        `Successfully transferred ${formatCurrency(transferAmount)} from ${fromAccount?.name} to ${toAccount?.name}`
      );
      handleClose();
    } catch (error) {
      console.error('Transfer failed:', error);
      alert('Failed to complete transfer. Please try again.');
      setIsProcessing(false);
    }
  };

  // Step navigation
  const goToStep = (step: WizardStep) => {
    setCurrentStep(step);
  };

  const nextStep = () => {
    if (currentStep === 'accounts' && canProceedFromAccounts) {
      goToStep('amount');
    } else if (currentStep === 'amount' && canProceedFromAmount) {
      goToStep('details');
    } else if (currentStep === 'details' && canProceedFromDetails) {
      goToStep('confirm');
    }
  };

  const prevStep = () => {
    if (currentStep === 'amount') {
      goToStep('accounts');
    } else if (currentStep === 'details') {
      goToStep('amount');
    } else if (currentStep === 'confirm') {
      goToStep('details');
    }
  };

  return (
    <Dialog.Root
      open={isOpen}
      onOpenChange={(open: boolean) => !open && handleClose()}
    >
      <Dialog.Portal>
        <Dialog.Overlay className="transfer-wizard__overlay" />
        <Dialog.Content className="transfer-wizard__content">
          {/* Header */}
          <div className="transfer-wizard__header">
            <Dialog.Title className="transfer-wizard__title">
              Transfer Money Between Accounts
            </Dialog.Title>
            <Dialog.Description className="transfer-wizard__description">
              Move funds from one account to another with automatic dual-entry
              bookkeeping
            </Dialog.Description>
            <Dialog.Close
              className="transfer-wizard__close"
              aria-label="Close dialog"
            >
              ✕
            </Dialog.Close>
          </div>

          {/* Progress Steps */}
          <div className="transfer-wizard__progress">
            <div
              className={`transfer-wizard__step ${currentStep === 'accounts' ? 'transfer-wizard__step--active' : ''} ${['amount', 'details', 'confirm'].includes(currentStep) ? 'transfer-wizard__step--completed' : ''}`}
              onClick={() => goToStep('accounts')}
            >
              <span className="transfer-wizard__step-number">1</span>
              <span className="transfer-wizard__step-label">Accounts</span>
            </div>
            <div className="transfer-wizard__step-divider" />
            <div
              className={`transfer-wizard__step ${currentStep === 'amount' ? 'transfer-wizard__step--active' : ''} ${['details', 'confirm'].includes(currentStep) ? 'transfer-wizard__step--completed' : ''}`}
              onClick={() => canProceedFromAccounts && goToStep('amount')}
            >
              <span className="transfer-wizard__step-number">2</span>
              <span className="transfer-wizard__step-label">Amount</span>
            </div>
            <div className="transfer-wizard__step-divider" />
            <div
              className={`transfer-wizard__step ${currentStep === 'details' ? 'transfer-wizard__step--active' : ''} ${currentStep === 'confirm' ? 'transfer-wizard__step--completed' : ''}`}
              onClick={() =>
                canProceedFromAccounts &&
                canProceedFromAmount &&
                goToStep('details')
              }
            >
              <span className="transfer-wizard__step-number">3</span>
              <span className="transfer-wizard__step-label">Details</span>
            </div>
            <div className="transfer-wizard__step-divider" />
            <div
              className={`transfer-wizard__step ${currentStep === 'confirm' ? 'transfer-wizard__step--active' : ''}`}
            >
              <span className="transfer-wizard__step-number">4</span>
              <span className="transfer-wizard__step-label">Confirm</span>
            </div>
          </div>

          {/* Step Content */}
          <div className="transfer-wizard__body">
            {/* Step 1: Select Accounts */}
            {currentStep === 'accounts' && (
              <div className="transfer-wizard__step-content">
                <h3 className="transfer-wizard__step-title">
                  Select Source and Destination Accounts
                </h3>

                <div className="transfer-wizard__field">
                  <label className="transfer-wizard__label">
                    From Account *
                  </label>
                  <Select
                    options={[
                      { value: '', label: 'Select source account...' },
                      ...accounts.map((acc) => ({
                        value: acc.id,
                        label: `${acc.name} (${formatCurrency(acc.balance)})`,
                      })),
                    ]}
                    value={fromAccountId}
                    onChange={(e) => setFromAccountId(e.target.value)}
                  />
                </div>

                <div className="transfer-wizard__arrow">
                  <ArrowRight size={32} />
                </div>

                <div className="transfer-wizard__field">
                  <label className="transfer-wizard__label">To Account *</label>
                  <Select
                    options={[
                      { value: '', label: 'Select destination account...' },
                      ...accounts.map((acc) => ({
                        value: acc.id,
                        label: `${acc.name} (${formatCurrency(acc.balance)})`,
                      })),
                    ]}
                    value={toAccountId}
                    onChange={(e) => setToAccountId(e.target.value)}
                  />
                </div>

                {fromAccountId &&
                  toAccountId &&
                  fromAccountId === toAccountId && (
                    <div className="transfer-wizard__error">
                      ⚠️ Source and destination accounts must be different
                    </div>
                  )}
              </div>
            )}

            {/* Step 2: Enter Amount */}
            {currentStep === 'amount' && (
              <div className="transfer-wizard__step-content">
                <h3 className="transfer-wizard__step-title">
                  How much do you want to transfer?
                </h3>

                <div className="transfer-wizard__summary">
                  <div className="transfer-wizard__summary-row">
                    <span>From:</span>
                    <strong>{fromAccount?.name}</strong>
                  </div>
                  <div className="transfer-wizard__summary-row">
                    <span>To:</span>
                    <strong>{toAccount?.name}</strong>
                  </div>
                </div>

                <div className="transfer-wizard__field">
                  <label className="transfer-wizard__label">
                    Transfer Amount *
                  </label>
                  <Input
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="0.00"
                    min="0.01"
                    step="0.01"
                    autoFocus
                  />
                  {transferAmount > 0 && (
                    <div className="transfer-wizard__hint">
                      {formatCurrency(transferAmount)} will be moved from{' '}
                      {fromAccount?.name} to {toAccount?.name}
                    </div>
                  )}
                </div>

                {fromAccount && transferAmount > fromAccount.balance && (
                  <div className="transfer-wizard__warning">
                    ⚠️ Transfer amount exceeds available balance in{' '}
                    {fromAccount.name}
                  </div>
                )}
              </div>
            )}

            {/* Step 3: Enter Details */}
            {currentStep === 'details' && (
              <div className="transfer-wizard__step-content">
                <h3 className="transfer-wizard__step-title">
                  Add Transfer Details
                </h3>

                <div className="transfer-wizard__field">
                  <label className="transfer-wizard__label">
                    Description *
                  </label>
                  <Input
                    type="text"
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder="e.g., Monthly savings transfer"
                    autoFocus
                  />
                </div>

                <div className="transfer-wizard__field">
                  <label className="transfer-wizard__label">
                    Transfer Date *
                  </label>
                  <Input
                    type="date"
                    value={date}
                    onChange={(e) => setDate(e.target.value)}
                  />
                </div>

                <div className="transfer-wizard__field">
                  <label className="transfer-wizard__label">
                    Notes (Optional)
                  </label>
                  <Input
                    type="text"
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder="Add any additional notes..."
                  />
                </div>
              </div>
            )}

            {/* Step 4: Confirm Transfer */}
            {currentStep === 'confirm' && (
              <div className="transfer-wizard__step-content">
                <h3 className="transfer-wizard__step-title">
                  Review and Confirm Transfer
                </h3>

                <div className="transfer-wizard__confirm-card">
                  <div className="transfer-wizard__confirm-header">
                    <CheckCircle2 size={48} color="var(--color-success)" />
                    <div className="transfer-wizard__confirm-amount">
                      {formatCurrency(transferAmount)}
                    </div>
                  </div>

                  <div className="transfer-wizard__confirm-details">
                    <div className="transfer-wizard__confirm-row">
                      <span className="transfer-wizard__confirm-label">
                        From:
                      </span>
                      <span className="transfer-wizard__confirm-value">
                        {fromAccount?.name}
                      </span>
                    </div>
                    <div className="transfer-wizard__confirm-row">
                      <span className="transfer-wizard__confirm-label">
                        To:
                      </span>
                      <span className="transfer-wizard__confirm-value">
                        {toAccount?.name}
                      </span>
                    </div>
                    <div className="transfer-wizard__confirm-row">
                      <span className="transfer-wizard__confirm-label">
                        Description:
                      </span>
                      <span className="transfer-wizard__confirm-value">
                        {description}
                      </span>
                    </div>
                    <div className="transfer-wizard__confirm-row">
                      <span className="transfer-wizard__confirm-label">
                        Date:
                      </span>
                      <span className="transfer-wizard__confirm-value">
                        {new Date(
                          date || new Date().toISOString()
                        ).toLocaleDateString()}
                      </span>
                    </div>
                    {notes && (
                      <div className="transfer-wizard__confirm-row">
                        <span className="transfer-wizard__confirm-label">
                          Notes:
                        </span>
                        <span className="transfer-wizard__confirm-value">
                          {notes}
                        </span>
                      </div>
                    )}
                  </div>

                  <div className="transfer-wizard__confirm-impact">
                    <h4 className="transfer-wizard__confirm-impact-title">
                      Account Balance Changes:
                    </h4>
                    <div className="transfer-wizard__confirm-impact-row">
                      <span>{fromAccount?.name}:</span>
                      <span>
                        {formatCurrency(fromAccount?.balance || 0)} →{' '}
                        <strong>
                          {formatCurrency(
                            (fromAccount?.balance || 0) - transferAmount
                          )}
                        </strong>
                      </span>
                    </div>
                    <div className="transfer-wizard__confirm-impact-row">
                      <span>{toAccount?.name}:</span>
                      <span>
                        {formatCurrency(toAccount?.balance || 0)} →{' '}
                        <strong>
                          {formatCurrency(
                            (toAccount?.balance || 0) + transferAmount
                          )}
                        </strong>
                      </span>
                    </div>
                  </div>
                </div>

                <div className="transfer-wizard__info">
                  ℹ️ This will create two linked transactions: a withdrawal from{' '}
                  {fromAccount?.name} and a deposit to {toAccount?.name}
                </div>
              </div>
            )}
          </div>

          {/* Footer Actions */}
          <div className="transfer-wizard__footer">
            <div className="transfer-wizard__footer-actions">
              <Button
                variant="secondary"
                onClick={currentStep === 'accounts' ? handleClose : prevStep}
                disabled={isProcessing}
              >
                {currentStep === 'accounts' ? 'Cancel' : 'Back'}
              </Button>

              {currentStep !== 'confirm' ? (
                <Button
                  onClick={nextStep}
                  disabled={
                    (currentStep === 'accounts' && !canProceedFromAccounts) ||
                    (currentStep === 'amount' && !canProceedFromAmount) ||
                    (currentStep === 'details' && !canProceedFromDetails)
                  }
                >
                  Continue
                  <ArrowRight size={20} />
                </Button>
              ) : (
                <Button onClick={handleTransfer} disabled={isProcessing}>
                  {isProcessing ? (
                    'Processing...'
                  ) : (
                    <>
                      <Check size={20} />
                      Complete Transfer
                    </>
                  )}
                </Button>
              )}
            </div>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
