# 🚀 WealthWise Development Quick Start

## Start Everything at Once

```bash
# Install root dependencies (one time)
pnpm install

# Start Firebase emulators + webapp dev server
pnpm dev
```

This single command will start:
- ✅ Firebase Emulators (Auth, Firestore, Functions) 
- ✅ Webapp development server
- ✅ Firebase Emulator UI at http://localhost:4000

## Individual Commands

```bash
# Start only Firebase emulators
pnpm emulators

# Start only webapp dev server
pnpm webapp:dev

# Build Cloud Functions
pnpm functions:build

# Deploy functions to production
pnpm functions:deploy

# Deploy everything to production
pnpm deploy
```

## First Time Setup

1. **Install Firebase SDK in webapp** (if not already done):
   ```bash
   cd webapp
   pnpm add firebase
   ```

2. **Install Functions dependencies**:
   ```bash
   cd functions
   pnpm install
   ```

3. **Build functions** (required before starting emulators):
   ```bash
   cd functions
   pnpm run build
   ```

4. **Start development environment**:
   ```bash
   cd ..  # back to root
   pnpm dev
   ```

## Testing with Emulators

1. Open Firebase Emulator UI: http://localhost:4000
2. Create a test user in the Auth tab
3. The webapp automatically connects to emulators in development mode
4. All data is local and will be cleared when emulators stop

## Architecture

- **Webapp**: React + Vite + Firebase SDK (thin client)
- **Functions**: TypeScript Cloud Functions (business logic)
- **Firestore**: NoSQL database with real-time updates
- **Auth**: Firebase Authentication with emulator support

See `docs/firebase-setup.md` for detailed documentation.
