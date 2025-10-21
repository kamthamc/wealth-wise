/**
 * Database schema definitions
 * Defines all tables and their structures
 */

export const DATABASE_VERSION = 5; // Updated: Added credit_card_details and brokerage_details tables

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
    'bank', 
    'credit_card', 
    'upi', 
    'brokerage', 
    'cash', 
    'wallet',
    'fixed_deposit',
    'recurring_deposit',
    'ppf',
    'nsc',
    'kvp',
    'scss',
    'post_office'
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
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Budgets table
CREATE TABLE IF NOT EXISTS budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  amount DECIMAL(15, 2) NOT NULL,
  spent DECIMAL(15, 2) NOT NULL DEFAULT 0,
  period TEXT NOT NULL CHECK (period IN ('daily', 'weekly', 'monthly', 'yearly')),
  start_date DATE NOT NULL,
  end_date DATE,
  alert_threshold INTEGER DEFAULT 80,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
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

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_goal_contributions_goal_id ON goal_contributions(goal_id);
CREATE INDEX IF NOT EXISTS idx_categories_type ON categories(type);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_deposit_details_account_id ON deposit_details(account_id);
CREATE INDEX IF NOT EXISTS idx_deposit_details_maturity_date ON deposit_details(maturity_date);
CREATE INDEX IF NOT EXISTS idx_credit_card_details_account_id ON credit_card_details(account_id);
CREATE INDEX IF NOT EXISTS idx_credit_card_details_payment_due_date ON credit_card_details(payment_due_date);
CREATE INDEX IF NOT EXISTS idx_brokerage_details_account_id ON brokerage_details(account_id);

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

CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON goals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deposit_details_updated_at BEFORE UPDATE ON deposit_details
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_credit_card_details_updated_at BEFORE UPDATE ON credit_card_details
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_brokerage_details_updated_at BEFORE UPDATE ON brokerage_details
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
