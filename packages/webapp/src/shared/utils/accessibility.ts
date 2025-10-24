/**
 * General accessibility utilities and helpers
 * WCAG 2.2 AA compliance utilities
 */

/**
 * Generate a unique ID for ARIA labeling
 * Useful for connecting labels to form inputs
 *
 * @param prefix - Prefix for the ID
 * @returns Unique ID string
 *
 * @example
 * ```tsx
 * function FormField() {
 *   const id = useId() // or generateId('field')
 *   return (
 *     <>
 *       <label htmlFor={id}>Name</label>
 *       <input id={id} />
 *     </>
 *   )
 * }
 * ```
 */
export function generateId(prefix = 'id'): string {
  return `${prefix}-${Math.random().toString(36).slice(2, 11)}`;
}

/**
 * Check if reduced motion is preferred
 */
export function prefersReducedMotion(): boolean {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

/**
 * Check if dark mode is preferred
 */
export function prefersDarkMode(): boolean {
  return window.matchMedia('(prefers-color-scheme: dark)').matches;
}

/**
 * Check if high contrast is preferred
 */
export function prefersHighContrast(): boolean {
  return window.matchMedia('(prefers-contrast: high)').matches;
}

/**
 * Calculate contrast ratio between two colors
 * Used for WCAG compliance checking
 *
 * @param color1 - First color in hex format
 * @param color2 - Second color in hex format
 * @returns Contrast ratio (1-21)
 *
 * @example
 * ```tsx
 * const ratio = getContrastRatio('#000000', '#ffffff')
 * console.log(ratio) // 21 (maximum contrast)
 *
 * // Check WCAG AA compliance for normal text (4.5:1)
 * const isCompliant = ratio >= 4.5
 * ```
 */
export function getContrastRatio(color1: string, color2: string): number {
  const luminance1 = getRelativeLuminance(color1);
  const luminance2 = getRelativeLuminance(color2);

  const lighter = Math.max(luminance1, luminance2);
  const darker = Math.min(luminance1, luminance2);

  return (lighter + 0.05) / (darker + 0.05);
}

/**
 * Calculate relative luminance of a color
 * Helper function for contrast ratio calculation
 */
function getRelativeLuminance(color: string): number {
  // Remove # if present
  const hex = color.replace('#', '');

  // Convert to RGB
  const r = Number.parseInt(hex.slice(0, 2), 16) / 255;
  const g = Number.parseInt(hex.slice(2, 4), 16) / 255;
  const b = Number.parseInt(hex.slice(4, 6), 16) / 255;

  // Apply gamma correction
  const rsRGB = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055) ** 2.4;
  const gsRGB = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055) ** 2.4;
  const bsRGB = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055) ** 2.4;

  // Calculate luminance
  return 0.2126 * rsRGB + 0.7152 * gsRGB + 0.0722 * bsRGB;
}

/**
 * Check if contrast ratio meets WCAG standards
 *
 * @param ratio - Contrast ratio to check
 * @param level - WCAG level ('AA' or 'AAA')
 * @param size - Text size ('normal' or 'large')
 * @returns Whether the ratio meets the standard
 */
export function meetsWCAGContrast(
  ratio: number,
  level: 'AA' | 'AAA' = 'AA',
  size: 'normal' | 'large' = 'normal'
): boolean {
  if (level === 'AAA') {
    return size === 'large' ? ratio >= 4.5 : ratio >= 7;
  }
  return size === 'large' ? ratio >= 3 : ratio >= 4.5;
}

/**
 * Format a date for screen readers
 * Provides verbose, unambiguous date format
 *
 * @param date - Date to format
 * @param includeTime - Include time in format
 * @returns Formatted date string
 *
 * @example
 * ```tsx
 * formatDateForScreenReader(new Date('2025-10-13'))
 * // Returns: "October 13, 2025"
 *
 * formatDateForScreenReader(new Date('2025-10-13 14:30'), true)
 * // Returns: "October 13, 2025 at 2:30 PM"
 * ```
 */
export function formatDateForScreenReader(
  date: Date,
  includeTime = false
): string {
  const dateFormatter = new Intl.DateTimeFormat('en-IN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  if (!includeTime) {
    return dateFormatter.format(date);
  }

  const timeFormatter = new Intl.DateTimeFormat('en-IN', {
    hour: 'numeric',
    minute: 'numeric',
    hour12: true,
  });

  return `${dateFormatter.format(date)} at ${timeFormatter.format(date)}`;
}

/**
 * Create ARIA label for a sortable table column
 *
 * @param columnName - Name of the column
 * @param currentSort - Current sort state
 * @returns ARIA label string
 *
 * @example
 * ```tsx
 * getSortAriaLabel('Amount', { column: 'amount', direction: 'desc' })
 * // Returns: "Amount, sorted descending"
 * ```
 */
export function getSortAriaLabel(
  columnName: string,
  currentSort?: { column: string; direction: 'asc' | 'desc' }
): string {
  if (!currentSort) {
    return `${columnName}, not sorted, activate to sort ascending`;
  }

  const direction =
    currentSort.direction === 'asc' ? 'ascending' : 'descending';
  const nextDirection =
    currentSort.direction === 'asc' ? 'descending' : 'ascending';

  return `${columnName}, sorted ${direction}, activate to sort ${nextDirection}`;
}

/**
 * Check if an element is visible to screen readers
 * Considers aria-hidden, display:none, visibility:hidden
 */
export function isVisibleToScreenReader(element: HTMLElement): boolean {
  // Check aria-hidden
  if (element.getAttribute('aria-hidden') === 'true') {
    return false;
  }

  // Check computed styles
  const styles = window.getComputedStyle(element);
  if (styles.display === 'none' || styles.visibility === 'hidden') {
    return false;
  }

  // Check parent elements
  let parent = element.parentElement;
  while (parent) {
    if (parent.getAttribute('aria-hidden') === 'true') {
      return false;
    }
    const parentStyles = window.getComputedStyle(parent);
    if (
      parentStyles.display === 'none' ||
      parentStyles.visibility === 'hidden'
    ) {
      return false;
    }
    parent = parent.parentElement;
  }

  return true;
}

/**
 * Create descriptive text for a progress indicator
 *
 * @param current - Current value
 * @param total - Total value
 * @param label - Label for the progress
 * @returns Descriptive text for screen readers
 *
 * @example
 * ```tsx
 * getProgressDescription(7500, 10000, 'Savings goal')
 * // Returns: "Savings goal: 7,500 rupees of 10,000 rupees, 75% complete"
 * ```
 */
export function getProgressDescription(
  current: number,
  total: number,
  label: string
): string {
  const percentage = Math.round((current / total) * 100);
  const currentFormatted = current.toLocaleString('en-IN');
  const totalFormatted = total.toLocaleString('en-IN');

  return `${label}: ${currentFormatted} rupees of ${totalFormatted} rupees, ${percentage}% complete`;
}

/**
 * Debounce screen reader announcements to prevent spam
 * Returns a debounced version of the announce function
 */
export function debounceAnnounce(
  announceFunction: (message: string) => void,
  delay = 300
): (message: string) => void {
  let timeoutId: number | undefined;

  return (message: string) => {
    if (timeoutId) {
      clearTimeout(timeoutId);
    }

    timeoutId = window.setTimeout(() => {
      announceFunction(message);
    }, delay);
  };
}
