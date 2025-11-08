/**
 * Account Actions Component
 * Quick action buttons for account operations
 */

import { ArrowDownUp, Download, Plus, Upload, XCircle } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { Button } from '@/shared/components';
import './AccountActions.css';

export interface AccountActionsProps {
  accountId: string;
  accountName: string;
  isClosed: boolean;
  onAddTransaction: () => void;
  onTransferMoney: () => void;
  onDownloadStatement: () => void;
  onImportTransactions: () => void;
  onExportTransactions: () => void;
  onCloseAccount: () => void;
  onReopenAccount: () => void;
}

export function AccountActions({
  isClosed,
  onAddTransaction,
  onTransferMoney,
  onDownloadStatement,
  onImportTransactions,
  onExportTransactions,
  onCloseAccount,
  onReopenAccount,
}: AccountActionsProps) {
  const { t } = useTranslation();
  
  return (
    <div className="account-actions">
      <h3 className="account-actions__title">
        {t('pages.accounts.details.actions.title', 'Quick Actions')}
      </h3>
      <div className="account-actions__grid">
        {!isClosed && (
          <>
            <Button
              variant="primary"
              onClick={onAddTransaction}
              className="account-actions__button"
            >
              <Plus size={20} />
              {t('pages.accounts.details.actions.addTransaction', 'Add Transaction')}
            </Button>
            <Button
              variant="secondary"
              onClick={onTransferMoney}
              className="account-actions__button"
            >
              <ArrowDownUp size={20} />
              {t('pages.accounts.details.actions.transferMoney', 'Transfer Money')}
            </Button>
            <Button
              variant="secondary"
              onClick={onImportTransactions}
              className="account-actions__button"
            >
              <Upload size={20} />
              {t('pages.accounts.details.actions.importTransactions', 'Import Transactions')}
            </Button>
          </>
        )}
        <Button
          variant="secondary"
          onClick={onExportTransactions}
          className="account-actions__button"
        >
          <Download size={20} />
          {t('pages.accounts.details.actions.exportTransactions', 'Export Transactions')}
        </Button>
        <Button
          variant="secondary"
          onClick={onDownloadStatement}
          className="account-actions__button"
        >
          <Download size={20} />
          {t('pages.accounts.details.actions.downloadStatement', 'Download Statement')}
        </Button>
        {isClosed ? (
          <Button
            variant="primary"
            onClick={onReopenAccount}
            className="account-actions__button"
          >
            <Plus size={20} />
            {t('pages.accounts.details.actions.reopenAccount', 'Reopen Account')}
          </Button>
        ) : (
          <Button
            variant="danger"
            onClick={onCloseAccount}
            className="account-actions__button"
          >
            <XCircle size={20} />
            {t('pages.accounts.details.actions.closeAccount', 'Close Account')}
          </Button>
        )}
      </div>
    </div>
  );
}
