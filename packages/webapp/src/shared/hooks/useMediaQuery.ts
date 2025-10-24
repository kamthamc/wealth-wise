import { useEffect, useState } from 'react';

/**
 * Custom hook to match media queries and respond to changes
 * Respects user preferences like prefers-reduced-motion, prefers-color-scheme
 *
 * @param query - The media query string to match
 * @returns Boolean indicating if the media query matches
 *
 * @example
 * ```tsx
 * function Component() {
 *   const prefersReducedMotion = useMediaQuery('(prefers-reduced-motion: reduce)')
 *   const prefersDarkMode = useMediaQuery('(prefers-color-scheme: dark)')
 *   const isMobile = useMediaQuery('(max-width: 768px)')
 *
 *   return <div>Motion: {prefersReducedMotion ? 'Reduced' : 'Normal'}</div>
 * }
 * ```
 */
export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(() => {
    if (typeof window === 'undefined') return false;
    return window.matchMedia(query).matches;
  });

  useEffect(() => {
    const mediaQuery = window.matchMedia(query);

    // Update state if initial value was different
    setMatches(mediaQuery.matches);

    // Create event listener
    const handleChange = (event: MediaQueryListEvent) => {
      setMatches(event.matches);
    };

    // Add event listener (using addEventListener for better compatibility)
    mediaQuery.addEventListener('change', handleChange);

    return () => {
      mediaQuery.removeEventListener('change', handleChange);
    };
  }, [query]);

  return matches;
}

/**
 * Predefined hooks for common media queries
 */
export const usePrefersDarkMode = () =>
  useMediaQuery('(prefers-color-scheme: dark)');
export const usePrefersReducedMotion = () =>
  useMediaQuery('(prefers-reduced-motion: reduce)');
export const usePrefersHighContrast = () =>
  useMediaQuery('(prefers-contrast: high)');
export const usePrefersReducedTransparency = () =>
  useMediaQuery('(prefers-reduced-transparency: reduce)');

/**
 * Responsive breakpoint hooks
 */
export const useIsMobile = () => useMediaQuery('(max-width: 768px)');
export const useIsTablet = () =>
  useMediaQuery('(min-width: 769px) and (max-width: 1024px)');
export const useIsDesktop = () => useMediaQuery('(min-width: 1025px)');
