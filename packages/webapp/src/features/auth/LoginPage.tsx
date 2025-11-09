/**
 * Firebase Login Page
 * Authentication UI for WealthWise
 */

import { useNavigate } from '@tanstack/react-router';
import { useId, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Button, Input } from '@/shared/components';
import { useAuthStore } from '@/core/stores';
import '@/routes/login.css';

export function LoginPage() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { signIn, signUp, signInWithGoogle, isLoading, error, clearError } =
    useAuthStore();

  const [mode, setMode] = useState<'signin' | 'signup'>('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');

  // Generate unique IDs
  const displayNameId = useId();
  const emailId = useId();
  const passwordId = useId();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();

    try {
      if (mode === 'signin') {
        await signIn(email, password);
      } else {
        await signUp(email, password, displayName);
      }
      navigate({
        to: '/',
      });
    } catch (error) {
      // Error is handled in the store
      console.error('Auth error:', error);
    }
  };

  const handleGoogleSignIn = async () => {
    clearError();
    try {
      await signInWithGoogle();
      navigate({
        to: '/',
      });
    } catch (error) {
      console.error('Google sign in error:', error);
    }
  };

  return (
    <div className="login-container">
      <div className="login-card">
        {/* Logo/Title */}
        <div className="login-header">
          <h1 className="login-title">💰 {t('app.name', 'WealthWise')}</h1>
          <p className="login-subtitle">
            {t('app.tagline', 'Manage your finances intelligently')}
          </p>
        </div>

        {/* Tabs */}
        <div className="login-tabs">
          <button
            type="button"
            className={`login-tab-button ${mode === 'signin' ? 'login-tab-button--active' : 'login-tab-button--inactive'}`}
            onClick={() => {
              setMode('signin');
              clearError();
            }}
          >
            {t('auth.signIn', 'Sign In')}
          </button>
          <button
            type="button"
            className={`login-tab-button ${mode === 'signup' ? 'login-tab-button--active' : 'login-tab-button--inactive'}`}
            onClick={() => {
              setMode('signup');
              clearError();
            }}
          >
            {t('auth.signUp', 'Sign Up')}
          </button>
        </div>

        {/* Error Message */}
        {error && (
          <div className="login-error">
            {error}
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="login-form">
          {mode === 'signup' && (
            <div className="login-field">
              <label htmlFor={displayNameId} className="login-label">
                {t('auth.displayName', 'Display Name')}
              </label>
                <Input
                  id={displayNameId}
                  type="text"
                  placeholder={t('auth.displayNamePlaceholder', 'Enter your display name')}
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  required
                />
              </div>
            )}

          <div className="login-field">
            <label htmlFor={emailId} className="login-label">
              {t('auth.email', 'Email')}
            </label>
            <Input
              id={emailId}
              type="email"
              value={email}
              autoComplete="email"
              onChange={(e) => setEmail(e.target.value)}
              placeholder={t('auth.emailPlaceholder', 'you@example.com')}
              required
              disabled={isLoading}
            />
          </div>

          <div className="login-field">
            <label htmlFor={passwordId} className="login-label">
              {t('auth.password', 'Password')}
            </label>
            <Input
              id={passwordId}
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder={t('auth.passwordPlaceholder', '••••••••')}
              required
              minLength={6}
              disabled={isLoading}
            />
          </div>

          <Button
            type="submit"
            disabled={isLoading}
            variant="primary"
            fullWidth
          >
              {isLoading
                ? t('auth.processing', 'Processing...')
                : mode === 'signin'
                  ? t('auth.signIn', 'Sign In')
                  : t('auth.signUp', 'Sign Up')}
            </Button>
        </form>

        {/* Divider */}
        <div className="login-divider">
          <div className="login-divider-text">
            <span className="login-divider-label">
              {t('auth.orContinueWith', 'Or continue with')}
            </span>
          </div>
        </div>

        {/* Google Sign In */}
        <Button
          type="button"
          onClick={handleGoogleSignIn}
          disabled={isLoading}
          variant="secondary"
          fullWidth
        >
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              style={{ marginRight: '0.5rem' }}
              aria-hidden="true"
            >
              <path
                fill="currentColor"
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              />
              <path
                fill="currentColor"
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              />
              <path
                fill="currentColor"
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
              />
              <path
                fill="currentColor"
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
              />
            </svg>
          {t('auth.signInWithGoogle', 'Sign in with Google')}
        </Button>

        {/* Emulator Notice */}
        {import.meta.env.DEV && (
          <div className="login-footer">
            <p className="login-footer-title">
              {t('auth.emulator.title', 'Testing with Firebase Emulators')}
            </p>
            <p className="login-footer-subtitle">
              {t('auth.emulator.subtitle', 'Auth: localhost:9099 | Firestore: localhost:8080')}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
