# @svc/wealth-wise-shared-types

## 2.0.0

### Major Changes

- 02fb7ef: Create a single-source-of-truth for request/response types, add runtime Zod validation and a structured error system in Cloud Functions, and wire typed, safe callable wrappers in the webapp.

  Primary goal: introduce runtime validation, central typed schemas, and an i18n-ready error system for Cloud Functions, and share types with the web app to ensure type-safe callable function usage.

  Main artifacts:

  - Centralized Zod schemas improved and exported (schemas.ts)
  - Structured error system (errors.ts) with AppError and ErrorCodes
  - Cloud Functions updated to use Zod + AppError patterns
  - Webapp API wrappers updated to use shared/consistent types
  - Documentation and a changeset added for the release

  - schemas.ts
  - Consolidated and expanded Zod schemas covering accounts, transactions, budgets, goals, import/export, dashboard, investments, deposits, reports, duplicates, etc.
  - Schemas include stricter constraints (currency, enums, length limits, array limits). Exports usable z.infer types.
  - errors.ts
  - Implemented AppError class and ErrorCodes mapping.
  - Added helper constructors: validationError(), notFoundError(), authError(), permissionError().
  - Error codes map to default English messages; codes are translation keys for the UI.
  - goals.ts
  - Example migration: createGoal now uses createGoalSchema + safeValidate, throws validationError(...) for invalid inputs, authError(...) for missing auth, wraps unexpected exceptions into AppError(ErrorCodes.OPERATION_FAILED, ...).
  - import.ts
  - importTransactions validates payload with importTransactionsSchema, verifies account ownership via notFoundError / permissionError, and wraps internal errors with AppError.
  - accounts.ts
  - Uses createAccountSchema validation for create/update flows. Some migration of ad-hoc types to schema-inferred types; temporary any casts kept where needed during migration.
  - dashboard.ts
  - Uses computeAndCacheDashboardSchema for TTL/forceRefresh validation; implements caching TTL.
  - investments.ts
  - Validates symbols/ISINs using fetchStockDataSchema / fetchMutualFundDataSchema; wraps provider or cache errors in ErrorCodes.INVESTMENT_API_ERROR or similar.
  - budgets.ts, transactions.ts, reports.ts, duplicates.ts, dataExport.ts, pubsub.ts, deposits.ts
  - Applied the same Zod + AppError pattern: input validation via schemas, typed outputs where possible, structured errors suitable for i18n translation.
  - index.ts
  - Updated exports to register the updated functions and new patterns.
  - tsconfig.json
  - Adjusted to the monorepo and new shared-types structure (project references / strict settings may be enabled).
  - goalsApi.ts
  - Replaced local duplicated input types with the shared-types import or typed FunctionInput/FunctionOutput pattern and uses typed httpsCallable or a typed callFunction(...) wrapper.
  - packages/webapp/src/core/api/\* (importApi, dashboardApi, accountApi, transactionApi, reportApi, duplicateApi, depositApi, dataExportApi)
  - Updated to import and use shared types or typed wrapper results. Reduced any usage and ensured API calls' input/output shapes match server types.
  - firebase.ts, stores/firebase.ts, hooks/useAuth.ts, hooks/useFirestore.ts
  - Adjusted to use typed wrappers and to make error details available for the UI (error code -> i18n lookup).
  - packages/webapp/src/core/stores/_, core/services/_, features/\* (budgets, accounts, deposits, dashboard, reports)
  - Updated call sites to accept typed outputs; some components now process ImportTransactionsOutput, DashboardData, etc.
  - notificationService.ts
    Now recognizes AppError/ErrorCodes in error details and uses error codes as i18n keys to display localized messages.
    routeTree.gen.ts
    Regenerated due to route or build changes.
    Shared / New (planned or referenced)
    shared-types (referenced and added as a workspace dependency in packages)
    Planned single-source package (@svc/wealth-wise-shared-types) to hold Zod schemas + TypeScript types + function signature map. The changeset references this package as part of the patch release.
    The approach allows both functions and webapp packages to import the same types and schemas.
    Documentation
    zod-error-codes-migration-guide.md
    Detailed migration guide showing before/after usage, code examples, testing strategies, frontend translation examples.
    shared-types-implementation-plan.md
    Implementation plan to create shared-types, generate types, litmus tests, migration steps and timeline.
    Tooling / Monorepo
    package.json (root)
    Workspaces configured; @changesets/cli is present in devDependencies.
    package.json, package.json
    Both declare @svc/wealth-wise-shared-types as a workspace:\* dependency (indicates intent to import shared types).
    Build and type iterations were performed: initial TypeScript errors were fixed (unused imports, renamed error codes, type inference), and a successful changeset file was created.
    Why these changes were made
    Zod schemas centralize runtime validation and make payload validation explicit and consistent.
    ErrorCodes + AppError produce i18n-friendly server errors; the UI can translate server-side error codes to localized, user-friendly messages.
    Shared types prevent server/client drift, provide compile-time safety for payloads and results, and enable IDE autocompletion.
    Reduces runtime bugs caused by mismatched payloads and speeds up developer workflows.
