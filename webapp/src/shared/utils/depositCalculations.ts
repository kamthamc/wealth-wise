/**
 * Deposit Calculations Utilities
 * Functions for calculating interest, maturity amounts, TDS, and other deposit-related calculations
 */

import type { DepositDetails, InterestPayoutFrequency } from '@/core/db/types';

/**
 * Calculate maturity amount for a fixed deposit
 * Uses compound interest formula: A = P(1 + r/n)^(nt)
 *
 * @param principal - Principal amount
 * @param rate - Annual interest rate (percentage, e.g., 7.5 for 7.5%)
 * @param tenureMonths - Tenure in months
 * @param frequency - Interest payout frequency
 * @returns Maturity amount
 */
export function calculateMaturityAmount(
  principal: number,
  rate: number,
  tenureMonths: number,
  frequency?: InterestPayoutFrequency
): number {
  const r = rate / 100; // Convert percentage to decimal
  const t = tenureMonths / 12; // Convert months to years

  // Determine compounding frequency
  let n = 4; // Default quarterly
  if (frequency === 'monthly') n = 12;
  else if (frequency === 'quarterly') n = 4;
  else if (frequency === 'annually') n = 1;
  else if (frequency === 'maturity') n = 1;

  // Compound interest formula
  const maturityAmount = principal * (1 + r / n) ** (n * t);

  return Math.round(maturityAmount * 100) / 100; // Round to 2 decimal places
}

/**
 * Calculate simple interest (used for some deposit types like RD)
 * Formula: SI = (P * R * T) / 100
 *
 * @param principal - Principal amount
 * @param rate - Annual interest rate (percentage)
 * @param tenureMonths - Tenure in months
 * @returns Simple interest amount
 */
export function calculateSimpleInterest(
  principal: number,
  rate: number,
  tenureMonths: number
): number {
  const t = tenureMonths / 12; // Convert months to years
  const interest = (principal * rate * t) / 100;
  return Math.round(interest * 100) / 100;
}

/**
 * Calculate maturity amount for recurring deposit
 * RD formula: M = P * [(1 + r/n)^(n*t) - 1] / (r/n) * (1 + r/n)
 * Simplified for monthly deposits
 *
 * @param monthlyDeposit - Monthly deposit amount
 * @param rate - Annual interest rate (percentage)
 * @param tenureMonths - Tenure in months
 * @returns Maturity amount
 */
export function calculateRDMaturityAmount(
  monthlyDeposit: number,
  rate: number,
  tenureMonths: number
): number {
  const r = rate / 100 / 12; // Monthly interest rate
  const n = tenureMonths;

  // RD maturity formula
  const maturityAmount = monthlyDeposit * ((((1 + r) ** n - 1) / r) * (1 + r));

  return Math.round(maturityAmount * 100) / 100;
}

/**
 * Calculate TDS (Tax Deducted at Source) on interest earned
 * TDS is deducted if interest exceeds ₹40,000 per year (₹50,000 for senior citizens)
 *
 * @param interestEarned - Total interest earned
 * @param tdsRate - TDS rate (percentage, default 10%)
 * @param isSeniorCitizen - Whether the holder is a senior citizen
 * @returns TDS amount to be deducted
 */
export function calculateTDS(
  interestEarned: number,
  tdsRate: number = 10,
  isSeniorCitizen: boolean = false
): number {
  const threshold = isSeniorCitizen ? 50000 : 40000;

  // TDS is applicable only if interest exceeds threshold
  if (interestEarned <= threshold) {
    return 0;
  }

  const tds = (interestEarned * tdsRate) / 100;
  return Math.round(tds * 100) / 100;
}

/**
 * Calculate interest earned so far based on completed months
 *
 * @param deposit - Deposit details
 * @returns Interest earned so far
 */
export function calculateInterestEarned(deposit: DepositDetails): number {
  const totalInterest = deposit.maturity_amount - deposit.principal_amount;
  const progressRatio = deposit.completed_months / deposit.tenure_months;

  // For simple calculations, interest accrues linearly
  // For more accurate compound interest, would need to recalculate
  const interestEarned = totalInterest * progressRatio;

  return Math.round(interestEarned * 100) / 100;
}

/**
 * Calculate current value of deposit
 * Current value = Principal + Interest earned so far
 *
 * @param deposit - Deposit details
 * @returns Current value
 */
export function calculateCurrentValue(deposit: DepositDetails): number {
  const interestEarned = calculateInterestEarned(deposit);
  const currentValue = deposit.principal_amount + interestEarned;

  return Math.round(currentValue * 100) / 100;
}

/**
 * Calculate monthly interest payout (for deposits with monthly interest)
 *
 * @param principal - Principal amount
 * @param rate - Annual interest rate (percentage)
 * @returns Monthly interest amount
 */
export function calculateMonthlyInterest(
  principal: number,
  rate: number
): number {
  const monthlyRate = rate / 100 / 12;
  const monthlyInterest = principal * monthlyRate;

  return Math.round(monthlyInterest * 100) / 100;
}

/**
 * Calculate penalty for premature withdrawal
 * Typically 1-2% penalty on interest rate
 *
 * @param deposit - Deposit details
 * @param penaltyRate - Penalty percentage (default 1%)
 * @returns Penalty amount
 */
export function calculatePrematureWithdrawalPenalty(
  deposit: DepositDetails,
  penaltyRate: number = 1
): number {
  const interestEarned = calculateInterestEarned(deposit);
  const penalty = (interestEarned * penaltyRate) / 100;

  return Math.round(penalty * 100) / 100;
}

/**
 * Calculate maturity amount after TDS deduction
 *
 * @param maturityAmount - Gross maturity amount
 * @param principal - Principal amount
 * @param tdsRate - TDS rate (percentage)
 * @param isSeniorCitizen - Whether the holder is a senior citizen
 * @returns Net maturity amount after TDS
 */
export function calculateNetMaturityAmount(
  maturityAmount: number,
  principal: number,
  tdsRate: number = 10,
  isSeniorCitizen: boolean = false
): number {
  const interestEarned = maturityAmount - principal;
  const tds = calculateTDS(interestEarned, tdsRate, isSeniorCitizen);
  const netAmount = maturityAmount - tds;

  return Math.round(netAmount * 100) / 100;
}

/**
 * Calculate number of completed months from start date
 *
 * @param startDate - Deposit start date
 * @returns Number of completed months
 */
export function calculateCompletedMonths(startDate: Date): number {
  const now = new Date();
  const start = new Date(startDate);

  const years = now.getFullYear() - start.getFullYear();
  const months = now.getMonth() - start.getMonth();

  return Math.max(0, years * 12 + months);
}

/**
 * Calculate remaining months until maturity
 *
 * @param maturityDate - Deposit maturity date
 * @returns Number of remaining months
 */
export function calculateRemainingMonths(maturityDate: Date): number {
  const now = new Date();
  const maturity = new Date(maturityDate);

  if (maturity < now) return 0; // Already matured

  const years = maturity.getFullYear() - now.getFullYear();
  const months = maturity.getMonth() - now.getMonth();

  return Math.max(0, years * 12 + months);
}

/**
 * Update deposit progress (completed and remaining months)
 *
 * @param deposit - Deposit details
 * @returns Updated completed and remaining months
 */
export function updateDepositProgress(deposit: DepositDetails): {
  completed_months: number;
  remaining_months: number;
} {
  const completedMonths = calculateCompletedMonths(deposit.start_date);
  const remainingMonths = Math.max(0, deposit.tenure_months - completedMonths);

  return {
    completed_months: Math.min(completedMonths, deposit.tenure_months),
    remaining_months: remainingMonths,
  };
}

/**
 * Check if deposit has matured
 *
 * @param deposit - Deposit details
 * @returns True if deposit has matured
 */
export function isDepositMatured(deposit: DepositDetails): boolean {
  const now = new Date();
  const maturityDate = new Date(deposit.maturity_date);
  return maturityDate <= now;
}

/**
 * Get days until maturity
 *
 * @param maturityDate - Deposit maturity date
 * @returns Number of days until maturity (0 if already matured)
 */
export function getDaysUntilMaturity(maturityDate: Date): number {
  const now = new Date();
  const maturity = new Date(maturityDate);

  if (maturity < now) return 0;

  const diffTime = maturity.getTime() - now.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  return diffDays;
}

/**
 * Format currency for Indian locale
 *
 * @param amount - Amount to format
 * @returns Formatted currency string
 */
export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

/**
 * Calculate effective annual rate (considering compounding)
 *
 * @param nominalRate - Nominal annual interest rate (percentage)
 * @param frequency - Compounding frequency
 * @returns Effective annual rate (percentage)
 */
export function calculateEffectiveAnnualRate(
  nominalRate: number,
  frequency?: InterestPayoutFrequency
): number {
  const r = nominalRate / 100;

  // Determine compounding frequency
  let n = 4; // Default quarterly
  if (frequency === 'monthly') n = 12;
  else if (frequency === 'quarterly') n = 4;
  else if (frequency === 'annually') n = 1;
  else if (frequency === 'maturity') n = 1;

  // Effective rate formula: (1 + r/n)^n - 1
  const effectiveRate = ((1 + r / n) ** n - 1) * 100;

  return Math.round(effectiveRate * 100) / 100;
}
