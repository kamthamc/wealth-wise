# WealthWise Architecture

## Overview

WealthWise is a **web-based personal finance management application** built with modern technologies to provide a fast, responsive, and scalable user experience.

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────┐
│           User's Browser (Client)               │
│  ┌──────────────────────────────────────────┐   │
│  │     React SPA (TypeScript)               │   │
│  │  ┌────────────┐  ┌──────────────────┐    │   │
│  │  │ Components │  │   Zustand Store  │    │   │
│  │  └────────────┘  └──────────────────┘    │   │
│  │  ┌────────────┐  ┌──────────────────┐    │   │
│  │  │ API Client │  │  i18n (react-i18next)│    │
│  │  └────────────┘  └──────────────────┘    │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
                        │ HTTPS/WebSocket
                        ▼
┌─────────────────────────────────────────────────┐
│         Firebase Platform (Backend)             │
│  ┌──────────────────────────────────────────┐   │
│  │        Firebase Authentication           │   │
│  └──────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────┐   │
│  │        Cloud Firestore (Database)        │   │
│  │     - users collection                   │   │
│  │     - accounts collection                │   │
│  │     - transactions collection            │   │
│  │     - budgets collection                 │   │
│  │     - goals collection                   │   │
│  │     - categories collection              │   │
│  └──────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────┐   │
│  │     Cloud Functions (Business Logic)     │   │
│  │     - createOrUpdateBudget               │   │
│  │     - createOrUpdateGoal                 │   │
│  │     - generateBudgetReport               │   │
│  │     - calculateBalances                  │   │
│  │     - bulkDeleteTransactions             │   │
│  │     - exportTransactions                 │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

## Technology Stack

### Frontend

**Core Framework**:
- **React 18**: Modern component-based UI with hooks
- **TypeScript**: Type-safe development
- **Vite**: Fast build tool and dev server

**State Management**:
- **Zustand**: Lightweight global state management
- **Custom Hooks**: Feature-specific state logic

**UI/UX**:
- **Radix UI**: Accessible, unstyled component primitives
- **Lucide Icons**: Modern icon set
- **CSS Modules**: Scoped component styling
- **CSS Variables**: Theming and dark mode

**Routing & Navigation**:
- **React Router v6**: Client-side routing

**Forms & Validation**:
- Custom validation hooks
- Type-safe form handling

**Internationalization**:
- **react-i18next**: Multi-language support
- JSON-based translation files

### Backend (Firebase)

**Authentication**:
- Firebase Authentication
- Email/password provider
- Session management
- Security rules integration

**Database**:
- **Cloud Firestore**: NoSQL document database
- Real-time synchronization
- Offline support
- Composite indexes for queries

**Business Logic**:
- **Cloud Functions**: Serverless Node.js functions
- **TypeScript**: Type-safe function development
- **Shared Types**: Common types across frontend/backend

**Hosting** (Planned):
- Firebase Hosting
- CDN distribution
- HTTPS by default

### Development Tools

**Monorepo Management**:
- **pnpm**: Fast, disk-efficient package manager
- **pnpm workspaces**: Monorepo architecture

**Code Quality**:
- **Biome**: Fast linter and formatter
- **TypeScript**: Strict type checking
- **ESLint**: Additional linting rules

**Testing** (Planned):
- **Vitest**: Fast unit testing
- **React Testing Library**: Component testing
- **Firebase Emulators**: Local backend testing

## Frontend Architecture

### Component Structure

```
packages/webapp/src/
├── components/          # Reusable UI components
│   ├── accounts/        # Account-related components
│   ├── budgets/         # Budget management
│   ├── goals/           # Goal tracking
│   ├── transactions/    # Transaction management
│   ├── reports/         # Analytics and reports
│   ├── settings/        # User preferences
│   └── common/          # Shared components
├── stores/              # Zustand state stores
├── hooks/               # Custom React hooks
├── services/            # API client services
├── types/               # TypeScript type definitions
├── locales/             # i18n translation files
├── utils/               # Utility functions
└── App.tsx              # Main application component
```

### State Management Pattern

**Zustand Stores**:
- `useUserStore`: Authentication and user profile
- `useAccountsStore`: Account data and operations
- `useTransactionsStore`: Transaction management
- `useBudgetsStore`: Budget tracking
- `useGoalsStore`: Goal management
- `useCategoriesStore`: Category data

**Store Pattern**:
```typescript
interface Store {
  // State
  data: DataType[];
  loading: boolean;
  error: string | null;
  
  // Actions
  fetch: () => Promise<void>;
  create: (item: CreateInput) => Promise<void>;
  update: (id: string, updates: UpdateInput) => Promise<void>;
  delete: (id: string) => Promise<void>;
}
```

### Data Flow

1. **User Action** → Component event handler
2. **Component** → Store action (Zustand)
3. **Store** → API service call
4. **API Service** → Cloud Function or Firestore
5. **Backend** → Process and respond
6. **API Service** → Update store state
7. **Store** → React re-render via subscription

### Routing Structure

```
/ (public)
├── /login                    # Authentication
├── /signup                   # Registration
└── /dashboard (protected)    # Main application
    ├── /accounts             # Account management
    ├── /transactions         # Transaction history
    ├── /budgets              # Budget planning
    ├── /goals                # Financial goals
    ├── /reports              # Analytics
    └── /settings             # User preferences
```

## Backend Architecture

### Firestore Data Model

**Collections**:

```
users/{userId}
  - email: string
  - displayName: string
  - locale: string
  - currency: string
  - createdAt: timestamp
  
accounts/{accountId}
  - userId: string (indexed)
  - name: string
  - type: 'bank' | 'credit_card' | 'upi' | 'brokerage'
  - balance: number
  - institution: string
  - createdAt: timestamp
  
transactions/{transactionId}
  - userId: string (indexed)
  - accountId: string (indexed)
  - date: timestamp (indexed)
  - amount: number
  - type: 'debit' | 'credit'
  - category: string
  - description: string
  - notes: string
  
budgets/{budgetId}
  - userId: string (indexed)
  - name: string
  - amount: number
  - period: 'monthly' | 'quarterly' | 'yearly'
  - categories: string[]
  - startDate: timestamp
  
goals/{goalId}
  - userId: string (indexed)
  - name: string
  - targetAmount: number
  - currentAmount: number
  - targetDate: timestamp
  - type: string
  - contributions: [{
      amount: number,
      date: timestamp,
      note: string
    }]
  
categories/{categoryId}
  - name: string
  - type: 'expense' | 'income'
  - icon: string
  - isDefault: boolean
```

### Cloud Functions

**Budget Management**:
- `createOrUpdateBudget`: Create/update budget with validation
- `generateBudgetReport`: Calculate spending vs. budget

**Goal Management**:
- `createOrUpdateGoal`: Manage financial goals
- `addGoalContribution`: Track contributions

**Transaction Processing**:
- `calculateBalances`: Compute account balances
- `bulkDeleteTransactions`: Batch transaction deletion
- `exportTransactions`: Generate CSV exports

**Function Structure**:
```typescript
export const functionName = onCall<InputType, ReturnType>(
  async (request) => {
    // 1. Authentication check
    if (!request.auth) throw new Error('Unauthorized');
    
    // 2. Input validation
    const validated = InputSchema.parse(request.data);
    
    // 3. Authorization check
    // Verify user owns the resource
    
    // 4. Business logic
    // Process the request
    
    // 5. Database operations
    // Update Firestore
    
    // 6. Return result
    return { success: true, data: result };
  }
);
```

### Security Rules

**Firestore Security**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /accounts/{accountId} {
      allow read, write: if request.auth != null 
        && resource.data.userId == request.auth.uid;
    }
    
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null 
        && resource.data.userId == request.auth.uid;
    }
    
    // Similar rules for budgets, goals, etc.
  }
}
```

## Performance Optimizations

### Frontend

**Code Splitting**:
- Route-based lazy loading
- Dynamic imports for heavy components
- Separate vendor bundles

**Rendering Optimization**:
- React.memo for expensive components
- useMemo/useCallback for derived state
- Virtual scrolling for large lists

**Data Fetching**:
- Zustand stores cache data
- Optimistic updates for UI responsiveness
- Debounced search/filter operations

**Bundle Size**:
- Tree-shaking unused code
- Selective Radix UI imports
- Optimized icon imports

### Backend

**Firestore Optimization**:
- Composite indexes for complex queries
- Batch reads/writes where possible
- Efficient query patterns (limit, where)

**Cloud Functions**:
- Lazy initialization of services
- Connection pooling for external APIs
- Response caching where appropriate

## Security Architecture

### Authentication Flow

1. User enters credentials
2. Firebase Auth validates
3. JWT token issued
4. Token stored in browser (httpOnly cookie planned)
5. Token sent with each API request
6. Cloud Functions validate token
7. Firestore rules enforce data access

### Data Security

**Encryption**:
- HTTPS for all communication
- Firebase handles encryption at rest
- Sensitive data hashed/encrypted in functions

**Access Control**:
- User-scoped data (userId in all documents)
- Firestore security rules enforce ownership
- Cloud Functions validate authorization

**Input Validation**:
- Zod schemas in Cloud Functions
- Client-side validation for UX
- Server-side validation for security

## Scalability Considerations

### Current Scale
- Single-user application
- Moderate transaction volume (<10k/user/year)
- Real-time sync not critical

### Future Scaling
- **Database**: Firestore auto-scales
- **Functions**: Auto-scale based on load
- **Frontend**: CDN distribution
- **Optimization**: Query pagination, lazy loading

## Monitoring & Observability

**Firebase Console**:
- Authentication metrics
- Firestore usage
- Cloud Functions logs
- Performance monitoring

**Error Tracking** (Planned):
- Sentry integration
- Cloud Functions error logs
- Frontend error boundaries

## Development Workflow

### Local Development

```bash
# Start Firebase emulators
cd packages/cloud-functions
pnpm run emulators

# Start webapp dev server
cd packages/webapp
pnpm run dev
```

**Emulator Suite**:
- Firestore emulator (port 8080)
- Auth emulator (port 9099)
- Functions emulator (port 5001)

### Build & Deploy

```bash
# Build all packages
pnpm build

# Deploy Cloud Functions
cd packages/cloud-functions
pnpm run deploy

# Deploy webapp (planned)
cd packages/webapp
firebase deploy --only hosting
```

## Future Architecture Plans

### Planned Improvements

1. **Progressive Web App (PWA)**:
   - Service worker for offline support
   - App manifest for installability

2. **Real-time Features**:
   - Live budget tracking
   - Collaborative features (family accounts)

3. **Advanced Analytics**:
   - BigQuery integration
   - ML-based insights

4. **Mobile Apps**:
   - Native iOS/Android apps
   - Shared business logic via API

5. **Microservices** (if needed):
   - Separate report generation service
   - Background job processing

## Conclusion

WealthWise uses a modern, serverless architecture with React and Firebase to provide a fast, secure, and scalable personal finance management experience. The monorepo structure with TypeScript throughout ensures type safety and code reusability across frontend and backend.