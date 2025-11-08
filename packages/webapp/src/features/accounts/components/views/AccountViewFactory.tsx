/**
 * Account View Factory
 * Routes to appropriate type-specific view based on account type
 */

import type {
  Account,
  AccountType,
  BrokerageDetails,
  CreditCardDetails,
  DepositDetails,
} from '@/core/types';
import { BrokerageView } from './BrokerageView';
import { CreditCardView } from './CreditCardView';
import { DepositView } from './DepositView';

export interface AccountViewFactoryProps {
  account: Account;
  creditCardDetails?: CreditCardDetails;
  depositDetails?: DepositDetails;
  brokerageDetails?: BrokerageDetails;
}

// Define account types that have specialized views
const CREDIT_CARD_TYPES: AccountType[] = ['credit_card'];

const DEPOSIT_TYPES: AccountType[] = [
  'fixed_deposit',
  'recurring_deposit',
  'ppf',
  'nsc',
  'kvp',
  'scss',
  'post_office',
];

const BROKERAGE_TYPES: AccountType[] = ['brokerage'];

/**
 * Factory component that renders the appropriate view based on account type
 */
export function AccountViewFactory({
  account,
  creditCardDetails,
  depositDetails,
  brokerageDetails,
}: AccountViewFactoryProps) {
  // Route to credit card view
  if (CREDIT_CARD_TYPES.includes(account.type)) {
    return (
      <CreditCardView account={account} creditCardDetails={creditCardDetails} />
    );
  }

  // Route to deposit view
  if (DEPOSIT_TYPES.includes(account.type)) {
    return <DepositView account={account} depositDetails={depositDetails} />;
  }

  // Route to brokerage view
  if (BROKERAGE_TYPES.includes(account.type)) {
    return (
      <BrokerageView account={account} brokerageDetails={brokerageDetails} />
    );
  }

  // Default fallback: render null (AccountDetails will show generic view)
  return null;
}

/**
 * Helper function to determine if an account type has a specialized view
 */
export function hasSpecializedView(accountType: AccountType): boolean {
  return (
    CREDIT_CARD_TYPES.includes(accountType) ||
    DEPOSIT_TYPES.includes(accountType) ||
    BROKERAGE_TYPES.includes(accountType)
  );
}

/**
 * Helper function to get the view type for an account
 */
export function getViewType(
  accountType: AccountType
): 'credit_card' | 'deposit' | 'brokerage' | 'default' {
  if (CREDIT_CARD_TYPES.includes(accountType)) return 'credit_card';
  if (DEPOSIT_TYPES.includes(accountType)) return 'deposit';
  if (BROKERAGE_TYPES.includes(accountType)) return 'brokerage';
  return 'default';
}
