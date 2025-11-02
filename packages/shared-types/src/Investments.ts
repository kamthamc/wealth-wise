/**
 * Shared Investment Types
 * Used across webapp and Firebase Cloud Functions
 */

// ==================== Account Types ====================

export type AccountType =
  // Banking & Cash
  | 'bank'
  | 'credit_card'
  | 'upi'
  | 'cash'
  | 'wallet'
  // Deposits & Savings
  | 'fixed_deposit'
  | 'recurring_deposit'
  | 'ppf'
  | 'nsc'
  | 'kvp'
  | 'scss'
  | 'post_office'
  | 'ssy'
  // Investments & Brokerage
  | 'brokerage'
  | 'mutual_fund'
  | 'stocks'
  | 'bonds'
  | 'etf'
  // Insurance
  | 'term_insurance'
  | 'endowment'
  | 'money_back'
  | 'ulip'
  | 'child_plan'
  // Retirement
  | 'nps'
  | 'apy'
  | 'epf'
  | 'vpf'
  // Real Estate
  | 'property'
  | 'reit'
  | 'invit'
  // Precious Metals
  | 'gold'
  | 'silver'
  // Alternative Investments
  | 'p2p_lending'
  | 'chit_fund'
  | 'cryptocurrency'
  | 'commodity'
  | 'hedge_fund'
  | 'angel_investment';

export type Currency = 'INR' | 'USD' | 'EUR' | 'GBP' | 'JPY' | 'AUD' | 'CAD' | 'CHF' | 'CNY' | 'HKD' | 'SGD' | 'NZD' | 'ZAR' | 'BRL' | 'MXN' | 'RUB' | 'KRW' | 'TRY';

// ==================== Status Types ====================

export type DepositStatus = 'active' | 'matured' | 'prematurely_closed' | 'renewed';
export type CreditCardStatus = 'active' | 'blocked' | 'closed';
export type BrokerageStatus = 'active' | 'dormant' | 'closed';
export type InsuranceStatus = 'active' | 'paid_up' | 'lapsed' | 'matured' | 'surrendered';
export type PensionStatus = 'active' | 'inactive' | 'matured';
export type RealEstateStatus = 'owned' | 'under_construction' | 'sold' | 'inherited';
export type AlternativeInvestmentStatus = 'active' | 'defaulted' | 'matured' | 'exited' | 'written_off';

// ==================== Enumerations ====================

export type InterestPayoutFrequency = 'monthly' | 'quarterly' | 'annually' | 'maturity';
export type PremiumFrequency = 'monthly' | 'quarterly' | 'half_yearly' | 'annual';
export type CardNetwork = 'visa' | 'mastercard' | 'amex' | 'rupay' | 'diners';
export type CardType = 'credit' | 'charge';
export type BrokerageAccountType = 'trading' | 'demat' | 'combined';
export type TaxDeductionSection = '80C' | '80D' | '80G' | 'none';
export type TransactionType = 'income' | 'expense' | 'transfer';
export type RecurringFrequency = 'daily' | 'weekly' | 'monthly' | 'yearly';
export type GoalPriority = 'low' | 'medium' | 'high';
export type GoalStatus = 'active' | 'completed' | 'paused' | 'cancelled';
export type CategoryType = 'income' | 'expense';
export type BudgetPeriodType = 'monthly' | 'quarterly' | 'annual' | 'custom' | 'event';
export type InsurancePolicyType = 'term' | 'endowment' | 'money_back' | 'ulip' | 'child';
export type PensionSchemeType = 'nps' | 'apy' | 'epf' | 'vpf';
export type RealEstateType = 'property' | 'reit' | 'invit';
export type PropertyType = 'residential_flat' | 'independent_house' | 'commercial_office' | 'shop' | 'plot' | 'agricultural_land';
export type MetalType = 'gold' | 'silver';
export type MetalInvestmentForm = 'physical' | 'sgb' | 'etf' | 'digital' | 'mutual_fund';
export type MetalStorageLocation = 'home' | 'bank_locker' | 'vault' | 'jeweller';
export type AlternativeInvestmentType = 'p2p_lending' | 'chit_fund' | 'cryptocurrency' | 'commodity' | 'hedge_fund' | 'angel_investment';
export type RiskRating = 'low' | 'medium' | 'high' | 'very_high';
export type InvestmentTransactionType = 'buy' | 'sell' | 'sip' | 'dividend' | 'interest' | 'bonus' | 'withdrawal' | 'contribution' | 'premium';

// ==================== Core Entities ====================

export interface Account {
  id: string;
  name: string;
  type: AccountType;
  balance: number;
  currency: Currency;
  icon?: string;
  color?: string;
  is_active: boolean;
  created_at: Date | string;
  updated_at: Date | string;
}

export interface Transaction {
  id: string;
  account_id: string;
  type: TransactionType;
  category: string;
  amount: number;
  description?: string;
  date: Date | string;
  tags?: string[];
  location?: string;
  receipt_url?: string;
  is_recurring: boolean;
  recurring_frequency?: RecurringFrequency;
  is_initial_balance: boolean;
  import_reference?: string;
  import_transaction_id?: string;
  import_file_hash?: string;
  import_source?: string;
  import_date?: Date | string;
  created_at: Date | string;
  updated_at: Date | string;
}

export interface Budget {
  id: string;
  name: string;
  description?: string;
  period_type: BudgetPeriodType;
  start_date: Date | string;
  end_date?: Date | string;
  is_recurring: boolean;
  rollover_enabled: boolean;
  rollover_amount: number;
  is_active: boolean;
  created_at: Date | string;
  updated_at: Date | string;
}

export interface BudgetCategory {
  id: string;
  budget_id: string;
  category: string;
  allocated_amount: number;
  alert_threshold: number;
  notes?: string;
  created_at: Date | string;
  updated_at: Date | string;
}

export interface Goal {
  id: string;
  name: string;
  target_amount: number;
  current_amount: number;
  target_date?: Date | string;
  category: string;
  priority?: GoalPriority;
  status: GoalStatus;
  icon?: string;
  color?: string;
  created_at: Date | string;
  updated_at: Date | string;
}

export interface GoalContribution {
  id: string;
  goal_id: string;
  amount: number;
  date: Date | string;
  note?: string;
  created_at: Date | string;
}

export interface Category {
  id: string;
  name: string;
  type: CategoryType;
  icon?: string;
  color?: string;
  parent_id?: string;
  is_default: boolean;
  created_at: Date | string;
}

// ==================== Investment Details ====================

export interface DepositDetails {
  id: string;
  account_id: string;
  principal_amount: number;
  maturity_amount: number;
  current_value: number;
  start_date: Date | string;
  maturity_date: Date | string;
  last_interest_date?: Date | string;
  interest_rate: number;
  interest_payout_frequency: InterestPayoutFrequency;
  total_interest_earned: number;
  tenure_months: number;
  completed_months: number;
  remaining_months: number;
  tds_deducted: number;
  tax_deduction_section?: TaxDeductionSection;
  is_tax_saving: boolean;
  status: DepositStatus;
  auto_renewal: boolean;
  premature_withdrawal_allowed: boolean;
  loan_against_deposit_allowed: boolean;
  bank_name?: string;
  branch?: string;
  account_number?: string;
  certificate_number?: string;
  nominee_name?: string;
  nominee_relationship?: string;
  notes?: string;
  created_at: Date | string;
  updated_at: Date | string;
}

export interface CreditCardDetails {
  id: string;
  account_id: string;
  credit_limit: number;
  available_credit: number;
  current_balance: number;
  minimum_due: number;
  total_due: number;
  billing_cycle_day: number;
  statement_date?: Date | string;
  payment_due_date?: Date | string;
  last_payment_amount?: number;
  last_payment_date?: Date | string;
  annual_fee: number;
  interest_rate?: number;
  late_payment_fee: number;
  over_limit_fee?: number;
  foreign_transaction_fee?: number;
  rewards_points: number;
  rewards_value: number;
  cashback_earned: number;
  status: CreditCardStatus;
  autopay_enabled: boolean;
  card_network?: CardNetwork;
  card_type?: CardType;
  card_last_four?: string;
  card_expiry_date?: Date | string;
  cardholder_name?: string;
  notes?: string;
  created_at: Date | string;
  updated_at: Date | string;
}

export interface BrokerageDetails {
  id: string;
  account_id: string;
  broker_name: string;
  account_number?: string;
  demat_account_number?: string;
  trading_account_number?: string;
  invested_value: number;
  current_value: number;
  total_returns: number;
  total_returns_percentage: number;
  realized_gains: number;
  unrealized_gains: number;
  equity_holdings: number;
  mutual_fund_holdings: number;
  bond_holdings: number;
  etf_holdings: number;
  account_type?: BrokerageAccountType;
  status: BrokerageStatus;
  auto_square_off: boolean;
  margin_enabled: boolean;
  notes?: string;
  created_at: Date | string;
  updated_at: Date | string;
}

export interface InsuranceDetails {
  id: string;
  account_id: string;
  policy_number: string;
  policy_type: InsurancePolicyType;
  plan_name: string;
  insurance_company: string;
  sum_assured: number;
  premium_amount: number;
  premium_frequency: PremiumFrequency;
  policy_term: number;
  policy_start_date: Date | string;
  policy_maturity_date: Date | string;
  last_premium_paid_date?: Date | string;
  next_premium_due_date?: Date | string;
  fund_value: number;
  maturity_benefit?: number;
  bonus_accumulated: number;
  nominee_name: string;
  nominee_relationship?: string;
  status: InsuranceStatus;
  notes?: string;
  created_at: Date | string;
  updated_at: Date | string;
}

export interface PensionAccount {
  id: string;
  account_id: string;
  scheme_type: PensionSchemeType;
  pran_number?: string;
  uan_number?: string;
  account_number?: string;
  employee_contribution: number;
  employer_contribution: number;
  total_corpus: number;
  equity_percentage?: number;
  corporate_debt_percentage?: number;
  government_securities_percentage?: number;
  pension_fund_manager?: string;
  guaranteed_pension_amount?: number;
  account_opening_date: Date | string;
  vesting_age: number;
  status: PensionStatus;
  notes?: string;
  created_at: Date | string;
  updated_at: Date | string;
}

export interface RealEstateInvestment {
  id: string;
  account_id: string;
  investment_type: RealEstateType;
  property_address?: string;
  property_type?: PropertyType;
  carpet_area?: number;
  purchase_price: number;
  purchase_date: Date | string;
  estimated_market_value?: number;
  last_valuation_date?: Date | string;
  is_rented: boolean;
  monthly_rental_income?: number;
  has_loan: boolean;
  outstanding_loan?: number;
  emi_amount?: number;
  units_held?: number;
  current_nav?: number;
  status: RealEstateStatus;
  notes?: string;
  created_at: Date | string;
  updated_at: Date | string;
}

export interface PreciousMetal {
  id: string;
  account_id: string;
  metal_type: MetalType;
  investment_form: MetalInvestmentForm;
  quantity_in_grams: number;
  purity?: string;
  average_purchase_price_per_gram: number;
  total_purchase_cost: number;
  purchase_date: Date | string;
  current_price_per_gram?: number;
  current_value?: number;
  storage_location?: MetalStorageLocation;
  bond_certificate_number?: string;
  interest_rate?: number;
  maturity_date?: Date | string;
  folio_number?: string;
  fund_name?: string;
  units_held?: number;
  notes?: string;
  created_at: Date | string;
  updated_at: Date | string;
}

export interface AlternativeInvestment {
  id: string;
  account_id: string;
  investment_type: AlternativeInvestmentType;
  platform_name: string;
  investment_id?: string;
  invested_amount: number;
  current_value?: number;
  interest_rate?: number;
  principal_recovered?: number;
  interest_earned?: number;
  chit_group_name?: string;
  total_chit_value?: number;
  monthly_contribution?: number;
  is_prized: boolean;
  crypto_symbol?: string;
  quantity?: number;
  wallet_address?: string;
  company_name?: string;
  equity_percentage?: number;
  risk_rating?: RiskRating;
  status: AlternativeInvestmentStatus;
  total_returns?: number;
  notes?: string;
  created_at: Date | string;
  updated_at: Date | string;
}

export interface InvestmentTransaction {
  id: string;
  account_id: string;
  transaction_type: InvestmentTransactionType;
  transaction_date: Date | string;
  transaction_amount: number;
  quantity?: number;
  price_per_unit?: number;
  brokerage_fee?: number;
  stt_charges?: number;
  gst_charges?: number;
  tds_deducted?: number;
  transaction_ref?: string;
  notes?: string;
  created_at: Date | string;
}

// ==================== Input/Output Types ====================

export type CreateAccountInput = Omit<Account, 'id' | 'created_at' | 'updated_at'>;
export type UpdateAccountInput = Partial<Omit<Account, 'id' | 'created_at' | 'updated_at'>>;
export type CreateTransactionInput = Omit<Transaction, 'id' | 'created_at' | 'updated_at'>;
export type UpdateTransactionInput = Partial<Omit<Transaction, 'id' | 'created_at' | 'updated_at'>>;
export type CreateBudgetInput = Omit<Budget, 'id' | 'created_at' | 'updated_at'>;
export type UpdateBudgetInput = Partial<Omit<Budget, 'id' | 'created_at' | 'updated_at'>>;
export type CreateGoalInput = Omit<Goal, 'id' | 'current_amount' | 'created_at' | 'updated_at'>;
export type UpdateGoalInput = Partial<Omit<Goal, 'id' | 'created_at' | 'updated_at'>>;
export type CreateDepositDetailsInput = Omit<DepositDetails, 'id' | 'created_at' | 'updated_at'>;
export type UpdateDepositDetailsInput = Partial<Omit<DepositDetails, 'id' | 'account_id' | 'created_at' | 'updated_at'>>;
export type CreateInsuranceDetailsInput = Omit<InsuranceDetails, 'id' | 'created_at' | 'updated_at'>;
export type UpdateInsuranceDetailsInput = Partial<Omit<InsuranceDetails, 'id' | 'account_id' | 'created_at' | 'updated_at'>>;
export type CreatePensionAccountInput = Omit<PensionAccount, 'id' | 'created_at' | 'updated_at'>;
export type UpdatePensionAccountInput = Partial<Omit<PensionAccount, 'id' | 'account_id' | 'created_at' | 'updated_at'>>;
export type CreateRealEstateInput = Omit<RealEstateInvestment, 'id' | 'created_at' | 'updated_at'>;
export type UpdateRealEstateInput = Partial<Omit<RealEstateInvestment, 'id' | 'account_id' | 'created_at' | 'updated_at'>>;
export type CreatePreciousMetalInput = Omit<PreciousMetal, 'id' | 'created_at' | 'updated_at'>;
export type UpdatePreciousMetalInput = Partial<Omit<PreciousMetal, 'id' | 'account_id' | 'created_at' | 'updated_at'>>;
export type CreateAlternativeInvestmentInput = Omit<AlternativeInvestment, 'id' | 'created_at' | 'updated_at'>;
export type UpdateAlternativeInvestmentInput = Partial<Omit<AlternativeInvestment, 'id' | 'account_id' | 'created_at' | 'updated_at'>>;

// ==================== Response Types ====================

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: unknown;
  };
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

export interface AccountSummary {
  totalAccounts: number;
  activeAccounts: number;
  totalBalance: number;
  accountsByType: Record<AccountType, number>;
}

export interface TransactionSummary {
  totalTransactions: number;
  totalIncome: number;
  totalExpense: number;
  netFlow: number;
  transactionsByCategory: Record<string, number>;
}

export interface BudgetProgress {
  budget_id: string;
  category: string;
  allocated: number;
  spent: number;
  remaining: number;
  percentage: number;
  status: 'under_budget' | 'on_track' | 'over_budget';
}

export interface InvestmentPortfolioSummary {
  totalInvested: number;
  currentValue: number;
  totalReturns: number;
  returnsPercentage: number;
  investmentsByType: Record<AccountType, {
    invested: number;
    current: number;
    returns: number;
  }>;
}
