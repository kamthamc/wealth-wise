import { useEffect, useRef } from 'react'

type Direction = 'horizontal' | 'vertical' | 'both'

interface UseKeyboardNavigationOptions {
  direction?: Direction
  enabled?: boolean
  loop?: boolean
  onSelect?: (index: number) => void
}

/**
 * Custom hook for keyboard navigation in lists, grids, and menus
 * Handles Arrow keys, Home, End, and Enter/Space for selection
 *
 * @param options - Configuration options for keyboard navigation
 * @returns Object with containerRef and currently focused index
 *
 * @example
 * ```tsx
 * function Menu({ items }: { items: string[] }) {
 *   const { containerRef, focusedIndex } = useKeyboardNavigation({
 *     direction: 'vertical',
 *     onSelect: (index) => console.log('Selected:', items[index])
 *   })
 *
 *   return (
 *     <ul ref={containerRef}>
 *       {items.map((item, i) => (
 *         <li key={i} tabIndex={focusedIndex === i ? 0 : -1}>
 *           {item}
 *         </li>
 *       ))}
 *     </ul>
 *   )
 * }
 * ```
 */
export function useKeyboardNavigation<T extends HTMLElement>({
  direction = 'vertical',
  enabled = true,
  loop = true,
  onSelect,
}: UseKeyboardNavigationOptions = {}) {
  const containerRef = useRef<T>(null)
  const focusedIndexRef = useRef<number>(0)

  useEffect(() => {
    if (!enabled || !containerRef.current) return

    const container = containerRef.current

    const getFocusableChildren = (): HTMLElement[] => {
      const selector = [
        'a[href]',
        'button:not([disabled])',
        '[tabindex]:not([tabindex="-1"])',
        '[role="menuitem"]',
        '[role="option"]',
        '[role="tab"]',
      ].join(',')

      return Array.from(container.querySelectorAll<HTMLElement>(selector))
    }

    const focusElement = (index: number) => {
      const elements = getFocusableChildren()
      if (elements.length === 0) return

      let targetIndex = index

      if (loop) {
        // Loop around if index is out of bounds
        targetIndex = ((index % elements.length) + elements.length) % elements.length
      } else {
        // Clamp to valid range
        targetIndex = Math.max(0, Math.min(index, elements.length - 1))
      }

      focusedIndexRef.current = targetIndex
      elements[targetIndex]?.focus()
    }

    const handleKeyDown = (event: KeyboardEvent) => {
      const elements = getFocusableChildren()
      if (elements.length === 0) return

      const currentIndex = elements.findIndex((el) => el === document.activeElement)
      if (currentIndex === -1) return

      let handled = false
      let newIndex = currentIndex

      switch (event.key) {
        case 'ArrowDown':
          if (direction === 'vertical' || direction === 'both') {
            newIndex = currentIndex + 1
            handled = true
          }
          break

        case 'ArrowUp':
          if (direction === 'vertical' || direction === 'both') {
            newIndex = currentIndex - 1
            handled = true
          }
          break

        case 'ArrowRight':
          if (direction === 'horizontal' || direction === 'both') {
            newIndex = currentIndex + 1
            handled = true
          }
          break

        case 'ArrowLeft':
          if (direction === 'horizontal' || direction === 'both') {
            newIndex = currentIndex - 1
            handled = true
          }
          break

        case 'Home':
          newIndex = 0
          handled = true
          break

        case 'End':
          newIndex = elements.length - 1
          handled = true
          break

        case 'Enter':
        case ' ':
          if (onSelect) {
            event.preventDefault()
            onSelect(currentIndex)
            handled = true
          }
          break
      }

      if (handled) {
        event.preventDefault()
        focusElement(newIndex)
      }
    }

    container.addEventListener('keydown', handleKeyDown)

    return () => {
      container.removeEventListener('keydown', handleKeyDown)
    }
  }, [direction, enabled, loop, onSelect])

  return {
    containerRef,
    focusedIndex: focusedIndexRef.current,
  }
}
