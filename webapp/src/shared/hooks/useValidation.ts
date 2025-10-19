/**
 * Debounced Validation Hook
 * Validate form fields with debouncing to avoid excessive validation
 */

import { useCallback, useEffect, useState } from 'react';

export interface ValidationResult {
  isValid: boolean;
  message?: string;
  state?: 'error' | 'success' | 'warning' | 'info';
}

export interface UseValidationOptions<T> {
  /** Validation function */
  validate: (value: T) => ValidationResult | Promise<ValidationResult>;
  /** Debounce delay in milliseconds */
  debounceMs?: number;
  /** Validate on mount */
  validateOnMount?: boolean;
  /** Only validate after first blur */
  validateOnlyAfterBlur?: boolean;
}

/**
 * Hook for debounced field validation
 */
export function useValidation<T>(
  value: T,
  options: UseValidationOptions<T>
) {
  const {
    validate,
    debounceMs = 500,
    validateOnMount = false,
    validateOnlyAfterBlur = true,
  } = options;

  const [validation, setValidation] = useState<ValidationResult>({
    isValid: true,
  });
  const [isValidating, setIsValidating] = useState(false);
  const [hasBlurred, setHasBlurred] = useState(!validateOnlyAfterBlur);

  // Validate function
  const performValidation = useCallback(async () => {
    if (validateOnlyAfterBlur && !hasBlurred) {
      return;
    }

    setIsValidating(true);
    try {
      const result = await validate(value);
      setValidation(result);
    } catch (error) {
      setValidation({
        isValid: false,
        message: 'Validation error',
        state: 'error',
      });
    } finally {
      setIsValidating(false);
    }
  }, [value, validate, hasBlurred, validateOnlyAfterBlur]);

  // Debounced validation
  useEffect(() => {
    if (!validateOnMount && !hasBlurred) {
      return;
    }

    const timer = setTimeout(() => {
      performValidation();
    }, debounceMs);

    return () => clearTimeout(timer);
  }, [value, performValidation, debounceMs, validateOnMount, hasBlurred]);

  return {
    ...validation,
    isValidating,
    hasBlurred,
    onBlur: () => setHasBlurred(true),
    revalidate: performValidation,
  };
}

/**
 * Common validation functions
 */
export const validators = {
  required: (value: unknown): ValidationResult => ({
    isValid: value !== null && value !== undefined && value !== '',
    message: value ? undefined : 'This field is required',
    state: value ? 'success' : 'error',
  }),

  minLength:
    (min: number) =>
    (value: string): ValidationResult => {
      const isValid = value.length >= min;
      return {
        isValid,
        message: isValid
          ? undefined
          : `Must be at least ${min} characters`,
        state: isValid ? 'success' : 'error',
      };
    },

  maxLength:
    (max: number) =>
    (value: string): ValidationResult => {
      const isValid = value.length <= max;
      return {
        isValid,
        message: isValid ? undefined : `Cannot exceed ${max} characters`,
        state: isValid ? 'success' : 'error',
      };
    },

  email: (value: string): ValidationResult => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    const isValid = emailRegex.test(value);
    return {
      isValid,
      message: isValid ? undefined : 'Please enter a valid email address',
      state: isValid ? 'success' : 'error',
    };
  },

  minAmount:
    (min: number) =>
    (value: number): ValidationResult => {
      const isValid = value >= min;
      return {
        isValid,
        message: isValid ? undefined : `Amount must be at least ₹${min}`,
        state: isValid ? 'success' : 'error',
      };
    },

  maxAmount:
    (max: number) =>
    (value: number): ValidationResult => {
      const isValid = value <= max;
      return {
        isValid,
        message: isValid ? undefined : `Amount cannot exceed ₹${max}`,
        state: isValid ? 'success' : 'error',
      };
    },

  positiveNumber: (value: number): ValidationResult => {
    const isValid = value > 0;
    return {
      isValid,
      message: isValid ? undefined : 'Amount must be greater than zero',
      state: isValid ? 'success' : 'error',
    };
  },

  futureDate: (value: Date | string): ValidationResult => {
    const date = typeof value === 'string' ? new Date(value) : value;
    const now = new Date();
    now.setHours(0, 0, 0, 0);
    const isValid = date >= now;
    return {
      isValid,
      message: isValid ? undefined : 'Date cannot be in the past',
      state: isValid ? 'success' : 'error',
    };
  },

  pastDate: (value: Date | string): ValidationResult => {
    const date = typeof value === 'string' ? new Date(value) : value;
    const now = new Date();
    now.setHours(23, 59, 59, 999);
    const isValid = date <= now;
    return {
      isValid,
      message: isValid ? undefined : 'Date cannot be in the future',
      state: isValid ? 'success' : 'error',
    };
  },

  combine:
    (...validatorFns: Array<(value: any) => ValidationResult>) =>
    (value: any): ValidationResult => {
      for (const validator of validatorFns) {
        const result = validator(value);
        if (!result.isValid) {
          return result;
        }
      }
      return { isValid: true, state: 'success' };
    },
};
