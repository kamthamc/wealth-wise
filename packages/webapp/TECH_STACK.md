# Technology Stack - Detailed Decision Guide

## Database Selection - Local-First Options

### Option 1: PGlite (Recommended) ⭐
**PostgreSQL in the browser via WebAssembly**

#### Pros
✅ Full PostgreSQL compatibility - Standard SQL  
✅ Easy migration path to server-side PostgreSQL later  
✅ Powerful query capabilities (JOINs, aggregations, CTEs)  
✅ ACID transactions  
✅ Advanced features: JSON support, full-text search, indexes  
✅ Familiar to developers who know PostgreSQL  
✅ Type-safe with pg-typed or similar tools  
✅ Great for complex data relationships  

#### Cons
❌ Larger bundle size (~3MB)  
❌ Newer technology (less battle-tested)  
❌ Learning curve if unfamiliar with PostgreSQL  
❌ Memory usage can be higher  

#### When to Choose
- You anticipate complex queries and data relationships
- You want easy migration to server-side database
- You're comfortable with SQL
- Bundle size is acceptable for your use case
- You want a professional, scalable solution

#### Setup Example
```bash
npm install @electric-sql/pglite
```

```typescript
import { PGlite } from '@electric-sql/pglite'

// Initialize database
const db = new PGlite()

// Create tables
await db.exec(`
  CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    balance DECIMAL(15,2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
  )
`)

// Query with type safety
const accounts = await db.query<Account>(
  'SELECT * FROM accounts WHERE type = $1',
  ['bank']
)
```

---

### Option 2: Dexie.js (IndexedDB Wrapper) 🔄
**Modern wrapper around browser's native IndexedDB**

#### Pros
✅ Smaller bundle size (~50KB)  
✅ Built on native browser API (IndexedDB)  
✅ Excellent performance  
✅ Well-established and battle-tested  
✅ Great TypeScript support  
✅ Reactive queries (live queries)  
✅ Easy to learn  
✅ Lower memory usage  

#### Cons
❌ NoSQL-style querying (less powerful than SQL)  
❌ More complex for relational data  
❌ Manual index management  
❌ Harder to migrate to server-side database  
❌ Limited query capabilities (no JOINs)  

#### When to Choose
- You want the smallest bundle size
- Your data model is simple (fewer relationships)
- You prefer NoSQL-style querying
- You want maximum browser compatibility
- You don't plan to add a server backend soon

#### Setup Example
```bash
npm install dexie
```

```typescript
import Dexie, { Table } from 'dexie'

class WealthWiseDB extends Dexie {
  accounts!: Table<Account>
  transactions!: Table<Transaction>

  constructor() {
    super('WealthWiseDB')
    this.version(1).stores({
      accounts: '++id, name, type, createdAt',
      transactions: '++id, accountId, date, amount, category'
    })
  }
}

const db = new WealthWiseDB()

// Query
const bankAccounts = await db.accounts
  .where('type')
  .equals('bank')
  .toArray()
```

---

### Option 3: SQLite WASM (sql.js) 🔄
**SQLite database compiled to WebAssembly**

#### Pros
✅ Standard SQL (similar to PostgreSQL)  
✅ Smaller than PGlite (~1-2MB)  
✅ Familiar to many developers  
✅ Good query capabilities  
✅ ACID transactions  
✅ Widely used and stable  

#### Cons
❌ In-memory by default (requires manual persistence)  
❌ Must export/import for persistence  
❌ Migration to server requires SQLite on backend  
❌ Less advanced features than PostgreSQL  
❌ Performance can be slower for large datasets  

#### When to Choose
- You want SQL but with smaller bundle size than PGlite
- You're familiar with SQLite
- You can manage manual persistence
- You want a middle ground between Dexie and PGlite

---

### Comparison Table

| Feature | PGlite | Dexie.js | SQLite WASM |
|---------|--------|----------|-------------|
| Bundle Size | ~3MB | ~50KB | ~1-2MB |
| Query Language | PostgreSQL | NoSQL-style | SQLite SQL |
| Learning Curve | Medium | Low | Low |
| Complex Queries | Excellent | Limited | Good |
| Persistence | Automatic | Automatic | Manual |
| Server Migration | Easy | Hard | Medium |
| TypeScript | Excellent | Excellent | Good |
| Performance | Excellent | Excellent | Good |
| Maturity | New | Mature | Mature |

### **Recommendation: PGlite**

For WealthWise, I recommend **PGlite** because:

1. **Complex financial data** - Accounts, transactions, budgets, goals have many relationships
2. **Future scalability** - Easy to add PostgreSQL backend later for sync
3. **Powerful queries** - Financial reports need aggregations, JOINs, date ranges
4. **Professional solution** - Better for a serious finance app
5. **Bundle size acceptable** - 3MB is reasonable for a desktop-first finance app

---

## UI Component Library

### Radix UI (Recommended) ⭐

#### Why Radix UI?
✅ **Unstyled primitives** - Full control over design  
✅ **Accessibility built-in** - WAI-ARIA compliant  
✅ **Composable** - Build complex components easily  
✅ **Tree-shakeable** - Only import what you use  
✅ **TypeScript** - Excellent type support  
✅ **No runtime styles** - Use CSS Modules or your choice  
✅ **Well-documented** - Great examples and API docs  

#### Components to Use
```bash
npm install @radix-ui/react-dialog
npm install @radix-ui/react-dropdown-menu
npm install @radix-ui/react-select
npm install @radix-ui/react-tooltip
npm install @radix-ui/react-switch
npm install @radix-ui/react-checkbox
npm install @radix-ui/react-radio-group
npm install @radix-ui/react-tabs
npm install @radix-ui/react-popover
npm install @radix-ui/react-toast
```

### Alternative: Headless UI
Good alternative if you prefer Tailwind CSS, but Radix has better TypeScript support.

---

## State Management

### Zustand (Recommended) ⭐

#### Why Zustand?
✅ **Minimal boilerplate** - Simple API  
✅ **Small bundle** - ~1KB  
✅ **No providers needed** - Use anywhere  
✅ **TypeScript first** - Excellent types  
✅ **DevTools** - Redux DevTools integration  
✅ **Middleware** - Persistence, immer, devtools  
✅ **Simple to learn** - Just hooks  

```bash
npm install zustand
```

```typescript
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface UserStore {
  theme: 'light' | 'dark' | 'system'
  setTheme: (theme: 'light' | 'dark' | 'system') => void
}

export const useUserStore = create<UserStore>()(
  persist(
    (set) => ({
      theme: 'system',
      setTheme: (theme) => set({ theme })
    }),
    { name: 'user-preferences' }
  )
)
```

### Why Not Redux?
- Too much boilerplate
- Larger bundle size
- Overkill for most applications
- Zustand offers same features with simpler API

---

## Routing

### TanStack Router (Recommended) ⭐

#### Why TanStack Router?
✅ **Type-safe** - Full TypeScript support for routes and params  
✅ **Modern** - Built for React 19  
✅ **Nested layouts** - Easy to implement  
✅ **Data loading** - Integrated loader patterns  
✅ **Search params** - Type-safe search params  
✅ **Code splitting** - Automatic lazy loading  

```bash
npm install @tanstack/react-router
```

### Alternative: React Router v7
Good alternative, but TanStack Router has better TypeScript support.

---

## Form Management

### React Hook Form (Recommended) ⭐

#### Why React Hook Form?
✅ **Performance** - Minimal re-renders  
✅ **Simple API** - Easy to use  
✅ **Validation** - Built-in or with Zod  
✅ **TypeScript** - Excellent type inference  
✅ **Small bundle** - ~25KB  
✅ **Accessibility** - Focus management, error handling  

```bash
npm install react-hook-form zod @hookform/resolvers
```

```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const schema = z.object({
  name: z.string().min(1, 'Name is required'),
  amount: z.number().positive('Amount must be positive')
})

type FormData = z.infer<typeof schema>

function TransactionForm() {
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema)
  })
  
  const onSubmit = (data: FormData) => {
    // Save transaction
  }
  
  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('name')} />
      {errors.name && <span>{errors.name.message}</span>}
    </form>
  )
}
```

---

## Charts & Visualization

### Recharts (Recommended) ⭐

#### Why Recharts?
✅ **React-first** - Built for React  
✅ **Accessible** - Good ARIA support  
✅ **Responsive** - Works on all screen sizes  
✅ **Composable** - Build custom charts  
✅ **Good documentation** - Many examples  
✅ **Finance-friendly** - Good for financial data  

```bash
npm install recharts
```

### Alternatives
- **Chart.js + react-chartjs-2** - More traditional, less React-like
- **Victory** - Similar to Recharts, but Recharts has better docs
- **Nivo** - Beautiful but heavier bundle size

---

## Icons

### Lucide React (Recommended) ⭐

#### Why Lucide React?
✅ **Modern** - Clean, consistent design  
✅ **Tree-shakeable** - Import only what you use  
✅ **Accessible** - Proper ARIA attributes  
✅ **Customizable** - Size, color, stroke width  
✅ **Finance icons** - Good coverage of finance-related icons  
✅ **TypeScript** - Full type support  

```bash
npm install lucide-react
```

```typescript
import { DollarSign, TrendingUp, PiggyBank } from 'lucide-react'

function Dashboard() {
  return (
    <>
      <DollarSign size={24} />
      <TrendingUp size={24} color="green" />
      <PiggyBank size={24} strokeWidth={1.5} />
    </>
  )
}
```

---

## Date/Time Handling

### date-fns (Recommended) ⭐

#### Why date-fns?
✅ **Modular** - Import only functions you use  
✅ **Lightweight** - Small bundle impact  
✅ **Functional** - Immutable, pure functions  
✅ **i18n** - Great internationalization support  
✅ **TypeScript** - Full type support  
✅ **Timezone** - Separate package for timezone support  

```bash
npm install date-fns
```

```typescript
import { format, parseISO, subMonths } from 'date-fns'

const formatted = format(new Date(), 'PPP') // "April 29th, 2021"
const lastMonth = subMonths(new Date(), 1)
```

### Alternative: Temporal API
The new JavaScript Temporal API is coming, but use a polyfill for now:
```bash
npm install @js-temporal/polyfill
```

---

## Testing

### Unit Testing: Vitest (Recommended) ⭐
```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom
```

### E2E Testing: Playwright (Recommended) ⭐
```bash
npm install -D @playwright/test
```

### Accessibility Testing: axe-core
```bash
npm install -D @axe-core/react
```

---

## CSS Approach

### CSS Modules + Modern CSS (Recommended) ⭐

#### Why This Approach?
✅ **No runtime** - Styles extracted at build time  
✅ **Scoped** - CSS Modules prevent conflicts  
✅ **Modern features** - Container Queries, :has(), Grid, Subgrid  
✅ **Type-safe** - With TypeScript declaration plugin  
✅ **No learning curve** - Just CSS  
✅ **Performance** - No JavaScript overhead  
✅ **Flexible** - Easy to customize  

```css
/* Button.module.css */
.button {
  padding: var(--space-3) var(--space-6);
  border-radius: var(--radius-md);
  background: var(--color-primary-500);
  color: white;
  
  &:hover {
    background: var(--color-primary-600);
  }
  
  &:focus-visible {
    outline: 2px solid var(--color-primary-500);
    outline-offset: 2px;
  }
}

.button[data-size="sm"] {
  padding: var(--space-2) var(--space-4);
  font-size: var(--text-sm);
}
```

### Why Not Tailwind?
- More verbose in JSX
- Harder to maintain custom design system
- Can lead to inconsistent styling
- CSS Modules offer same benefits with better organization

### Why Not CSS-in-JS (Styled Components, Emotion)?
- Runtime overhead
- Larger bundle size
- More complex setup
- Modern CSS can do most of what they offer

---

## Build Tool

### Vite (Recommended) ⭐

Already the best choice! Benefits:
- ⚡ Lightning fast HMR
- 📦 Optimized production builds
- 🔌 Rich plugin ecosystem
- 📝 TypeScript support out of the box
- 🎯 Modern browser features

---

## Package Manager

### pnpm (Recommended for new projects)
```bash
npm install -g pnpm
pnpm install
```

Benefits:
- Faster than npm
- Saves disk space (content-addressable store)
- Strict dependency resolution
- Better monorepo support

### npm (Also fine)
- Pre-installed with Node.js
- More widely used
- Simpler for beginners

---

## Summary - Final Tech Stack

```json
{
  "framework": "React 19.2",
  "language": "TypeScript 5.7+",
  "build": "Vite 6+",
  "linter": "Biome",
  "database": "PGlite",
  "state": "Zustand",
  "routing": "TanStack Router",
  "forms": "React Hook Form + Zod",
  "ui": "Radix UI",
  "styling": "CSS Modules",
  "icons": "Lucide React",
  "charts": "Recharts",
  "dates": "date-fns",
  "testing": "Vitest + Testing Library + Playwright",
  "a11y": "axe-core"
}
```

This stack provides:
- 🚀 **Performance** - Fast, lightweight, optimized
- ♿ **Accessibility** - Built-in, not an afterthought
- 🔒 **Type Safety** - TypeScript everywhere
- 🎨 **Flexibility** - Full design control
- 📱 **Responsive** - Mobile-first approach
- 🔮 **Future-Proof** - Modern, actively maintained
- 👨‍💻 **DX** - Great developer experience
- 📚 **Documentation** - Well-documented libraries

---

## Next Steps

1. ✅ Review this tech stack
2. ✅ Make any adjustments based on your preferences
3. ➡️ Start with Phase 0 in the Implementation Roadmap
4. ➡️ Set up the project with these technologies

**Ready to build? Let's go! 🚀**
