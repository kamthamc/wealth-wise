import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { fetchUserPreferences } from './preferences';

const db = admin.firestore();

interface DepositCalculationResult {
  principal: number;
  interestRate: number;
  maturityAmount: number;
  interestEarned: number;
  tdsAmount: number;
  netAmount: number;
  maturityDate: string;
}

/**
 * Calculate Fixed Deposit maturity
 */
export const calculateFDMaturity = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const {
    principal,
    interestRate,
    tenureMonths,
    compoundingFrequency = 'quarterly',
    isSeniorCitizen = false,
  } = request.data as {
    principal: number;
    interestRate: number;
    tenureMonths: number;
    compoundingFrequency?: 'monthly' | 'quarterly' | 'half-yearly' | 'yearly';
    isSeniorCitizen?: boolean;
  };

  if (!principal || !interestRate || !tenureMonths) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Principal, interest rate, and tenure are required',
    );
  }

  try {
    // Fetch user preferences for currency
    const userId = request.auth.uid;
    const userPreferences = await fetchUserPreferences(userId);
    const currency = userPreferences.currency;

    // Calculate maturity amount with compound interest
    const n = getCompoundingPeriodsPerYear(compoundingFrequency);
    const t = tenureMonths / 12;
    const r = interestRate / 100;

    // Compound interest formula: A = P(1 + r/n)^(nt)
    const maturityAmount = principal * (1 + r / n) ** (n * t);
    const interestEarned = maturityAmount - principal;

    // Calculate TDS (Tax Deducted at Source)
    const tdsAmount = calculateTDS(interestEarned, isSeniorCitizen);
    const netAmount = maturityAmount - tdsAmount;

    // Calculate maturity date
    const maturityDate = new Date();
    maturityDate.setMonth(maturityDate.getMonth() + tenureMonths);

    return {
      success: true,
      currency, // Return currency for proper formatting
      calculation: {
        principal: Math.round(principal * 100) / 100,
        interestRate,
        tenureMonths,
        compoundingFrequency,
        maturityAmount: Math.round(maturityAmount * 100) / 100,
        interestEarned: Math.round(interestEarned * 100) / 100,
        tdsAmount: Math.round(tdsAmount * 100) / 100,
        netAmount: Math.round(netAmount * 100) / 100,
        maturityDate: maturityDate.toISOString(),
        effectiveRate: ((maturityAmount - principal) / principal / t) * 100,
      } as DepositCalculationResult,
    };
  } catch (error) {
    console.error('Error calculating FD maturity:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to calculate FD maturity',
    );
  }
});

/**
 * Calculate Recurring Deposit maturity
 */
export const calculateRDMaturity = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const {
    monthlyDeposit,
    interestRate,
    tenureMonths,
    isSeniorCitizen = false,
  } = request.data as {
    monthlyDeposit: number;
    interestRate: number;
    tenureMonths: number;
    isSeniorCitizen?: boolean;
  };

  if (!monthlyDeposit || !interestRate || !tenureMonths) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Monthly deposit, interest rate, and tenure are required',
    );
  }

  try {
    // Fetch user preferences for currency
    const userId = request.auth.uid;
    const userPreferences = await fetchUserPreferences(userId);
    const currency = userPreferences.currency;

    // RD maturity formula: M = P × n × [(1 + i)^n - 1] / [1 - (1 + i)^(-1/3)]
    // Where P = monthly installment, n = number of months, i = monthly interest rate
    const r = interestRate / 100 / 12; // Monthly interest rate
    const n = tenureMonths;

    // Simplified formula: M = P × [n(n+1)/2] × (1 + r)
    // This is an approximation commonly used for RD calculations
    const totalPrincipal = monthlyDeposit * n;

    // Calculate interest using the RD formula
    let maturityAmount = monthlyDeposit * n * (1 + ((n + 1) / (2 * n)) * r * n);

    // More accurate calculation considering monthly compounding
    maturityAmount = 0;
    for (let month = 1; month <= n; month++) {
      const monthsRemaining = n - month + 1;
      maturityAmount += monthlyDeposit * (1 + r) ** monthsRemaining;
    }

    const interestEarned = maturityAmount - totalPrincipal;

    // Calculate TDS
    const tdsAmount = calculateTDS(interestEarned, isSeniorCitizen);
    const netAmount = maturityAmount - tdsAmount;

    // Calculate maturity date
    const maturityDate = new Date();
    maturityDate.setMonth(maturityDate.getMonth() + tenureMonths);

    return {
      success: true,
      currency, // Return currency for proper formatting
      calculation: {
        monthlyDeposit: Math.round(monthlyDeposit * 100) / 100,
        interestRate,
        tenureMonths,
        totalPrincipal: Math.round(totalPrincipal * 100) / 100,
        maturityAmount: Math.round(maturityAmount * 100) / 100,
        interestEarned: Math.round(interestEarned * 100) / 100,
        tdsAmount: Math.round(tdsAmount * 100) / 100,
        netAmount: Math.round(netAmount * 100) / 100,
        maturityDate: maturityDate.toISOString(),
        effectiveRate: (interestEarned / totalPrincipal) * 100,
      },
    };
  } catch (error) {
    console.error('Error calculating RD maturity:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to calculate RD maturity',
    );
  }
});

/**
 * Calculate PPF (Public Provident Fund) maturity
 */
export const calculatePPFMaturity = functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated',
    );
  }

  const {
    yearlyDeposit,
    interestRate = 7.1, // Current PPF rate
    tenureYears = 15, // PPF standard tenure
  } = request.data as {
    yearlyDeposit: number;
    interestRate?: number;
    tenureYears?: number;
  };

  if (!yearlyDeposit) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Yearly deposit is required',
    );
  }

  try {
    // Fetch user preferences for currency
    const userId = request.auth.uid;
    const userPreferences = await fetchUserPreferences(userId);
    const currency = userPreferences.currency;

    // PPF interest is compounded annually
    const r = interestRate / 100;
    let maturityAmount = 0;

    // Calculate maturity with yearly deposits
    for (let year = 1; year <= tenureYears; year++) {
      const yearsRemaining = tenureYears - year + 1;
      maturityAmount += yearlyDeposit * (1 + r) ** yearsRemaining;
    }

    const totalPrincipal = yearlyDeposit * tenureYears;
    const interestEarned = maturityAmount - totalPrincipal;

    // PPF is tax-exempt (EEE status), so no TDS
    const netAmount = maturityAmount;

    // Calculate maturity date
    const maturityDate = new Date();
    maturityDate.setFullYear(maturityDate.getFullYear() + tenureYears);

    return {
      success: true,
      currency, // Return currency for proper formatting
      calculation: {
        yearlyDeposit: Math.round(yearlyDeposit * 100) / 100,
        interestRate,
        tenureYears,
        totalPrincipal: Math.round(totalPrincipal * 100) / 100,
        maturityAmount: Math.round(maturityAmount * 100) / 100,
        interestEarned: Math.round(interestEarned * 100) / 100,
        tdsAmount: 0, // PPF is tax-exempt
        netAmount: Math.round(netAmount * 100) / 100,
        maturityDate: maturityDate.toISOString(),
        effectiveRate: (interestEarned / totalPrincipal) * 100,
        taxStatus: 'EEE (Exempt-Exempt-Exempt)',
      },
    };
  } catch (error) {
    console.error('Error calculating PPF maturity:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to calculate PPF maturity',
    );
  }
});

/**
 * Calculate interest for savings account
 */
export const calculateSavingsInterest = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated',
      );
    }

    const {
      averageBalance,
      interestRate,
      periodDays = 365,
    } = request.data as {
      averageBalance: number;
      interestRate: number;
      periodDays?: number;
    };

    if (!averageBalance || !interestRate) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Average balance and interest rate are required',
      );
    }

    try {
      // Fetch user preferences for currency
      const userId = request.auth.uid;
      const userPreferences = await fetchUserPreferences(userId);
      const currency = userPreferences.currency;

      // Savings account interest is calculated daily and credited quarterly
      const dailyRate = interestRate / 100 / 365;
      const interestEarned = averageBalance * dailyRate * periodDays;

      // Calculate TDS (applicable if interest > ₹10,000 for regular, ₹50,000 for senior citizens)
      const isSeniorCitizen = false; // Can be passed as parameter if needed
      const tdsAmount = calculateTDS(interestEarned, isSeniorCitizen);

      return {
        success: true,
        currency, // Return currency for proper formatting
        calculation: {
          averageBalance: Math.round(averageBalance * 100) / 100,
          interestRate,
          periodDays,
          interestEarned: Math.round(interestEarned * 100) / 100,
          tdsAmount: Math.round(tdsAmount * 100) / 100,
          netInterest: Math.round((interestEarned - tdsAmount) * 100) / 100,
          annualizedRate:
            (interestEarned / averageBalance / periodDays) * 365 * 100,
        },
      };
    } catch (error) {
      console.error('Error calculating savings interest:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to calculate savings interest',
      );
    }
  },
);

// Helper functions
function getCompoundingPeriodsPerYear(frequency: string): number {
  switch (frequency) {
    case 'monthly':
      return 12;
    case 'quarterly':
      return 4;
    case 'half-yearly':
      return 2;
    case 'yearly':
      return 1;
    default:
      return 4; // Default to quarterly
  }
}

function calculateTDS(
  interestAmount: number,
  isSeniorCitizen: boolean,
): number {
  // TDS threshold as per Indian tax laws
  const tdsThreshold = isSeniorCitizen ? 50000 : 10000;

  if (interestAmount <= tdsThreshold) {
    return 0;
  }

  // TDS rate is 10% (or 20% if PAN not provided, but we'll assume PAN is available)
  const tdsRate = 0.1;
  return interestAmount * tdsRate;
}

/**
 * Get deposit details with calculations for an account
 */
export const getDepositAccountDetails = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated',
      );
    }

    const userId = request.auth.uid;
    const { accountId } = request.data as { accountId: string };

    if (!accountId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Account ID is required',
      );
    }

    try {
      // Get account details
      const accountDoc = await db.collection('accounts').doc(accountId).get();

      if (!accountDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Account not found');
      }

      const account = accountDoc.data();

      if (account?.user_id !== userId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Access denied',
        );
      }

      // Calculate based on account type
      let calculation: any = null;

      if (account?.type === 'fixed_deposit' && account.deposit_info) {
        const fdInfo = account.deposit_info;

        // Calculate FD maturity
        const r = fdInfo.interest_rate / 100;
        const n = getCompoundingPeriodsPerYear(
          fdInfo.compounding_frequency || 'quarterly',
        );
        const t = fdInfo.tenure_months / 12;
        const principal = fdInfo.principal || account.balance;

        const maturityAmount = principal * (1 + r / n) ** (n * t);
        const interestEarned = maturityAmount - principal;
        const tdsAmount = calculateTDS(
          interestEarned,
          fdInfo.is_senior_citizen || false,
        );
        const netAmount = maturityAmount - tdsAmount;

        const maturityDate = new Date();
        maturityDate.setMonth(maturityDate.getMonth() + fdInfo.tenure_months);

        calculation = {
          principal: Math.round(principal * 100) / 100,
          interestRate: fdInfo.interest_rate,
          tenureMonths: fdInfo.tenure_months,
          compoundingFrequency: fdInfo.compounding_frequency,
          maturityAmount: Math.round(maturityAmount * 100) / 100,
          interestEarned: Math.round(interestEarned * 100) / 100,
          tdsAmount: Math.round(tdsAmount * 100) / 100,
          netAmount: Math.round(netAmount * 100) / 100,
          maturityDate: maturityDate.toISOString(),
          effectiveRate: ((maturityAmount - principal) / principal / t) * 100,
        };
      } else if (
        account?.type === 'recurring_deposit' &&
        account.deposit_info
      ) {
        const rdInfo = account.deposit_info;

        // Calculate RD maturity
        const r = rdInfo.interest_rate / 100 / 12;
        const n = rdInfo.tenure_months;
        const monthlyDeposit = rdInfo.monthly_deposit;

        let maturityAmount = 0;
        for (let month = 1; month <= n; month++) {
          const monthsRemaining = n - month + 1;
          maturityAmount += monthlyDeposit * (1 + r) ** monthsRemaining;
        }

        const totalPrincipal = monthlyDeposit * n;
        const interestEarned = maturityAmount - totalPrincipal;
        const tdsAmount = calculateTDS(
          interestEarned,
          rdInfo.is_senior_citizen || false,
        );
        const netAmount = maturityAmount - tdsAmount;

        const maturityDate = new Date();
        maturityDate.setMonth(maturityDate.getMonth() + n);

        calculation = {
          monthlyDeposit: Math.round(monthlyDeposit * 100) / 100,
          interestRate: rdInfo.interest_rate,
          tenureMonths: n,
          totalPrincipal: Math.round(totalPrincipal * 100) / 100,
          maturityAmount: Math.round(maturityAmount * 100) / 100,
          interestEarned: Math.round(interestEarned * 100) / 100,
          tdsAmount: Math.round(tdsAmount * 100) / 100,
          netAmount: Math.round(netAmount * 100) / 100,
          maturityDate: maturityDate.toISOString(),
          effectiveRate: (interestEarned / totalPrincipal) * 100,
        };
      } else if (account?.type === 'ppf' && account.deposit_info) {
        const ppfInfo = account.deposit_info;

        // Calculate PPF maturity
        const r = ppfInfo.interest_rate / 100;
        const tenureYears = ppfInfo.tenure_years || 15;
        const yearlyDeposit = ppfInfo.yearly_deposit;

        let maturityAmount = 0;
        for (let year = 1; year <= tenureYears; year++) {
          const yearsRemaining = tenureYears - year + 1;
          maturityAmount += yearlyDeposit * (1 + r) ** yearsRemaining;
        }

        const totalPrincipal = yearlyDeposit * tenureYears;
        const interestEarned = maturityAmount - totalPrincipal;
        const netAmount = maturityAmount;

        const maturityDate = new Date();
        maturityDate.setFullYear(maturityDate.getFullYear() + tenureYears);

        calculation = {
          yearlyDeposit: Math.round(yearlyDeposit * 100) / 100,
          interestRate: ppfInfo.interest_rate,
          tenureYears,
          totalPrincipal: Math.round(totalPrincipal * 100) / 100,
          maturityAmount: Math.round(maturityAmount * 100) / 100,
          interestEarned: Math.round(interestEarned * 100) / 100,
          tdsAmount: 0,
          netAmount: Math.round(netAmount * 100) / 100,
          maturityDate: maturityDate.toISOString(),
          effectiveRate: (interestEarned / totalPrincipal) * 100,
          taxStatus: 'EEE (Exempt-Exempt-Exempt)',
        };
      }

      // Fetch user preferences for currency
      const userPreferences = await fetchUserPreferences(userId);
      const currency = userPreferences.currency;

      return {
        success: true,
        currency, // Return currency for proper formatting
        account: {
          id: accountDoc.id,
          name: account?.name,
          type: account?.type,
          balance: account?.balance,
          deposit_info: account?.deposit_info,
        },
        calculation,
      };
    } catch (error) {
      console.error('Error getting deposit account details:', error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        'internal',
        'Failed to get deposit account details',
      );
    }
  },
);
