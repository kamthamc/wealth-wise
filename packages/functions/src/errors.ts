/**
 * Centralized error codes for i18n translations in UI
 * Format: ENTITY_ERROR_TYPE
 */

type HTTPStatusCode =
  | 400
  | 401
  | 403
  | 404
  | 405
  | 409
  | 412
  | 415
  | 429
  | 500
  | 503
  | 200
  | 201
  | 202
  | 204
  | 206
  | 301
  | 302
  | 303
  | 304;

export const HTTP_STATUS_CODES: Record<string, HTTPStatusCode> = {
  OK: 200,
  CREATED: 201,
  ACCEPTED: 202,
  NO_CONTENT: 204,
  PARTIAL_CONTENT: 206,
  MOVED_PERMANENTLY: 301,
  FOUND: 302,
  SEE_OTHER: 303,
  NOT_MODIFIED: 304,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  METHOD_NOT_ALLOWED: 405,
  CONFLICT: 409,
  PRECONDITION_FAILED: 412,
  UNSUPPORTED_MEDIA_TYPE: 415,
  TOO_MANY_REQUESTS: 429,
  INTERNAL_SERVER_ERROR: 500,
  SERVICE_UNAVAILABLE: 503,
};

export const ErrorCodes = {
  // Authentication errors
  AUTH_UNAUTHENTICATED: 'auth.unauthenticated',
  AUTH_UNAUTHORIZED: 'auth.unauthorized',
  AUTH_TOKEN_EXPIRED: 'auth.token_expired',

  // General validation errors
  VALIDATION_REQUIRED_FIELD: 'validation.required_field',
  VALIDATION_INVALID_FORMAT: 'validation.invalid_format',
  VALIDATION_OUT_OF_RANGE: 'validation.out_of_range',
  VALIDATION_INVALID_TYPE: 'validation.invalid_type',
  VALIDATION_INVALID_ACCOUNT_ID: 'validation.invalid_account_id',

  // Account errors
  ACCOUNT_NOT_FOUND: 'account.not_found',
  ACCOUNT_ALREADY_EXISTS: 'account.already_exists',
  ACCOUNT_INVALID_TYPE: 'account.invalid_type',
  ACCOUNT_INVALID_BALANCE: 'account.invalid_balance',
  ACCOUNT_DELETE_FAILED: 'account.delete_failed',
  ACCOUNT_NAME_REQUIRED: 'account.name_required',
  ACCOUNT_TYPE_REQUIRED: 'account.type_required',
  ACCOUNT_VALIDATION_FAILED: 'account.validation_failed',
  ACCOUNT_CREATION_FAILED: 'account.creation_failed',

  // Transaction errors
  TRANSACTION_NOT_FOUND: 'transaction.not_found',
  TRANSACTION_INVALID_AMOUNT: 'transaction.invalid_amount',
  TRANSACTION_INVALID_DATE: 'transaction.invalid_date',
  TRANSACTION_INVALID_TYPE: 'transaction.invalid_type',
  TRANSACTION_DESCRIPTION_REQUIRED: 'transaction.description_required',
  TRANSACTION_ACCOUNT_REQUIRED: 'transaction.account_required',
  TRANSACTION_DELETE_FAILED: 'transaction.delete_failed',

  // Budget errors
  BUDGET_NOT_FOUND: 'budget.not_found',
  BUDGET_INVALID_AMOUNT: 'budget.invalid_amount',
  BUDGET_INVALID_DATES: 'budget.invalid_dates',
  BUDGET_END_BEFORE_START: 'budget.end_before_start',
  BUDGET_NAME_REQUIRED: 'budget.name_required',
  BUDGET_AMOUNT_REQUIRED: 'budget.amount_required',
  BUDGET_OVERLAP: 'budget.overlap',
  BUDGET_DELETE_FAILED: 'budget.delete_failed',

  // Goal errors
  GOAL_NOT_FOUND: 'goal.not_found',
  GOAL_INVALID_TARGET: 'goal.invalid_target',
  GOAL_INVALID_AMOUNT: 'goal.invalid_amount',
  GOAL_NAME_REQUIRED: 'goal.name_required',
  GOAL_TARGET_AMOUNT_REQUIRED: 'goal.target_amount_required',
  GOAL_ALREADY_COMPLETED: 'goal.already_completed',
  GOAL_CONTRIBUTION_INVALID: 'goal.contribution_invalid',
  GOAL_DELETE_FAILED: 'goal.delete_failed',

  // Import/Export errors
  IMPORT_NO_DATA: 'import.no_data',
  IMPORT_INVALID_FORMAT: 'import.invalid_format',
  IMPORT_PARSING_FAILED: 'import.parsing_failed',
  IMPORT_TOO_MANY_RECORDS: 'import.too_many_records',
  IMPORT_ACCOUNT_REQUIRED: 'import.account_required',
  EXPORT_NO_DATA: 'export.no_data',
  EXPORT_GENERATION_FAILED: 'export.generation_failed',
  CLEAR_DATA_CONFIRMATION_REQUIRED: 'clear_data.confirmation_required',
  CLEAR_DATA_FAILED: 'clear_data.failed',

  // Investment errors
  INVESTMENT_SYMBOL_REQUIRED: 'investment.symbol_required',
  INVESTMENT_SYMBOL_INVALID: 'investment.symbol_invalid',
  INVESTMENT_DATA_NOT_FOUND: 'investment.data_not_found',
  INVESTMENT_API_ERROR: 'investment.api_error',
  INVESTMENT_RATE_LIMIT: 'investment.rate_limit',
  INVESTMENT_CACHE_CLEAR_FAILED: 'investment.cache_clear_failed',

  // Dashboard errors
  DASHBOARD_COMPUTE_FAILED: 'dashboard.compute_failed',
  DASHBOARD_CACHE_FAILED: 'dashboard.cache_failed',
  DASHBOARD_SUMMARY_FAILED: 'dashboard.summary_failed',

  // Report errors
  REPORT_GENERATION_FAILED: 'report.generation_failed',
  REPORT_INVALID_DATES: 'report.invalid_dates',
  REPORT_NO_DATA: 'report.no_data',

  // Deposit errors
  DEPOSIT_INVALID_PRINCIPAL: 'deposit.invalid_principal',
  DEPOSIT_INVALID_RATE: 'deposit.invalid_rate',
  DEPOSIT_INVALID_TENURE: 'deposit.invalid_tenure',
  DEPOSIT_CALCULATION_FAILED: 'deposit.calculation_failed',

  // Duplicate errors
  DUPLICATE_CHECK_FAILED: 'duplicate.check_failed',
  DUPLICATE_TRANSACTION_FOUND: 'duplicate.transaction_found',

  // Generic errors
  INTERNAL_ERROR: 'error.internal',
  OPERATION_FAILED: 'error.operation_failed',
  PERMISSION_DENIED: 'error.permission_denied',
  RESOURCE_NOT_FOUND: 'error.resource_not_found',
  INVALID_REQUEST: 'error.invalid_request',
  DATABASE_ERROR: 'error.database',
  NETWORK_ERROR: 'error.network',
} as const;

export type ErrorCode = (typeof ErrorCodes)[keyof typeof ErrorCodes];

export class WWHttpError extends Error {
  /**
   * A standard error code that will be returned to the client. This also
   * determines the HTTP status code of the response, as defined in code.proto.
   */
  readonly errorCode: ErrorCode;
  readonly details: unknown;
  readonly httpErrorCode?: number;

  constructor(
    code: ErrorCode,
    httpErrorCode?: HTTPStatusCode,
    message?: string,
    details?: unknown,
  ) {
    super(message ?? ErrorMessages[code]);
    this.errorCode = code;
    this.details = details;
    this.httpErrorCode =
      httpErrorCode ?? HTTP_STATUS_CODES.INTERNAL_SERVER_ERROR;
  }
  /**
   * Returns a JSON-serializable representation of this object.
   */
  toJSON() {
    const { details, httpErrorCode: status, message } = this;
    return {
      ...(details === undefined ? {} : { details }),
      message,
      status,
    };
  }
}

/**
 * Custom error class with error code for i18n
 */
export class AppError extends Error {
  constructor(
    public readonly code: ErrorCode,
    message: string,
    public readonly statusCode:
      | 'unauthenticated'
      | 'permission-denied'
      | 'invalid-argument'
      | 'not-found'
      | 'internal'
      | 'failed-precondition'
      | 'resource-exhausted' = 'internal',
    public readonly details?: Record<string, any>,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

/**
 * Helper to create validation errors
 */
export function validationError(
  code: ErrorCode,
  field?: string,
  details?: any,
): AppError {
  const message = field
    ? `Validation failed for field: ${field}`
    : 'Validation failed';
  return new AppError(code, message, 'invalid-argument', { field, ...details });
}

/**
 * Helper to create not found errors
 */
export function notFoundError(code: ErrorCode, resource: string): AppError {
  return new AppError(code, `${resource} not found`, 'not-found');
}

/**
 * Helper to create permission errors
 */
export function permissionError(code: ErrorCode): AppError {
  return new AppError(code, 'Permission denied', 'permission-denied');
}

/**
 * Helper to create authentication errors
 */
export function authError(code: ErrorCode): AppError {
  return new AppError(code, 'Authentication required', 'unauthenticated');
}

/**
 * Map error code to default English message (fallback)
 */
export const ErrorMessages: Record<ErrorCode, string> = {
  // Authentication
  [ErrorCodes.AUTH_UNAUTHENTICATED]:
    'You must be logged in to perform this action',
  [ErrorCodes.AUTH_UNAUTHORIZED]:
    'You do not have permission to access this resource',
  [ErrorCodes.AUTH_TOKEN_EXPIRED]:
    'Your session has expired. Please log in again',

  // Validation
  [ErrorCodes.VALIDATION_REQUIRED_FIELD]: 'This field is required',
  [ErrorCodes.VALIDATION_INVALID_FORMAT]: 'Invalid format',
  [ErrorCodes.VALIDATION_OUT_OF_RANGE]: 'Value is out of acceptable range',
  [ErrorCodes.VALIDATION_INVALID_TYPE]: 'Invalid data type',
  [ErrorCodes.VALIDATION_INVALID_ACCOUNT_ID]:
    'The provided account ID is invalid',

  // Account
  [ErrorCodes.ACCOUNT_NOT_FOUND]: 'Account not found',
  [ErrorCodes.ACCOUNT_ALREADY_EXISTS]: 'Account with this name already exists',
  [ErrorCodes.ACCOUNT_INVALID_TYPE]: 'Invalid account type',
  [ErrorCodes.ACCOUNT_INVALID_BALANCE]: 'Invalid balance amount',
  [ErrorCodes.ACCOUNT_DELETE_FAILED]: 'Failed to delete account',
  [ErrorCodes.ACCOUNT_NAME_REQUIRED]: 'Account name is required',
  [ErrorCodes.ACCOUNT_TYPE_REQUIRED]: 'Account type is required',
  [ErrorCodes.ACCOUNT_VALIDATION_FAILED]: 'Account validation failed',
  [ErrorCodes.ACCOUNT_CREATION_FAILED]: 'Failed to create account',

  // Transaction
  [ErrorCodes.TRANSACTION_NOT_FOUND]: 'Transaction not found',
  [ErrorCodes.TRANSACTION_INVALID_AMOUNT]: 'Invalid transaction amount',
  [ErrorCodes.TRANSACTION_INVALID_DATE]: 'Invalid transaction date',
  [ErrorCodes.TRANSACTION_INVALID_TYPE]: 'Invalid transaction type',
  [ErrorCodes.TRANSACTION_DESCRIPTION_REQUIRED]:
    'Transaction description is required',
  [ErrorCodes.TRANSACTION_ACCOUNT_REQUIRED]: 'Account is required',
  [ErrorCodes.TRANSACTION_DELETE_FAILED]: 'Failed to delete transaction',

  // Budget
  [ErrorCodes.BUDGET_NOT_FOUND]: 'Budget not found',
  [ErrorCodes.BUDGET_INVALID_AMOUNT]: 'Invalid budget amount',
  [ErrorCodes.BUDGET_INVALID_DATES]: 'Invalid budget dates',
  [ErrorCodes.BUDGET_END_BEFORE_START]: 'End date must be after start date',
  [ErrorCodes.BUDGET_NAME_REQUIRED]: 'Budget name is required',
  [ErrorCodes.BUDGET_AMOUNT_REQUIRED]: 'Budget amount is required',
  [ErrorCodes.BUDGET_OVERLAP]: 'Budget period overlaps with existing budget',
  [ErrorCodes.BUDGET_DELETE_FAILED]: 'Failed to delete budget',

  // Goal
  [ErrorCodes.GOAL_NOT_FOUND]: 'Goal not found',
  [ErrorCodes.GOAL_INVALID_TARGET]: 'Invalid target amount',
  [ErrorCodes.GOAL_INVALID_AMOUNT]: 'Invalid amount',
  [ErrorCodes.GOAL_NAME_REQUIRED]: 'Goal name is required',
  [ErrorCodes.GOAL_TARGET_AMOUNT_REQUIRED]: 'Target amount is required',
  [ErrorCodes.GOAL_ALREADY_COMPLETED]: 'Goal is already completed',
  [ErrorCodes.GOAL_CONTRIBUTION_INVALID]: 'Invalid contribution amount',
  [ErrorCodes.GOAL_DELETE_FAILED]: 'Failed to delete goal',

  // Import/Export
  [ErrorCodes.IMPORT_NO_DATA]: 'No data to import',
  [ErrorCodes.IMPORT_INVALID_FORMAT]: 'Invalid file format',
  [ErrorCodes.IMPORT_PARSING_FAILED]: 'Failed to parse import file',
  [ErrorCodes.IMPORT_TOO_MANY_RECORDS]: 'Too many records to import at once',
  [ErrorCodes.IMPORT_ACCOUNT_REQUIRED]: 'Account selection is required',
  [ErrorCodes.EXPORT_NO_DATA]: 'No data to export',
  [ErrorCodes.EXPORT_GENERATION_FAILED]: 'Failed to generate export',
  [ErrorCodes.CLEAR_DATA_CONFIRMATION_REQUIRED]:
    'Confirmation required to delete data',
  [ErrorCodes.CLEAR_DATA_FAILED]: 'Failed to clear data',

  // Investment
  [ErrorCodes.INVESTMENT_SYMBOL_REQUIRED]: 'Stock/Fund symbol is required',
  [ErrorCodes.INVESTMENT_SYMBOL_INVALID]: 'Invalid stock/fund symbol',
  [ErrorCodes.INVESTMENT_DATA_NOT_FOUND]: 'Investment data not found',
  [ErrorCodes.INVESTMENT_API_ERROR]: 'Failed to fetch investment data',
  [ErrorCodes.INVESTMENT_RATE_LIMIT]:
    'API rate limit exceeded. Please try again later',
  [ErrorCodes.INVESTMENT_CACHE_CLEAR_FAILED]:
    'Failed to clear investment cache',

  // Dashboard
  [ErrorCodes.DASHBOARD_COMPUTE_FAILED]: 'Failed to compute dashboard',
  [ErrorCodes.DASHBOARD_CACHE_FAILED]: 'Failed to cache dashboard data',
  [ErrorCodes.DASHBOARD_SUMMARY_FAILED]: 'Failed to generate summary',

  // Report
  [ErrorCodes.REPORT_GENERATION_FAILED]: 'Failed to generate report',
  [ErrorCodes.REPORT_INVALID_DATES]: 'Invalid date range',
  [ErrorCodes.REPORT_NO_DATA]: 'No data available for report',

  // Deposit
  [ErrorCodes.DEPOSIT_INVALID_PRINCIPAL]: 'Invalid principal amount',
  [ErrorCodes.DEPOSIT_INVALID_RATE]: 'Invalid interest rate',
  [ErrorCodes.DEPOSIT_INVALID_TENURE]: 'Invalid tenure period',
  [ErrorCodes.DEPOSIT_CALCULATION_FAILED]:
    'Failed to calculate deposit maturity',

  // Duplicate
  [ErrorCodes.DUPLICATE_CHECK_FAILED]: 'Failed to check for duplicates',
  [ErrorCodes.DUPLICATE_TRANSACTION_FOUND]: 'Duplicate transaction found',

  // Generic
  [ErrorCodes.INTERNAL_ERROR]: 'An internal error occurred',
  [ErrorCodes.OPERATION_FAILED]: 'Operation failed',
  [ErrorCodes.PERMISSION_DENIED]: 'Permission denied',
  [ErrorCodes.RESOURCE_NOT_FOUND]: 'Resource not found',
  [ErrorCodes.INVALID_REQUEST]: 'Invalid request',
  [ErrorCodes.DATABASE_ERROR]: 'Database error occurred',
  [ErrorCodes.NETWORK_ERROR]: 'Network error occurred',
};
