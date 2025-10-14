/**
 * Divider Component
 * Visual separator between content
 */

import type { HTMLAttributes } from 'react';
import './Divider.css';

export interface DividerProps extends HTMLAttributes<HTMLHRElement> {
  orientation?: 'horizontal' | 'vertical';
  spacing?: 'small' | 'medium' | 'large';
  label?: string;
}

export function Divider({
  orientation = 'horizontal',
  spacing = 'medium',
  label,
  className = '',
  ...props
}: DividerProps) {
  const classes = [
    'divider',
    `divider--${orientation}`,
    `divider--spacing-${spacing}`,
    label && 'divider--with-label',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  if (label) {
    return (
      <div className={classes}>
        <hr className="divider__line" {...props} />
        <span className="divider__label">{label}</span>
        <hr className="divider__line" {...props} />
      </div>
    );
  }

  return <hr className={classes} {...props} />;
}
