# WealthWise Firebase Setup

This document provides instructions for setting up and testing Firebase locally with emulators.

## 🚀 Quick Start (Local Development with Emulators)

### 1. Install Dependencies

```bash
# Install functions dependencies
cd functions
pnpm install
cd ..
```

### 2. Start Firebase Emulators

```bash
# From the project root
npx firebase emulators:start
```

This will start:
- **Firebase UI**: http://localhost:4000 (Main emulator dashboard)
- **Auth Emulator**: http://localhost:9099
- **Firestore Emulator**: http://localhost:8080
- **Functions Emulator**: http://localhost:5001

### 3. Start the Webapp

In a new terminal:

```bash
cd webapp
pnpm dev
```

The webapp will automatically connect to the Firebase emulators when running in development mode.

## Emulator Status

The emulators are successfully running with the following endpoints:

| Emulator | Host:Port | Emulator UI |
|----------|-----------|-------------|
| **Emulator UI Hub** | http://127.0.0.1:4000/ | Main dashboard |
| Authentication | 127.0.0.1:9099 | http://127.0.0.1:4000/auth |
| Functions | 127.0.0.1:5001 | http://127.0.0.1:4000/functions |
| Firestore | 127.0.0.1:8080 | http://127.0.0.1:4000/firestore |

### Active Cloud Functions

All 12 Cloud Functions are successfully loaded:

**Budget Functions:**
- ✅ `createBudget` - http://127.0.0.1:5001/svc-wealthwise/us-central1/createBudget
- ✅ `updateBudget` - http://127.0.0.1:5001/svc-wealthwise/us-central1/updateBudget
- ✅ `deleteBudget` - http://127.0.0.1:5001/svc-wealthwise/us-central1/deleteBudget
- ✅ `calculateBudgetProgress` - http://127.0.0.1:5001/svc-wealthwise/us-central1/calculateBudgetProgress

**Account Functions:**
- ✅ `createAccount` - http://127.0.0.1:5001/svc-wealthwise/us-central1/createAccount
- ✅ `updateAccount` - http://127.0.0.1:5001/svc-wealthwise/us-central1/updateAccount
- ✅ `deleteAccount` - http://127.0.0.1:5001/svc-wealthwise/us-central1/deleteAccount
- ✅ `calculateAccountBalance` - http://127.0.0.1:5001/svc-wealthwise/us-central1/calculateAccountBalance

**Transaction Functions:**
- ✅ `createTransaction` - http://127.0.0.1:5001/svc-wealthwise/us-central1/createTransaction
- ✅ `updateTransaction` - http://127.0.0.1:5001/svc-wealthwise/us-central1/updateTransaction
- ✅ `deleteTransaction` - http://127.0.0.1:5001/svc-wealthwise/us-central1/deleteTransaction
- ✅ `getTransactionStats` - http://127.0.0.1:5001/svc-wealthwise/us-central1/getTransactionStats

## Development Workflow

### Create a Test User

1. Open Firebase Emulator UI: http://localhost:4000
2. Go to the **Authentication** tab
3. Click "Add User"
4. Enter email and password (e.g., `test@example.com` / `password123`)

### Test Cloud Functions

The webapp will automatically use the emulated functions. You can also test them directly:

```javascript
// In your browser console or test file
import { functions } from './core/firebase/firebase';
import { httpsCallable } from 'firebase/functions';

// Create a budget
const createBudget = httpsCallable(functions, 'createBudget');
const result = await createBudget({
  name: 'Test Budget',
  description: 'My first budget',
  period_type: 'monthly',
  start_date: new Date().toISOString(),
  is_recurring: true,
  rollover_enabled: false,
  categories: [
    { category: 'Food', allocated_amount: 10000 },
    { category: 'Transport', allocated_amount: 5000 }
  ]
});
console.log(result.data);
```

### View Firestore Data

1. Open Firebase Emulator UI: http://localhost:4000
2. Go to the **Firestore** tab
3. Browse the data structure: `users/{userId}/budgets/{budgetId}`

## 🏗️ Data Structure

### Budgets Collection

```
users/{userId}/budgets/{budgetId}
├── name: string
├── description: string
├── period_type: 'monthly' | 'quarterly' | 'annual' | 'custom' | 'event'
├── start_date: Timestamp
├── end_date: Timestamp | null
├── is_recurring: boolean
├── rollover_enabled: boolean
├── rollover_amount: number
├── is_active: boolean
├── created_at: Timestamp
├── updated_at: Timestamp
└── categories (subcollection)
    └── {categoryId}
        ├── category: string
        ├── allocated_amount: number
        ├── alert_threshold: number
        ├── notes: string
        ├── created_at: Timestamp
        └── updated_at: Timestamp
```

## 🔐 Security Rules

Firestore security rules are defined in `firestore.rules`. Key points:

- All data is scoped to authenticated users
- Users can only read/write their own data
- Each user's data is under `users/{userId}/`

## 📝 Available Cloud Functions

### `createBudget`
Creates a new budget with categories.

**Input:**
```typescript
{
  name: string;
  description?: string;
  period_type: 'monthly' | 'quarterly' | 'annual' | 'custom' | 'event';
  start_date: string; // ISO date
  end_date?: string;
  is_recurring: boolean;
  rollover_enabled: boolean;
  categories: Array<{
    category: string;
    allocated_amount: number;
    alert_threshold?: number;
    notes?: string;
  }>;
}
```

### `updateBudget`
Updates an existing budget.

**Input:**
```typescript
{
  budgetId: string;
  updates: {
    name?: string;
    description?: string;
    // ... other fields
  };
}
```

### `deleteBudget`
Deletes a budget and all its categories.

**Input:**
```typescript
{
  budgetId: string;
}
```

### `calculateBudgetProgress`
Calculates spending and progress for a budget.

**Input:**
```typescript
{
  budgetId: string;
}
```

## 🚀 Deploying to Production

### 1. Create Firebase Project

1. Go to https://console.firebase.google.com
2. Create a new project
3. Enable Authentication, Firestore, and Functions

### 2. Update Configuration

Update `webapp/.env` with your actual Firebase configuration values from the Firebase Console.

### 3. Deploy

```bash
# Deploy everything
firebase deploy

# Or deploy specific services
firebase deploy --only functions
firebase deploy --only firestore:rules
```

## 📊 Monitoring & Analytics

In production, Google Analytics will automatically track:
- User authentication events
- Budget creation/updates
- Feature usage

View analytics in the Firebase Console under the Analytics tab.

## 🔧 Troubleshooting

### Emulators not starting

```bash
# Kill any existing processes
lsof -ti:4000 -ti:8080 -ti:9099 -ti:5001 | xargs kill -9

# Restart emulators
npx firebase emulators:start
```

### Functions not found

Make sure you've built the functions:

```bash
cd functions
pnpm run build
```

### Authentication errors

Ensure you're using the Auth Emulator URL in development:
```
http://localhost:9099
```

## 📚 Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Cloud Functions](https://firebase.google.com/docs/functions)
- [Firestore](https://firebase.google.com/docs/firestore)
- [Firebase Emulators](https://firebase.google.com/docs/emulator-suite)
