/**
 * Pagination Component
 * Navigate through pages of data
 */

import { Button } from './Button'
import './Pagination.css'

export interface PaginationProps {
  currentPage: number
  totalPages: number
  onPageChange: (page: number) => void
  maxVisible?: number
  showFirstLast?: boolean
  className?: string
}

export function Pagination({
  currentPage,
  totalPages,
  onPageChange,
  maxVisible = 5,
  showFirstLast = true,
  className = '',
}: PaginationProps) {
  if (totalPages <= 1) return null

  const getPageNumbers = (): (number | string)[] => {
    const pages: (number | string)[] = []
    const halfVisible = Math.floor(maxVisible / 2)

    let startPage = Math.max(1, currentPage - halfVisible)
    let endPage = Math.min(totalPages, currentPage + halfVisible)

    // Adjust if we're at the beginning or end
    if (currentPage <= halfVisible) {
      endPage = Math.min(totalPages, maxVisible)
    } else if (currentPage >= totalPages - halfVisible) {
      startPage = Math.max(1, totalPages - maxVisible + 1)
    }

    // Add first page and ellipsis
    if (startPage > 1) {
      pages.push(1)
      if (startPage > 2) {
        pages.push('...')
      }
    }

    // Add page numbers
    for (let i = startPage; i <= endPage; i++) {
      pages.push(i)
    }

    // Add ellipsis and last page
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pages.push('...')
      }
      pages.push(totalPages)
    }

    return pages
  }

  const pageNumbers = getPageNumbers()

  return (
    <nav className={`pagination ${className}`} aria-label="Pagination">
      <div className="pagination__controls">
        {showFirstLast && (
          <Button
            variant="ghost"
            size="small"
            onClick={() => onPageChange(1)}
            disabled={currentPage === 1}
            aria-label="Go to first page"
          >
            ««
          </Button>
        )}

        <Button
          variant="ghost"
          size="small"
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage === 1}
          aria-label="Go to previous page"
        >
          ‹
        </Button>

        <div className="pagination__pages">
          {pageNumbers.map((page) => {
            if (page === '...') {
              return (
                <span key={`ellipsis-${Math.random()}`} className="pagination__ellipsis">
                  ...
                </span>
              )
            }

            const pageNumber = page as number
            const isActive = pageNumber === currentPage

            return (
              <Button
                key={pageNumber}
                variant={isActive ? 'primary' : 'ghost'}
                size="small"
                onClick={() => onPageChange(pageNumber)}
                aria-label={`Go to page ${pageNumber}`}
                aria-current={isActive ? 'page' : undefined}
              >
                {pageNumber}
              </Button>
            )
          })}
        </div>

        <Button
          variant="ghost"
          size="small"
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage === totalPages}
          aria-label="Go to next page"
        >
          ›
        </Button>

        {showFirstLast && (
          <Button
            variant="ghost"
            size="small"
            onClick={() => onPageChange(totalPages)}
            disabled={currentPage === totalPages}
            aria-label="Go to last page"
          >
            »»
          </Button>
        )}
      </div>

      <div className="pagination__info">
        Page {currentPage} of {totalPages}
      </div>
    </nav>
  )
}
