/**
 * Database schema definitions
 * Defines all tables and their structures
 */

export const DATABASE_VERSION = 8; // Updated: Comprehensive investment types support

/**
 * SQL schema for the entire database
 * Following PostgreSQL syntax for PGlite compatibility
 */
export const SCHEMA_SQL = `
-- Accounts table
CREATE TABLE IF NOT EXISTS accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN (
    -- Banking & Cash
    'bank', 
    'credit_card', 
    'upi', 
    'cash', 
    'wallet',
    -- Deposits & Savings
    'fixed_deposit',
    'recurring_deposit',
    'ppf',
    'nsc',
    'kvp',
    'scss',
    'post_office',
    'ssy',
    -- Investments & Brokerage
    'brokerage',
    'mutual_fund',
    'stocks',
    'bonds',
    'etf',
    -- Insurance
    'term_insurance',
    'endowment',
    'money_back',
    'ulip',
    'child_plan',
    -- Retirement
    'nps',
    'apy',
    'epf',
    'vpf',
    -- Real Estate
    'property',
    'reit',
    'invit',
    -- Precious Metals
    'gold',
    'silver',
    -- Alternative Investments
    'p2p_lending',
    'chit_fund',
    'cryptocurrency',
    'commodity',
    'hedge_fund',
    'angel_investment'
  )),
  balance DECIMAL(15, 2) NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'INR',
  icon TEXT,
  color TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  category TEXT NOT NULL,
  amount DECIMAL(15, 2) NOT NULL,
  description TEXT,
  date TIMESTAMP NOT NULL DEFAULT NOW(),
  tags TEXT[] DEFAULT '{}',
  location TEXT,
  receipt_url TEXT,
  is_recurring BOOLEAN NOT NULL DEFAULT false,
  recurring_frequency TEXT CHECK (recurring_frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
  is_initial_balance BOOLEAN NOT NULL DEFAULT false,
  -- Import metadata for duplicate detection
  import_reference TEXT,
  import_transaction_id TEXT,
  import_file_hash TEXT,
  import_source TEXT,
  import_date TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Budgets table (enhanced for multi-category budgets)
CREATE TABLE IF NOT EXISTS budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  period_type TEXT NOT NULL CHECK (period_type IN ('monthly', 'quarterly', 'annual', 'custom', 'event')),
  start_date DATE NOT NULL,
  end_date DATE,
  is_recurring BOOLEAN NOT NULL DEFAULT false,
  rollover_enabled BOOLEAN NOT NULL DEFAULT false,
  rollover_amount DECIMAL(15, 2) DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Budget categories table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS budget_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  allocated_amount DECIMAL(15, 2) NOT NULL,
  alert_threshold DECIMAL(5, 2) DEFAULT 0.80, -- Alert at 80% usage
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(budget_id, category)
);

-- Budget history table (for tracking over time)
CREATE TABLE IF NOT EXISTS budget_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  allocated DECIMAL(15, 2) NOT NULL,
  spent DECIMAL(15, 2) NOT NULL,
  variance DECIMAL(15, 2) NOT NULL,
  rollover_from_previous DECIMAL(15, 2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Goals table
CREATE TABLE IF NOT EXISTS goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  target_amount DECIMAL(15, 2) NOT NULL,
  current_amount DECIMAL(15, 2) NOT NULL DEFAULT 0,
  target_date DATE,
  category TEXT NOT NULL,
  priority TEXT CHECK (priority IN ('low', 'medium', 'high')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused', 'cancelled')),
  icon TEXT,
  color TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Goal contributions table (track deposits towards goals)
CREATE TABLE IF NOT EXISTS goal_contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  amount DECIMAL(15, 2) NOT NULL,
  date TIMESTAMP NOT NULL DEFAULT NOW(),
  note TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Deposit details table (for deposit instruments like FD, RD, PPF, etc)
CREATE TABLE IF NOT EXISTS deposit_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE UNIQUE,
  
  -- Principal and maturity
  principal_amount DECIMAL(15, 2) NOT NULL,
  maturity_amount DECIMAL(15, 2) NOT NULL,
  current_value DECIMAL(15, 2) NOT NULL DEFAULT 0,
  
  -- Dates
  start_date DATE NOT NULL,
  maturity_date DATE NOT NULL,
  last_interest_date DATE,
  
  -- Interest details
  interest_rate DECIMAL(5, 2) NOT NULL,
  interest_payout_frequency TEXT CHECK (interest_payout_frequency IN ('monthly', 'quarterly', 'annually', 'maturity')),
  total_interest_earned DECIMAL(15, 2) NOT NULL DEFAULT 0,
  
  -- Tenure
  tenure_months INTEGER NOT NULL,
  completed_months INTEGER NOT NULL DEFAULT 0,
  remaining_months INTEGER NOT NULL,
  
  -- Tax information
  tds_deducted DECIMAL(15, 2) NOT NULL DEFAULT 0,
  tax_deduction_section TEXT,
  is_tax_saving BOOLEAN NOT NULL DEFAULT false,
  
  -- Status and options
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'matured', 'prematurely_closed', 'renewed')),
  auto_renewal BOOLEAN NOT NULL DEFAULT false,
  premature_withdrawal_allowed BOOLEAN NOT NULL DEFAULT true,
  loan_against_deposit_allowed BOOLEAN NOT NULL DEFAULT false,
  
  -- Institution details
  bank_name TEXT,
  branch TEXT,
  account_number TEXT,
  certificate_number TEXT,
  
  -- Nominee
  nominee_name TEXT,
  nominee_relationship TEXT,
  
  -- Additional metadata
  notes TEXT,
  
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Credit card details table (for credit card specific information)
CREATE TABLE IF NOT EXISTS credit_card_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE UNIQUE,
  
  -- Credit limits
  credit_limit DECIMAL(15, 2) NOT NULL,
  available_credit DECIMAL(15, 2) NOT NULL,
  
  -- Billing cycle
  billing_cycle_day INTEGER NOT NULL CHECK (billing_cycle_day >= 1 AND billing_cycle_day <= 31),
  statement_date DATE,
  payment_due_date DATE,
  
  -- Outstanding amounts
  current_balance DECIMAL(15, 2) NOT NULL DEFAULT 0,
  minimum_due DECIMAL(15, 2) NOT NULL DEFAULT 0,
  total_due DECIMAL(15, 2) NOT NULL DEFAULT 0,
  
  -- Interest and fees
  interest_rate DECIMAL(5, 2),
  annual_fee DECIMAL(15, 2) DEFAULT 0,
  late_payment_fee DECIMAL(15, 2) DEFAULT 0,
  
  -- Rewards and benefits
  rewards_points INTEGER DEFAULT 0,
  rewards_value DECIMAL(15, 2) DEFAULT 0,
  cashback_earned DECIMAL(15, 2) DEFAULT 0,
  
  -- Card details
  card_network TEXT CHECK (card_network IN ('visa', 'mastercard', 'amex', 'rupay', 'diners')),
  card_type TEXT CHECK (card_type IN ('credit', 'charge')),
  last_four_digits TEXT,
  expiry_date DATE,
  
  -- Bank details
  issuer_bank TEXT,
  customer_id TEXT,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'blocked', 'closed')),
  autopay_enabled BOOLEAN NOT NULL DEFAULT false,
  
  -- Additional metadata
  notes TEXT,
  
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Brokerage details table (for investment accounts)
CREATE TABLE IF NOT EXISTS brokerage_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE UNIQUE,
  
  -- Account information
  broker_name TEXT NOT NULL,
  account_number TEXT,
  demat_account_number TEXT,
  trading_account_number TEXT,
  
  -- Account values
  invested_value DECIMAL(15, 2) NOT NULL DEFAULT 0,
  current_value DECIMAL(15, 2) NOT NULL DEFAULT 0,
  total_returns DECIMAL(15, 2) NOT NULL DEFAULT 0,
  total_returns_percentage DECIMAL(5, 2) NOT NULL DEFAULT 0,
  
  -- P&L tracking
  realized_gains DECIMAL(15, 2) NOT NULL DEFAULT 0,
  unrealized_gains DECIMAL(15, 2) NOT NULL DEFAULT 0,
  
  -- Holdings summary
  equity_holdings INTEGER NOT NULL DEFAULT 0,
  mutual_fund_holdings INTEGER NOT NULL DEFAULT 0,
  bond_holdings INTEGER NOT NULL DEFAULT 0,
  etf_holdings INTEGER NOT NULL DEFAULT 0,
  
  -- Account type
  account_type TEXT CHECK (account_type IN ('trading', 'demat', 'combined')),
  
  -- Status
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'dormant', 'closed')),
  
  -- Trading preferences
  auto_square_off BOOLEAN NOT NULL DEFAULT false,
  margin_enabled BOOLEAN NOT NULL DEFAULT false,
  
  -- Additional metadata
  notes TEXT,
  
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Categories table (for organizing transactions)
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  icon TEXT,
  color TEXT,
  parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Settings table (key-value store for app settings)
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Insurance details table (for all insurance products)
CREATE TABLE IF NOT EXISTS insurance_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE UNIQUE,
  
  -- Policy information
  policy_number TEXT NOT NULL,
  policy_type TEXT NOT NULL CHECK (policy_type IN ('term', 'endowment', 'money_back', 'ulip', 'child')),
  plan_name TEXT NOT NULL,
  insurance_company TEXT NOT NULL,
  
  -- Coverage details
  sum_assured DECIMAL(15, 2) NOT NULL,
  premium_amount DECIMAL(15, 2) NOT NULL,
  premium_frequency TEXT CHECK (premium_frequency IN ('monthly', 'quarterly', 'half_yearly', 'annual')),
  policy_term INTEGER NOT NULL,
  
  -- Dates
  policy_start_date DATE NOT NULL,
  policy_maturity_date DATE NOT NULL,
  last_premium_paid_date DATE,
  next_premium_due_date DATE,
  
  -- Investment component (for ULIP, endowment)
  fund_value DECIMAL(15, 2) DEFAULT 0,
  maturity_benefit DECIMAL(15, 2),
  bonus_accumulated DECIMAL(15, 2) DEFAULT 0,
  
  -- Nominee details
  nominee_name TEXT NOT NULL,
  nominee_relationship TEXT,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paid_up', 'lapsed', 'matured', 'surrendered')),
  
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Pension accounts table (NPS, APY, EPF, VPF)
CREATE TABLE IF NOT EXISTS pension_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE UNIQUE,
  
  -- Account information
  scheme_type TEXT NOT NULL CHECK (scheme_type IN ('nps', 'apy', 'epf', 'vpf')),
  pran_number TEXT,
  uan_number TEXT,
  account_number TEXT,
  
  -- Contribution details
  employee_contribution DECIMAL(15, 2) DEFAULT 0,
  employer_contribution DECIMAL(15, 2) DEFAULT 0,
  total_corpus DECIMAL(15, 2) DEFAULT 0,
  
  -- Investment allocation (for NPS)
  equity_percentage DECIMAL(5, 2),
  corporate_debt_percentage DECIMAL(5, 2),
  government_securities_percentage DECIMAL(5, 2),
  pension_fund_manager TEXT,
  
  -- Pension details (for APY)
  guaranteed_pension_amount DECIMAL(15, 2),
  
  -- Dates
  account_opening_date DATE NOT NULL,
  vesting_age INTEGER DEFAULT 60,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'matured')),
  
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Real estate investments table
CREATE TABLE IF NOT EXISTS real_estate_investments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE UNIQUE,
  
  -- Investment type
  investment_type TEXT NOT NULL CHECK (investment_type IN ('property', 'reit', 'invit')),
  
  -- Property details
  property_address TEXT,
  property_type TEXT CHECK (property_type IN ('residential_flat', 'independent_house', 'commercial_office', 'shop', 'plot', 'agricultural_land')),
  carpet_area DECIMAL(10, 2),
  
  -- Purchase details
  purchase_price DECIMAL(15, 2) NOT NULL,
  purchase_date DATE NOT NULL,
  
  -- Current valuation
  estimated_market_value DECIMAL(15, 2),
  last_valuation_date DATE,
  
  -- Rental income
  is_rented BOOLEAN DEFAULT false,
  monthly_rental_income DECIMAL(15, 2),
  
  -- Loan details
  has_loan BOOLEAN DEFAULT false,
  outstanding_loan DECIMAL(15, 2),
  emi_amount DECIMAL(15, 2),
  
  -- REIT/InvIT specific
  units_held DECIMAL(15, 4),
  current_nav DECIMAL(10, 2),
  
  -- Status
  status TEXT NOT NULL DEFAULT 'owned' CHECK (status IN ('owned', 'under_construction', 'sold', 'inherited')),
  
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Precious metals table (Gold, Silver)
CREATE TABLE IF NOT EXISTS precious_metals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE UNIQUE,
  
  -- Metal type
  metal_type TEXT NOT NULL CHECK (metal_type IN ('gold', 'silver')),
  
  -- Form of investment
  investment_form TEXT NOT NULL CHECK (investment_form IN ('physical', 'sgb', 'etf', 'digital', 'mutual_fund')),
  
  -- Quantity tracking
  quantity_in_grams DECIMAL(15, 6) NOT NULL,
  purity TEXT,
  
  -- Purchase details
  average_purchase_price_per_gram DECIMAL(10, 2) NOT NULL,
  total_purchase_cost DECIMAL(15, 2) NOT NULL,
  purchase_date DATE NOT NULL,
  
  -- Current valuation
  current_price_per_gram DECIMAL(10, 2),
  current_value DECIMAL(15, 2),
  
  -- Physical storage
  storage_location TEXT CHECK (storage_location IN ('home', 'bank_locker', 'vault', 'jeweller')),
  
  -- SGB specific
  bond_certificate_number TEXT,
  interest_rate DECIMAL(5, 2),
  maturity_date DATE,
  
  -- ETF/MF specific
  folio_number TEXT,
  fund_name TEXT,
  units_held DECIMAL(15, 6),
  
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Alternative investments table
CREATE TABLE IF NOT EXISTS alternative_investments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE UNIQUE,
  
  -- Investment type
  investment_type TEXT NOT NULL CHECK (investment_type IN ('p2p_lending', 'chit_fund', 'cryptocurrency', 'commodity', 'hedge_fund', 'angel_investment')),
  
  -- Platform/Company details
  platform_name TEXT NOT NULL,
  investment_id TEXT,
  
  -- Investment details
  invested_amount DECIMAL(15, 2) NOT NULL,
  current_value DECIMAL(15, 2),
  
  -- P2P Lending specific
  interest_rate DECIMAL(5, 2),
  principal_recovered DECIMAL(15, 2),
  interest_earned DECIMAL(15, 2),
  
  -- Chit Fund specific
  chit_group_name TEXT,
  total_chit_value DECIMAL(15, 2),
  monthly_contribution DECIMAL(10, 2),
  is_prized BOOLEAN DEFAULT false,
  
  -- Cryptocurrency specific
  crypto_symbol TEXT,
  quantity DECIMAL(20, 8),
  wallet_address TEXT,
  
  -- Startup/Angel specific
  company_name TEXT,
  equity_percentage DECIMAL(5, 2),
  
  -- Risk & Status
  risk_rating TEXT CHECK (risk_rating IN ('low', 'medium', 'high', 'very_high')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'defaulted', 'matured', 'exited', 'written_off')),
  
  -- Returns
  total_returns DECIMAL(15, 2),
  
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Investment transactions table (unified transaction tracking)
CREATE TABLE IF NOT EXISTS investment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  
  -- Transaction details
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('buy', 'sell', 'sip', 'dividend', 'interest', 'bonus', 'withdrawal', 'contribution', 'premium')),
  transaction_date DATE NOT NULL,
  
  -- Amounts
  transaction_amount DECIMAL(15, 2) NOT NULL,
  quantity DECIMAL(15, 6),
  price_per_unit DECIMAL(15, 4),
  
  -- Fees and charges
  brokerage_fee DECIMAL(10, 2),
  stt_charges DECIMAL(10, 2),
  gst_charges DECIMAL(10, 2),
  tds_deducted DECIMAL(10, 2),
  
  -- Reference
  transaction_ref TEXT,
  
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
-- Import metadata indices for duplicate detection
CREATE INDEX IF NOT EXISTS idx_transactions_import_ref ON transactions(import_reference);
CREATE INDEX IF NOT EXISTS idx_transactions_import_txn_id ON transactions(import_transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_file_hash ON transactions(import_file_hash);
CREATE INDEX IF NOT EXISTS idx_transactions_account_date_amount ON transactions(account_id, date, amount);
CREATE INDEX IF NOT EXISTS idx_goal_contributions_goal_id ON goal_contributions(goal_id);
CREATE INDEX IF NOT EXISTS idx_categories_type ON categories(type);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_deposit_details_account_id ON deposit_details(account_id);
CREATE INDEX IF NOT EXISTS idx_deposit_details_maturity_date ON deposit_details(maturity_date);
CREATE INDEX IF NOT EXISTS idx_credit_card_details_account_id ON credit_card_details(account_id);
CREATE INDEX IF NOT EXISTS idx_credit_card_details_payment_due_date ON credit_card_details(payment_due_date);
CREATE INDEX IF NOT EXISTS idx_brokerage_details_account_id ON brokerage_details(account_id);
CREATE INDEX IF NOT EXISTS idx_insurance_details_account_id ON insurance_details(account_id);
CREATE INDEX IF NOT EXISTS idx_insurance_details_maturity_date ON insurance_details(policy_maturity_date);
CREATE INDEX IF NOT EXISTS idx_insurance_details_status ON insurance_details(status);
CREATE INDEX IF NOT EXISTS idx_pension_accounts_account_id ON pension_accounts(account_id);
CREATE INDEX IF NOT EXISTS idx_pension_accounts_scheme_type ON pension_accounts(scheme_type);
CREATE INDEX IF NOT EXISTS idx_real_estate_account_id ON real_estate_investments(account_id);
CREATE INDEX IF NOT EXISTS idx_real_estate_type ON real_estate_investments(investment_type);
CREATE INDEX IF NOT EXISTS idx_precious_metals_account_id ON precious_metals(account_id);
CREATE INDEX IF NOT EXISTS idx_precious_metals_type ON precious_metals(metal_type);
CREATE INDEX IF NOT EXISTS idx_alternative_investments_account_id ON alternative_investments(account_id);
CREATE INDEX IF NOT EXISTS idx_alternative_investments_type ON alternative_investments(investment_type);
CREATE INDEX IF NOT EXISTS idx_investment_transactions_account_id ON investment_transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_investment_transactions_date ON investment_transactions(transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_investment_transactions_type ON investment_transactions(transaction_type);

-- Budget indices
CREATE INDEX IF NOT EXISTS idx_budgets_period ON budgets(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_budgets_active ON budgets(is_active);
CREATE INDEX IF NOT EXISTS idx_budget_categories_budget_id ON budget_categories(budget_id);
CREATE INDEX IF NOT EXISTS idx_budget_categories_category ON budget_categories(category);
CREATE INDEX IF NOT EXISTS idx_budget_history_budget_id ON budget_history(budget_id);
CREATE INDEX IF NOT EXISTS idx_budget_history_period ON budget_history(period_start, period_end);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to tables
CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON budgets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_budget_categories_updated_at BEFORE UPDATE ON budget_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON goals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deposit_details_updated_at BEFORE UPDATE ON deposit_details
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_credit_card_details_updated_at BEFORE UPDATE ON credit_card_details
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_brokerage_details_updated_at BEFORE UPDATE ON brokerage_details
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_insurance_details_updated_at BEFORE UPDATE ON insurance_details
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pension_accounts_updated_at BEFORE UPDATE ON pension_accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_real_estate_updated_at BEFORE UPDATE ON real_estate_investments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_precious_metals_updated_at BEFORE UPDATE ON precious_metals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_alternative_investments_updated_at BEFORE UPDATE ON alternative_investments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
`;

/**
 * Default categories to seed on first run
 */
export const DEFAULT_CATEGORIES = [
  // Income categories
  { name: 'Salary', type: 'income', icon: '💼', color: '#10b981' },
  { name: 'Freelance', type: 'income', icon: '💻', color: '#3b82f6' },
  { name: 'Investment', type: 'income', icon: '📈', color: '#8b5cf6' },
  { name: 'Gift', type: 'income', icon: '🎁', color: '#ec4899' },
  { name: 'Other Income', type: 'income', icon: '💰', color: '#6b7280' },

  // Expense categories
  { name: 'Food & Dining', type: 'expense', icon: '🍽️', color: '#ef4444' },
  { name: 'Transportation', type: 'expense', icon: '🚗', color: '#f59e0b' },
  { name: 'Shopping', type: 'expense', icon: '🛍️', color: '#ec4899' },
  { name: 'Entertainment', type: 'expense', icon: '🎬', color: '#8b5cf6' },
  { name: 'Healthcare', type: 'expense', icon: '🏥', color: '#ef4444' },
  { name: 'Education', type: 'expense', icon: '📚', color: '#3b82f6' },
  { name: 'Bills & Utilities', type: 'expense', icon: '💡', color: '#f59e0b' },
  { name: 'Rent', type: 'expense', icon: '🏠', color: '#06b6d4' },
  { name: 'Insurance', type: 'expense', icon: '🛡️', color: '#10b981' },
  { name: 'Savings', type: 'expense', icon: '🏦', color: '#10b981' },
  { name: 'Other Expense', type: 'expense', icon: '📝', color: '#6b7280' },
] as const;

/**
 * Insert default categories SQL
 */
export const SEED_CATEGORIES_SQL = `
INSERT INTO categories (name, type, icon, color, is_default)
VALUES
  ${DEFAULT_CATEGORIES.map(
    (cat) =>
      `('${cat.name}', '${cat.type}', '${cat.icon}', '${cat.color}', true)`
  ).join(',\n  ')}
ON CONFLICT (name) DO NOTHING;
`;
