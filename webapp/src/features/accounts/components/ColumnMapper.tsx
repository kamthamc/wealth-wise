import * as Select from '@radix-ui/react-select';
import { AlertCircle, Check, ChevronDown } from 'lucide-react';
import { useEffect, useState } from 'react';
import './ColumnMapper.css';

interface ColumnMapping {
  csvColumn: string;
  systemField:
    | 'date'
    | 'description'
    | 'amount'
    | 'amount_debit'
    | 'amount_credit'
    | 'type'
    | 'category'
    | 'skip';
  valueMapping?: Record<string, string>; // For mapping credit/debit to income/expense
}

interface ColumnMapperProps {
  csvHeaders: string[];
  sampleData: Record<string, string>[];
  onMappingComplete: (mapping: ColumnMapping[]) => void;
  onCancel: () => void;
}

const SYSTEM_FIELDS = [
  { value: 'date', label: 'Date', required: true },
  { value: 'description', label: 'Description', required: true },
  { value: 'amount', label: 'Amount', required: true },
  {
    value: 'amount_debit',
    label: 'Amount (Debit/Withdrawal)',
    required: false,
  },
  { value: 'amount_credit', label: 'Amount (Credit/Deposit)', required: false },
  { value: 'type', label: 'Type (Income/Expense)', required: false }, // Made optional
  { value: 'category', label: 'Category', required: false },
  { value: 'skip', label: 'Skip this column', required: false },
] as const;

// Common transaction type mappings
const TYPE_MAPPINGS = {
  // Credit/Debit mapping
  credit: 'income',
  debit: 'expense',
  cr: 'income',
  dr: 'expense',
  'credit card': 'expense',
  deposit: 'income',
  withdrawal: 'expense',
  // Common variations
  income: 'income',
  expense: 'expense',
  spending: 'expense',
  earning: 'income',
  payment: 'expense',
  receipt: 'income',
  refund: 'income',
  charge: 'expense',
};

export function ColumnMapper({
  csvHeaders,
  sampleData,
  onMappingComplete,
  onCancel,
}: ColumnMapperProps) {
  const [mappings, setMappings] = useState<ColumnMapping[]>([]);
  const [valueMappings, setValueMappings] = useState<
    Record<string, Record<string, string>>
  >({});
  const [autoDetected, setAutoDetected] = useState(false);

  useEffect(() => {
    // Auto-detect columns based on common patterns
    const detected = csvHeaders.map((header) => {
      const lowerHeader = header.toLowerCase().trim();

      let systemField: ColumnMapping['systemField'] = 'skip';

      // Date detection
      if (
        lowerHeader.includes('date') ||
        lowerHeader.includes('txn') ||
        lowerHeader === 'dt'
      ) {
        systemField = 'date';
      }
      // Description detection
      else if (
        lowerHeader.includes('description') ||
        lowerHeader.includes('narration') ||
        lowerHeader.includes('particulars') ||
        lowerHeader.includes('details') ||
        lowerHeader.includes('remarks')
      ) {
        systemField = 'description';
      }
      // Debit/Withdrawal amount detection (HDFC, ICICI format)
      else if (
        lowerHeader.includes('withdrawal') ||
        lowerHeader.includes('debit amt') ||
        (lowerHeader.includes('debit') && lowerHeader.includes('amt'))
      ) {
        systemField = 'amount_debit';
      }
      // Credit/Deposit amount detection (HDFC, ICICI format)
      else if (
        lowerHeader.includes('deposit') ||
        lowerHeader.includes('credit amt') ||
        (lowerHeader.includes('credit') && lowerHeader.includes('amt'))
      ) {
        systemField = 'amount_credit';
      }
      // General amount detection
      else if (
        lowerHeader.includes('amount') ||
        lowerHeader.includes('amt') ||
        lowerHeader === 'value'
      ) {
        systemField = 'amount';
      }
      // Type detection
      else if (
        lowerHeader.includes('type') ||
        lowerHeader.includes('transaction type') ||
        lowerHeader === 'cr/dr'
      ) {
        systemField = 'type';
      }
      // Category detection
      else if (
        lowerHeader.includes('category') ||
        lowerHeader.includes('tag')
      ) {
        systemField = 'category';
      }

      return {
        csvColumn: header,
        systemField,
      };
    });

    setMappings(detected);
    setAutoDetected(true);

    // Auto-detect type mappings from sample data
    const typeMapping: Record<string, string> = {};
    const typeColumn = detected.find(
      (m) => m.systemField === 'type'
    )?.csvColumn;

    if (typeColumn && sampleData.length > 0) {
      const uniqueValues = new Set<string>();
      sampleData.forEach((row) => {
        const value = row[typeColumn]?.toLowerCase().trim();
        if (value) uniqueValues.add(value);
      });

      uniqueValues.forEach((value) => {
        // Try to map using common patterns
        if (TYPE_MAPPINGS[value as keyof typeof TYPE_MAPPINGS]) {
          typeMapping[value] =
            TYPE_MAPPINGS[value as keyof typeof TYPE_MAPPINGS];
        }
      });

      if (Object.keys(typeMapping).length > 0) {
        setValueMappings({ [typeColumn]: typeMapping });
      }
    }
  }, [csvHeaders, sampleData]);

  const updateMapping = (
    csvColumn: string,
    systemField: ColumnMapping['systemField']
  ) => {
    setMappings((prev) =>
      prev.map((m) => (m.csvColumn === csvColumn ? { ...m, systemField } : m))
    );
  };

  const updateValueMapping = (
    csvColumn: string,
    csvValue: string,
    systemValue: string
  ) => {
    setValueMappings((prev) => ({
      ...prev,
      [csvColumn]: {
        ...prev[csvColumn],
        [csvValue]: systemValue,
      },
    }));
  };

  const getUniqueValues = (column: string): string[] => {
    const values = new Set<string>();
    sampleData.forEach((row) => {
      const value = row[column]?.trim();
      if (value) values.add(value);
    });
    return Array.from(values);
  };

  const handleComplete = () => {
    const finalMappings = mappings.map((m) => ({
      ...m,
      valueMapping: valueMappings[m.csvColumn],
    }));
    onMappingComplete(finalMappings);
  };

  // Get mapped fields first
  const mappedFields = mappings
    .map((m) => m.systemField)
    .filter((f) => f !== 'skip');

  // Check if we have separate debit/credit columns (HDFC format)
  const hasSeparateAmountColumns =
    mappedFields.includes('amount_debit') &&
    mappedFields.includes('amount_credit');

  // Build required fields list
  let effectiveRequiredFields = SYSTEM_FIELDS.filter((f) => f.required).map(
    (f) => f.value
  );

  // If we have separate debit/credit columns, we don't need 'type' column
  // and we don't need general 'amount' column
  if (hasSeparateAmountColumns) {
    effectiveRequiredFields = effectiveRequiredFields.filter(
      (f) => f !== 'amount'
    );
    // Add amount_debit and amount_credit as required
    if (!effectiveRequiredFields.includes('amount_debit' as any)) {
      effectiveRequiredFields.push('amount_debit' as any);
    }
    if (!effectiveRequiredFields.includes('amount_credit' as any)) {
      effectiveRequiredFields.push('amount_credit' as any);
    }
  }

  const missingRequired = effectiveRequiredFields.filter(
    (f) => !mappedFields.includes(f)
  );
  const canComplete = missingRequired.length === 0;

  const typeColumn = mappings.find((m) => m.systemField === 'type')?.csvColumn;
  const typeValues = typeColumn ? getUniqueValues(typeColumn) : [];
  const needsTypeMapping =
    typeValues.length > 0 &&
    typeValues.some((v) => {
      const lower = v.toLowerCase();
      return lower !== 'income' && lower !== 'expense' && lower !== 'transfer';
    });

  return (
    <div className="column-mapper">
      <div className="column-mapper-header">
        <h3>Map Your Columns</h3>
        <p>
          {autoDetected && (
            <span className="auto-detected">
              <Check size={16} /> Columns auto-detected
            </span>
          )}{' '}
          Match your CSV columns to system fields
        </p>
      </div>

      {missingRequired.length > 0 && (
        <div className="mapping-warning">
          <AlertCircle size={16} />
          <div>
            <strong>Missing required fields:</strong>
            <div style={{ marginTop: '4px' }}>
              {missingRequired.map((field) => {
                const fieldLabel =
                  SYSTEM_FIELDS.find((f) => f.value === field)?.label || field;
                return <div key={field}>• {fieldLabel}</div>;
              })}
            </div>
            <div style={{ marginTop: '8px', fontSize: '0.9em', opacity: 0.9 }}>
              {hasSeparateAmountColumns
                ? 'Tip: Using separate debit/credit columns. No "Type" field needed.'
                : 'Tip: Map your CSV columns to the required fields above to continue.'}
            </div>
          </div>
        </div>
      )}

      {hasSeparateAmountColumns && missingRequired.length === 0 && (
        <div
          className="mapping-info"
          style={{
            padding: '12px',
            background: '#e3f2fd',
            border: '1px solid #90caf9',
            borderRadius: '8px',
            marginBottom: '16px',
            display: 'flex',
            gap: '8px',
            color: '#1565c0',
          }}
        >
          <Check size={16} style={{ flexShrink: 0, marginTop: '2px' }} />
          <span>
            <strong>Separate debit/credit columns detected.</strong> Transaction
            types will be automatically assigned based on which column has a
            value.
          </span>
        </div>
      )}

      <div className="mapping-grid">
        <div className="mapping-header">
          <span>Your CSV Column</span>
          <span>Maps To</span>
          <span>Sample Data</span>
        </div>

        {mappings.map((mapping) => (
          <div key={mapping.csvColumn} className="mapping-row">
            <div className="csv-column">
              <strong>{mapping.csvColumn}</strong>
            </div>

            <div className="system-field">
              <Select.Root
                value={mapping.systemField}
                onValueChange={(value) =>
                  updateMapping(
                    mapping.csvColumn,
                    value as ColumnMapping['systemField']
                  )
                }
              >
                <Select.Trigger className="select-trigger">
                  <Select.Value />
                  <Select.Icon>
                    <ChevronDown size={16} />
                  </Select.Icon>
                </Select.Trigger>

                <Select.Portal>
                  <Select.Content className="select-content">
                    <Select.Viewport>
                      {SYSTEM_FIELDS.map((field) => (
                        <Select.Item
                          key={field.value}
                          value={field.value}
                          className="select-item"
                        >
                          <Select.ItemText>
                            {field.label}
                            {field.required && (
                              <span className="required-badge">Required</span>
                            )}
                          </Select.ItemText>
                          <Select.ItemIndicator className="select-indicator">
                            <Check size={16} />
                          </Select.ItemIndicator>
                        </Select.Item>
                      ))}
                    </Select.Viewport>
                  </Select.Content>
                </Select.Portal>
              </Select.Root>
            </div>

            <div className="sample-preview">
              {sampleData[0] && sampleData[0][mapping.csvColumn] ? (
                <code>{sampleData[0][mapping.csvColumn]}</code>
              ) : (
                <span className="no-data">—</span>
              )}
            </div>
          </div>
        ))}
      </div>

      {needsTypeMapping && typeColumn && (
        <div className="value-mapping-section">
          <h4>Map Transaction Types</h4>
          <p>Your CSV uses different values. Map them to our system:</p>

          <div className="value-mapping-grid">
            {typeValues.map((csvValue) => {
              const lower = csvValue.toLowerCase();
              const isStandard =
                lower === 'income' ||
                lower === 'expense' ||
                lower === 'transfer';
              const currentMapping =
                valueMappings[typeColumn]?.[csvValue] ||
                (isStandard ? lower : '');

              return (
                <div key={csvValue} className="value-mapping-row">
                  <div className="csv-value">
                    <code>{csvValue}</code>
                  </div>
                  <span>→</span>
                  <div className="system-value">
                    <Select.Root
                      value={currentMapping}
                      onValueChange={(value) =>
                        updateValueMapping(typeColumn, csvValue, value)
                      }
                    >
                      <Select.Trigger className="select-trigger small">
                        <Select.Value placeholder="Select..." />
                        <ChevronDown size={14} />
                      </Select.Trigger>

                      <Select.Portal>
                        <Select.Content className="select-content">
                          <Select.Viewport>
                            <Select.Item value="income" className="select-item">
                              <Select.ItemText>Income</Select.ItemText>
                              <Select.ItemIndicator>
                                <Check size={14} />
                              </Select.ItemIndicator>
                            </Select.Item>
                            <Select.Item
                              value="expense"
                              className="select-item"
                            >
                              <Select.ItemText>Expense</Select.ItemText>
                              <Select.ItemIndicator>
                                <Check size={14} />
                              </Select.ItemIndicator>
                            </Select.Item>
                            <Select.Item
                              value="transfer"
                              className="select-item"
                            >
                              <Select.ItemText>Transfer</Select.ItemText>
                              <Select.ItemIndicator>
                                <Check size={14} />
                              </Select.ItemIndicator>
                            </Select.Item>
                          </Select.Viewport>
                        </Select.Content>
                      </Select.Portal>
                    </Select.Root>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      <div className="column-mapper-actions">
        <button type="button" onClick={onCancel} className="btn-secondary">
          Cancel
        </button>
        <button
          type="button"
          onClick={handleComplete}
          className="btn-primary"
          disabled={!canComplete}
        >
          Continue with Mapping
        </button>
      </div>
    </div>
  );
}
