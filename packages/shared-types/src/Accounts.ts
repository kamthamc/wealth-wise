import type { CallableFunction } from "firebase-functions/v2/https";

export type AccountType = 'savings'|   'checking'|   'credit_card'|   'investment'|   'brokerage'|   'mutual_fund'|   'loan'|   'mortgage'|   'fixed_deposit'|   'recurring_deposit'|   'ppf'|   'nps'|   'epf'|   'cash'|   'other';

export type Balance = number;
export type Currency = 'INR' | 'USD' | 'EUR' | 'GBP' | 'JPY' | 'AUD' | 'CAD' | 'CHF' | 'CNY' | 'HKD' | 'SGD' | 'NZD' | 'ZAR' | 'BRL' | 'MXN' | 'RUB' | 'KRW' | 'TRY' | string;

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



export type CreateAccountPayload = Omit<IAccount, 'balance' | 'id' | 'user_id'> & { initial_balance?: Balance };
export type UpdateAccountPayload = Partial<IAccount> & Pick<IAccount, 'id'>;
export type DeleteAccountPayload = { id: string };

export type CreateAccountSuccessResponse = {
    success: true;
    accountId: string;
    message: string;
};

export type CreateAccountFailureResponse = IFailureResponse;
//CallableFunction<null, Promise<{ success: boolean; accountTypes: string[]; }>, unknown>
export type GetAccountTypesResponse = IResponse & { accountTypes: AccountType[] };
export type GetAccountTypesHttpsCallable = CallableFunction<null, Promise<GetAccountTypesResponse>>;

