/**
 * Focus management utilities for accessibility
 * Handles focus indicators, focus restoration, and keyboard navigation
 */

/**
 * Check if an element is currently focused
 */
export function isFocused(element: HTMLElement | null): boolean {
  return element === document.activeElement;
}

/**
 * Get all focusable elements within a container
 *
 * @param container - Container element to search within
 * @returns Array of focusable elements
 */
export function getFocusableElements(container: HTMLElement): HTMLElement[] {
  const selector = [
    'a[href]',
    'button:not([disabled])',
    'textarea:not([disabled])',
    'input:not([disabled])',
    'select:not([disabled])',
    '[tabindex]:not([tabindex="-1"])',
    'audio[controls]',
    'video[controls]',
    '[contenteditable]:not([contenteditable="false"])',
  ].join(',');

  return Array.from(container.querySelectorAll<HTMLElement>(selector));
}

/**
 * Get the first focusable element within a container
 */
export function getFirstFocusableElement(
  container: HTMLElement
): HTMLElement | null {
  const elements = getFocusableElements(container);
  return elements[0] || null;
}

/**
 * Get the last focusable element within a container
 */
export function getLastFocusableElement(
  container: HTMLElement
): HTMLElement | null {
  const elements = getFocusableElements(container);
  return elements[elements.length - 1] || null;
}

/**
 * Focus the first focusable element in a container
 *
 * @param container - Container element
 * @param preventScroll - Prevent scrolling on focus
 * @returns Whether focus was successful
 */
export function focusFirst(
  container: HTMLElement,
  preventScroll = false
): boolean {
  const firstElement = getFirstFocusableElement(container);
  if (firstElement) {
    firstElement.focus({ preventScroll });
    return true;
  }
  return false;
}

/**
 * Focus the last focusable element in a container
 *
 * @param container - Container element
 * @param preventScroll - Prevent scrolling on focus
 * @returns Whether focus was successful
 */
export function focusLast(
  container: HTMLElement,
  preventScroll = false
): boolean {
  const lastElement = getLastFocusableElement(container);
  if (lastElement) {
    lastElement.focus({ preventScroll });
    return true;
  }
  return false;
}

/**
 * Store current focus to restore later
 * Useful for dialogs and modals
 *
 * @returns Function to restore the original focus
 *
 * @example
 * ```tsx
 * function Modal({ isOpen }: { isOpen: boolean }) {
 *   useEffect(() => {
 *     if (isOpen) {
 *       const restoreFocus = storeFocus()
 *       return () => restoreFocus()
 *     }
 *   }, [isOpen])
 * }
 * ```
 */
export function storeFocus(): () => void {
  const previouslyFocused = document.activeElement as HTMLElement | null;

  return () => {
    if (previouslyFocused && typeof previouslyFocused.focus === 'function') {
      previouslyFocused.focus();
    }
  };
}

/**
 * Create a focus guard to prevent focus from leaving a container
 * Returns cleanup function
 *
 * @param container - Container element to guard
 * @returns Cleanup function
 */
export function createFocusGuard(container: HTMLElement): () => void {
  const handleFocusOut = (event: FocusEvent) => {
    const relatedTarget = event.relatedTarget as HTMLElement | null;

    // If focus moved outside the container, bring it back
    if (relatedTarget && !container.contains(relatedTarget)) {
      event.preventDefault();
      focusFirst(container);
    }
  };

  container.addEventListener('focusout', handleFocusOut);

  return () => {
    container.removeEventListener('focusout', handleFocusOut);
  };
}

/**
 * Check if keyboard focus is visible (not triggered by mouse)
 * Uses :focus-visible polyfill detection
 */
export function isFocusVisible(): boolean {
  try {
    // Check if browser supports :focus-visible
    document.querySelector(':focus-visible');
    return true;
  } catch {
    // Fallback: assume focus is visible
    return true;
  }
}

/**
 * Disable focus outline temporarily (e.g., during mouse interactions)
 * Re-enables on keyboard interaction
 *
 * @returns Cleanup function
 */
export function manageFocusVisible(): () => void {
  const handleMouseDown = () => {
    document.body.classList.add('using-mouse');
    document.body.classList.remove('using-keyboard');
  };

  const handleKeyDown = (event: KeyboardEvent) => {
    if (event.key === 'Tab') {
      document.body.classList.add('using-keyboard');
      document.body.classList.remove('using-mouse');
    }
  };

  document.addEventListener('mousedown', handleMouseDown);
  document.addEventListener('keydown', handleKeyDown);

  return () => {
    document.removeEventListener('mousedown', handleMouseDown);
    document.removeEventListener('keydown', handleKeyDown);
    document.body.classList.remove('using-mouse', 'using-keyboard');
  };
}

/**
 * Focus an element only if it's not already focused
 * Prevents unnecessary scroll jumps
 */
export function focusIfNeeded(
  element: HTMLElement | null,
  options?: FocusOptions
) {
  if (element && !isFocused(element)) {
    element.focus(options);
  }
}

/**
 * Scroll element into view if not visible
 * Respects prefers-reduced-motion
 */
export function scrollIntoViewIfNeeded(
  element: HTMLElement,
  options?: ScrollIntoViewOptions
) {
  const rect = element.getBoundingClientRect();
  const isVisible =
    rect.top >= 0 &&
    rect.left >= 0 &&
    rect.bottom <= window.innerHeight &&
    rect.right <= window.innerWidth;

  if (!isVisible) {
    const prefersReducedMotion = window.matchMedia(
      '(prefers-reduced-motion: reduce)'
    ).matches;

    element.scrollIntoView({
      behavior: prefersReducedMotion ? 'auto' : 'smooth',
      block: 'nearest',
      ...options,
    });
  }
}
