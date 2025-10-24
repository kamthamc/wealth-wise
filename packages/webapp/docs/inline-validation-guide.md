# Inline Validation System

## Overview

WealthWise has a **comprehensive inline validation system** that provides real-time feedback as users interact with forms. The system is accessible, performant, and provides clear guidance to users.

## Components

### ValidationMessage Component

A flexible component for displaying validation feedback with different states.

**Features:**
- 4 states: `error`, `success`, `warning`, `info`
- Automatic icons for each state
- Custom icon support
- Accessible (ARIA live regions)
- Smooth animations
- Dark mode support
- Responsive design

**Usage:**

```tsx
import { ValidationMessage } from '@/shared/components';

<ValidationMessage
  state="error"
  message="Amount must be at least ₹100"
  fieldId="amount"
/>
```

### useValidation Hook

Custom hook for debounced field validation with async support.

**Features:**
- Debounced validation (configurable delay)
- Async validation support
- Validate on blur or on mount
- Loading states
- Revalidation trigger

**Usage:**

```tsx
import { useValidation, validators } from '@/shared/hooks/useValidation';

const [amount, setAmount] = useState(0);
const validation = useValidation(amount, {
  validate: validators.combine(
    validators.required,
    validators.positiveNumber,
    validators.minAmount(100)
  ),
  debounceMs: 500,
  validateOnlyAfterBlur: true,
});

<Input
  value={amount}
  onChange={(e) => setAmount(Number(e.target.value))}
  onBlur={validation.onBlur}
  error={validation.message}
/>
<ValidationMessage
  state={validation.state}
  message={validation.message}
/>
```

## Built-in Validators

### Text Validators

**required** - Ensures field is not empty
```tsx
validators.required(value)
```

**minLength** - Minimum character length
```tsx
validators.minLength(5)(value)
```

**maxLength** - Maximum character length
```tsx
validators.maxLength(100)(value)
```

**email** - Valid email format
```tsx
validators.email(value)
```

### Number Validators

**positiveNumber** - Must be > 0
```tsx
validators.positiveNumber(value)
```

**minAmount** - Minimum amount
```tsx
validators.minAmount(100)(value)
```

**maxAmount** - Maximum amount
```tsx
validators.maxAmount(10000)(value)
```

### Date Validators

**futureDate** - Date must be in future
```tsx
validators.futureDate(value)
```

**pastDate** - Date must be in past
```tsx
validators.pastDate(value)
```

### Combining Validators

**combine** - Run multiple validators
```tsx
validators.combine(
  validators.required,
  validators.minLength(3),
  validators.maxLength(50)
)(value)
```

## Complete Form Example

```tsx
import { useState } from 'react';
import { 
  Input, 
  Button, 
  ValidationMessage 
} from '@/shared/components';
import { useValidation, validators } from '@/shared/hooks/useValidation';

function TransactionForm() {
  const [description, setDescription] = useState('');
  const [amount, setAmount] = useState(0);

  // Description validation
  const descValidation = useValidation(description, {
    validate: validators.combine(
      validators.required,
      validators.minLength(3),
      validators.maxLength(100)
    ),
    debounceMs: 300,
  });

  // Amount validation
  const amountValidation = useValidation(amount, {
    validate: validators.combine(
      validators.required,
      validators.positiveNumber,
      validators.minAmount(1)
    ),
    debounceMs: 500,
  });

  const isFormValid = 
    descValidation.isValid && 
    amountValidation.isValid;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (isFormValid) {
      // Submit form
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <Input
          id="description"
          label="Description"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          onBlur={descValidation.onBlur}
          required
        />
        {descValidation.hasBlurred && (
          <ValidationMessage
            state={descValidation.state}
            message={descValidation.message}
            fieldId="description"
          />
        )}
      </div>

      <div>
        <Input
          id="amount"
          type="number"
          label="Amount"
          value={amount}
          onChange={(e) => setAmount(Number(e.target.value))}
          onBlur={amountValidation.onBlur}
          required
        />
        {amountValidation.hasBlurred && (
          <ValidationMessage
            state={amountValidation.state}
            message={amountValidation.message}
            fieldId="amount"
          />
        )}
      </div>

      <Button 
        type="submit" 
        disabled={!isFormValid || descValidation.isValidating}
      >
        {descValidation.isValidating ? 'Validating...' : 'Save'}
      </Button>
    </form>
  );
}
```

## Custom Validators

Create custom validators for specific business logic:

```tsx
// Custom validator for Indian phone numbers
const indianPhone = (value: string): ValidationResult => {
  const phoneRegex = /^[6-9]\d{9}$/;
  const isValid = phoneRegex.test(value);
  return {
    isValid,
    message: isValid 
      ? undefined 
      : 'Enter a valid 10-digit Indian mobile number',
    state: isValid ? 'success' : 'error',
  };
};

// Async validator (e.g., check if username is available)
const checkUsername = async (value: string): Promise<ValidationResult> => {
  if (!value) {
    return {
      isValid: false,
      message: 'Username is required',
      state: 'error',
    };
  }

  try {
    const response = await fetch(`/api/check-username/${value}`);
    const { available } = await response.json();
    
    return {
      isValid: available,
      message: available 
        ? 'Username is available' 
        : 'Username already taken',
      state: available ? 'success' : 'error',
    };
  } catch {
    return {
      isValid: false,
      message: 'Could not validate username',
      state: 'error',
    };
  }
};
```

## Validation States

### Error State (Red)
- Shows validation failures
- Prevents form submission
- Clear, actionable messages

### Success State (Green)
- Shows field is valid
- Provides positive feedback
- Optional (can hide on success)

### Warning State (Yellow)
- Non-blocking warnings
- Informational messages
- User can still proceed

### Info State (Blue)
- Helpful hints
- Format suggestions
- Non-blocking information

## Accessibility Features

### ARIA Support
```tsx
<div
  role="alert" // For errors
  role="status" // For success/info
  aria-live="assertive" // For errors
  aria-live="polite" // For success/info
  aria-describedby="field-id-validation"
>
```

### Screen Reader Announcements
- Error messages announced immediately
- Success messages announced politely
- Loading states announced

### Keyboard Navigation
- Full keyboard support
- Focus management
- Tab order preserved

### Visual Indicators
- Color + icon (not color alone)
- Clear borders
- High contrast support

## Best Practices

### ✅ Do's

1. **Validate after blur** - Don't annoy users while typing
2. **Debounce validation** - Wait for user to stop typing
3. **Show success** - Positive feedback is good
4. **Clear messages** - Tell users what to fix
5. **Disable submit** - Prevent invalid submissions
6. **Show loading** - Indicate async validation
7. **Combine validators** - Reuse validation logic

### ❌ Don'ts

1. **Don't validate on every keystroke** - Too aggressive
2. **Don't show errors before blur** - Let users finish typing
3. **Don't use vague messages** - "Invalid input" is not helpful
4. **Don't rely on color alone** - Use icons too
5. **Don't forget async states** - Show loading indicators
6. **Don't validate on mount** - Unless explicitly needed
7. **Don't forget to clean up** - Cancel async operations

## Performance Tips

### Debouncing
```tsx
// Good - Debounced, validates after user stops typing
useValidation(value, {
  validate: validator,
  debounceMs: 500, // Wait 500ms
});

// Bad - Validates on every keystroke
useEffect(() => {
  validate(value); // No debounce!
}, [value]);
```

### Memoization
```tsx
// Memoize expensive validators
const validate = useCallback((value) => {
  // Expensive validation logic
  return result;
}, [/* dependencies */]);

useValidation(value, { validate });
```

### Async Cancellation
```tsx
// Built-in - Hook cancels pending validations
useEffect(() => {
  // Previous validation cancelled automatically
  const timer = setTimeout(validate, 500);
  return () => clearTimeout(timer);
}, [value]);
```

## Integration with React Hook Form

```tsx
import { useForm } from 'react-hook-form';
import { ValidationMessage } from '@/shared/components';

function Form() {
  const { register, formState: { errors } } = useForm();

  return (
    <div>
      <Input
        {...register('email', {
          required: 'Email is required',
          pattern: {
            value: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
            message: 'Invalid email format',
          },
        })}
      />
      {errors.email && (
        <ValidationMessage
          state="error"
          message={errors.email.message}
        />
      )}
    </div>
  );
}
```

## Testing Validation

### Unit Tests
```tsx
import { validators } from '@/shared/hooks/useValidation';

describe('validators', () => {
  it('validates required fields', () => {
    expect(validators.required('')).toEqual({
      isValid: false,
      message: 'This field is required',
      state: 'error',
    });
    
    expect(validators.required('value')).toEqual({
      isValid: true,
      state: 'success',
    });
  });
});
```

### Integration Tests
```tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('shows validation error after blur', async () => {
  render(<MyForm />);
  
  const input = screen.getByLabelText('Amount');
  await userEvent.type(input, '-100');
  await userEvent.tab(); // Trigger blur
  
  await waitFor(() => {
    expect(screen.getByText(/must be positive/i)).toBeInTheDocument();
  });
});
```

## Future Enhancements

- 🔄 Real-time validation toggle in settings
- 🌐 Localized validation messages
- 📊 Validation analytics
- 🎨 Custom validation message themes
- 🔌 Zod schema integration
- 📱 Mobile-optimized messages
- 🎯 Field-level validation strategies

## Resources

- [WCAG Form Validation](https://www.w3.org/WAI/WCAG21/Understanding/error-identification.html)
- [Inclusive Components - Forms](https://inclusive-components.design/a-todo-list/)
- [React Hook Form](https://react-hook-form.com/)
