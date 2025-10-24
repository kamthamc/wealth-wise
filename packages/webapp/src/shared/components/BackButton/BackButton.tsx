/**
 * BackButton Component
 * Reusable back button for navigation
 */

import { useNavigate } from '@tanstack/react-router';
import { useTranslation } from 'react-i18next';
import './BackButton.css';

interface BackButtonProps {
  /** Optional custom destination, defaults to -1 (browser back) */
  to?: string;
  /** Optional label text override */
  label?: string;
  /** Additional CSS classes */
  className?: string;
}

export function BackButton({ to, label, className = '' }: BackButtonProps) {
  const navigate = useNavigate();
  const { t } = useTranslation();

  const handleClick = () => {
    if (to) {
      navigate({ to });
    } else {
      window.history.back();
    }
  };

  return (
    <button
      type="button"
      onClick={handleClick}
      className={`back-button ${className}`}
      aria-label={t('common.backButton.ariaLabel')}
    >
      <svg
        className="back-button__icon"
        width="20"
        height="20"
        viewBox="0 0 20 20"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        aria-hidden="true"
      >
        <path
          d="M12.5 15L7.5 10L12.5 5"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
      <span className="back-button__label">
        {label || t('common.backButton.label')}
      </span>
    </button>
  );
}
