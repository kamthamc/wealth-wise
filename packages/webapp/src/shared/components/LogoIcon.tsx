/**
 * WealthWise Logo Icon Component
 * Diamond/Gem icon representing wealth and value
 */

interface LogoIconProps {
  size?: number;
  className?: string;
}

export function LogoIcon({ size = 24, className = '' }: LogoIconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      aria-hidden="true"
    >
      <defs>
        <linearGradient id="logoGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style={{ stopColor: '#3b82f6', stopOpacity: 1 }} />
          <stop
            offset="100%"
            style={{ stopColor: '#2563eb', stopOpacity: 1 }}
          />
        </linearGradient>
      </defs>

      {/* Diamond/Gem shape */}
      <path d="M 12,3 L 19,9 L 12,21 L 5,9 Z" fill="url(#logoGradient)" />

      {/* Highlight facet */}
      <path
        d="M 12,8 L 15.5,11 L 12,16 L 8.5,11 Z"
        fill="currentColor"
        opacity="0.3"
      />

      {/* Top facet */}
      <path
        d="M 12,3 L 15,6 L 12,8 L 9,6 Z"
        fill="currentColor"
        opacity="0.2"
      />
    </svg>
  );
}
