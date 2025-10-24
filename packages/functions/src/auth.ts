import type { CallableRequest } from 'firebase-functions/https';
import type { NoUndefined } from 'zod/v4/core/util.cjs';
import { ErrorCodes, HTTP_STATUS_CODES, WWHttpError } from './errors';

export const getUserAuthenticated = (
  auth?: CallableRequest['auth'],
): NoUndefined<CallableRequest['auth']> => {
  if (!auth) {
    throw new WWHttpError(
      ErrorCodes.AUTH_UNAUTHENTICATED,
      HTTP_STATUS_CODES.UNAUTHORIZED,
      'User must be authenticated',
    );
  }
  return auth;
};
