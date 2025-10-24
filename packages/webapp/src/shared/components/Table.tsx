/**
 * Table Component
 * Accessible data table with sorting and selection
 */

import type { ReactNode } from 'react';
import './Table.css';

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
  className?: string;
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
  className = '',
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

  const classes = [
    'table-container',
    striped && 'table--striped',
    hoverable && 'table--hoverable',
    compact && 'table--compact',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  if (data.length === 0) {
    return (
      <div className="table-empty">
        <p>{emptyMessage}</p>
      </div>
    );
  }

  return (
    <div className={classes}>
      <table className="table">
        <thead>
          <tr>
            {columns.map((column) => (
              <th
                key={column.key}
                style={{
                  width: column.width,
                  textAlign: column.align || 'left',
                }}
                className={column.sortable ? 'table-header--sortable' : ''}
              >
                {column.sortable ? (
                  <button
                    type="button"
                    className="table-sort-button"
                    onClick={() => handleSort(column.key)}
                    aria-label={`Sort by ${column.header}`}
                  >
                    {column.header}
                    {sortKey === column.key && (
                      <span className="table-sort-icon" aria-hidden="true">
                        {sortDirection === 'asc' ? ' ▲' : ' ▼'}
                      </span>
                    )}
                  </button>
                ) : (
                  column.header
                )}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((row, index) => (
            <tr key={keyExtractor(row, index)}>
              {columns.map((column) => (
                <td
                  key={column.key}
                  style={{ textAlign: column.align || 'left' }}
                  className="table-cell"
                >
                  {column.accessor(row)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
