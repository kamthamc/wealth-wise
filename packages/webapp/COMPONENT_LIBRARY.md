# Component Library Reference

A visual and technical reference for building consistent, accessible UI components.

---

## 🎨 Design Tokens

### Colors

```css
/* Primary - Teal (Trust & Professionalism) */
--color-primary-50: #e6f7f7;
--color-primary-100: #b3e6e6;
--color-primary-200: #80d5d5;
--color-primary-300: #4dc4c4;
--color-primary-400: #1ab3b3;
--color-primary-500: #00a0a0;  /* Main */
--color-primary-600: #008080;
--color-primary-700: #006060;
--color-primary-800: #004040;
--color-primary-900: #002020;

/* Success - Green */
--color-success-50: #e8f5e9;
--color-success-500: #4caf50;
--color-success-700: #2e7d32;

/* Warning - Amber */
--color-warning-50: #fff8e1;
--color-warning-500: #ffc107;
--color-warning-700: #f57c00;

/* Danger - Red */
--color-danger-50: #ffebee;
--color-danger-500: #f44336;
--color-danger-700: #c62828;

/* Info - Blue */
--color-info-50: #e3f2fd;
--color-info-500: #2196f3;
--color-info-700: #1565c0;

/* Neutral - Grays */
--color-gray-50: #fafafa;
--color-gray-100: #f5f5f5;
--color-gray-200: #eeeeee;
--color-gray-300: #e0e0e0;
--color-gray-400: #bdbdbd;
--color-gray-500: #9e9e9e;
--color-gray-600: #757575;
--color-gray-700: #616161;
--color-gray-800: #424242;
--color-gray-900: #212121;
```

### Typography

```css
/* Font Families */
--font-sans: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
--font-mono: 'JetBrains Mono', 'Fira Code', monospace;

/* Font Sizes (Fluid) */
--text-xs: clamp(0.75rem, 0.7rem + 0.25vw, 0.875rem);      /* 12-14px */
--text-sm: clamp(0.875rem, 0.8rem + 0.375vw, 1rem);        /* 14-16px */
--text-base: clamp(1rem, 0.95rem + 0.25vw, 1.125rem);      /* 16-18px */
--text-lg: clamp(1.125rem, 1rem + 0.625vw, 1.25rem);       /* 18-20px */
--text-xl: clamp(1.25rem, 1.1rem + 0.75vw, 1.5rem);        /* 20-24px */
--text-2xl: clamp(1.5rem, 1.3rem + 1vw, 2rem);             /* 24-32px */
--text-3xl: clamp(1.875rem, 1.6rem + 1.375vw, 2.5rem);     /* 30-40px */
--text-4xl: clamp(2.25rem, 1.9rem + 1.75vw, 3rem);         /* 36-48px */

/* Font Weights */
--font-light: 300;
--font-normal: 400;
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;

/* Line Heights */
--leading-tight: 1.25;
--leading-normal: 1.5;
--leading-relaxed: 1.75;

/* Letter Spacing */
--tracking-tight: -0.025em;
--tracking-normal: 0;
--tracking-wide: 0.025em;
```

### Spacing

```css
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-5: 1.25rem;   /* 20px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px */
--space-16: 4rem;     /* 64px */
--space-20: 5rem;     /* 80px */
--space-24: 6rem;     /* 96px */
```

### Border Radius

```css
--radius-sm: 0.25rem;   /* 4px */
--radius-md: 0.375rem;  /* 6px */
--radius-lg: 0.5rem;    /* 8px */
--radius-xl: 0.75rem;   /* 12px */
--radius-2xl: 1rem;     /* 16px */
--radius-full: 9999px;  /* Circular */
```

### Shadows

```css
--shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
--shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
--shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
--shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1);
--shadow-2xl: 0 25px 50px -12px rgb(0 0 0 / 0.25);
```

### Transitions

```css
--transition-fast: 150ms cubic-bezier(0.4, 0, 0.2, 1);
--transition-base: 200ms cubic-bezier(0.4, 0, 0.2, 1);
--transition-slow: 300ms cubic-bezier(0.4, 0, 0.2, 1);
```

---

## 🧩 Base Components

### Button

**Variants**: Primary, Secondary, Outline, Ghost, Danger  
**Sizes**: Small, Medium, Large  
**States**: Default, Hover, Focus, Active, Disabled, Loading

```typescript
// Button.tsx
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
  icon?: React.ReactNode
  iconPosition?: 'left' | 'right'
  fullWidth?: boolean
}

// Usage
<Button variant="primary" size="md" onClick={handleClick}>
  Save Transaction
</Button>

<Button variant="outline" icon={<Plus />} iconPosition="left">
  Add Account
</Button>

<Button variant="danger" loading>
  Deleting...
</Button>
```

**Accessibility Checklist**:
- ✅ Visible focus indicator (2px outline)
- ✅ Keyboard accessible (Enter/Space)
- ✅ ARIA labels for icon-only buttons
- ✅ Disabled state prevents interaction
- ✅ Loading state announces to screen readers
- ✅ Minimum touch target 44x44px

---

### Input

**Types**: Text, Email, Password, Number, Search  
**States**: Default, Focus, Error, Disabled

```typescript
// Input.tsx
interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
  helperText?: string
  leftIcon?: React.ReactNode
  rightIcon?: React.ReactNode
  fullWidth?: boolean
}

// Usage
<Input
  label="Account Name"
  type="text"
  placeholder="Enter account name"
  helperText="This will be displayed on your dashboard"
/>

<Input
  label="Email"
  type="email"
  error="Please enter a valid email"
  required
/>

<Input
  type="search"
  placeholder="Search transactions..."
  leftIcon={<Search />}
/>
```

**Accessibility Checklist**:
- ✅ Associated label with `htmlFor`
- ✅ Error messages with `aria-describedby`
- ✅ Required fields marked with `aria-required`
- ✅ Clear focus indicator
- ✅ Error state announced to screen readers
- ✅ Helper text visible and accessible

---

### Select

**States**: Default, Open, Focus, Error, Disabled

```typescript
// Select.tsx (Using Radix UI)
interface SelectProps {
  label?: string
  options: Array<{ value: string; label: string }>
  value?: string
  onChange?: (value: string) => void
  error?: string
  disabled?: boolean
  placeholder?: string
}

// Usage
<Select
  label="Account Type"
  options={[
    { value: 'bank', label: 'Bank Account' },
    { value: 'credit_card', label: 'Credit Card' },
    { value: 'investment', label: 'Investment' },
  ]}
  value={accountType}
  onChange={setAccountType}
  placeholder="Select account type"
/>
```

**Accessibility Checklist**:
- ✅ Keyboard navigation (Arrow keys, Enter, Esc)
- ✅ Search/filter functionality
- ✅ ARIA roles (combobox, listbox, option)
- ✅ Focus management
- ✅ Screen reader announcements

---

### Card

**Variants**: Default, Elevated, Outlined  
**Sections**: Header, Body, Footer

```typescript
// Card.tsx
interface CardProps {
  variant?: 'default' | 'elevated' | 'outlined'
  padding?: 'none' | 'sm' | 'md' | 'lg'
  children: React.ReactNode
  onClick?: () => void
  hoverable?: boolean
}

// CardHeader.tsx
interface CardHeaderProps {
  title: string
  subtitle?: string
  action?: React.ReactNode
}

// Usage
<Card variant="elevated" padding="md">
  <CardHeader
    title="Total Balance"
    subtitle="All accounts"
    action={<Button variant="ghost" icon={<MoreVertical />} />}
  />
  <CardBody>
    <p className={styles.amount}>$12,345.67</p>
  </CardBody>
  <CardFooter>
    <Button variant="outline" fullWidth>View Details</Button>
  </CardFooter>
</Card>
```

**Accessibility Checklist**:
- ✅ Semantic HTML structure
- ✅ Keyboard accessible if interactive
- ✅ Clear focus indicator for clickable cards
- ✅ Color contrast for text

---

### Modal/Dialog

**Sizes**: Small, Medium, Large, Full  
**States**: Open, Closed

```typescript
// Modal.tsx (Using Radix UI)
interface ModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  description?: string
  children: React.ReactNode
  size?: 'sm' | 'md' | 'lg' | 'full'
  footer?: React.ReactNode
}

// Usage
<Modal
  open={isOpen}
  onOpenChange={setIsOpen}
  title="Add New Transaction"
  description="Fill in the transaction details below"
  size="md"
  footer={
    <>
      <Button variant="outline" onClick={() => setIsOpen(false)}>
        Cancel
      </Button>
      <Button variant="primary" onClick={handleSave}>
        Save
      </Button>
    </>
  }
>
  <TransactionForm />
</Modal>
```

**Accessibility Checklist**:
- ✅ Focus trapped inside modal
- ✅ Close on Escape key
- ✅ Close on overlay click (optional)
- ✅ ARIA roles (dialog, alertdialog)
- ✅ Focus returns to trigger element on close
- ✅ Title announced by screen readers
- ✅ Scrollable content when needed

---

### Toast/Notification

**Types**: Success, Error, Warning, Info  
**Duration**: Auto-dismiss or persistent

```typescript
// Toast.tsx (Using Radix UI)
interface ToastProps {
  type: 'success' | 'error' | 'warning' | 'info'
  title: string
  description?: string
  action?: {
    label: string
    onClick: () => void
  }
  duration?: number
}

// Usage (via hook)
const { toast } = useToast()

toast({
  type: 'success',
  title: 'Transaction saved',
  description: 'Your transaction has been recorded',
  duration: 3000,
})

toast({
  type: 'error',
  title: 'Failed to save',
  description: 'Please try again',
  action: {
    label: 'Retry',
    onClick: handleRetry,
  },
})
```

**Accessibility Checklist**:
- ✅ ARIA live region (polite or assertive)
- ✅ Keyboard accessible actions
- ✅ Pause on hover (for auto-dismiss)
- ✅ Clear dismiss button
- ✅ Color + icon (not color alone)
- ✅ Sufficient contrast

---

### Table

**Features**: Sortable, Paginated, Responsive

```typescript
// Table.tsx
interface Column<T> {
  key: keyof T
  header: string
  sortable?: boolean
  render?: (value: T[keyof T], row: T) => React.ReactNode
}

interface TableProps<T> {
  data: T[]
  columns: Column<T>[]
  onSort?: (key: keyof T, direction: 'asc' | 'desc') => void
  loading?: boolean
  emptyMessage?: string
}

// Usage
<Table
  data={transactions}
  columns={[
    { key: 'date', header: 'Date', sortable: true },
    { key: 'description', header: 'Description' },
    { key: 'category', header: 'Category' },
    {
      key: 'amount',
      header: 'Amount',
      sortable: true,
      render: (amount) => formatCurrency(amount),
    },
  ]}
  onSort={handleSort}
/>
```

**Accessibility Checklist**:
- ✅ Semantic table markup
- ✅ Table caption or aria-label
- ✅ Column headers with scope
- ✅ Sortable columns announced
- ✅ Keyboard navigation
- ✅ Responsive (horizontal scroll or card layout)

---

## 🎯 Form Components

### Checkbox

```typescript
<Checkbox
  label="Remember me"
  checked={rememberMe}
  onChange={setRememberMe}
/>

<Checkbox
  label="I agree to the terms"
  required
  error="You must agree to continue"
/>
```

### Radio Group

```typescript
<RadioGroup
  label="Transaction Type"
  options={[
    { value: 'income', label: 'Income' },
    { value: 'expense', label: 'Expense' },
    { value: 'transfer', label: 'Transfer' },
  ]}
  value={type}
  onChange={setType}
/>
```

### Switch/Toggle

```typescript
<Switch
  label="Enable notifications"
  checked={notificationsEnabled}
  onChange={setNotificationsEnabled}
/>
```

### Date Picker

```typescript
<DatePicker
  label="Transaction Date"
  value={date}
  onChange={setDate}
  minDate={new Date('2020-01-01')}
  maxDate={new Date()}
/>
```

### Currency Input

```typescript
<CurrencyInput
  label="Amount"
  value={amount}
  onChange={setAmount}
  currency="USD"
  locale="en-US"
/>
```

---

## 🎨 Layout Components

### Container

```typescript
<Container maxWidth="lg" padding="md">
  {children}
</Container>
```

### Grid

```typescript
<Grid cols={3} gap={4} responsive>
  <Card>Item 1</Card>
  <Card>Item 2</Card>
  <Card>Item 3</Card>
</Grid>
```

### Stack

```typescript
<Stack direction="vertical" gap={4}>
  <Input label="Name" />
  <Input label="Email" />
  <Button>Submit</Button>
</Stack>
```

### Flex

```typescript
<Flex justify="space-between" align="center">
  <h1>Dashboard</h1>
  <Button icon={<Plus />}>Add Transaction</Button>
</Flex>
```

---

## 💡 Best Practices

### Accessibility Patterns

#### Focus Management
```typescript
// Trap focus in modal
const modalRef = useRef<HTMLDivElement>(null)
useFocusTrap(modalRef, isOpen)

// Return focus to trigger
useEffect(() => {
  if (!isOpen) {
    triggerRef.current?.focus()
  }
}, [isOpen])
```

#### Screen Reader Announcements
```typescript
// Live region for dynamic content
<div role="status" aria-live="polite" aria-atomic="true">
  {message}
</div>

// For urgent messages
<div role="alert" aria-live="assertive">
  {errorMessage}
</div>
```

#### Keyboard Navigation
```typescript
// Handle keyboard shortcuts
useEffect(() => {
  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'Escape') {
      closeModal()
    }
    if (e.key === '/' && (e.metaKey || e.ctrlKey)) {
      focusSearch()
    }
  }
  
  window.addEventListener('keydown', handleKeyDown)
  return () => window.removeEventListener('keydown', handleKeyDown)
}, [])
```

### Responsive Design Patterns

#### Container Queries (Preferred)
```css
.card {
  container-type: inline-size;
}

.card__content {
  display: grid;
  grid-template-columns: 1fr;
}

@container (min-width: 400px) {
  .card__content {
    grid-template-columns: 1fr 1fr;
  }
}
```

#### Media Queries (Global)
```css
.layout {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--space-4);
}

@media (min-width: 768px) {
  .layout {
    grid-template-columns: 250px 1fr;
  }
}

@media (min-width: 1024px) {
  .layout {
    grid-template-columns: 280px 1fr 320px;
  }
}
```

### Performance Patterns

#### Code Splitting
```typescript
// Lazy load components
const Dashboard = lazy(() => import('./features/dashboard'))
const Transactions = lazy(() => import('./features/transactions'))

// Use with Suspense
<Suspense fallback={<LoadingSpinner />}>
  <Dashboard />
</Suspense>
```

#### Virtual Scrolling
```typescript
// For long lists
import { useVirtualizer } from '@tanstack/react-virtual'

const virtualizer = useVirtualizer({
  count: transactions.length,
  getScrollElement: () => parentRef.current,
  estimateSize: () => 50,
})
```

#### Memoization
```typescript
// Expensive calculations
const totalBalance = useMemo(() => {
  return accounts.reduce((sum, account) => sum + account.balance, 0)
}, [accounts])

// Callbacks
const handleSort = useCallback((key: string) => {
  setSortKey(key)
  setSortDirection(prev => prev === 'asc' ? 'desc' : 'asc')
}, [])
```

---

## 🎭 Animation Patterns

### Respect User Preferences
```css
@media (prefers-reduced-motion: no-preference) {
  .button {
    transition: background-color var(--transition-base);
  }
  
  .modal {
    animation: slideIn var(--transition-slow);
  }
}

@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

### Common Animations
```css
@keyframes slideIn {
  from {
    transform: translateY(100%);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
```

---

## 🌓 Dark Mode Pattern

```css
/* tokens.css */
:root {
  --bg-primary: #ffffff;
  --bg-secondary: #f5f5f5;
  --text-primary: #212121;
  --text-secondary: #616161;
  --border: #e0e0e0;
}

[data-theme="dark"] {
  --bg-primary: #1a1a1a;
  --bg-secondary: #2a2a2a;
  --text-primary: #ffffff;
  --text-secondary: #b0b0b0;
  --border: #404040;
}

/* Respect system preference */
@media (prefers-color-scheme: dark) {
  :root {
    --bg-primary: #1a1a1a;
    --bg-secondary: #2a2a2a;
    --text-primary: #ffffff;
    --text-secondary: #b0b0b0;
    --border: #404040;
  }
}
```

---

## 📱 Mobile Patterns

### Touch Targets
```css
/* Minimum 44x44px touch target */
.button {
  min-height: 44px;
  min-width: 44px;
  padding: var(--space-3) var(--space-6);
}
```

### Mobile Navigation
```typescript
// Hamburger menu for mobile
const [isMenuOpen, setIsMenuOpen] = useState(false)

<button
  className={styles.hamburger}
  onClick={() => setIsMenuOpen(!isMenuOpen)}
  aria-label="Toggle menu"
  aria-expanded={isMenuOpen}
>
  <Menu />
</button>

<nav
  className={styles.mobileNav}
  data-open={isMenuOpen}
  aria-hidden={!isMenuOpen}
>
  {/* Navigation items */}
</nav>
```

---

## ✅ Component Checklist

Before marking a component as complete, ensure:

- [ ] **Functionality**
  - [ ] Component works as expected
  - [ ] All props are implemented
  - [ ] Default props are set
  - [ ] Error handling is in place

- [ ] **Accessibility**
  - [ ] Keyboard accessible
  - [ ] Screen reader compatible
  - [ ] ARIA attributes where needed
  - [ ] Focus management
  - [ ] Color contrast meets WCAG AA
  - [ ] Touch targets minimum 44x44px

- [ ] **Responsive**
  - [ ] Works on mobile (320px+)
  - [ ] Works on tablet (768px+)
  - [ ] Works on desktop (1024px+)
  - [ ] Text is readable at all sizes
  - [ ] No horizontal scrolling

- [ ] **Performance**
  - [ ] No unnecessary re-renders
  - [ ] Memoization where appropriate
  - [ ] Lazy loading if applicable
  - [ ] Optimized bundle size

- [ ] **Code Quality**
  - [ ] TypeScript types defined
  - [ ] Props interface documented
  - [ ] Complex logic commented
  - [ ] No linting errors
  - [ ] Formatted with Biome

- [ ] **Testing**
  - [ ] Unit tests written
  - [ ] Accessibility tests pass
  - [ ] Visual regression tests (if applicable)
  - [ ] Edge cases covered

- [ ] **Documentation**
  - [ ] Usage examples provided
  - [ ] Props documented
  - [ ] Accessibility notes included
  - [ ] Examples in Storybook (if using)

---

**Ready to build amazing, accessible components! 🎨**
