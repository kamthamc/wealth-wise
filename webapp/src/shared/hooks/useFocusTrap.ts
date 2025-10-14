import { useEffect, useRef } from 'react';

interface UseFocusTrapOptions {
  enabled?: boolean;
  initialFocus?: boolean;
  returnFocus?: boolean;
}

/**
 * Custom hook to trap focus within a container element
 * Useful for modals, dialogs, and other overlay components
 *
 * @param options - Configuration options for focus trap
 * @returns Ref to attach to the container element
 *
 * @example
 * ```tsx
 * function Modal({ isOpen }: { isOpen: boolean }) {
 *   const trapRef = useFocusTrap({ enabled: isOpen })
 *   return <div ref={trapRef}>...</div>
 * }
 * ```
 */
export function useFocusTrap<T extends HTMLElement>({
  enabled = true,
  initialFocus = true,
  returnFocus = true,
}: UseFocusTrapOptions = {}) {
  const containerRef = useRef<T>(null);
  const previouslyFocusedElement = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (!enabled || !containerRef.current) return;

    const container = containerRef.current;

    // Store the currently focused element to return focus later
    previouslyFocusedElement.current = document.activeElement as HTMLElement;

    // Get all focusable elements
    const getFocusableElements = (): HTMLElement[] => {
      const selector = [
        'a[href]',
        'button:not([disabled])',
        'textarea:not([disabled])',
        'input:not([disabled])',
        'select:not([disabled])',
        '[tabindex]:not([tabindex="-1"])',
      ].join(',');

      return Array.from(container.querySelectorAll<HTMLElement>(selector));
    };

    // Set initial focus
    if (initialFocus) {
      const focusableElements = getFocusableElements();
      if (focusableElements.length > 0) {
        // Focus the first focusable element or autofocus element
        const autoFocusElement = focusableElements.find((el) =>
          el.hasAttribute('autofocus')
        );
        const elementToFocus = autoFocusElement || focusableElements[0];
        elementToFocus?.focus();
      }
    }

    // Handle Tab key press to trap focus
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key !== 'Tab') return;

      const focusableElements = getFocusableElements();
      if (focusableElements.length === 0) return;

      const firstElement = focusableElements[0];
      const lastElement = focusableElements[focusableElements.length - 1];

      if (event.shiftKey) {
        // Shift + Tab: moving backwards
        if (document.activeElement === firstElement) {
          event.preventDefault();
          lastElement?.focus();
        }
      } else {
        // Tab: moving forwards
        if (document.activeElement === lastElement) {
          event.preventDefault();
          firstElement?.focus();
        }
      }
    };

    container.addEventListener('keydown', handleKeyDown);

    return () => {
      container.removeEventListener('keydown', handleKeyDown);

      // Return focus to previously focused element
      if (returnFocus && previouslyFocusedElement.current) {
        previouslyFocusedElement.current.focus();
      }
    };
  }, [enabled, initialFocus, returnFocus]);

  return containerRef;
}
