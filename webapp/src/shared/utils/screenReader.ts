/**
 * Screen reader utilities for announcing dynamic content changes
 * Uses ARIA live regions to communicate updates to assistive technologies
 */

type AriaLive = 'polite' | 'assertive'

class ScreenReaderAnnouncer {
  private liveRegion: HTMLDivElement | null = null
  private announcementQueue: Array<{ message: string; priority: AriaLive }> = []
  private isAnnouncing = false

  /**
   * Initialize the live region if it doesn't exist
   */
  private initializeLiveRegion() {
    if (this.liveRegion) return

    // Create container for live regions
    const container = document.createElement('div')
    container.setAttribute('aria-live', 'polite')
    container.setAttribute('aria-atomic', 'true')
    container.setAttribute('role', 'status')
    container.className = 'sr-only'
    container.id = 'screen-reader-announcements'

    document.body.appendChild(container)
    this.liveRegion = container
  }

  /**
   * Announce a message to screen readers
   *
   * @param message - The message to announce
   * @param priority - Priority level ('polite' or 'assertive')
   * @param delay - Optional delay before announcement (in ms)
   *
   * @example
   * ```tsx
   * // Announce success message
   * announce('Transaction saved successfully', 'polite')
   *
   * // Announce error with high priority
   * announce('Error: Invalid amount', 'assertive')
   * ```
   */
  announce(message: string, priority: AriaLive = 'polite', delay = 100) {
    if (!message.trim()) return

    this.initializeLiveRegion()
    this.announcementQueue.push({ message, priority })

    if (!this.isAnnouncing) {
      this.processQueue(delay)
    }
  }

  /**
   * Process the announcement queue
   */
  private processQueue(delay: number) {
    if (this.announcementQueue.length === 0) {
      this.isAnnouncing = false
      return
    }

    this.isAnnouncing = true
    const { message, priority } = this.announcementQueue.shift()!

    if (this.liveRegion) {
      // Update aria-live attribute based on priority
      this.liveRegion.setAttribute('aria-live', priority)

      // Clear existing content first
      this.liveRegion.textContent = ''

      // Add new message after delay
      setTimeout(() => {
        if (this.liveRegion) {
          this.liveRegion.textContent = message
        }

        // Process next message after a short delay
        setTimeout(() => {
          this.processQueue(delay)
        }, delay)
      }, 50)
    }
  }

  /**
   * Clear the live region
   */
  clear() {
    if (this.liveRegion) {
      this.liveRegion.textContent = ''
    }
    this.announcementQueue = []
    this.isAnnouncing = false
  }

  /**
   * Clean up and remove the live region
   */
  destroy() {
    if (this.liveRegion) {
      this.liveRegion.remove()
      this.liveRegion = null
    }
    this.announcementQueue = []
    this.isAnnouncing = false
  }
}

// Singleton instance
const announcer = new ScreenReaderAnnouncer()

/**
 * Announce a message to screen readers
 *
 * @param message - The message to announce
 * @param priority - Priority level ('polite' or 'assertive')
 *
 * @example
 * ```tsx
 * function SaveButton() {
 *   const handleSave = async () => {
 *     await save()
 *     announce('Changes saved successfully')
 *   }
 *
 *   return <button onClick={handleSave}>Save</button>
 * }
 * ```
 */
export function announce(message: string, priority: AriaLive = 'polite') {
  announcer.announce(message, priority)
}

/**
 * Announce an error message with high priority
 *
 * @param message - The error message
 */
export function announceError(message: string) {
  announcer.announce(message, 'assertive')
}

/**
 * Announce a success message
 *
 * @param message - The success message
 */
export function announceSuccess(message: string) {
  announcer.announce(message, 'polite')
}

/**
 * Clear all pending announcements
 */
export function clearAnnouncements() {
  announcer.clear()
}

/**
 * Get a descriptive label for screen readers
 * Useful for complex UI elements that need context
 *
 * @param label - Primary label
 * @param value - Current value
 * @param description - Additional description
 * @returns Formatted accessible label
 *
 * @example
 * ```tsx
 * const label = getAccessibleLabel('Total Balance', '$1,234.56', 'across all accounts')
 * // Returns: "Total Balance: $1,234.56, across all accounts"
 * ```
 */
export function getAccessibleLabel(label: string, value?: string, description?: string): string {
  const parts = [label]

  if (value) {
    parts.push(value)
  }

  if (description) {
    parts.push(description)
  }

  return parts.join(', ')
}

/**
 * Format a number for screen readers
 * Adds context and proper pronunciation
 *
 * @param value - Numeric value
 * @param type - Type of value (currency, percentage, count)
 * @returns Formatted string for screen readers
 *
 * @example
 * ```tsx
 * formatForScreenReader(1234.56, 'currency')
 * // Returns: "1,234 rupees and 56 paise"
 *
 * formatForScreenReader(75, 'percentage')
 * // Returns: "75 percent"
 * ```
 */
export function formatForScreenReader(
  value: number,
  type: 'currency' | 'percentage' | 'count' = 'count'
): string {
  switch (type) {
    case 'currency': {
      const rupees = Math.floor(value)
      const paise = Math.round((value - rupees) * 100)

      if (paise === 0) {
        return `${rupees.toLocaleString('en-IN')} rupees`
      }
      return `${rupees.toLocaleString('en-IN')} rupees and ${paise} paise`
    }

    case 'percentage':
      return `${value} percent`

    case 'count':
    default:
      return value.toLocaleString('en-IN')
  }
}

export default announcer
