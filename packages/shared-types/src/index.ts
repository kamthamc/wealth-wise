// Export all investment types (primary source of truth)
export * from './Investments.js';

// Export cloud function types
export * from './CloudFunctionTypes.js';

// Export user preferences types
export * from './UserPreferences.js';

// Export HTTP utilities
export * from './Http.js';

// Export legacy account types for backward compatibility
export type {
  IAccount,
  Balance,
  CreateAccountPayload,
  UpdateAccountPayload,
  DeleteAccountPayload,
  CreateAccountSuccessResponse,
  CreateAccountFailureResponse,
  GetAccountTypesResponse,
  GetAccountTypesHttpsCallable,
} from './Accounts.js';