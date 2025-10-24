/**
 * Toast Notification Component
 * Radix UI Toast for non-intrusive user feedback
 */

import * as Toast from '@radix-ui/react-toast';
import { AlertCircle, CheckCircle, Info, X, XCircle } from 'lucide-react';
import { createContext, useCallback, useContext, useState } from 'react';
import './ToastProvider.css';

export type ToastType = 'success' | 'error' | 'info' | 'warning';

export interface ToastMessage {
  id: string;
  type: ToastType;
  title: string;
  description?: string;
  duration?: number;
  action?: {
    label: string;
    onClick: () => void;
  };
}

interface ToastContextValue {
  showToast: (toast: Omit<ToastMessage, 'id'>) => void;
  success: (title: string, description?: string) => void;
  error: (title: string, description?: string) => void;
  info: (title: string, description?: string) => void;
  warning: (title: string, description?: string) => void;
}

const ToastContext = createContext<ToastContextValue | undefined>(undefined);

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used within ToastProvider');
  }
  return context;
}

interface ToastProviderProps {
  children: React.ReactNode;
  /**
   * Maximum number of toasts to show at once
   */
  maxToasts?: number;
  /**
   * Default duration in milliseconds (0 = no auto-dismiss)
   */
  defaultDuration?: number;
}

export function ToastProvider({
  children,
  maxToasts = 3,
  defaultDuration = 5000,
}: ToastProviderProps) {
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  const showToast = useCallback(
    (toast: Omit<ToastMessage, 'id'>) => {
      const id = Math.random().toString(36).substring(2, 9);
      const newToast: ToastMessage = {
        ...toast,
        id,
        duration: toast.duration ?? defaultDuration,
      };

      setToasts((prev) => {
        // Remove oldest toast if at max
        const updated = prev.length >= maxToasts ? prev.slice(1) : prev;
        return [...updated, newToast];
      });
    },
    [maxToasts, defaultDuration]
  );

  const success = useCallback(
    (title: string, description?: string) => {
      showToast({ type: 'success', title, description });
    },
    [showToast]
  );

  const error = useCallback(
    (title: string, description?: string) => {
      showToast({ type: 'error', title, description });
    },
    [showToast]
  );

  const info = useCallback(
    (title: string, description?: string) => {
      showToast({ type: 'info', title, description });
    },
    [showToast]
  );

  const warning = useCallback(
    (title: string, description?: string) => {
      showToast({ type: 'warning', title, description });
    },
    [showToast]
  );

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((toast) => toast.id !== id));
  }, []);

  const getToastIcon = (type: ToastType) => {
    const icons = {
      success: <CheckCircle size={20} />,
      error: <XCircle size={20} />,
      warning: <AlertCircle size={20} />,
      info: <Info size={20} />,
    };
    return icons[type];
  };

  return (
    <ToastContext.Provider value={{ showToast, success, error, info, warning }}>
      {children}
      <Toast.Provider swipeDirection="right">
        {toasts.map((toast) => (
          <Toast.Root
            key={toast.id}
            className={`toast toast--${toast.type}`}
            duration={toast.duration}
            onOpenChange={(open) => {
              if (!open) removeToast(toast.id);
            }}
          >
            <div className="toast__content">
              <div className="toast__icon">{getToastIcon(toast.type)}</div>
              <div className="toast__text">
                <Toast.Title className="toast__title">
                  {toast.title}
                </Toast.Title>
                {toast.description && (
                  <Toast.Description className="toast__description">
                    {toast.description}
                  </Toast.Description>
                )}
              </div>
              {toast.action && (
                <Toast.Action
                  className="toast__action"
                  altText={toast.action.label}
                  onClick={toast.action.onClick}
                >
                  {toast.action.label}
                </Toast.Action>
              )}
              <Toast.Close className="toast__close" aria-label="Close">
                <X size={16} />
              </Toast.Close>
            </div>
          </Toast.Root>
        ))}
        <Toast.Viewport className="toast__viewport" />
      </Toast.Provider>
    </ToastContext.Provider>
  );
}
