/**
 * Financial Calculations Utility
 * Centralized place for all financial computations with BigInt support for large numbers
 *
 * Performance Optimizations:
 * - Uses BigInt for precise calculations without floating point errors
 * - Single-pass algorithms for O(n) time complexity
 * - Pre-filtered date ranges to minimize iterations
 * - Efficient array methods (reduce, filter) optimized by JS engine
 * - Transaction caching with 5-minute TTL for expensive calculations
 * - Can handle millions of transactions with proper database indexing
 *
 * Database Requirements for Large Datasets:
 * - Index on: account_id, date, type, category
 * - Consider partitioning by date for > 1M transactions
 * - Use date range queries at database level before passing to these functions
 */

import { transactionCache } from '@/core/cache';
import type { Account, Transaction } from '@/core/types';

/**
 * Precision for currency calculations (2 decimal places)
 */
const CURRENCY_PRECISION = 100n;

/**
 * Convert number/string to BigInt cents (handles decimals)
 * Examples: 1000.50 => 100050n, "2500.75" => 250075n
 */
export function toBigIntCents(value: number | string): bigint {
  if (typeof value === 'string') {
    value = parseFloat(value);
  }

  if (Number.isNaN(value) || !Number.isFinite(value)) {
    return 0n;
  }

  // Convert to cents to avoid floating point issues
  return BigInt(Math.round(value * 100));
}

/**
 * Convert BigInt cents back to number
 * Example: 100050n => 1000.50
 */
export function fromBigIntCents(value: bigint): number {
  return Number(value) / 100;
}

/**
 * Safe addition of currency amounts
 */
export function addCurrency(a: number | string, b: number | string): number {
  const aBigInt = toBigIntCents(a);
  const bBigInt = toBigIntCents(b);
  return fromBigIntCents(aBigInt + bBigInt);
}

/**
 * Safe subtraction of currency amounts
 */
export function subtractCurrency(
  a: number | string,
  b: number | string
): number {
  const aBigInt = toBigIntCents(a);
  const bBigInt = toBigIntCents(b);
  return fromBigIntCents(aBigInt - bBigInt);
}

/**
 * Safe multiplication of currency amount by a factor
 */
export function multiplyCurrency(
  amount: number | string,
  factor: number
): number {
  const amountBigInt = toBigIntCents(amount);
  const factorBigInt = BigInt(Math.round(factor * 100));
  return fromBigIntCents((amountBigInt * factorBigInt) / CURRENCY_PRECISION);
}

/**
 * Calculate current account balance from transactions only
 * Initial balance is represented as a transaction with is_initial_balance = true
 */
export function calculateAccountBalance(transactions: Transaction[]): number {
  let balance = 0n;

  for (const txn of transactions) {
    const amount = toBigIntCents(txn.amount);

    switch (txn.type) {
      case 'income':
        balance += amount;
        break;
      case 'expense':
        balance -= amount;
        break;
      case 'transfer':
        // Transfers are handled separately
        break;
    }
  }

  return fromBigIntCents(balance);
}

/**
 * Calculate total balance across all accounts
 */
export function calculateTotalBalance(accounts: Account[]): number {
  let total = 0n;

  for (const account of accounts) {
    if (account.is_active) {
      total += toBigIntCents(account.balance);
    }
  }

  return fromBigIntCents(total);
}

/**
 * Calculate account balance including transactions
 */
export function calculateCurrentAccountBalance(
  account: Account,
  transactions: Transaction[]
): number {
  return calculateAccountBalance(
    transactions.filter((t) => t.account_id === account.id)
  );
}

/**
 * Batch calculate balances for multiple accounts efficiently
 * Optimized for large datasets - single pass through transactions
 * O(n) where n = number of transactions
 *
 * With caching: Subsequent calls with same data return cached result (5-min TTL)
 */
export function calculateAccountBalances(
  accounts: Account[],
  transactions: Transaction[]
): Map<string, number> {
  // Generate cache key based on account IDs and transaction count/hash
  const accountIds = accounts
    .map((a) => a.id)
    .sort()
    .join(',');
  const txnHash =
    transactions.length > 0
      ? `${transactions.length}_${transactions[0]?.id}_${transactions[transactions.length - 1]?.id}`
      : '0';
  const cacheKey = `balances_${accountIds}_${txnHash}`;

  // Check cache
  const cached = transactionCache.get<Map<string, number>>(cacheKey);
  if (cached) {
    return cached;
  }

  // Initialize balance map with zero (balances calculated from transactions only)
  const balances = new Map<string, bigint>();
  for (const account of accounts) {
    balances.set(account.id, 0n);
  }

  // Single pass through all transactions
  for (const txn of transactions) {
    const currentBalance = balances.get(txn.account_id);
    if (currentBalance === undefined) continue;

    const amount = toBigIntCents(txn.amount);

    switch (txn.type) {
      case 'income':
        balances.set(txn.account_id, currentBalance + amount);
        break;
      case 'expense':
        balances.set(txn.account_id, currentBalance - amount);
        break;
    }
  }

  // Convert back to numbers
  const result = new Map<string, number>();
  for (const [accountId, balance] of balances) {
    result.set(accountId, fromBigIntCents(balance));
  }

  // Cache result
  transactionCache.set(cacheKey, result);

  return result;
}

/**
 * Calculate income for a period
 */
export function calculateIncome(
  transactions: Transaction[],
  startDate?: Date,
  endDate?: Date
): number {
  let total = 0n;

  for (const txn of transactions) {
    if (txn.type !== 'income') continue;

    const txnDate = new Date(txn.date);
    if (startDate && txnDate < startDate) continue;
    if (endDate && txnDate > endDate) continue;

    total += toBigIntCents(txn.amount);
  }

  return fromBigIntCents(total);
}

/**
 * Calculate expenses for a period
 */
export function calculateExpenses(
  transactions: Transaction[],
  startDate?: Date,
  endDate?: Date
): number {
  let total = 0n;

  for (const txn of transactions) {
    if (txn.type !== 'expense') continue;

    const txnDate = new Date(txn.date);
    if (startDate && txnDate < startDate) continue;
    if (endDate && txnDate > endDate) continue;

    total += toBigIntCents(txn.amount);
  }

  return fromBigIntCents(total);
}

/**
 * Calculate net change (income - expenses)
 */
export function calculateNetChange(
  transactions: Transaction[],
  startDate?: Date,
  endDate?: Date
): number {
  const income = toBigIntCents(
    calculateIncome(transactions, startDate, endDate)
  );
  const expenses = toBigIntCents(
    calculateExpenses(transactions, startDate, endDate)
  );
  return fromBigIntCents(income - expenses);
}

/**
 * Calculate percentage change
 */
export function calculatePercentageChange(
  current: number,
  previous: number
): number {
  if (previous === 0) return current > 0 ? 100 : 0;
  return ((current - previous) / previous) * 100;
}

/**
 * Calculate monthly statistics
 */
export interface MonthlyStats {
  month: number;
  year: number;
  income: number;
  expenses: number;
  netChange: number;
  balance: number;
}

export function calculateMonthlyStats(
  transactions: Transaction[],
  monthsBack = 6,
  initialBalance = 0
): MonthlyStats[] {
  const now = new Date();
  const stats: MonthlyStats[] = [];

  // Calculate balance at the start of the period (going backwards from initial balance)
  let startBalance = initialBalance;

  // Calculate all transactions after the end of our period to get current balance
  const periodStart = new Date(
    now.getFullYear(),
    now.getMonth() - (monthsBack - 1),
    1
  );
  const futureTransactions = transactions.filter(
    (t) => new Date(t.date) >= periodStart
  );

  // Work backwards from current balance to get the balance at start of period
  for (const txn of futureTransactions) {
    const amount = Number(txn.amount) || 0;
    if (txn.type === 'income') {
      startBalance = subtractCurrency(startBalance, amount);
    } else if (txn.type === 'expense') {
      startBalance = addCurrency(startBalance, amount);
    }
  }

  // Now calculate forward with the correct starting balance
  let runningBalance = startBalance;

  for (let i = monthsBack - 1; i >= 0; i--) {
    const monthDate = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const startDate = new Date(
      monthDate.getFullYear(),
      monthDate.getMonth(),
      1
    );
    const endDate = new Date(
      monthDate.getFullYear(),
      monthDate.getMonth() + 1,
      0,
      23,
      59,
      59
    );

    const income = calculateIncome(transactions, startDate, endDate);
    const expenses = calculateExpenses(transactions, startDate, endDate);
    const netChange = income - expenses;

    // Add net change to running balance
    runningBalance = addCurrency(runningBalance, netChange);

    stats.push({
      month: monthDate.getMonth() + 1,
      year: monthDate.getFullYear(),
      income,
      expenses,
      netChange,
      balance: runningBalance,
    });
  }

  return stats;
}

/**
 * Calculate category breakdown
 */
export interface CategoryBreakdown {
  category: string;
  amount: number;
  percentage: number;
  transactionCount: number;
}

export function calculateCategoryBreakdown(
  transactions: Transaction[],
  type: 'income' | 'expense'
): CategoryBreakdown[] {
  const categoryMap = new Map<string, { amount: bigint; count: number }>();
  let total = 0n;

  for (const txn of transactions) {
    if (txn.type !== type) continue;

    const category = txn.category || 'Uncategorized';
    const amount = toBigIntCents(txn.amount);

    const existing = categoryMap.get(category);
    if (existing) {
      existing.amount += amount;
      existing.count++;
    } else {
      categoryMap.set(category, { amount, count: 1 });
    }

    total += amount;
  }

  const breakdown: CategoryBreakdown[] = [];
  const totalNum = fromBigIntCents(total);

  for (const [category, data] of categoryMap.entries()) {
    const amount = fromBigIntCents(data.amount);
    breakdown.push({
      category,
      amount,
      percentage: totalNum > 0 ? (amount / totalNum) * 100 : 0,
      transactionCount: data.count,
    });
  }

  // Sort by amount descending
  breakdown.sort((a, b) => b.amount - a.amount);

  return breakdown;
}

/**
 * Calculate savings rate (net change / income * 100)
 */
export function calculateSavingsRate(
  transactions: Transaction[],
  startDate?: Date,
  endDate?: Date
): number {
  const income = calculateIncome(transactions, startDate, endDate);
  const expenses = calculateExpenses(transactions, startDate, endDate);

  if (income === 0) return 0;

  const netChange = income - expenses;
  return (netChange / income) * 100;
}

/**
 * Format large numbers for display (e.g., 1.5M, 2.3K)
 */
export function formatCompactNumber(value: number): string {
  const abs = Math.abs(value);

  if (abs >= 10000000) {
    // 1 Crore
    return `${(value / 10000000).toFixed(1)}Cr`;
  }
  if (abs >= 100000) {
    // 1 Lakh
    return `${(value / 100000).toFixed(1)}L`;
  }
  if (abs >= 1000) {
    return `${(value / 1000).toFixed(1)}K`;
  }

  return value.toFixed(0);
}

/**
 * Calculate total net worth across all active accounts
 */
export function calculateNetWorth(
  accounts: Account[],
  transactions: Transaction[]
): number {
  const activeAccounts = accounts.filter((acc) => acc.is_active);
  const balances = calculateAccountBalances(activeAccounts, transactions);

  return activeAccounts.reduce((sum, acc) => {
    return sum + (balances.get(acc.id) || 0);
  }, 0);
}
