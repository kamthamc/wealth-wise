/**
 * Spinner Component
 * Loading spinner with different sizes using Radix UI
 */

import { Spinner as RadixSpinner } from '@radix-ui/themes';

export interface SpinnerProps {
  size?: 'small' | 'medium' | 'large';
  label?: string;
}

export function Spinner({
  size = 'medium',
  label = 'Loading...',
}: SpinnerProps) {
  // Map our sizes to Radix sizes
  const getRadixSize = () => {
    switch (size) {
      case 'small':
        return '1';
      case 'medium':
        return '2';
      case 'large':
        return '3';
      default:
        return '2';
    }
  };

  return (
    <RadixSpinner
      size={getRadixSize()}
      aria-label={label}
    />
  );
}
