import { httpsCallable } from 'firebase/functions';
import { functions } from '@/core/firebase/firebase';

export interface FDCalculationParams {
  principal: number;
  interestRate: number;
  tenureMonths: number;
  compoundingFrequency?: 'monthly' | 'quarterly' | 'half-yearly' | 'yearly';
  isSeniorCitizen?: boolean;
}

export interface RDCalculationParams {
  monthlyDeposit: number;
  interestRate: number;
  tenureMonths: number;
  isSeniorCitizen?: boolean;
}

export interface PPFCalculationParams {
  yearlyDeposit: number;
  interestRate?: number;
  tenureYears?: number;
}

export interface SavingsInterestParams {
  averageBalance: number;
  interestRate: number;
  periodDays?: number;
}

export interface DepositCalculationResult {
  success: boolean;
  calculation: {
    principal?: number;
    interestRate: number;
    maturityAmount: number;
    interestEarned: number;
    tdsAmount: number;
    netAmount: number;
    maturityDate: string;
    effectiveRate?: number;
  };
}

/**
 * Calculate Fixed Deposit maturity
 */
export async function calculateFDMaturity(
  params: FDCalculationParams
): Promise<DepositCalculationResult> {
  const callable = httpsCallable<FDCalculationParams, DepositCalculationResult>(
    functions,
    'calculateFDMaturity'
  );
  const result = await callable(params);
  return result.data;
}

/**
 * Calculate Recurring Deposit maturity
 */
export async function calculateRDMaturity(
  params: RDCalculationParams
): Promise<DepositCalculationResult> {
  const callable = httpsCallable<RDCalculationParams, DepositCalculationResult>(
    functions,
    'calculateRDMaturity'
  );
  const result = await callable(params);
  return result.data;
}

/**
 * Calculate PPF maturity
 */
export async function calculatePPFMaturity(
  params: PPFCalculationParams
): Promise<DepositCalculationResult> {
  const callable = httpsCallable<
    PPFCalculationParams,
    DepositCalculationResult
  >(functions, 'calculatePPFMaturity');
  const result = await callable(params);
  return result.data;
}

/**
 * Calculate savings account interest
 */
export async function calculateSavingsInterest(
  params: SavingsInterestParams
): Promise<DepositCalculationResult> {
  const callable = httpsCallable<
    SavingsInterestParams,
    DepositCalculationResult
  >(functions, 'calculateSavingsInterest');
  const result = await callable(params);
  return result.data;
}

/**
 * Get deposit account details with calculations
 */
export async function getDepositAccountDetails(accountId: string): Promise<{
  success: boolean;
  account: any;
  calculation: any;
}> {
  const callable = httpsCallable<{ accountId: string }, any>(
    functions,
    'getDepositAccountDetails'
  );
  const result = await callable({ accountId });
  return result.data;
}
