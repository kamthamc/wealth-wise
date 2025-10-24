# 🚀 WealthWise Web App - Quick Reference Card

> **One-page overview for rapid development**

---

## 📦 Essential Commands

```bash
# Setup
npm create vite@latest . -- --template react-ts
npm install
npm run dev

# Development
npm run dev          # Start dev server (localhost:3000)
npm run typecheck    # Type checking
npm run lint         # Lint code
npm run format       # Format code
npm run check        # All checks (typecheck + lint + test)

# Testing
npm run test         # Unit tests (watch mode)
npm run test:e2e     # E2E tests
npm run test:coverage # Coverage report

# Build
npm run build        # Production build
npm run preview      # Preview build
```

---

## 🎯 Current Phase

**Phase 0: Project Setup** (1-2 days)

- [ ] Initialize Vite + React + TypeScript
- [ ] Install dependencies
- [ ] Configure Biome, TypeScript, Vite
- [ ] Set up testing (Vitest, Playwright)
- [ ] Create project structure

**Next**: Phase 1 - Core Infrastructure

---

## 🛠️ Tech Stack (Quick Ref)

| Category | Technology | Why? |
|----------|------------|------|
| Framework | React 19.2 | Latest features |
| Language | TypeScript 5.7+ | Type safety |
| Build | Vite 6 | Fast HMR |
| Linter | Biome | All-in-one tool |
| Database | PGlite | PostgreSQL in browser |
| State | Zustand | Simple, lightweight |
| Router | TanStack Router | Type-safe |
| UI | Radix UI | Accessible primitives |
| Forms | React Hook Form + Zod | Performant |
| Icons | Lucide React | Modern, tree-shakeable |
| Charts | Recharts | React-friendly |
| Testing | Vitest + Playwright | Fast, modern |

---

## 🎨 Design Tokens (Copy-Paste Ready)

```css
/* Colors */
--color-primary-500: #00a0a0;  /* Teal - Main brand */
--color-success-500: #4caf50;  /* Green - Positive */
--color-warning-500: #ffc107;  /* Amber - Caution */
--color-danger-500: #f44336;   /* Red - Critical */
--color-info-500: #2196f3;     /* Blue - Info */

/* Typography */
--font-sans: 'Inter', -apple-system, sans-serif;
--text-base: clamp(1rem, 0.95rem + 0.25vw, 1.125rem);

/* Spacing */
--space-4: 1rem;    /* 16px - base unit */
--space-8: 2rem;    /* 32px - large */

/* Border & Shadow */
--radius-md: 0.375rem;
--shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);

/* Transitions */
--transition-base: 200ms cubic-bezier(0.4, 0, 0.2, 1);
```

---

## 📁 Folder Structure (Quick Create)

```bash
mkdir -p src/{app,features,shared,core,styles,assets}
mkdir -p src/shared/{components,hooks,utils,types}
mkdir -p src/core/{db,router,i18n}
mkdir -p src/features/{dashboard,accounts,transactions,goals,budgets}
mkdir -p tests/{unit,integration,e2e}
```

---

## ⚡ Component Template (Copy-Paste)

```typescript
// Button.tsx
import { ButtonHTMLAttributes, forwardRef } from 'react'
import styles from './Button.module.css'
import clsx from 'clsx'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline'
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'md', loading, children, className, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={clsx(
          styles.button,
          styles[variant],
          styles[size],
          loading && styles.loading,
          className
        )}
        disabled={loading || props.disabled}
        {...props}
      >
        {loading ? 'Loading...' : children}
      </button>
    )
  }
)

Button.displayName = 'Button'
```

```css
/* Button.module.css */
.button {
  padding: var(--space-3) var(--space-6);
  border-radius: var(--radius-md);
  font-weight: var(--font-medium);
  transition: all var(--transition-base);
  cursor: pointer;
  border: none;
}

.button:focus-visible {
  outline: 2px solid var(--color-primary-500);
  outline-offset: 2px;
}

.primary {
  background: var(--color-primary-500);
  color: white;
}

.primary:hover {
  background: var(--color-primary-600);
}

.sm {
  padding: var(--space-2) var(--space-4);
  font-size: var(--text-sm);
}
```

---

## ✅ Component Checklist (Quick)

Before completing any component:

- [ ] Works functionally
- [ ] Keyboard accessible (Tab, Enter, Esc)
- [ ] Screen reader compatible
- [ ] Focus indicator visible
- [ ] Responsive (320px+)
- [ ] Color contrast 4.5:1
- [ ] Touch target 44x44px
- [ ] TypeScript types defined
- [ ] Tests written
- [ ] No linting errors

---

## 🎯 Priority Tasks (MVP)

### Phase 0-1 (Week 1)
1. Project setup
2. Design tokens
3. Database setup
4. Basic routing

### Phase 2 (Week 2-3)
1. Button, Input, Card
2. Modal, Toast
3. Form components

### Phase 3-5 (Week 4-7)
1. Dashboard
2. Accounts CRUD
3. Transactions CRUD
4. Basic reports

**Minimum Viable Product**: Phases 0-5

---

## 🐛 Common Issues & Fixes

### Port Already in Use
```bash
lsof -ti:3000 | xargs kill -9
```

### Module Not Found
```bash
rm -rf node_modules package-lock.json
npm install
```

### TypeScript Errors
```bash
npm run typecheck
# Check tsconfig.json paths
```

### Import Path Issues
```typescript
// Use @ alias (configured in vite.config.ts)
import { Button } from '@/shared/components/Button'
```

---

## 🔥 Hot Tips

### 1. Use TypeScript Strictly
```typescript
// ❌ Bad
const data: any = fetchData()

// ✅ Good
interface Data {
  id: string
  name: string
}
const data: Data = fetchData()
```

### 2. Accessibility From Start
```typescript
// Always include ARIA labels for icon buttons
<button aria-label="Close modal">
  <X />
</button>
```

### 3. Responsive Design
```css
/* Mobile-first approach */
.container {
  padding: var(--space-4);
}

@media (min-width: 768px) {
  .container {
    padding: var(--space-8);
  }
}
```

### 4. Performance
```typescript
// Lazy load routes
const Dashboard = lazy(() => import('./features/dashboard'))

// Memoize expensive calculations
const total = useMemo(() => 
  transactions.reduce((sum, t) => sum + t.amount, 0),
  [transactions]
)
```

### 5. Testing
```typescript
// Test accessibility
import { axe } from 'jest-axe'

it('has no accessibility violations', async () => {
  const { container } = render(<Button>Click me</Button>)
  const results = await axe(container)
  expect(results).toHaveNoViolations()
})
```

---

## 📊 Development Metrics

Track these as you build:

- **Bundle Size**: < 200KB (initial, gzipped)
- **Lighthouse Score**: 90+ (all categories)
- **Test Coverage**: 80%+
- **Build Time**: < 30 seconds
- **Hot Reload**: < 1 second

---

## 🎓 Learn As You Go

### Essential Reading (In Order)
1. React 19 Docs - New features
2. TypeScript Handbook - Type system
3. Vite Guide - Build concepts
4. Radix UI Docs - Accessible patterns
5. WCAG 2.2 Quick Reference - Accessibility

### Practice Daily
- Write tests first (TDD)
- Use semantic HTML
- Check keyboard navigation
- Test with screen reader
- Validate color contrast

---

## 🌟 Quality Gates

Before committing:
```bash
npm run typecheck  # No TS errors
npm run lint       # No lint errors
npm run test       # All tests pass
```

Before pushing:
```bash
npm run check      # All checks pass
```

Before PR:
- All acceptance criteria met
- Tests written and passing
- Accessibility validated
- Performance tested
- Documentation updated

---

## 🚀 Daily Workflow

### Morning
1. `git pull origin main`
2. `npm install` (if package.json changed)
3. `npm run dev`
4. Pick task from roadmap

### During Development
1. Write feature
2. Write tests
3. Check accessibility
4. Test responsiveness
5. `npm run check`

### End of Day
1. `npm run check`
2. `git add .`
3. `git commit -m "feat: ..."`
4. `git push`

---

## 📞 Quick Links

- 📖 [Full Architecture](ARCHITECTURE.md)
- 🗺️ [Implementation Roadmap](IMPLEMENTATION_ROADMAP.md)
- 🎨 [Component Library](COMPONENT_LIBRARY.md)
- 🛠️ [Tech Stack Details](TECH_STACK.md)
- 🚀 [Setup Guide](QUICK_START.md)
- 📋 [Documentation Index](INDEX.md)

---

## 💡 Remember

> **Build for accessibility from day one - it's easier than retrofitting**

> **Test continuously - don't leave testing for the end**

> **Keep it simple - solve today's problems, not tomorrow's**

> **Document as you go - future you will thank present you**

---

**Print this. Pin it. Reference it daily. 📌**

**Now go build! 🚀**
