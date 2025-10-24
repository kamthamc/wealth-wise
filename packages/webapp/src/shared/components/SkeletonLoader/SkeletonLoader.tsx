/**
 * Skeleton Loader Component
 * Animated loading placeholder for content
 */

import './SkeletonLoader.css';

export interface SkeletonLoaderProps {
  /**
   * Type of skeleton to display
   */
  variant?:
    | 'text'
    | 'heading'
    | 'circle'
    | 'rectangle'
    | 'card'
    | 'list-item'
    | 'stat-card';

  /**
   * Width of skeleton (CSS value)
   */
  width?: string | number;

  /**
   * Height of skeleton (CSS value)
   */
  height?: string | number;

  /**
   * Number of items to repeat (for list items)
   */
  count?: number;

  /**
   * Additional CSS class
   */
  className?: string;

  /**
   * Animation style
   */
  animation?: 'pulse' | 'wave' | 'none';
}

export function SkeletonLoader({
  variant = 'rectangle',
  width,
  height,
  count = 1,
  className = '',
  animation = 'wave',
}: SkeletonLoaderProps) {
  const getVariantStyles = () => {
    const styles: React.CSSProperties = {};

    // Apply custom dimensions if provided
    if (width !== undefined) {
      styles.width = typeof width === 'number' ? `${width}px` : width;
    }
    if (height !== undefined) {
      styles.height = typeof height === 'number' ? `${height}px` : height;
    }

    return styles;
  };

  const classes = [
    'skeleton',
    `skeleton--${variant}`,
    `skeleton--${animation}`,
    className,
  ]
    .filter(Boolean)
    .join(' ');

  // For composite variants (card, list-item, stat-card)
  if (variant === 'card') {
    return (
      <div className="skeleton-card">
        <div
          className={`skeleton skeleton--rectangle skeleton--${animation}`}
          style={{ height: '160px' }}
        />
        <div className="skeleton-card__content">
          <div
            className={`skeleton skeleton--heading skeleton--${animation}`}
            style={{ width: '70%' }}
          />
          <div
            className={`skeleton skeleton--text skeleton--${animation}`}
            style={{ width: '90%' }}
          />
          <div
            className={`skeleton skeleton--text skeleton--${animation}`}
            style={{ width: '60%' }}
          />
        </div>
      </div>
    );
  }

  if (variant === 'list-item') {
    return (
      <>
        {Array.from({ length: count }).map((_, index) => (
          <div key={index} className="skeleton-list-item">
            <div
              className={`skeleton skeleton--circle skeleton--${animation}`}
              style={{ width: '48px', height: '48px' }}
            />
            <div className="skeleton-list-item__content">
              <div
                className={`skeleton skeleton--text skeleton--${animation}`}
                style={{ width: '40%' }}
              />
              <div
                className={`skeleton skeleton--text skeleton--${animation}`}
                style={{ width: '60%' }}
              />
            </div>
            <div
              className={`skeleton skeleton--text skeleton--${animation}`}
              style={{ width: '80px' }}
            />
          </div>
        ))}
      </>
    );
  }

  if (variant === 'stat-card') {
    return (
      <div className="skeleton-stat-card">
        <div
          className={`skeleton skeleton--text skeleton--${animation}`}
          style={{ width: '60%' }}
        />
        <div
          className={`skeleton skeleton--heading skeleton--${animation}`}
          style={{ width: '80%', marginTop: '8px' }}
        />
        <div
          className={`skeleton skeleton--text skeleton--${animation}`}
          style={{ width: '40%', marginTop: '4px' }}
        />
      </div>
    );
  }

  // For simple variants (text, heading, circle, rectangle)
  if (count > 1) {
    return (
      <>
        {Array.from({ length: count }).map((_, index) => (
          <div key={index} className={classes} style={getVariantStyles()} />
        ))}
      </>
    );
  }

  return <div className={classes} style={getVariantStyles()} />;
}

// Compound components for common patterns
export function SkeletonText({
  lines = 3,
  width,
}: {
  lines?: number;
  width?: string;
}) {
  return (
    <div className="skeleton-text-block">
      {Array.from({ length: lines }).map((_, index) => (
        <SkeletonLoader
          key={index}
          variant="text"
          width={index === lines - 1 ? width || '60%' : '100%'}
        />
      ))}
    </div>
  );
}

export function SkeletonCard({ count = 1 }: { count?: number }) {
  return (
    <>
      {Array.from({ length: count }).map((_, index) => (
        <SkeletonLoader key={index} variant="card" />
      ))}
    </>
  );
}

export function SkeletonList({ items = 5 }: { items?: number }) {
  return <SkeletonLoader variant="list-item" count={items} />;
}

export function SkeletonStats({ count = 4 }: { count?: number }) {
  return (
    <div className="skeleton-stats-grid">
      {Array.from({ length: count }).map((_, index) => (
        <SkeletonLoader key={index} variant="stat-card" />
      ))}
    </div>
  );
}
