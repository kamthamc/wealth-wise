/**
 * Account Actions Component
 * Quick action buttons for account operations
 */

import { ArrowDownUp, Download, Plus, Upload, XCircle } from 'lucide-react';
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
  return (
    <div className="account-actions">
      <h3 className="account-actions__title">Quick Actions</h3>
      <div className="account-actions__grid">
        {!isClosed && (
          <>
            <Button
              variant="primary"
              onClick={onAddTransaction}
              className="account-actions__button"
            >
              <Plus size={20} />
              Add Transaction
            </Button>
            <Button
              variant="secondary"
              onClick={onTransferMoney}
              className="account-actions__button"
            >
              <ArrowDownUp size={20} />
              Transfer Money
            </Button>
            <Button
              variant="secondary"
              onClick={onImportTransactions}
              className="account-actions__button"
            >
              <Upload size={20} />
              Import Transactions
            </Button>
          </>
        )}
        <Button
          variant="secondary"
          onClick={onExportTransactions}
          className="account-actions__button"
        >
          <Download size={20} />
          Export Transactions
        </Button>
        <Button
          variant="secondary"
          onClick={onDownloadStatement}
          className="account-actions__button"
        >
          <Download size={20} />
          Download Statement
        </Button>
        {isClosed ? (
          <Button
            variant="primary"
            onClick={onReopenAccount}
            className="account-actions__button"
          >
            <Plus size={20} />
            Reopen Account
          </Button>
        ) : (
          <Button
            variant="danger"
            onClick={onCloseAccount}
            className="account-actions__button"
          >
            <XCircle size={20} />
            Close Account
          </Button>
        )}
      </div>
    </div>
  );
}
