/**
 * Spinner Component
 * Loading spinner with different sizes
 */

import type { OutputHTMLAttributes } from 'react'
import './Spinner.css'

export interface SpinnerProps extends OutputHTMLAttributes<HTMLOutputElement> {
  size?: 'small' | 'medium' | 'large'
  label?: string
}

export function Spinner({
  size = 'medium',
  label = 'Loading...',
  className = '',
  ...props
}: SpinnerProps) {
  const classes = ['spinner', `spinner--${size}`, className].filter(Boolean).join(' ')

  return (
    <output className={classes} aria-live="polite" {...props}>
      <div className="spinner__circle" aria-hidden="true" />
      <span className="sr-only">{label}</span>
    </output>
  )
}
