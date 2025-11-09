/**
 * Legacy Accounts Types - DEPRECATED
 * 
 * This file is maintained for backward compatibility with Firebase Cloud Functions.
 * New code should use types from Investments.ts
 * 
 * Migration TODO: Update all Firebase functions to use Investments.ts types,
 * then remove this file.
 */

import type { CallableFunction } from "firebase-functions/v2/https";
import type { AccountType as NewAccountType, Currency as NewCurrency } from './Investments.js';

// Re-export modern types for backward compatibility
export type AccountType = NewAccountType;
export type Currency = NewCurrency;
export type Balance = number;

// Legacy interfaces - to be phased out
export interface IAccount {
    id: string;
    user_id: string;
    name: string;
    type: AccountType;
    balance: Balance;
    currency: Currency;
    institution?: string;
    account_number: string;
    notes?: string;
    is_active?: boolean;
}

interface IResponse {
    success: boolean;
}

interface IFailureResponse extends IResponse {
    message: string;
    errorCode: string;
}

// Legacy API payload types
export type CreateAccountPayload = Omit<IAccount, 'balance' | 'id' | 'user_id'> & { initial_balance?: Balance };
export type UpdateAccountPayload = Partial<IAccount> & Pick<IAccount, 'id'>;
export type DeleteAccountPayload = { id: string };

export type CreateAccountSuccessResponse = {
    success: true;
    accountId: string;
    message: string;
};

export type CreateAccountFailureResponse = IFailureResponse;
export type GetAccountTypesResponse = IResponse & { accountTypes: AccountType[] };
export type GetAccountTypesHttpsCallable = CallableFunction<null, Promise<GetAccountTypesResponse>>;

