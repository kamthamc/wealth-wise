/**
 * Stat Card Component
 * Display key statistics with optional trend using Radix UI
 */

import type { ReactNode } from 'react';
import { Card } from './Card';

export interface StatCardProps {
  label: string;
  value: string | number;
  icon?: ReactNode;
  trend?: {
    value: number;
    label?: string;
    isPositive?: boolean;
  };
  description?: string;
  variant?: 'default' | 'primary' | 'success' | 'warning' | 'danger';
}

export function StatCard({
  label,
  value,
  icon,
  trend,
  description,
  variant = 'default',
}: StatCardProps) {
  // Map variants to colors
  const getColorStyles = () => {
    switch (variant) {
      case 'primary':
        return { accentColor: 'var(--color-blue-600)' };
      case 'success':
        return { accentColor: 'var(--color-green-600)' };
      case 'warning':
        return { accentColor: 'var(--color-yellow-600)' };
      case 'danger':
        return { accentColor: 'var(--color-red-600)' };
      case 'default':
      default:
        return { accentColor: 'var(--color-text-primary)' };
    }
  };

  const colorStyles = getColorStyles();

  return (
    <Card>
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 'var(--space-2)',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <span
            style={{
              fontSize: 'var(--font-size-2)',
              color: 'var(--color-text-secondary)',
              fontWeight: 'var(--font-weight-medium)',
            }}
          >
            {label}
          </span>
          {icon && (
            <span
              style={{
                color: colorStyles.accentColor,
                fontSize: 'var(--font-size-3)',
              }}
            >
              {icon}
            </span>
          )}
        </div>

        <div
          style={{
            fontSize: 'var(--font-size-5)',
            fontWeight: 'var(--font-weight-bold)',
            color: 'var(--color-text-primary)',
            lineHeight: 'var(--leading-tight)',
          }}
        >
          {value}
        </div>

        {(trend || description) && (
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              marginTop: 'var(--space-1)',
            }}
          >
            {trend && (
              <span
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--space-1)',
                  fontSize: 'var(--font-size-1)',
                  fontWeight: 'var(--font-weight-medium)',
                  color: trend.isPositive ? 'var(--color-green-600)' : 'var(--color-red-600)',
                }}
              >
                <span aria-hidden="true">
                  {trend.isPositive ? '↑' : '↓'}
                </span>
                <span>
                  {trend.value}%{trend.label && ` ${trend.label}`}
                </span>
              </span>
            )}
            {description && (
              <span
                style={{
                  fontSize: 'var(--font-size-1)',
                  color: 'var(--color-text-tertiary)',
                }}
              >
                {description}
              </span>
            )}
          </div>
        )}
      </div>
    </Card>
  );
}
