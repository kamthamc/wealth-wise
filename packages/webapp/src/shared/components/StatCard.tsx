/**
 * Stat Card Component
 * Display key statistics with optional trend
 */

import type { ReactNode } from 'react';
import { Card } from './Card';
import './StatCard.css';

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
  className?: string;
}

export function StatCard({
  label,
  value,
  icon,
  trend,
  description,
  variant = 'default',
  className = '',
}: StatCardProps) {
  const classes = ['stat-card', `stat-card--${variant}`, className]
    .filter(Boolean)
    .join(' ');

  return (
    <Card className={classes} padding="medium">
      <div className="stat-card__header">
        <span className="stat-card__label">{label}</span>
        {icon && <span className="stat-card__icon">{icon}</span>}
      </div>

      <div className="stat-card__value">{value}</div>

      {(trend || description) && (
        <div className="stat-card__footer">
          {trend && (
            <span
              className={`stat-card__trend ${
                trend.isPositive
                  ? 'stat-card__trend--positive'
                  : 'stat-card__trend--negative'
              }`}
            >
              <span aria-hidden="true">{trend.isPositive ? '↑' : '↓'}</span>
              <span>
                {trend.value}%{trend.label && ` ${trend.label}`}
              </span>
            </span>
          )}
          {description && (
            <span className="stat-card__description">{description}</span>
          )}
        </div>
      )}
    </Card>
  );
}
