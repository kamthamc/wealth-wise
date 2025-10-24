/**
 * Import Transactions Modal
 * Upload CSV, Excel, or PDF files to import transactions
 */

import * as Dialog from '@radix-ui/react-dialog';
import { Upload, X } from 'lucide-react';
import { useRef, useState } from 'react';
import { batchCheckDuplicates } from '@/core/api';
import type {
  DuplicateCheckResult,
  DuplicateMatch,
} from '@/core/services/duplicateDetectionService';
import { useTransactionStore } from '@/core/stores';
import { Button, useToast } from '@/shared/components';
import {
  detectFileFormat,
  type ParsedData,
  parseFile,
} from '../utils/fileParser';
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
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [previewData, setPreviewData] = useState<ParsedTransaction[]>([]);
  const [showColumnMapper, setShowColumnMapper] = useState(false);
  const [parsedData, setParsedData] = useState<ParsedData | null>(null);

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
        'Unsupported format',
        'Please upload CSV, Excel (.xlsx, .xls), or PDF files'
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
      toast.success('File parsed', `Found ${data.rows.length} rows`);
    } catch (error) {
      console.error('Failed to parse file:', error);
      toast.error(
        'Parse error',
        error instanceof Error ? error.message : 'Failed to parse file'
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
      const batchResult = await batchCheckDuplicates({
        transactions: transactions.map((t) => ({
          date: t.date,
          amount: t.amount,
          description: t.description,
          reference: t.reference,
          type: t.type,
        })),
        accountId,
      });

      // Transform Cloud Function results to match local format
      const results: DuplicateCheckResult[] = batchResult.results.map((r) => {
        const isNewTransaction = !r.result.isDuplicate;
        const duplicateMatches: DuplicateMatch[] = [];

        if (r.result.isDuplicate && r.result.matchedTransactionId) {
          // Create a match object with placeholder transaction
          // In a real scenario, we'd fetch the full transaction details
          duplicateMatches.push({
            existingTransaction: {
              id: r.result.matchedTransactionId,
              date: new Date(r.transaction.date),
              description: r.transaction.description,
              amount: r.transaction.amount,
              type: r.transaction.type,
              accountId,
              category: r.transaction.category || 'Uncategorized',
            } as any, // Using 'as any' since we don't have full transaction details
            confidence:
              r.result.confidence >= 90
                ? 'exact'
                : r.result.confidence >= 70
                  ? 'high'
                  : 'possible',
            matchReasons: r.result.reason
              ? [r.result.reason]
              : ['Potential duplicate detected'],
            score: r.result.confidence,
          });
        }

        return {
          isNewTransaction,
          duplicateMatches,
          bestMatch:
            duplicateMatches.length > 0 ? duplicateMatches[0] : undefined,
        };
      });

      setDuplicateResults(results);
      setPreviewData(transactions);

      // Show duplicate review modal
      setShowDuplicateReview(true);

      const newCount = results.filter((r) => r.isNewTransaction).length;
      const dupCount = results.filter((r) => !r.isNewTransaction).length;

      toast.success(
        'Duplicate detection complete',
        `Found ${newCount} new and ${dupCount} potential duplicate transactions`
      );
    } catch (error) {
      console.error('Duplicate detection failed:', error);
      toast.error('Detection failed', 'Could not check for duplicates');
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
          date: new Date(item.transaction.date),
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
          if (item.action === 'update' && item.duplicateResult.bestMatch) {
            // Update existing transaction
            await updateTransaction({
              id: item.duplicateResult.bestMatch.existingTransaction.id,
              ...transactionData,
            });
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
        'Import complete',
        `Imported ${successCount} transactions${failCount > 0 ? `, ${failCount} failed` : ''}`
      );

      // Call success callback to refresh transactions
      if (onImportSuccess) {
        onImportSuccess();
      }

      handleClose();
    } catch (error) {
      console.error('Import error:', error);
      toast.error('Import failed', 'Failed to import transactions');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleImport = async () => {
    if (previewData.length === 0) {
      toast.error('No data', 'No valid transactions to import');
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
            date: new Date(transaction.date),
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
        'Import complete',
        `Imported ${successCount} transactions${failCount > 0 ? `, ${failCount} failed` : ''}`
      );

      // Call success callback to refresh transactions
      if (onImportSuccess) {
        onImportSuccess();
      }

      handleClose();
    } catch (error) {
      console.error('Import error:', error);
      toast.error('Import failed', 'Failed to import transactions');
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
                  Import Transactions
                </Dialog.Title>
                <Dialog.Description className="import-modal__subtitle">
                  Upload CSV, Excel, or PDF file to import transactions for{' '}
                  {accountName}
                </Dialog.Description>
              </div>
              <Dialog.Close asChild>
                <button className="import-modal__close" aria-label="Close">
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
                        : 'Drag and drop file or click to browse'}
                    </p>
                    <p className="import-modal__upload-hint">
                      Supported: CSV, Excel (.xlsx, .xls), PDF
                    </p>
                    {selectedFile && (
                      <p className="import-modal__file-info">
                        Format: {detectFileFormat(selectedFile).toUpperCase()} •
                        Size: {(selectedFile.size / 1024).toFixed(2)} KB
                      </p>
                    )}
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept=".csv,.xlsx,.xls,.pdf"
                      onChange={handleFileSelect}
                      className="import-modal__file-input"
                      aria-label="Upload file"
                    />
                  </div>

                  {/* Preview */}
                  {previewData.length > 0 && (
                    <div className="import-modal__preview">
                      <h4 className="import-modal__preview-title">
                        Preview ({previewData.length} transactions)
                      </h4>
                      <div className="import-modal__preview-table">
                        <table>
                          <thead>
                            <tr>
                              <th>Date</th>
                              <th>Description</th>
                              <th>Amount</th>
                              <th>Type</th>
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
                            and {previewData.length - 5} more...
                          </p>
                        )}
                      </div>
                    </div>
                  )}

                  {/* Sample Format */}
                  <div className="import-modal__sample">
                    <h4 className="import-modal__sample-title">
                      Sample CSV Format:
                    </h4>
                    <pre className="import-modal__sample-code">
                      {`date,description,amount,type,category
2025-01-15,Salary,50000,income,
2025-01-16,Grocery Shopping,2500,expense,food
2025-01-17,Netflix Subscription,499,expense,entertainment`}
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
                Cancel
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
                      Complete column mapping to import
                    </span>
                  )}
                <Button
                  variant="primary"
                  onClick={handleImport}
                  disabled={isProcessing || previewData.length === 0}
                  isLoading={isProcessing}
                >
                  Import{' '}
                  {previewData.length > 0 &&
                    `${previewData.length} Transactions`}
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
