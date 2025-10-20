/**
 * Import Transactions Modal
 * Upload CSV, Excel, or PDF files to import transactions
 */

import * as Dialog from '@radix-ui/react-dialog';
import { Upload, X } from 'lucide-react';
import { useRef, useState } from 'react';
import { useTransactionStore } from '@/core/stores';
import { Button, useToast } from '@/shared/components';
import { detectFileFormat, parseFile, type ParsedData } from '../utils/fileParser';
import { ColumnMapper } from './ColumnMapper';
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
  const { createTransaction } = useTransactionStore();
  const toast = useToast();

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const format = detectFileFormat(file);
    if (format === 'unknown') {
      toast.error('Unsupported format', 'Please upload CSV, Excel (.xlsx, .xls), or PDF files');
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
      toast.error('Parse error', error instanceof Error ? error.message : 'Failed to parse file');
      setSelectedFile(null);
      setParsedData(null);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleMappingComplete = (mappings: any[]) => {
    setShowColumnMapper(false);
    
    if (!parsedData) return;
    
    // Check if using separate debit/credit columns (HDFC format)
    const hasDebitColumn = mappings.some(m => m.systemField === 'amount_debit');
    const hasCreditColumn = mappings.some(m => m.systemField === 'amount_credit');
    const hasSeparateColumns = hasDebitColumn && hasCreditColumn;
    
    // Apply mappings to transform data
    const transactions = parsedData.rows.map(row => {
      const txn: any = {};
      
      mappings.forEach(mapping => {
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
        type = (txn.type?.toLowerCase() || 'expense') as 'income' | 'expense' | 'transfer';
      }
      
      return {
        date: txn.date || '',
        description: txn.description || '',
        amount,
        type,
        category: txn.category || undefined,
      } as ParsedTransaction;
    }).filter(t => t.date && t.description && !isNaN(t.amount) && t.amount > 0);
    
    setPreviewData(transactions);
    
    // Show detailed feedback
    if (transactions.length === 0) {
      toast.error(
        'No valid transactions found',
        'All rows were filtered out. Check that your data has valid dates, descriptions, and amounts.'
      );
    } else if (transactions.length < parsedData.rows.length) {
      const filtered = parsedData.rows.length - transactions.length;
      toast.warning(
        'Mapping complete',
        `${transactions.length} valid transactions found. ${filtered} rows were filtered out (missing data or invalid amounts).`
      );
    } else {
      toast.success('Mapping complete', `${transactions.length} valid transactions ready to import`);
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
    <Dialog.Root open={isOpen} onOpenChange={(open) => !open && handleClose()}>
      <Dialog.Portal>
        <Dialog.Overlay className="modal-overlay" />
        <Dialog.Content className="import-modal__content" aria-describedby={undefined}>
          <div className="import-modal__header">
            <div>
              <Dialog.Title className="import-modal__title">
                Import Transactions
              </Dialog.Title>
              <Dialog.Description className="import-modal__subtitle">
                Upload CSV, Excel, or PDF file to import transactions for {accountName}
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
                    {selectedFile ? selectedFile.name : 'Drag and drop file or click to browse'}
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
                                <span className={`import-modal__type-badge import-modal__type-badge--${txn.type}`}>
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
                  <h4 className="import-modal__sample-title">Sample CSV Format:</h4>
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
            <Button variant="secondary" onClick={handleClose} disabled={isProcessing}>
              Cancel
            </Button>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '4px' }}>
              {!showColumnMapper && previewData.length === 0 && selectedFile && !isProcessing && (
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
                Import {previewData.length > 0 && `${previewData.length} Transactions`}
              </Button>
            </div>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
