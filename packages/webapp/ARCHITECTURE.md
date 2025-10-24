# WealthWise Web Application Architecture

## Overview
Local-first progressive web application built with React 19.2, focusing on accessibility, performance, and future scalability.

## Technology Stack

### Core Framework
- **React 19.2** - Latest features including automatic batching, transitions, and server components support
- **TypeScript 5.7+** - Type safety and better developer experience
- **Vite 6+** - Fast build tool with HMR and optimized production builds

### Code Quality & Formatting
- **Biome** - Fast, all-in-one toolchain for linting, formatting, and more
  - Replaces ESLint + Prettier with better performance
  - Built-in TypeScript support
  - Zero configuration needed

### Database Layer (Local-First)
**Recommended: PGlite + Electric SQL** (Future-proof choice)
- **PGlite** - Lightweight PostgreSQL compiled to WASM
  - Full PostgreSQL compatibility
  - Runs entirely in the browser
  - Easy migration path to server-side PostgreSQL
  - Better for complex queries and data relationships
  - ~3MB bundle size

**Alternative Options:**
- **IndexedDB with Dexie.js** - Simpler option
  - Native browser API with better wrapper
  - Good for simpler data structures
  - Proven track record
  
- **SQLite WASM (sql.js)** - Middle ground
  - SQL familiarity
  - Good performance
  - Smaller bundle size (~1MB)

**Not Recommended for Local-First:**
- Firebase - Requires internet, not truly local-first
- Better for sync layer if needed later

### State Management
- **Zustand** - Lightweight, modern state management
  - Simple API, minimal boilerplate
  - Built-in TypeScript support
  - Middleware for persistence, DevTools
  - Better than Context API for complex state

### Routing
- **TanStack Router (React Router v7)** - Type-safe routing
  - Full TypeScript support
  - Nested layouts
  - Data loading patterns
  - Better DX than React Router v6

### UI & Styling

#### CSS Architecture
- **CSS Modules + Modern CSS** - Primary approach
  - Native CSS with Container Queries
  - CSS Grid, Subgrid, Flexbox
  - CSS Custom Properties for theming
  - No runtime overhead

#### Component Library (Accessible & Finance-Friendly)
- **Radix UI Primitives** - Unstyled, accessible components
  - WAI-ARIA compliant
  - Keyboard navigation
  - Focus management
  - Screen reader support
  
#### Icons
- **Lucide React** - Modern, consistent icon set
  - Tree-shakeable
  - Accessible by default
  - Finance-specific icons available

#### Design Tokens
- Custom design system with finance-appropriate colors:
  - Success: Green shades (growth, positive)
  - Warning: Amber (caution, alerts)
  - Danger: Red (losses, critical)
  - Info: Blue (neutral information)
  - Accent: Teal/Purple (professional, trustworthy)

### Form Management
- **React Hook Form v7** - Performant form handling
  - Minimal re-renders
  - Built-in validation
  - Accessibility support

### Data Visualization
- **Recharts** - Accessible charts for financial data
  - Built on D3
  - Accessible by default
  - Responsive
  - Good documentation

### Date/Time Handling
- **Temporal API (Polyfill)** - Modern date/time handling
  - Or **date-fns** as fallback
  - Locale-aware
  - Timezone support

### Testing
- **Vitest** - Fast unit testing (Vite-native)
- **Testing Library (React)** - Component testing
- **Playwright** - E2E testing with accessibility audits

### Accessibility Tools
- **axe-core** - Automated accessibility testing
- **react-aria** - Accessible component behaviors (if needed beyond Radix)

## Project Structure

```
webapp/
├── public/                      # Static assets
│   ├── manifest.json           # PWA manifest
│   ├── robots.txt
│   └── icons/                  # App icons
├── src/
│   ├── app/                    # Application root
│   │   ├── App.tsx
│   │   ├── App.module.css
│   │   └── providers/          # Context providers
│   ├── features/               # Feature-based modules
│   │   ├── dashboard/
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   ├── services/
│   │   │   ├── stores/
│   │   │   ├── types/
│   │   │   └── index.ts
│   │   ├── accounts/
│   │   ├── transactions/
│   │   ├── goals/
│   │   ├── reports/
│   │   └── settings/
│   ├── shared/                 # Shared across features
│   │   ├── components/         # Reusable UI components
│   │   │   ├── Button/
│   │   │   ├── Card/
│   │   │   ├── Input/
│   │   │   └── ...
│   │   ├── layouts/            # Layout components
│   │   │   ├── MainLayout/
│   │   │   ├── AuthLayout/
│   │   │   └── DashboardLayout/
│   │   ├── hooks/              # Custom hooks
│   │   ├── utils/              # Utility functions
│   │   ├── constants/          # App constants
│   │   └── types/              # Shared TypeScript types
│   ├── core/                   # Core functionality
│   │   ├── db/                 # Database layer
│   │   │   ├── client.ts       # DB client setup
│   │   │   ├── schema.ts       # Database schema
│   │   │   ├── migrations/     # DB migrations
│   │   │   └── queries/        # Reusable queries
│   │   ├── router/             # Routing configuration
│   │   ├── i18n/               # Internationalization
│   │   └── api/                # API clients (future sync)
│   ├── styles/                 # Global styles
│   │   ├── tokens.css          # Design tokens
│   │   ├── reset.css           # CSS reset
│   │   ├── globals.css         # Global styles
│   │   └── themes/             # Theme definitions
│   ├── assets/                 # Images, fonts, etc.
│   └── main.tsx                # Application entry
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── .github/
│   └── workflows/              # CI/CD pipelines
├── biome.json                  # Biome configuration
├── tsconfig.json               # TypeScript config
├── vite.config.ts              # Vite configuration
├── vitest.config.ts            # Vitest configuration
├── playwright.config.ts        # Playwright config
├── package.json
└── README.md
```

## Core Principles

### 1. Local-First Architecture
- All data operations work offline
- Immediate UI feedback (optimistic updates)
- Background sync when online (future phase)
- Conflict resolution strategies (CRDTs or last-write-wins)

### 2. Accessibility (WCAG 2.2 AA Compliance)
- Semantic HTML
- Keyboard navigation for all interactions
- Screen reader support (ARIA labels, live regions)
- Focus management and visible focus indicators
- Skip navigation links
- Color contrast ratios (4.5:1 for text, 3:1 for UI)
- Reduced motion support (`prefers-reduced-motion`)
- High contrast mode support (`prefers-contrast`)
- Text resizing up to 200%
- Touch target size minimum 44x44px

### 3. Responsive Design (Mobile-First)
- Desktop: 1024px+ (primary target)
- Tablet: 768px-1023px
- Mobile: 320px-767px
- Container queries for component-level responsiveness
- Fluid typography using `clamp()`
- Responsive images with `srcset` and `sizes`

### 4. Performance
- Code splitting by route and feature
- Lazy loading for below-fold content
- Virtual scrolling for large lists
- Image optimization (WebP, AVIF)
- Service Worker for offline support
- Lighthouse score target: 90+

### 5. Security
- Content Security Policy (CSP)
- Sanitize user inputs
- Secure data storage (encrypted IndexedDB/PGlite)
- No sensitive data in localStorage
- HTTPS only
- Subresource Integrity (SRI) for CDN resources

### 6. User Preferences
- System theme detection (`prefers-color-scheme`)
- Manual theme override (light/dark/system)
- Respect `prefers-reduced-motion`
- Respect `prefers-contrast`
- Respect `prefers-reduced-transparency`
- Font size preferences
- Language preferences

## Database Schema (Initial)

### Core Entities
```typescript
// Users (for multi-user support later)
interface User {
  id: string;
  name: string;
  email: string;
  preferences: UserPreferences;
  createdAt: Date;
  updatedAt: Date;
}

// Accounts
interface Account {
  id: string;
  userId: string;
  name: string;
  type: 'bank' | 'credit_card' | 'investment' | 'cash' | 'loan';
  currency: string;
  balance: number;
  institution?: string;
  accountNumber?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// Transactions
interface Transaction {
  id: string;
  accountId: string;
  userId: string;
  type: 'income' | 'expense' | 'transfer';
  amount: number;
  currency: string;
  category: string;
  subcategory?: string;
  description: string;
  date: Date;
  payee?: string;
  tags: string[];
  isRecurring: boolean;
  recurringId?: string;
  attachments?: string[];
  createdAt: Date;
  updatedAt: Date;
}

// Goals
interface Goal {
  id: string;
  userId: string;
  name: string;
  type: 'savings' | 'investment' | 'debt_payoff' | 'custom';
  targetAmount: number;
  currentAmount: number;
  currency: string;
  targetDate: Date;
  priority: 'low' | 'medium' | 'high';
  linkedAccountId?: string;
  isCompleted: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// Budgets
interface Budget {
  id: string;
  userId: string;
  name: string;
  period: 'weekly' | 'monthly' | 'yearly';
  categories: BudgetCategory[];
  startDate: Date;
  endDate?: Date;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

interface BudgetCategory {
  category: string;
  allocated: number;
  spent: number;
  currency: string;
}
```

## Design System

### Color Palette (Finance-Appropriate)

```css
/* Primary Colors - Trust & Professionalism */
--color-primary-50: #e6f7f7;
--color-primary-100: #b3e6e6;
--color-primary-500: #00a0a0;  /* Teal - Primary brand */
--color-primary-600: #008080;
--color-primary-900: #004040;

/* Success - Growth & Positive */
--color-success-50: #e8f5e9;
--color-success-500: #4caf50;
--color-success-700: #2e7d32;

/* Warning - Caution */
--color-warning-50: #fff8e1;
--color-warning-500: #ffc107;
--color-warning-700: #f57c00;

/* Danger - Losses & Critical */
--color-danger-50: #ffebee;
--color-danger-500: #f44336;
--color-danger-700: #c62828;

/* Info - Neutral Information */
--color-info-50: #e3f2fd;
--color-info-500: #2196f3;
--color-info-700: #1565c0;

/* Neutral - Backgrounds & Text */
--color-gray-50: #fafafa;
--color-gray-100: #f5f5f5;
--color-gray-200: #eeeeee;
--color-gray-300: #e0e0e0;
--color-gray-500: #9e9e9e;
--color-gray-700: #616161;
--color-gray-900: #212121;

/* Semantic Colors */
--color-income: var(--color-success-500);
--color-expense: var(--color-danger-500);
--color-transfer: var(--color-info-500);
--color-investment: var(--color-primary-500);
```

### Typography
```css
/* Font Families */
--font-sans: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
--font-mono: 'JetBrains Mono', 'Fira Code', monospace;

/* Font Sizes (Fluid) */
--text-xs: clamp(0.75rem, 0.7rem + 0.25vw, 0.875rem);
--text-sm: clamp(0.875rem, 0.8rem + 0.375vw, 1rem);
--text-base: clamp(1rem, 0.95rem + 0.25vw, 1.125rem);
--text-lg: clamp(1.125rem, 1rem + 0.625vw, 1.25rem);
--text-xl: clamp(1.25rem, 1.1rem + 0.75vw, 1.5rem);
--text-2xl: clamp(1.5rem, 1.3rem + 1vw, 2rem);
--text-3xl: clamp(1.875rem, 1.6rem + 1.375vw, 2.5rem);
--text-4xl: clamp(2.25rem, 1.9rem + 1.75vw, 3rem);

/* Line Heights */
--leading-tight: 1.25;
--leading-normal: 1.5;
--leading-relaxed: 1.75;
```

### Spacing Scale
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
```

## Accessibility Features

### Keyboard Navigation
- Tab order follows visual order
- Skip to main content link
- Focus visible indicators (2px outline)
- Escape to close modals/menus
- Arrow keys for menu navigation
- Enter/Space for button activation

### Screen Reader Support
- Semantic HTML elements
- ARIA labels for icon buttons
- ARIA live regions for dynamic content
- ARIA expanded/collapsed states
- Descriptive link text
- Form field labels and descriptions

### Visual Accessibility
- Minimum contrast ratio 4.5:1
- Focus indicators visible in all themes
- No information conveyed by color alone
- Text resizable up to 200%
- No horizontal scrolling at 320px width
- Touch targets minimum 44x44px

## Progressive Web App (PWA)

### Features
- Install to home screen
- Offline functionality
- Background sync (when online)
- Push notifications (optional)
- App-like experience

### Service Worker Strategy
- Cache-first for static assets
- Network-first for API calls
- Stale-while-revalidate for data

## Development Workflow

### Local Development
```bash
npm run dev          # Start dev server
npm run build        # Production build
npm run preview      # Preview production build
npm run lint         # Run Biome linter
npm run format       # Format code with Biome
npm run typecheck    # TypeScript type checking
npm run test         # Run unit tests
npm run test:e2e     # Run E2E tests
npm run a11y         # Accessibility audit
```

### Git Workflow
- Main branch: `main`
- Feature branches: `feature/feature-name`
- Commit messages: Conventional Commits
- Pre-commit hooks: lint, format, typecheck

## Performance Targets

- **First Contentful Paint (FCP)**: < 1.5s
- **Largest Contentful Paint (LCP)**: < 2.5s
- **Time to Interactive (TTI)**: < 3.5s
- **Cumulative Layout Shift (CLS)**: < 0.1
- **First Input Delay (FID)**: < 100ms
- **Bundle size**: < 200KB initial (gzipped)

## Browser Support

- **Chrome/Edge**: Last 2 versions
- **Firefox**: Last 2 versions
- **Safari**: Last 2 versions
- **Mobile Safari**: iOS 15+
- **Chrome Android**: Last 2 versions

## Future Enhancements

### Phase 2
- Multi-user support
- Real-time sync across devices
- Cloud backup
- Import/Export functionality
- Receipt OCR scanning
- Financial insights with AI

### Phase 3
- Mobile native apps (React Native)
- Bank account integration
- Investment tracking
- Tax reporting
- Budget forecasting
- Collaborative budgets

## Security Considerations

### Data Encryption
- Encrypt sensitive data at rest
- Use Web Crypto API for encryption
- Secure key management
- No plaintext passwords

### Privacy
- No tracking/analytics without consent
- GDPR compliant
- Data export functionality
- Clear data deletion

### Input Validation
- Sanitize all user inputs
- Validate on client and server (future)
- Prevent XSS attacks
- SQL injection prevention (prepared statements)

## Testing Strategy

### Unit Tests (80% coverage target)
- Utility functions
- Custom hooks
- Business logic
- Data transformations

### Integration Tests
- Feature workflows
- Database operations
- State management
- Form submissions

### E2E Tests
- Critical user journeys
- Dashboard viewing
- Transaction creation
- Goal management
- Report generation

### Accessibility Tests
- Automated: axe-core, Lighthouse
- Manual: Screen reader testing
- Keyboard navigation testing
- Color contrast validation

## Deployment

### Static Hosting Options
- Vercel (recommended - best DX)
- Netlify
- Cloudflare Pages
- GitHub Pages

### CI/CD Pipeline
- Automated testing
- Lighthouse CI
- Accessibility audits
- Bundle size monitoring
- Automated deployment

## Documentation

### Required Documentation
- Setup guide (README)
- Architecture overview (this document)
- Component documentation (Storybook)
- API documentation (if applicable)
- Contribution guidelines
- Accessibility guidelines

## Conclusion

This architecture provides a solid foundation for a modern, accessible, high-performance local-first web application. The tech stack is chosen for:

1. **Developer Experience**: TypeScript, Vite, Biome, React 19.2
2. **User Experience**: Fast, accessible, offline-capable
3. **Scalability**: PGlite allows easy migration to PostgreSQL
4. **Maintainability**: Feature-based structure, TypeScript, testing
5. **Future-Proof**: Modern standards, PWA, easy to extend

The focus on accessibility, performance, and local-first principles ensures a high-quality product that works for all users, regardless of their abilities or network conditions.
