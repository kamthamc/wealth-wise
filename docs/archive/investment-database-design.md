# Comprehensive Investment Database Design

**Date**: November 2, 2025  
**Purpose**: Database schema validation and enhancement for 41 investment types in India

## Current Database Analysis

### ✅ Existing Coverage (Good Foundation)

#### 1. **Deposit Instruments** - FULLY SUPPORTED
- Fixed Deposits (FD)
- Recurring Deposits (RD)
- PPF (Public Provident Fund)
- NSC (National Savings Certificate)
- KVP (Kisan Vikas Patra)
- SCSS (Senior Citizen Savings Scheme)
- Post Office Savings Schemes

**Implementation**: `deposit_details` table with:
- Principal, maturity amounts, interest rates
- Tenure tracking, TDS management
- Auto-renewal options, nominee details
- Status tracking (active, matured, closed)

#### 2. **Brokerage Accounts** - FULLY SUPPORTED
- Direct Equity/Stocks
- Equity Mutual Funds
- ETFs (Exchange Traded Funds)
- Bonds tracking

**Implementation**: `brokerage_details` table with:
- Broker information, account numbers
- Demat/trading account details
- Holdings summary (equity, MF, bonds, ETFs)
- P&L tracking (realized/unrealized gains)
- Investment vs current value tracking

#### 3. **Credit Cards** - FULLY SUPPORTED
**Implementation**: `credit_card_details` table with:
- Credit limits, billing cycles
- Payment due dates, interest rates
- Rewards tracking, statement management

#### 4. **Basic Accounts** - FULLY SUPPORTED
- Bank Accounts
- UPI Wallets
- Cash
- Digital Wallets

**Implementation**: Core `accounts` table with balance tracking

---

## 🔄 Required Enhancements

### **Missing Investment Types - Need New Tables**

#### 1. **Insurance Products** (5 types)
**Investment Types**:
- Term Insurance Plans (#40)
- Endowment Plans (#39)
- Money-Back Plans (#39)
- ULIPs (Unit-Linked Insurance Plans) (#23)
- Child Plans (#41)

**Proposed Table**: `insurance_details`
```sql
CREATE TABLE insurance_details (
  id UUID PRIMARY KEY,
  account_id UUID REFERENCES accounts(id) UNIQUE,
  
  -- Policy information
  policy_number TEXT NOT NULL,
  policy_type TEXT CHECK (policy_type IN ('term', 'endowment', 'money_back', 'ulip', 'child')),
  plan_name TEXT NOT NULL,
  insurance_company TEXT NOT NULL,
  
  -- Coverage details
  sum_assured DECIMAL(15, 2) NOT NULL,
  premium_amount DECIMAL(15, 2) NOT NULL,
  premium_frequency TEXT CHECK (premium_frequency IN ('monthly', 'quarterly', 'half_yearly', 'annual')),
  policy_term INTEGER NOT NULL, -- in years
  
  -- Dates
  policy_start_date DATE NOT NULL,
  policy_maturity_date DATE NOT NULL,
  last_premium_paid_date DATE,
  next_premium_due_date DATE,
  
  -- Investment component (for ULIP, endowment)
  fund_value DECIMAL(15, 2) DEFAULT 0,
  maturity_benefit DECIMAL(15, 2),
  fund_allocation JSONB, -- {"equity": 60, "debt": 30, "liquid": 10}
  
  -- Riders and add-ons
  riders JSONB, -- [{"name": "Critical Illness", "cover": 500000}]
  
  -- Nominee details
  nominee_name TEXT NOT NULL,
  nominee_relationship TEXT,
  nominee_dob DATE,
  
  -- Additional benefits
  waiver_of_premium BOOLEAN DEFAULT false,
  bonus_accumulated DECIMAL(15, 2) DEFAULT 0,
  loyalty_additions DECIMAL(15, 2) DEFAULT 0,
  
  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paid_up', 'lapsed', 'matured', 'surrendered')),
  
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### 2. **Retirement & Pension Schemes** (3 types)
**Investment Types**:
- National Pension System (NPS) (#4)
- Atal Pension Yojana (APY) (#12)
- EPF (Employee Provident Fund) (#13)
- VPF (Voluntary Provident Fund) (#14)

**Proposed Table**: `pension_accounts`
```sql
CREATE TABLE pension_accounts (
  id UUID PRIMARY KEY,
  account_id UUID REFERENCES accounts(id) UNIQUE,
  
  -- Account information
  scheme_type TEXT NOT NULL CHECK (scheme_type IN ('nps', 'apy', 'epf', 'vpf')),
  pran_number TEXT, -- Permanent Retirement Account Number for NPS/APY
  uan_number TEXT, -- Universal Account Number for EPF/VPF
  account_number TEXT,
  
  -- Contribution details
  employee_contribution DECIMAL(15, 2) DEFAULT 0,
  employer_contribution DECIMAL(15, 2) DEFAULT 0,
  voluntary_contribution DECIMAL(15, 2) DEFAULT 0,
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
  
  -- Withdrawal tracking
  partial_withdrawals_made INTEGER DEFAULT 0,
  partial_withdrawal_amount DECIMAL(15, 2) DEFAULT 0,
  
  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'matured')),
  
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### 3. **Real Estate Investments** (2 types)
**Investment Types**:
- Residential/Commercial Property (#33)
- REITs (Real Estate Investment Trusts) (#34)
- InvITs (Infrastructure Investment Trusts) (#35)

**Proposed Table**: `real_estate_investments`
```sql
CREATE TABLE real_estate_investments (
  id UUID PRIMARY KEY,
  account_id UUID REFERENCES accounts(id) UNIQUE,
  
  -- Investment type
  investment_type TEXT NOT NULL CHECK (investment_type IN ('property', 'reit', 'invit')),
  
  -- Property details (for physical real estate)
  property_address TEXT,
  property_type TEXT CHECK (property_type IN ('residential_flat', 'independent_house', 'commercial_office', 'shop', 'warehouse', 'plot', 'agricultural_land')),
  carpet_area DECIMAL(10, 2),
  built_up_area DECIMAL(10, 2),
  
  -- Purchase details
  purchase_price DECIMAL(15, 2) NOT NULL,
  purchase_date DATE NOT NULL,
  registration_cost DECIMAL(15, 2),
  stamp_duty DECIMAL(15, 2),
  
  -- Current valuation
  estimated_market_value DECIMAL(15, 2),
  last_valuation_date DATE,
  
  -- Rental income
  is_rented BOOLEAN DEFAULT false,
  monthly_rental_income DECIMAL(15, 2),
  rental_agreement_end_date DATE,
  tenant_name TEXT,
  
  -- Loan details
  has_loan BOOLEAN DEFAULT false,
  loan_amount DECIMAL(15, 2),
  outstanding_loan DECIMAL(15, 2),
  emi_amount DECIMAL(15, 2),
  loan_tenure_months INTEGER,
  
  -- REIT/InvIT specific
  units_held DECIMAL(15, 4),
  current_nav DECIMAL(10, 2),
  dividend_yield DECIMAL(5, 2),
  
  -- Legal documents
  khata_number TEXT,
  survey_number TEXT,
  property_tax_account TEXT,
  
  -- Status
  status TEXT DEFAULT 'owned' CHECK (status IN ('owned', 'under_construction', 'sold', 'inherited')),
  
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### 4. **Precious Metals** (2 types)
**Investment Types**:
- Gold (Physical, SGB, ETF, Digital) (#30)
- Silver (#31)

**Proposed Table**: `precious_metals`
```sql
CREATE TABLE precious_metals (
  id UUID PRIMARY KEY,
  account_id UUID REFERENCES accounts(id) UNIQUE,
  
  -- Metal type
  metal_type TEXT NOT NULL CHECK (metal_type IN ('gold', 'silver', 'platinum')),
  
  -- Form of investment
  investment_form TEXT NOT NULL CHECK (investment_form IN ('physical', 'sgb', 'etf', 'digital', 'mutual_fund')),
  
  -- Quantity tracking
  quantity_in_grams DECIMAL(15, 6) NOT NULL,
  purity TEXT, -- 22K, 24K, 999, etc.
  
  -- Purchase details
  average_purchase_price_per_gram DECIMAL(10, 2) NOT NULL,
  total_purchase_cost DECIMAL(15, 2) NOT NULL,
  purchase_date DATE NOT NULL,
  
  -- Current valuation
  current_price_per_gram DECIMAL(10, 2),
  current_value DECIMAL(15, 2),
  last_price_update TIMESTAMP,
  
  -- Physical storage (for physical gold/silver)
  storage_location TEXT CHECK (storage_location IN ('home', 'bank_locker', 'vault', 'jeweller')),
  locker_rent_annual DECIMAL(10, 2),
  insurance_value DECIMAL(15, 2),
  
  -- SGB specific
  bond_certificate_number TEXT,
  interest_rate DECIMAL(5, 2),
  maturity_date DATE,
  
  -- ETF/MF specific
  folio_number TEXT,
  fund_name TEXT,
  units_held DECIMAL(15, 6),
  
  -- Making charges (for jewelry)
  making_charges DECIMAL(10, 2),
  stone_value DECIMAL(10, 2),
  
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### 5. **Alternative Investments** (6 types)
**Investment Types**:
- Peer-to-Peer Lending (#38)
- Chit Funds (#36)
- Cryptocurrencies (#28)
- Commodities (Oil, Gas, Agricultural) (#32)
- Hedge Funds (#26)
- Angel Investing (#27)

**Proposed Table**: `alternative_investments`
```sql
CREATE TABLE alternative_investments (
  id UUID PRIMARY KEY,
  account_id UUID REFERENCES accounts(id) UNIQUE,
  
  -- Investment type
  investment_type TEXT NOT NULL CHECK (investment_type IN ('p2p_lending', 'chit_fund', 'cryptocurrency', 'commodity', 'hedge_fund', 'angel', 'startup_equity')),
  
  -- Platform/Company details
  platform_name TEXT NOT NULL,
  investment_id TEXT, -- Platform-specific ID
  
  -- Investment details
  invested_amount DECIMAL(15, 2) NOT NULL,
  current_value DECIMAL(15, 2),
  
  -- P2P Lending specific
  interest_rate DECIMAL(5, 2),
  loan_tenure_months INTEGER,
  emi_received DECIMAL(10, 2),
  principal_recovered DECIMAL(15, 2),
  interest_earned DECIMAL(15, 2),
  default_amount DECIMAL(15, 2) DEFAULT 0,
  
  -- Chit Fund specific
  chit_group_name TEXT,
  foreman_name TEXT,
  total_chit_value DECIMAL(15, 2),
  monthly_contribution DECIMAL(10, 2),
  cycle_duration_months INTEGER,
  is_prized BOOLEAN DEFAULT false,
  prize_amount DECIMAL(15, 2),
  dividend_received DECIMAL(15, 2),
  
  -- Cryptocurrency specific
  crypto_symbol TEXT, -- BTC, ETH, etc.
  quantity DECIMAL(20, 8),
  purchase_price DECIMAL(15, 2),
  wallet_address TEXT,
  exchange_name TEXT,
  
  -- Commodity specific
  commodity_name TEXT, -- Crude Oil, Gold, Wheat, etc.
  contract_size DECIMAL(15, 4),
  contract_expiry_date DATE,
  lot_size INTEGER,
  
  -- Startup/Angel specific
  company_name TEXT,
  equity_percentage DECIMAL(5, 2),
  valuation DECIMAL(18, 2),
  funding_round TEXT, -- Seed, Series A, etc.
  co_investors TEXT[],
  
  -- Risk & Status
  risk_rating TEXT CHECK (risk_rating IN ('low', 'medium', 'high', 'very_high')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'defaulted', 'matured', 'exited', 'written_off')),
  
  -- Returns
  total_returns DECIMAL(15, 2),
  irr_percentage DECIMAL(5, 2),
  
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### 6. **Investment Transactions Tracking**
For detailed transaction history across all investment types:

**Proposed Table**: `investment_transactions`
```sql
CREATE TABLE investment_transactions (
  id UUID PRIMARY KEY,
  account_id UUID NOT NULL REFERENCES accounts(id),
  
  -- Transaction details
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('buy', 'sell', 'sip', 'dividend', 'interest', 'bonus', 'split', 'rights', 'withdrawal', 'contribution', 'maturity', 'premium')),
  transaction_date DATE NOT NULL,
  
  -- Amounts
  transaction_amount DECIMAL(15, 2) NOT NULL,
  quantity DECIMAL(15, 6), -- Units/shares/grams
  price_per_unit DECIMAL(15, 4),
  
  -- Fees and charges
  brokerage_fee DECIMAL(10, 2),
  stt_charges DECIMAL(10, 2),
  gst_charges DECIMAL(10, 2),
  other_charges DECIMAL(10, 2),
  
  -- Tax deductions
  tds_deducted DECIMAL(10, 2),
  
  -- Reference
  transaction_ref TEXT,
  broker_note_number TEXT,
  
  -- Settlement
  settlement_date DATE,
  
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_investment_transactions_account ON investment_transactions(account_id);
CREATE INDEX idx_investment_transactions_date ON investment_transactions(transaction_date DESC);
CREATE INDEX idx_investment_transactions_type ON investment_transactions(transaction_type);
```

---

## Updated Account Types

The `accounts` table should support these additional types:

```sql
ALTER TABLE accounts DROP CONSTRAINT IF EXISTS accounts_type_check;
ALTER TABLE accounts ADD CONSTRAINT accounts_type_check 
CHECK (type IN (
  -- Banking & Cash
  'bank', 'credit_card', 'upi', 'cash', 'wallet',
  
  -- Deposits & Savings
  'fixed_deposit', 'recurring_deposit', 'ppf', 'nsc', 'kvp', 'scss', 'post_office', 'ssy',
  
  -- Investments & Brokerage
  'brokerage', 'mutual_fund', 'stocks', 'bonds', 'etf',
  
  -- Insurance
  'term_insurance', 'endowment', 'money_back', 'ulip', 'child_plan',
  
  -- Retirement
  'nps', 'apy', 'epf', 'vpf',
  
  -- Real Estate
  'property', 'reit', 'invit',
  
  -- Precious Metals
  'gold', 'silver',
  
  -- Alternative
  'p2p_lending', 'chit_fund', 'cryptocurrency', 'commodity', 'hedge_fund', 'angel_investment'
));
```

---

## Database Migration Plan

### Migration 7→8: Add Investment Tables

```sql
-- 1. Add new account types
ALTER TABLE accounts DROP CONSTRAINT IF EXISTS accounts_type_check;
ALTER TABLE accounts ADD CONSTRAINT accounts_type_check CHECK (type IN (
  'bank', 'credit_card', 'upi', 'cash', 'wallet',
  'fixed_deposit', 'recurring_deposit', 'ppf', 'nsc', 'kvp', 'scss', 'post_office', 'ssy',
  'brokerage', 'mutual_fund', 'stocks', 'bonds', 'etf',
  'term_insurance', 'endowment', 'money_back', 'ulip', 'child_plan',
  'nps', 'apy', 'epf', 'vpf',
  'property', 'reit', 'invit',
  'gold', 'silver',
  'p2p_lending', 'chit_fund', 'cryptocurrency', 'commodity', 'hedge_fund', 'angel_investment'
));

-- 2. Create insurance_details table
-- 3. Create pension_accounts table
-- 4. Create real_estate_investments table
-- 5. Create precious_metals table
-- 6. Create alternative_investments table
-- 7. Create investment_transactions table
-- 8. Create necessary indexes
-- 9. Update DATABASE_VERSION to 8
```

---

## Data Validation Rules

### Common Validations (All Investment Types)
1. ✅ `invested_amount` > 0
2. ✅ `current_value` >= 0
3. ✅ `purchase_date` <= TODAY
4. ✅ `account_id` must reference existing active account
5. ✅ Nominee details mandatory for insurance & long-term investments

### Investment-Specific Validations

#### Insurance Products
- ✅ `premium_amount` > 0
- ✅ `sum_assured` >= `premium_amount * 10` (regulatory minimum)
- ✅ `policy_term` between 5 and 100 years
- ✅ `nominee_name` is mandatory
- ✅ ULIP: `fund_value` >= 0

#### Pension Accounts
- ✅ NPS: `equity_percentage` + `corporate_debt_percentage` + `government_securities_percentage` = 100
- ✅ EPF/VPF: `employee_contribution` >= `employer_contribution`
- ✅ APY: `guaranteed_pension_amount` in [1000, 2000, 3000, 4000, 5000]

#### Real Estate
- ✅ `purchase_price` > 0
- ✅ Property: `estimated_market_value` >= `purchase_price * 0.5` (sanity check)
- ✅ If `has_loan` = true, then `outstanding_loan` > 0
- ✅ REIT/InvIT: `units_held` > 0

#### Precious Metals
- ✅ `quantity_in_grams` > 0
- ✅ Gold purity in ['22K', '24K', '18K', '14K', '999', '995']
- ✅ SGB: `interest_rate` = 2.5% (current government rate)
- ✅ Physical: `storage_location` is mandatory

#### Alternative Investments
- ✅ Cryptocurrency: `quantity` > 0
- ✅ P2P: `interest_rate` between 10% and 36% (RBI limit)
- ✅ Chit Fund: `monthly_contribution` * `cycle_duration_months` = `total_chit_value`
- ✅ Startup Equity: `equity_percentage` <= 100

---

## API Endpoints Needed

### Insurance Management
```
POST   /api/insurance/create
GET    /api/insurance/:id
PUT    /api/insurance/:id/update
POST   /api/insurance/:id/pay-premium
GET    /api/insurance/upcoming-premiums
```

### Pension Accounts
```
POST   /api/pension/create
GET    /api/pension/:id
POST   /api/pension/:id/contribute
GET    /api/pension/:id/projection
```

### Real Estate
```
POST   /api/realestate/create
PUT    /api/realestate/:id/update-valuation
POST   /api/realestate/:id/record-rent
GET    /api/realestate/:id/roi-calculation
```

### Precious Metals
```
POST   /api/metals/create
PUT    /api/metals/:id/update-quantity
GET    /api/metals/current-rates
GET    /api/metals/:id/profit-loss
```

### Alternative Investments
```
POST   /api/alternative/create
GET    /api/alternative/:id
POST   /api/alternative/:id/record-transaction
GET    /api/alternative/portfolio-summary
```

---

## Summary

### ✅ Already Implemented (10/41 types)
- FD, RD, PPF, NSC, KVP, SCSS, Post Office schemes
- Brokerage accounts with stocks/MF tracking
- Credit cards
- Basic banking accounts

### 🔄 Need Implementation (31/41 types)
- **5 New Tables Required**:
  1. `insurance_details` (5 investment types)
  2. `pension_accounts` (4 investment types)
  3. `real_estate_investments` (3 investment types)
  4. `precious_metals` (2 investment types)
  5. `alternative_investments` (6 investment types)
  6. `investment_transactions` (unified transaction tracking)

### Priority Order
1. **High Priority**: Insurance, Pension (common in salaried class)
2. **Medium Priority**: Real Estate, Gold (traditional investments)
3. **Low Priority**: Alternative investments (less common, higher risk)

---

## Next Steps
1. ✅ Review and approve schema design
2. Create migration script (v7 → v8)
3. Update TypeScript types
4. Create repository classes for new tables
5. Build UI components for each investment type
6. Implement validation rules
7. Create API endpoints
8. Add comprehensive tests
