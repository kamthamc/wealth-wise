/**
 * Import Transactions Modal
 * Upload CSV, Excel, or PDF files to import transactions
 */

import * as Dialog from '@radix-ui/react-dialog';
import { Upload, X } from 'lucide-react';
import { useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { timestampToDate } from '@/core/utils/firebase';
import {
  detectFileFormat,
  parseFile,
  type ParsedFileData,
} from '@/core/api';
import type { Transaction } from '@/core/types';
import { batchCheckDuplicates } from '@/core/services/duplicateDetectionService';
import type {
  DuplicateCheckResult,
} from '@/core/services/duplicateDetectionService';
import { useTransactionStore } from '@/core/stores';
import { Button, useToast } from '@/shared/components';
import { getTransactionReference } from '../utils/referenceExtraction';
import { ColumnMapper } from './ColumnMapper';
import {
  DuplicateReviewModal,
  type TransactionReviewItem,
} from './DuplicateReviewModal';
import './ImportTransactionsModal.css';

export interface ImportTransactionsModalProps {
  isOpen: boolean;
  onClose: () => void;
  accountId: string;
  accountName: string;
  onImportSuccess?: () => void; // Callback to refresh transactions
}

interface ParsedTransaction {
  date: string;
  description: string;
  amount: number;
  type: 'income' | 'expense' | 'transfer';
  category?: string;
  reference?: string; // Bank transaction reference/ID (Chq./Ref.No., UTR, etc.)
}

export function ImportTransactionsModal({
  isOpen,
  onClose,
  accountId,
  accountName,
  onImportSuccess,
}: ImportTransactionsModalProps) {
  const { t } = useTranslation();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [previewData, setPreviewData] = useState<ParsedTransaction[]>([]);
  const [showColumnMapper, setShowColumnMapper] = useState(false);
  const [parsedData, setParsedData] = useState<ParsedFileData | null>(null);

  // Duplicate detection state
  const [showDuplicateReview, setShowDuplicateReview] = useState(false);
  const [duplicateResults, setDuplicateResults] = useState<
    DuplicateCheckResult[]
  >([]);
  const [importMetadata, setImportMetadata] = useState<{
    importReference: string;
    fileHash: string;
    importSource: string;
  } | null>(null);

  const { createTransaction, updateTransaction } = useTransactionStore();
  const toast = useToast();

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const format = detectFileFormat(file);
    if (format === 'unknown') {
      toast.error(
        t(
          'pages.accounts.import.messages.unsupportedFormatTitle',
          'Unsupported format'
        ),
        t(
          'pages.accounts.import.messages.unsupportedFormatDesc',
          'Please upload CSV, Excel (.xlsx, .xls), or PDF files'
        )
      );
      return;
    }

    setSelectedFile(file);
    parseFileWithFormat(file);
  };

  const parseFileWithFormat = async (file: File) => {
    setIsProcessing(true);
    try {
      const data = await parseFile(file);
      setParsedData(data);
      setShowColumnMapper(true);
      toast.success(
        t('pages.accounts.import.messages.fileParsedTitle', 'File parsed'),
        t(
          'pages.accounts.import.messages.fileParsedDesc',
          'Found {{count}} rows',
          { count: data.rows.length }
        )
      );
    } catch (error) {
      console.error('Failed to parse file:', error);
      toast.error(
        t('pages.accounts.import.messages.parseErrorTitle', 'Parse error'),
        error instanceof Error ? error.message : t('pages.accounts.import.messages.importError', 'Failed to parse file')
      );
      setSelectedFile(null);
      setParsedData(null);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleMappingComplete = async (mappings: any[]) => {
    setShowColumnMapper(false);

    if (!parsedData) return;

    // Check if using separate debit/credit columns (HDFC format)
    const hasDebitColumn = mappings.some(
      (m) => m.systemField === 'amount_debit'
    );
    const hasCreditColumn = mappings.some(
      (m) => m.systemField === 'amount_credit'
    );
    const hasSeparateColumns = hasDebitColumn && hasCreditColumn;

    // Apply mappings to transform data
    const transactions = parsedData.rows
      .map((row) => {
        const txn: any = {};

        mappings.forEach((mapping) => {
          if (mapping.systemField === 'skip') return;

          let value = row[mapping.csvColumn];

          // Apply value mappings (e.g., credit -> income)
          if (mapping.valueMapping && value) {
            const lowerValue = value.toLowerCase().trim();
            value = mapping.valueMapping[lowerValue] || value;
          }

          txn[mapping.systemField] = value;
        });

        // Handle separate debit/credit columns (HDFC format)
        let amount = 0;
        let type: 'income' | 'expense' | 'transfer' = 'expense';

        if (hasSeparateColumns) {
          const debitValue = parseFloat(txn.amount_debit || '0');
          const creditValue = parseFloat(txn.amount_credit || '0');

          if (debitValue > 0) {
            amount = debitValue;
            type = 'expense';
          } else if (creditValue > 0) {
            amount = creditValue;
            type = 'income';
          }
        } else {
          amount = Math.abs(parseFloat(txn.amount || '0'));
          type = (txn.type?.toLowerCase() || 'expense') as
            | 'income'
            | 'expense'
            | 'transfer';
        }

        return {
          date: txn.date || '',
          description: txn.description || '',
          amount,
          type,
          category: txn.category || undefined,
          reference: txn.reference || undefined, // Include reference if mapped
        } as ParsedTransaction;
      })
      .filter(
        (t) =>
          t.date && t.description && !Number.isNaN(t.amount) && t.amount > 0
      );

    if (transactions.length === 0) {
      toast.error(
        'No valid transactions found',
        'All rows were filtered out. Check that your data has valid dates, descriptions, and amounts.'
      );
      return;
    }

    // Generate import metadata
    const importReference = crypto.randomUUID();
    const fileHash = await calculateFileHash(selectedFile!);
    const importSource = detectImportSource(selectedFile!);

    setImportMetadata({
      importReference,
      fileHash,
      importSource,
    });

    // Run duplicate detection
    setIsProcessing(true);
    try {
      const parsedTransactions: Partial<Transaction>[] = transactions.map((t) => ({
        date: t.date,
        amount: t.amount,
        description: t.description,
        import_reference: t.reference,
        type: t.type,
        account_id: accountId,
      }));

      const results = await batchCheckDuplicates(
        parsedTransactions,
        accountId
      );

      setDuplicateResults(results);
      setPreviewData(transactions);

      // Show duplicate review modal
      setShowDuplicateReview(true);

      const dupCount = results.filter((r) => !r.isNewTransaction).length;

      toast.success(
        t(
          'pages.accounts.import.messages.duplicatesFoundTitle',
          'Duplicates detected'
        ),
        t(
          'pages.accounts.import.messages.duplicatesFoundDesc',
          'Found {{count}} potential duplicates. Please review.',
          { count: dupCount }
        )
      );
    } catch (error) {
      console.error('Duplicate detection failed:', error);
      toast.error(
        t(
          'pages.accounts.import.messages.detectionFailedTitle',
          'Detection failed'
        ),
        t(
          'pages.accounts.import.messages.detectionFailedDesc',
          'Could not check for duplicates'
        )
      );
      // Fall back to showing preview without duplicate detection
      setPreviewData(transactions);
    } finally {
      setIsProcessing(false);
    }
  };

  // Helper function to calculate file hash
  const calculateFileHash = async (file: File): Promise<string> => {
    const arrayBuffer = await file.arrayBuffer();
    const hashBuffer = await crypto.subtle.digest('SHA-256', arrayBuffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
  };

  // Helper function to detect import source
  const detectImportSource = (file: File): string => {
    const filename = file.name.toLowerCase();
    if (filename.includes('hdfc')) return 'HDFC Bank CSV';
    if (filename.includes('icici')) return 'ICICI Bank CSV';
    if (filename.includes('sbi')) return 'SBI CSV';
    if (filename.includes('axis')) return 'Axis Bank CSV';
    return `CSV Import (${file.name})`;
  };

  // Handle import with duplicate review actions
  const handleDuplicateReviewImport = async (
    items: TransactionReviewItem[]
  ) => {
    if (!importMetadata) return;

    setIsProcessing(true);
    try {
      let successCount = 0;
      let failCount = 0;

      for (const item of items) {
        // Skip if user chose to skip
        if (item.action === 'skip') continue;

        const transactionData = {
          account_id: accountId,
          amount: item.transaction.amount,
          type: item.transaction.type,
          description: item.transaction.description,
          date: timestampToDate(item.transaction.date),
          category: item.transaction.category || '',
          is_recurring: false,
          is_initial_balance: false,
          tags: [],
          // Add import metadata
          import_reference: importMetadata.importReference,
          import_transaction_id: getTransactionReference(
            item.transaction.reference,
            item.transaction.description
          ),
          import_file_hash: importMetadata.fileHash,
          import_source: importMetadata.importSource,
          import_date: new Date(),
        };

        try {
          if (item.action === 'update' && (item.duplicateResult as any).bestMatch) {
            // Update existing transaction
            const bestMatch = (item.duplicateResult as any).bestMatch;
            await updateTransaction(
              bestMatch.existingTransaction.id,
              transactionData as any
            );
            successCount++;
          } else {
            // Import as new (action === 'import' or 'force')
            await createTransaction(transactionData);
            successCount++;
          }
        } catch (error) {
          console.error('Failed to import transaction:', error);
          failCount++;
        }
      }

      toast.success(
        t(
          'pages.accounts.import.messages.importSuccessTitle',
          'Import complete'
        ),
        t(
          'pages.accounts.import.messages.importSuccess',
          'Successfully imported {{count}} transactions',
          { count: successCount }
        ) +
          (failCount > 0 ? `, ${failCount} failed` : '')
      );

      // Call success callback to refresh transactions
      if (onImportSuccess) {
        onImportSuccess();
      }

      handleClose();
    } catch (error) {
      console.error('Import error:', error);
      toast.error(
        t('pages.accounts.import.messages.importFailed', 'Import failed'),
        t(
          'pages.accounts.import.messages.importError',
          'Failed to import transactions'
        )
      );
    } finally {
      setIsProcessing(false);
    }
  };

  const handleImport = async () => {
    if (previewData.length === 0) {
      toast.error(
        t('pages.accounts.import.messages.noDataTitle', 'No data'),
        t(
          'pages.accounts.import.messages.noDataDesc',
          'No valid transactions to import'
        )
      );
      return;
    }

    setIsProcessing(true);
    try {
      let successCount = 0;
      let failCount = 0;

      for (const transaction of previewData) {
        try {
          await createTransaction({
            account_id: accountId,
            amount: transaction.amount,
            type: transaction.type,
            description: transaction.description,
            date: timestampToDate(transaction.date),
            category: transaction.category || '',
            is_recurring: false,
            is_initial_balance: false,
            tags: [],
          });
          successCount++;
        } catch (error) {
          console.error('Failed to import transaction:', error);
          failCount++;
        }
      }

      toast.success(
        t(
          'pages.accounts.import.messages.importSuccessTitle',
          'Import complete'
        ),
        t(
          'pages.accounts.import.messages.importSuccess',
          'Successfully imported {{count}} transactions',
          { count: successCount }
        ) +
          (failCount > 0 ? `, ${failCount} failed` : '')
      );

      // Call success callback to refresh transactions
      if (onImportSuccess) {
        onImportSuccess();
      }

      handleClose();
    } catch (error) {
      console.error('Import error:', error);
      toast.error(
        t('pages.accounts.import.messages.importFailed', 'Import failed'),
        t(
          'pages.accounts.import.messages.importError',
          'Failed to import transactions'
        )
      );
    } finally {
      setIsProcessing(false);
    }
  };

  const handleClose = () => {
    setSelectedFile(null);
    setPreviewData([]);
    setParsedData(null);
    setShowColumnMapper(false);
    setIsProcessing(false);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
    onClose();
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();

    const file = e.dataTransfer.files[0];
    if (file) {
      setSelectedFile(file);
      parseFileWithFormat(file);
    }
  };

  return (
    <>
      <Dialog.Root
        open={isOpen}
        onOpenChange={(open) => !open && handleClose()}
      >
        <Dialog.Portal>
          <Dialog.Overlay className="modal-overlay" />
          <Dialog.Content
            className="import-modal__content"
            aria-describedby={undefined}
          >
            <div className="import-modal__header">
              <div>
                <Dialog.Title className="import-modal__title">
                  {t('pages.accounts.import.title', 'Import Transactions')}
                </Dialog.Title>
                <Dialog.Description className="import-modal__subtitle">
                  {t(
                    'pages.accounts.import.subtitle',
                    'Upload CSV, Excel, or PDF file to import transactions for {{accountName}}',
                    { accountName }
                  )}
                </Dialog.Description>
              </div>
              <Dialog.Close asChild>
                <button
                  className="import-modal__close"
                  aria-label={t('pages.accounts.import.closeLabel', 'Close')}
                >
                  <X size={20} />
                </button>
              </Dialog.Close>
            </div>

            <div className="import-modal__body">
              {/* Column Mapper */}
              {showColumnMapper && parsedData && (
                <ColumnMapper
                  csvHeaders={parsedData.headers}
                  sampleData={parsedData.rows.slice(0, 5)}
                  onMappingComplete={handleMappingComplete}
                  onCancel={() => {
                    setShowColumnMapper(false);
                    setSelectedFile(null);
                    setParsedData(null);
                  }}
                />
              )}

              {/* File Upload Zone */}
              {!showColumnMapper && (
                <>
                  <div
                    className="import-modal__upload-zone"
                    onDragOver={handleDragOver}
                    onDrop={handleDrop}
                    onClick={() => fileInputRef.current?.click()}
                  >
                    <Upload size={48} className="import-modal__upload-icon" />
                    <p className="import-modal__upload-text">
                      {selectedFile
                        ? selectedFile.name
                        : t(
                            'pages.accounts.import.upload.dragDrop',
                            'Drag and drop file or click to browse'
                          )}
                    </p>
                    <p className="import-modal__upload-hint">
                      {t(
                        'pages.accounts.import.upload.supported',
                        'Supported: CSV, Excel (.xlsx, .xls), PDF'
                      )}
                    </p>
                    {selectedFile && (
                      <p className="import-modal__file-info">
                        {t(
                          'pages.accounts.import.upload.fileInfo',
                          'Format: {{format}} • Size: {{size}} KB',
                          {
                            format: detectFileFormat(selectedFile).toUpperCase(),
                            size: (selectedFile.size / 1024).toFixed(2),
                          }
                        )}
                      </p>
                    )}
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept=".csv,.xlsx,.xls,.pdf"
                      onChange={handleFileSelect}
                      className="import-modal__file-input"
                      aria-label={t(
                        'pages.accounts.import.upload.uploadLabel',
                        'Upload file'
                      )}
                    />
                  </div>

                  {/* Preview */}
                  {previewData.length > 0 && (
                    <div className="import-modal__preview">
                      <h4 className="import-modal__preview-title">
                        {t(
                          'pages.accounts.import.preview.title',
                          'Preview ({{count}} transactions)',
                          { count: previewData.length }
                        )}
                      </h4>
                      <div className="import-modal__preview-table">
                        <table>
                          <thead>
                            <tr>
                              <th>
                                {t(
                                  'pages.accounts.import.preview.headers.date',
                                  'Date'
                                )}
                              </th>
                              <th>
                                {t(
                                  'pages.accounts.import.preview.headers.description',
                                  'Description'
                                )}
                              </th>
                              <th>
                                {t(
                                  'pages.accounts.import.preview.headers.amount',
                                  'Amount'
                                )}
                              </th>
                              <th>
                                {t(
                                  'pages.accounts.import.preview.headers.type',
                                  'Type'
                                )}
                              </th>
                            </tr>
                          </thead>
                          <tbody>
                            {previewData.slice(0, 5).map((txn, index) => (
                              <tr key={index}>
                                <td>{txn.date}</td>
                                <td>{txn.description}</td>
                                <td>₹{txn.amount.toLocaleString()}</td>
                                <td>
                                  <span
                                    className={`import-modal__type-badge import-modal__type-badge--${txn.type}`}
                                  >
                                    {txn.type}
                                  </span>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                        {previewData.length > 5 && (
                          <p className="import-modal__preview-more">
                            {t(
                              'pages.accounts.import.preview.moreTransactions',
                              'and {{count}} more...',
                              { count: previewData.length - 5 }
                            )}
                          </p>
                        )}
                      </div>
                    </div>
                  )}

                  {/* Sample Format */}
                  <div className="import-modal__sample">
                    <h4 className="import-modal__sample-title">
                      {t(
                        'pages.accounts.import.sample.title',
                        'Sample CSV Format:'
                      )}
                    </h4>
                    <pre className="import-modal__sample-code">
                      {t(
                        'pages.accounts.import.sample.code',
                        'date,description,amount,type,category\n2025-01-15,Salary,50000,income,\n2025-01-16,Grocery Shopping,2500,expense,food\n2025-01-17,Netflix Subscription,499,expense,entertainment'
                      )}
                    </pre>
                  </div>
                </>
              )}
            </div>

            <div className="import-modal__footer">
              <Button
                variant="secondary"
                onClick={handleClose}
                disabled={isProcessing}
              >
                {t('pages.accounts.import.actions.cancel', 'Cancel')}
              </Button>
              <div
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'flex-end',
                  gap: '4px',
                }}
              >
                {!showColumnMapper &&
                  previewData.length === 0 &&
                  selectedFile &&
                  !isProcessing && (
                    <span style={{ fontSize: '0.85em', color: '#ef4444' }}>
                      {t(
                        'pages.accounts.import.messages.mappingRequired',
                        'Complete column mapping to import'
                      )}
                    </span>
                  )}
                <Button
                  variant="primary"
                  onClick={handleImport}
                  disabled={isProcessing || previewData.length === 0}
                  isLoading={isProcessing}
                >
                  {previewData.length > 0
                    ? t(
                        'pages.accounts.import.actions.importCount',
                        'Import {{count}} Transactions',
                        { count: previewData.length }
                      )
                    : t('pages.accounts.import.actions.import', 'Import')}
                </Button>
              </div>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>

      {/* Duplicate Review Modal */}
      {showDuplicateReview && (
        <DuplicateReviewModal
          isOpen={showDuplicateReview}
          onClose={() => {
            setShowDuplicateReview(false);
            setPreviewData([]);
            setDuplicateResults([]);
          }}
          onImport={handleDuplicateReviewImport}
          transactions={previewData}
          duplicateResults={duplicateResults}
          accountName={accountName}
        />
      )}
    </>
  );
}
