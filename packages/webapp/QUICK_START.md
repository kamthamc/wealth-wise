# Quick Start Guide - Getting Started with WealthWise Web App

This guide will help you get started with building the WealthWise web application. Follow these steps to set up your development environment and start building.

---

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** - v20 or later (LTS recommended)
- **npm** or **pnpm** - Package manager
- **Git** - Version control
- **VS Code** (recommended) - Code editor with extensions:
  - Biome (biomejs.biome)
  - TypeScript Vue Plugin (Vue.volar)
  - ESLint (disabled when using Biome)
  - Prettier (disabled when using Biome)

Check versions:
```bash
node --version  # Should be v20+
npm --version   # Should be v10+
git --version
```

---

## Phase 0: Project Setup (Start Here!)

### Step 1: Create Project with Vite

```bash
# Navigate to webapp directory
cd /Users/chaitanyakkamatham/Projects/wealth-wise/webapp

# Create Vite project
npm create vite@latest . -- --template react-ts

# Install dependencies
npm install
```

### Step 2: Install Core Dependencies

```bash
# Database
npm install @electric-sql/pglite

# State Management
npm install zustand

# Routing
npm install @tanstack/react-router

# Forms
npm install react-hook-form zod @hookform/resolvers

# UI Components (Radix UI)
npm install @radix-ui/react-dialog @radix-ui/react-dropdown-menu @radix-ui/react-select @radix-ui/react-tooltip @radix-ui/react-switch @radix-ui/react-checkbox @radix-ui/react-radio-group @radix-ui/react-tabs @radix-ui/react-popover @radix-ui/react-toast

# Icons
npm install lucide-react

# Charts
npm install recharts

# Date/Time
npm install date-fns

# Utilities
npm install clsx class-variance-authority
```

### Step 3: Install Development Dependencies

```bash
# Biome (linter + formatter)
npm install -D @biomejs/biome

# Testing
npm install -D vitest @vitest/ui jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event

# Playwright (E2E)
npm install -D @playwright/test
npx playwright install

# Types
npm install -D @types/react @types/react-dom

# Vite Plugins
npm install -D vite-plugin-pwa vite-tsconfig-paths

# CSS Modules Types
npm install -D typescript-plugin-css-modules
```

### Step 4: Configure Biome

Create `biome.json`:
```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.4/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "files": {
    "ignoreUnknown": false,
    "ignore": ["node_modules", "dist", "build", "coverage", ".vite"]
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100,
    "lineEnding": "lf"
  },
  "organizeImports": {
    "enabled": true
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "a11y": {
        "recommended": true
      },
      "complexity": {
        "recommended": true
      },
      "correctness": {
        "recommended": true
      },
      "performance": {
        "recommended": true
      },
      "security": {
        "recommended": true
      },
      "style": {
        "recommended": true
      },
      "suspicious": {
        "recommended": true
      }
    }
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "jsxQuoteStyle": "double",
      "trailingCommas": "es5",
      "semicolons": "asNeeded",
      "arrowParentheses": "always"
    }
  }
}
```

### Step 5: Update TypeScript Configuration

Update `tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2023", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",

    /* Linting */
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,

    /* Path Mapping */
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    },

    /* CSS Modules */
    "plugins": [
      {
        "name": "typescript-plugin-css-modules"
      }
    ]
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

Create `tsconfig.node.json`:
```json
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true,
    "strict": true
  },
  "include": ["vite.config.ts"]
}
```

### Step 6: Configure Vite

Update `vite.config.ts`:
```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'
import tsconfigPaths from 'vite-tsconfig-paths'
import path from 'path'

export default defineConfig({
  plugins: [
    react(),
    tsconfigPaths(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.ico', 'robots.txt', 'icons/*.png'],
      manifest: {
        name: 'WealthWise',
        short_name: 'WealthWise',
        description: 'Personal finance management application',
        theme_color: '#00a0a0',
        background_color: '#ffffff',
        display: 'standalone',
        icons: [
          {
            src: '/icons/icon-192.png',
            sizes: '192x192',
            type: 'image/png',
          },
          {
            src: '/icons/icon-512.png',
            sizes: '512x512',
            type: 'image/png',
          },
        ],
      },
    }),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    open: true,
  },
  build: {
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom'],
          'ui-vendor': ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu'],
          'chart-vendor': ['recharts'],
        },
      },
    },
  },
})
```

### Step 7: Configure Vitest

Create `vitest.config.ts`:
```typescript
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.test.{ts,tsx}',
        '**/*.spec.{ts,tsx}',
      ],
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
```

### Step 8: Configure Playwright

Create `playwright.config.ts`:
```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
})
```

### Step 9: Update package.json Scripts

Add/update scripts in `package.json`:
```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "biome check .",
    "lint:fix": "biome check --write .",
    "format": "biome format --write .",
    "typecheck": "tsc --noEmit",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "check": "npm run typecheck && npm run lint && npm run test"
  }
}
```

### Step 10: Create Initial Project Structure

```bash
# Create directory structure
mkdir -p src/{app,features,shared,core,styles,assets,test}
mkdir -p src/shared/{components,layouts,hooks,utils,constants,types}
mkdir -p src/core/{db,router,i18n,api}
mkdir -p src/features/{dashboard,accounts,transactions,goals,budgets,reports,settings}
mkdir -p tests/{unit,integration,e2e}
mkdir -p public/icons

# Create test setup file
mkdir -p src/test
```

### Step 11: Create Test Setup

Create `src/test/setup.ts`:
```typescript
import { expect, afterEach } from 'vitest'
import { cleanup } from '@testing-library/react'
import * as matchers from '@testing-library/jest-dom/matchers'

expect.extend(matchers)

afterEach(() => {
  cleanup()
})
```

### Step 12: Create Global Type Declarations

Create `src/types/global.d.ts`:
```typescript
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_APP_TITLE: string
  // Add more env variables as needed
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
```

Create `src/types/css-modules.d.ts`:
```typescript
declare module '*.module.css' {
  const classes: { readonly [key: string]: string }
  export default classes
}
```

### Step 13: Create .gitignore

Create `.gitignore`:
```
# Dependencies
node_modules
.pnpm-store

# Build
dist
build
.vite

# Testing
coverage
.nyc_output
playwright-report
test-results

# Environment
.env
.env.local
.env.production

# Editor
.vscode/*
!.vscode/extensions.json
!.vscode/settings.json
.idea
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
logs

# Misc
.cache
.temp
```

### Step 14: Initialize Git (if not already done)

```bash
git init
git add .
git commit -m "Initial project setup with Vite, React 19, TypeScript, and Biome"
```

---

## Next Steps

Now that your project is set up, you can start building:

1. **Phase 1: Core Infrastructure**
   - Start with design tokens (colors, typography, spacing)
   - Set up the database (PGlite)
   - Create state management stores
   - Set up routing

2. **Phase 2: Shared UI Components**
   - Build Button component
   - Build Input component
   - Build Card component
   - Continue with other base components

3. **Follow the Implementation Roadmap**
   - See `IMPLEMENTATION_ROADMAP.md` for detailed task list
   - Work through phases sequentially
   - Test as you build

---

## Development Commands

```bash
# Start development server
npm run dev

# Type check
npm run typecheck

# Lint and format
npm run lint
npm run format

# Run tests
npm run test          # Watch mode
npm run test:ui       # UI mode
npm run test:coverage # Coverage report

# Run E2E tests
npm run test:e2e      # Headless
npm run test:e2e:ui   # UI mode

# Build for production
npm run build

# Preview production build
npm run preview

# Run all checks
npm run check
```

---

## Helpful Resources

### Official Documentation
- [React 19 Docs](https://react.dev)
- [TypeScript Docs](https://www.typescriptlang.org/docs/)
- [Vite Docs](https://vitejs.dev)
- [Biome Docs](https://biomejs.dev)
- [PGlite Docs](https://github.com/electric-sql/pglite)
- [Zustand Docs](https://zustand-demo.pmnd.rs)
- [TanStack Router Docs](https://tanstack.com/router)
- [Radix UI Docs](https://www.radix-ui.com/primitives/docs/overview/introduction)
- [React Hook Form Docs](https://react-hook-form.com)

### Accessibility Resources
- [WCAG 2.2 Guidelines](https://www.w3.org/WAI/WCAG22/quickref/)
- [MDN Accessibility](https://developer.mozilla.org/en-US/docs/Web/Accessibility)
- [WebAIM](https://webaim.org)

### CSS Resources
- [MDN CSS Reference](https://developer.mozilla.org/en-US/docs/Web/CSS)
- [CSS Tricks](https://css-tricks.com)
- [Modern CSS Solutions](https://moderncss.dev)

---

## Tips for Success

### 1. Start Small
Don't try to build everything at once. Start with Phase 0, then Phase 1, etc.

### 2. Test Continuously
Write tests as you build features. Don't leave testing for the end.

### 3. Focus on Accessibility
Build accessibility in from the start. It's much harder to add later.

### 4. Use TypeScript Strictly
Don't use `any`. Take advantage of TypeScript's type system.

### 5. Keep It Simple
Don't over-engineer. Start with simple solutions and refactor as needed.

### 6. Document As You Go
Write comments for complex logic. Update docs when you make changes.

### 7. Commit Often
Make small, focused commits with clear messages.

### 8. Ask for Help
Don't get stuck. Use documentation, communities, and AI assistants.

---

## Troubleshooting

### Issue: Module not found
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
```

### Issue: TypeScript errors
```bash
# Check TypeScript configuration
npm run typecheck
# Look for any configuration issues in tsconfig.json
```

### Issue: Vite not starting
```bash
# Check if port 3000 is available
lsof -ti:3000 | xargs kill -9
# Or change port in vite.config.ts
```

### Issue: Tests failing
```bash
# Clear test cache
npm run test -- --clearCache
# Run tests with verbose output
npm run test -- --verbose
```

---

## What's Next?

1. ✅ Complete Phase 0 setup (you're here!)
2. ➡️ Move to Phase 1: Core Infrastructure
3. ➡️ Follow the Implementation Roadmap
4. ➡️ Build features incrementally
5. ➡️ Test and refine
6. ➡️ Deploy when ready

**You're all set! Let's start building! 🚀**

---

## Questions?

Refer to:
- `ARCHITECTURE.md` - Overall architecture
- `IMPLEMENTATION_ROADMAP.md` - Detailed task breakdown
- `TECH_STACK.md` - Technology decisions

Happy coding! 💻✨
