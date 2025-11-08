/**
 * Welcome Banner Component
 * Onboarding guide for first-time users
 */

import { useNavigate } from '@tanstack/react-router';
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useAccountStore } from '@/core/stores';
import './WelcomeBanner.css';

export function WelcomeBanner() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { accounts } = useAccountStore();
  const [dismissed, setDismissed] = useState(() => {
    return localStorage.getItem('welcomeBannerDismissed') === 'true';
  });

  const hasAccounts = accounts.length > 0;

  const handleDismiss = () => {
    localStorage.setItem('welcomeBannerDismissed', 'true');
    setDismissed(true);
  };

  const handleGetStarted = () => {
    navigate({ to: '/accounts' });
  };

  // Don't show if dismissed or user already has accounts
  if (dismissed || hasAccounts) {
    return null;
  }

  return (
    <section
      className="welcome-banner"
      role="region"
      aria-labelledby="welcome-title"
    >
      <button
        type="button"
        className="welcome-banner__close"
        onClick={handleDismiss}
        aria-label={t('pages.dashboard.welcomeBanner.dismiss', 'Dismiss welcome message')}
      >
        ✕
      </button>

      <div className="welcome-banner__content">
        <div className="welcome-banner__icon" aria-hidden="true">
          👋
        </div>

        <div className="welcome-banner__text">
          <h2 id="welcome-title" className="welcome-banner__title">
            {t('pages.dashboard.welcomeBanner.title', 'Welcome to WealthWise!')}
          </h2>
          <p className="welcome-banner__description">
            {t('pages.dashboard.welcomeBanner.description', 'Start tracking your finances in 3 simple steps:')}
          </p>

          <ol className="welcome-banner__steps">
            <li className="welcome-banner__step">
              <span className="welcome-banner__step-number" aria-hidden="true">
                1
              </span>
              <span className="welcome-banner__step-text">
                {t('pages.dashboard.welcomeBanner.step1', 'Add your first account (bank, wallet, or credit card)')}
              </span>
            </li>
            <li className="welcome-banner__step">
              <span className="welcome-banner__step-number" aria-hidden="true">
                2
              </span>
              <span className="welcome-banner__step-text">
                {t('pages.dashboard.welcomeBanner.step2', 'Record transactions to track your spending')}
              </span>
            </li>
            <li className="welcome-banner__step">
              <span className="welcome-banner__step-number" aria-hidden="true">
                3
              </span>
              <span className="welcome-banner__step-text">
                {t('pages.dashboard.welcomeBanner.step3', 'Set budgets and goals to reach your financial targets')}
              </span>
            </li>
          </ol>
        </div>
      </div>

      <div className="welcome-banner__actions">
        <button
          type="button"
          className="welcome-banner__button welcome-banner__button--primary"
          onClick={handleGetStarted}
        >
          {t('pages.dashboard.welcomeBanner.getStarted', 'Get Started')}
        </button>
        <button
          type="button"
          className="welcome-banner__button welcome-banner__button--secondary"
          onClick={handleDismiss}
        >
          {t('pages.dashboard.welcomeBanner.maybeLater', 'Maybe Later')}
        </button>
      </div>
    </section>
  );
}
