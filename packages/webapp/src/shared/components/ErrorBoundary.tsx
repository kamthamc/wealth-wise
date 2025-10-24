/**
 * Error Boundary Component
 * Catches and displays errors in child components
 */

import { Component, type ErrorInfo, type ReactNode } from 'react';
import { Button } from './Button';
import { Card } from './Card';
import './ErrorBoundary.css';

interface ErrorBoundaryProps {
  children: ReactNode;
  fallback?: (error: Error, reset: () => void) => ReactNode;
}

interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<
  ErrorBoundaryProps,
  ErrorBoundaryState
> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
    };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return {
      hasError: true,
      error,
    };
  }

  override componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    console.error('Error caught by boundary:', error, errorInfo);
  }

  resetError = (): void => {
    this.setState({
      hasError: false,
      error: null,
    });
  };

  override render(): ReactNode {
    const { hasError, error } = this.state;
    const { children, fallback } = this.props;

    if (hasError && error) {
      if (fallback) {
        return fallback(error, this.resetError);
      }

      return (
        <div className="error-boundary">
          <Card variant="outlined" padding="large">
            <div className="error-boundary__content">
              <div className="error-boundary__icon" aria-hidden="true">
                ⚠️
              </div>
              <h2 className="error-boundary__title">Something went wrong</h2>
              <p className="error-boundary__message">{error.message}</p>
              {import.meta.env.DEV && (
                <details className="error-boundary__details">
                  <summary>Error details</summary>
                  <pre className="error-boundary__stack">{error.stack}</pre>
                </details>
              )}
              <Button onClick={this.resetError} variant="primary">
                Try Again
              </Button>
            </div>
          </Card>
        </div>
      );
    }

    return children;
  }
}
