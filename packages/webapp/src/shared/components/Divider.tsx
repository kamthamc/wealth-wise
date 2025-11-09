/**
 * Divider Component
 * Visual separator between content using Radix UI
 */

import { Separator } from '@radix-ui/themes';

export interface DividerProps {
  orientation?: 'horizontal' | 'vertical';
  spacing?: 'small' | 'medium' | 'large';
  label?: string;
}

export function Divider({
  orientation = 'horizontal',
  spacing = 'medium',
  label,
}: DividerProps) {
  // Map spacing to margin
  const getSpacingStyles = () => {
    switch (spacing) {
      case 'small':
        return orientation === 'horizontal'
          ? { margin: 'var(--space-2) 0' }
          : { margin: '0 var(--space-2)' };
      case 'large':
        return orientation === 'horizontal'
          ? { margin: 'var(--space-4) 0' }
          : { margin: '0 var(--space-4)' };
      case 'medium':
      default:
        return orientation === 'horizontal'
          ? { margin: 'var(--space-3) 0' }
          : { margin: '0 var(--space-3)' };
    }
  };

  if (label) {
    return (
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          ...getSpacingStyles(),
        }}
      >
        <Separator
          orientation={orientation}
          style={{ flex: 1 }}
        />
        <span
          style={{
            padding: orientation === 'horizontal' ? '0 var(--space-2)' : 'var(--space-2) 0',
            fontSize: 'var(--font-size-1)',
            color: 'var(--color-text-secondary)',
            fontWeight: 'var(--font-weight-medium)',
          }}
        >
          {label}
        </span>
        <Separator
          orientation={orientation}
          style={{ flex: 1 }}
        />
      </div>
    );
  }

  return (
    <Separator
      orientation={orientation}
      style={getSpacingStyles()}
    />
  );
}
