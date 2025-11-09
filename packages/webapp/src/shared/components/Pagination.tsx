/**
 * Pagination Component
 * Navigate through pages of data using Radix UI components
 */

import { Button } from './Button';

export interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  maxVisible?: number;
  showFirstLast?: boolean;
}

export function Pagination({
  currentPage,
  totalPages,
  onPageChange,
  maxVisible = 5,
  showFirstLast = true,
}: PaginationProps) {
  if (totalPages <= 1) return null;

  const getPageNumbers = (): (number | string)[] => {
    const pages: (number | string)[] = [];
    const halfVisible = Math.floor(maxVisible / 2);

    let startPage = Math.max(1, currentPage - halfVisible);
    let endPage = Math.min(totalPages, currentPage + halfVisible);

    // Adjust if we're at the beginning or end
    if (currentPage <= halfVisible) {
      endPage = Math.min(totalPages, maxVisible);
    } else if (currentPage >= totalPages - halfVisible) {
      startPage = Math.max(1, totalPages - maxVisible + 1);
    }

    // Add first page and ellipsis
    if (startPage > 1) {
      pages.push(1);
      if (startPage > 2) {
        pages.push('...');
      }
    }

    // Add page numbers
    for (let i = startPage; i <= endPage; i++) {
      pages.push(i);
    }

    // Add ellipsis and last page
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pages.push('...');
      }
      pages.push(totalPages);
    }

    return pages;
  };

  const pageNumbers = getPageNumbers();

  return (
    <nav aria-label="Pagination">
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 'var(--space-1)',
          flexWrap: 'wrap',
        }}
      >
        {showFirstLast && (
          <Button
            variant="ghost"
            size="small"
            onClick={() => onPageChange(1)}
            disabled={currentPage === 1}
          >
            ««
          </Button>
        )}

        <Button
          variant="ghost"
          size="small"
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage === 1}
        >
          ‹
        </Button>

        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 'var(--space-1)',
          }}
        >
          {pageNumbers.map((page) => {
            if (page === '...') {
              return (
                <span
                  key={`ellipsis-${Math.random()}`}
                  style={{
                    padding: 'var(--space-1) var(--space-2)',
                    color: 'var(--color-text-tertiary)',
                  }}
                >
                  ...
                </span>
              );
            }

            const pageNumber = page as number;
            const isActive = pageNumber === currentPage;

            return (
              <Button
                key={pageNumber}
                variant={isActive ? 'primary' : 'ghost'}
                size="small"
                onClick={() => onPageChange(pageNumber)}
              >
                {pageNumber}
              </Button>
            );
          })}
        </div>

        <Button
          variant="ghost"
          size="small"
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage === totalPages}
        >
          ›
        </Button>

        {showFirstLast && (
          <Button
            variant="ghost"
            size="small"
            onClick={() => onPageChange(totalPages)}
            disabled={currentPage === totalPages}
          >
            »»
          </Button>
        )}
      </div>

      <div
        style={{
          textAlign: 'center',
          marginTop: 'var(--space-2)',
          fontSize: 'var(--font-size-1)',
          color: 'var(--color-text-secondary)',
        }}
      >
        Page {currentPage} of {totalPages}
      </div>
    </nav>
  );
}
