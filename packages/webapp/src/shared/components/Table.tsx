/**
 * Table Component
 * Accessible data table with sorting and selection using Radix UI
 */

import type { ReactNode } from 'react';
import { Table as RadixTable } from '@radix-ui/themes';

export interface TableColumn<T> {
  key: string;
  header: string;
  accessor: (row: T) => ReactNode;
  sortable?: boolean;
  align?: 'left' | 'center' | 'right';
  width?: string;
}

export interface TableProps<T> {
  columns: TableColumn<T>[];
  data: T[];
  keyExtractor: (row: T, index: number) => string;
  onSort?: (key: string, direction: 'asc' | 'desc') => void;
  sortKey?: string;
  sortDirection?: 'asc' | 'desc';
  emptyMessage?: string;
  striped?: boolean;
  hoverable?: boolean;
  compact?: boolean;
}

export function Table<T>({
  columns,
  data,
  keyExtractor,
  onSort,
  sortKey,
  sortDirection,
  emptyMessage = 'No data available',
  striped = false,
  hoverable = true,
  compact = false,
}: TableProps<T>) {
  const handleSort = (key: string) => {
    if (!onSort) return;

    const newDirection =
      sortKey === key && sortDirection === 'asc' ? 'desc' : 'asc';
    onSort(key, newDirection);
  };

  if (data.length === 0) {
    return (
      <div
        style={{
          padding: 'var(--space-4)',
          textAlign: 'center',
          color: 'var(--color-text-tertiary)',
        }}
      >
        <p>{emptyMessage}</p>
      </div>
    );
  }

  return (
    <RadixTable.Root
      size={compact ? '1' : '2'}
      variant={striped ? 'surface' : 'ghost'}
    >
      <RadixTable.Header>
        <RadixTable.Row>
          {columns.map((column) => (
            <RadixTable.ColumnHeaderCell
              key={column.key}
              style={{
                width: column.width,
                textAlign: column.align || 'left',
              }}
            >
              {column.sortable ? (
                <button
                  type="button"
                  onClick={() => handleSort(column.key)}
                  style={{
                    background: 'none',
                    border: 'none',
                    cursor: 'pointer',
                    font: 'inherit',
                    color: 'inherit',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 'var(--space-1)',
                    width: '100%',
                    justifyContent:
                      column.align === 'right'
                        ? 'flex-end'
                        : column.align === 'center'
                        ? 'center'
                        : 'flex-start',
                  }}
                  aria-label={`Sort by ${column.header}`}
                >
                  {column.header}
                  {sortKey === column.key && (
                    <span aria-hidden="true">
                      {sortDirection === 'asc' ? ' ▲' : ' ▼'}
                    </span>
                  )}
                </button>
              ) : (
                column.header
              )}
            </RadixTable.ColumnHeaderCell>
          ))}
        </RadixTable.Row>
      </RadixTable.Header>

      <RadixTable.Body>
        {data.map((row, index) => (
          <RadixTable.Row
            key={keyExtractor(row, index)}
            style={hoverable ? { cursor: 'pointer' } : undefined}
          >
            {columns.map((column) => (
              <RadixTable.Cell
                key={column.key}
                style={{ textAlign: column.align || 'left' }}
              >
                {column.accessor(row)}
              </RadixTable.Cell>
            ))}
          </RadixTable.Row>
        ))}
      </RadixTable.Body>
    </RadixTable.Root>
  );
}
