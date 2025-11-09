/**
 * Account Transfer Wizard Component
 * Step-by-step wizard for transferring money between accounts with dual-entry bookkeeping
 */

import * as Dialog from '@radix-ui/react-dialog';
import { ArrowRight, Check, CheckCircle2 } from 'lucide-react';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
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
  const { t } = useTranslation();
  const { accounts } = useAccountStore();
  const { createTransaction } = useTransactionStore();

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

      // Create transfer transaction - Cloud Function handles both sides and linking
      await createTransaction({
        account_id: fromAccountId,
        type: 'transfer',
        category: 'Transfer',
        amount: transferAmount,
        description: description || 'Account Transfer',
        date: new Date(date || new Date().toISOString()),
        tags: ['transfer'],
        is_recurring: false,
        to_account_id: toAccountId, // Cloud Function uses this to create linked transactions
      });

      // Success!
      alert(
        t('pages.accounts.transfer.success', {
          amount: formatCurrency(transferAmount),
          fromAccount: fromAccount?.name,
          toAccount: toAccount?.name,
          defaultValue:
            'Successfully transferred {{amount}} from {{fromAccount}} to {{toAccount}}',
        })
      );
      handleClose();
    } catch (error) {
      console.error('Transfer failed:', error);
      alert(
        t(
          'pages.accounts.transfer.error',
          'Failed to complete transfer. Please try again.'
        )
      );
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
              {t(
                'pages.accounts.transfer.title',
                'Transfer Money Between Accounts'
              )}
            </Dialog.Title>
            <Dialog.Description className="transfer-wizard__description">
              {t(
                'pages.accounts.transfer.description',
                'Move funds from one account to another with automatic dual-entry bookkeeping'
              )}
            </Dialog.Description>
            <Dialog.Close
              className="transfer-wizard__close"
              aria-label={t(
                'pages.accounts.transfer.closeLabel',
                'Close dialog'
              )}
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
              <span className="transfer-wizard__step-label">
                {t('pages.accounts.transfer.steps.accounts', 'Accounts')}
              </span>
            </div>
            <div className="transfer-wizard__step-divider" />
            <div
              className={`transfer-wizard__step ${currentStep === 'amount' ? 'transfer-wizard__step--active' : ''} ${['details', 'confirm'].includes(currentStep) ? 'transfer-wizard__step--completed' : ''}`}
              onClick={() => canProceedFromAccounts && goToStep('amount')}
            >
              <span className="transfer-wizard__step-number">2</span>
              <span className="transfer-wizard__step-label">
                {t('pages.accounts.transfer.steps.amount', 'Amount')}
              </span>
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
              <span className="transfer-wizard__step-label">
                {t('pages.accounts.transfer.steps.details', 'Details')}
              </span>
            </div>
            <div className="transfer-wizard__step-divider" />
            <div
              className={`transfer-wizard__step ${currentStep === 'confirm' ? 'transfer-wizard__step--active' : ''}`}
            >
              <span className="transfer-wizard__step-number">4</span>
              <span className="transfer-wizard__step-label">
                {t('pages.accounts.transfer.steps.confirm', 'Confirm')}
              </span>
            </div>
          </div>

          {/* Step Content */}
          <div className="transfer-wizard__body">
            {/* Step 1: Select Accounts */}
            {currentStep === 'accounts' && (
              <div className="transfer-wizard__step-content">
                <h3 className="transfer-wizard__step-title">
                  {t(
                    'pages.accounts.transfer.accountsStep.title',
                    'Select Source and Destination Accounts'
                  )}
                </h3>

                <div className="transfer-wizard__field">
                  <label className="transfer-wizard__label">
                    {t(
                      'pages.accounts.transfer.accountsStep.fromLabel',
                      'From Account *'
                    )}
                  </label>
                  <Select
                    options={[
                      {
                        value: '',
                        label: t(
                          'pages.accounts.transfer.accountsStep.fromPlaceholder',
                          'Select source account...'
                        ),
                      },
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
                  <label className="transfer-wizard__label">
                    {t(
                      'pages.accounts.transfer.accountsStep.toLabel',
                      'To Account *'
                    )}
                  </label>
                  <Select
                    options={[
                      {
                        value: '',
                        label: t(
                          'pages.accounts.transfer.accountsStep.toPlaceholder',
                          'Select destination account...'
                        ),
                      },
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
                      {t(
                        'pages.accounts.transfer.accountsStep.sameAccountError',
                        '⚠️ Source and destination accounts must be different'
                      )}
                    </div>
                  )}
              </div>
            )}

            {/* Step 2: Enter Amount */}
            {currentStep === 'amount' && (
              <div className="transfer-wizard__step-content">
                <h3 className="transfer-wizard__step-title">
                  {t(
                    'pages.accounts.transfer.amountStep.title',
                    'How much do you want to transfer?'
                  )}
                </h3>

                <div className="transfer-wizard__summary">
                  <div className="transfer-wizard__summary-row">
                    <span>
                      {t('pages.accounts.transfer.amountStep.fromLabel', 'From:')}
                    </span>
                    <strong>{fromAccount?.name}</strong>
                  </div>
                  <div className="transfer-wizard__summary-row">
                    <span>
                      {t('pages.accounts.transfer.amountStep.toLabel', 'To:')}
                    </span>
                    <strong>{toAccount?.name}</strong>
                  </div>
                </div>

                <div className="transfer-wizard__field">
                  <label className="transfer-wizard__label">
                    {t(
                      'pages.accounts.transfer.amountStep.amountLabel',
                      'Transfer Amount *'
                    )}
                  </label>
                  <Input
                    type="number"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder={t(
                      'pages.accounts.transfer.amountStep.amountPlaceholder',
                      '0.00'
                    )}
                    min="0.01"
                    step="0.01"
                    autoFocus
                  />
                  {transferAmount > 0 && (
                    <div className="transfer-wizard__hint">
                      {t('pages.accounts.transfer.amountStep.hint', {
                        amount: formatCurrency(transferAmount),
                        fromAccount: fromAccount?.name,
                        toAccount: toAccount?.name,
                        defaultValue:
                          '{{amount}} will be moved from {{fromAccount}} to {{toAccount}}',
                      })}
                    </div>
                  )}
                </div>

                {fromAccount && transferAmount > fromAccount.balance && (
                  <div className="transfer-wizard__warning">
                    {t('pages.accounts.transfer.amountStep.balanceWarning', {
                      account: fromAccount.name,
                      defaultValue:
                        '⚠️ Transfer amount exceeds available balance in {{account}}',
                    })}
                  </div>
                )}
              </div>
            )}

            {/* Step 3: Enter Details */}
            {currentStep === 'details' && (
              <div className="transfer-wizard__step-content">
                <h3 className="transfer-wizard__step-title">
                  {t(
                    'pages.accounts.transfer.detailsStep.title',
                    'Add Transfer Details'
                  )}
                </h3>

                <div className="transfer-wizard__field">
                  <label className="transfer-wizard__label">
                    {t(
                      'pages.accounts.transfer.detailsStep.descriptionLabel',
                      'Description *'
                    )}
                  </label>
                  <Input
                    type="text"
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    placeholder={t(
                      'pages.accounts.transfer.detailsStep.descriptionPlaceholder',
                      'e.g., Monthly savings transfer'
                    )}
                    autoFocus
                  />
                </div>

                <div className="transfer-wizard__field">
                  <label className="transfer-wizard__label">
                    {t(
                      'pages.accounts.transfer.detailsStep.dateLabel',
                      'Transfer Date *'
                    )}
                  </label>
                  <Input
                    type="date"
                    value={date}
                    onChange={(e) => setDate(e.target.value)}
                  />
                </div>

                <div className="transfer-wizard__field">
                  <label className="transfer-wizard__label">
                    {t(
                      'pages.accounts.transfer.detailsStep.notesLabel',
                      'Notes (Optional)'
                    )}
                  </label>
                  <Input
                    type="text"
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder={t(
                      'pages.accounts.transfer.detailsStep.notesPlaceholder',
                      'Add any additional notes...'
                    )}
                  />
                </div>
              </div>
            )}

            {/* Step 4: Confirm Transfer */}
            {currentStep === 'confirm' && (
              <div className="transfer-wizard__step-content">
                <h3 className="transfer-wizard__step-title">
                  {t(
                    'pages.accounts.transfer.confirmStep.title',
                    'Review and Confirm Transfer'
                  )}
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
                        {t(
                          'pages.accounts.transfer.confirmStep.fromLabel',
                          'From:'
                        )}
                      </span>
                      <span className="transfer-wizard__confirm-value">
                        {fromAccount?.name}
                      </span>
                    </div>
                    <div className="transfer-wizard__confirm-row">
                      <span className="transfer-wizard__confirm-label">
                        {t(
                          'pages.accounts.transfer.confirmStep.toLabel',
                          'To:'
                        )}
                      </span>
                      <span className="transfer-wizard__confirm-value">
                        {toAccount?.name}
                      </span>
                    </div>
                    <div className="transfer-wizard__confirm-row">
                      <span className="transfer-wizard__confirm-label">
                        {t(
                          'pages.accounts.transfer.confirmStep.descriptionLabel',
                          'Description:'
                        )}
                      </span>
                      <span className="transfer-wizard__confirm-value">
                        {description}
                      </span>
                    </div>
                    <div className="transfer-wizard__confirm-row">
                      <span className="transfer-wizard__confirm-label">
                        {t(
                          'pages.accounts.transfer.confirmStep.dateLabel',
                          'Date:'
                        )}
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
                          {t(
                            'pages.accounts.transfer.confirmStep.notesLabel',
                            'Notes:'
                          )}
                        </span>
                        <span className="transfer-wizard__confirm-value">
                          {notes}
                        </span>
                      </div>
                    )}
                  </div>

                  <div className="transfer-wizard__confirm-impact">
                    <h4 className="transfer-wizard__confirm-impact-title">
                      {t(
                        'pages.accounts.transfer.confirmStep.impactTitle',
                        'Account Balance Changes:'
                      )}
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
                  {t('pages.accounts.transfer.confirmStep.impactInfo', {
                    fromAccount: fromAccount?.name,
                    toAccount: toAccount?.name,
                    defaultValue:
                      'ℹ️ This will create two linked transactions: a withdrawal from {{fromAccount}} and a deposit to {{toAccount}}',
                  })}
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
                {currentStep === 'accounts'
                  ? t('pages.accounts.transfer.actions.cancel', 'Cancel')
                  : t('pages.accounts.transfer.actions.back', 'Back')}
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
                  {t('pages.accounts.transfer.actions.continue', 'Continue')}
                  <ArrowRight size={20} />
                </Button>
              ) : (
                <Button onClick={handleTransfer} disabled={isProcessing}>
                  {isProcessing ? (
                    t('pages.accounts.transfer.actions.processing', 'Processing...')
                  ) : (
                    <>
                      <Check size={20} />
                      {t(
                        'pages.accounts.transfer.actions.complete',
                        'Complete Transfer'
                      )}
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
