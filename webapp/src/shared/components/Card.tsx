/**
 * Card Component
 * Container component for grouping related content
 */

import type { HTMLAttributes, ReactNode } from 'react'
import './Card.css'

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'outlined' | 'elevated'
  padding?: 'none' | 'small' | 'medium' | 'large'
  interactive?: boolean
  header?: ReactNode
  footer?: ReactNode
}

export function Card({
  variant = 'default',
  padding = 'medium',
  interactive = false,
  header,
  footer,
  children,
  className = '',
  ...props
}: CardProps) {
  const classes = [
    'card',
    `card--${variant}`,
    `card--padding-${padding}`,
    interactive && 'card--interactive',
    className,
  ]
    .filter(Boolean)
    .join(' ')

  return (
    <div className={classes} {...props}>
      {header && <div className="card__header">{header}</div>}
      {children && <div className="card__content">{children}</div>}
      {footer && <div className="card__footer">{footer}</div>}
    </div>
  )
}
