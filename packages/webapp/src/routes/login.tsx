import { createFileRoute, Navigate } from '@tanstack/react-router';
import { useId, useState } from 'react';
import { Button, Card, Input } from '@/shared/components';
import { useAuthStore } from '../core/stores/authStore';
import './login.css';

export const Route = createFileRoute('/login')({
  component: LoginPage,
});

function LoginPage() {
  const { user, signIn, signUp, signInWithGoogle, error } = useAuthStore();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isSignUp, setIsSignUp] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  // Generate unique IDs
  const emailId = useId();
  const passwordId = useId();

  // Redirect if already logged in
  if (user) {
    return <Navigate to="/dashboard" />;
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    try {
      if (isSignUp) {
        await signUp(email, password);
      } else {
        await signIn(email, password);
      }
    } catch {
      // Error is already handled in store
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    setIsLoading(true);
    try {
      await signInWithGoogle();
    } catch {
      // Error is already handled in store
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="login-container">
      <Card
        className="login-card"
        padding="large"
      >
        <div className="login-header">
          <h1 className="login-title">
            WealthWise
          </h1>
          <p className="login-subtitle">
            Manage your finances intelligently
          </p>
        </div>

        <div className="login-tabs">
          <button
            type="button"
            onClick={() => setIsSignUp(false)}
            className={`login-tab-button ${!isSignUp ? 'login-tab-button--active' : 'login-tab-button--inactive'}`}
          >
            Sign In
          </button>
          <button
            type="button"
            onClick={() => setIsSignUp(true)}
            className={`login-tab-button ${isSignUp ? 'login-tab-button--active' : 'login-tab-button--inactive'}`}
          >
            Sign Up
          </button>
        </div>

        <form onSubmit={handleSubmit} className="login-form">
          <div className="login-field">
            <label htmlFor={emailId} className="login-label">
              Email
            </label>
            <Input
              id={emailId}
              type="email"
              placeholder="you@example.com"
              value={email}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                setEmail(e.target.value)
              }
              required
              disabled={isLoading}
            />
          </div>

          <div className="login-field">
            <label htmlFor={passwordId} className="login-label">
              Password
            </label>
            <Input
              id={passwordId}
              type="password"
              placeholder="••••••••"
              value={password}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                setPassword(e.target.value)
              }
              required
              minLength={6}
              disabled={isLoading}
            />
          </div>

          {error && (
            <div className="login-error">
              {error}
            </div>
          )}

          <Button type="submit" disabled={isLoading}>
            {isLoading
              ? 'Please wait...'
              : isSignUp
                ? 'Create Account'
                : 'Sign In'}
          </Button>
        </form>

        <div className="login-divider">
          <div className="login-divider-text">
            <span className="login-divider-label">
              Or continue with
            </span>
          </div>
        </div>

        <Button
          type="button"
          onClick={handleGoogleSignIn}
          disabled={isLoading}
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
          Sign in with Google
        </Button>

        <div className="login-footer">
          <p className="login-footer-title">Testing with Firebase Emulators</p>
          <p className="login-footer-subtitle">
            Auth: localhost:9099 | Firestore: localhost:8080
          </p>
        </div>
      </Card>
    </div>
  );
}
