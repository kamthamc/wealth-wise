import { AccountType, TransactionCategory, TransactionType } from '../models/core-models';
import { DateUtils, CurrencyUtils, ValidationUtils } from '../utils/common-utils';

describe('Core Models', () => {
  test('AccountType enum should have all required values', () => {
    expect(AccountType.SAVINGS).toBe('savings');
    expect(AccountType.CURRENT).toBe('current');
    expect(AccountType.CREDIT_CARD).toBe('credit_card');
    expect(AccountType.UPI).toBe('upi');
  });

  test('TransactionType enum should have correct values', () => {
    expect(TransactionType.INCOME).toBe('income');
    expect(TransactionType.EXPENSE).toBe('expense');
    expect(TransactionType.TRANSFER).toBe('transfer');
  });

  test('TransactionCategory should include common categories', () => {
    expect(TransactionCategory.SALARY).toBe('salary');
    expect(TransactionCategory.FOOD_DINING).toBe('food_dining');
    expect(TransactionCategory.TRANSPORTATION).toBe('transportation');
  });
});

describe('DateUtils', () => {
  test('should get financial year start date', () => {
    const fyStart = DateUtils.getFinancialYearStart(new Date('2024-06-15'));
    expect(fyStart.getFullYear()).toBe(2024);
    expect(fyStart.getMonth()).toBe(3); // April (0-indexed)
    expect(fyStart.getDate()).toBe(1);
  });

  test('should get financial year end date', () => {
    const fyEnd = DateUtils.getFinancialYearEnd(new Date('2024-06-15'));
    expect(fyEnd.getFullYear()).toBe(2025);
    expect(fyEnd.getMonth()).toBe(2); // March (0-indexed)
    expect(fyEnd.getDate()).toBe(31);
  });

  test('should format Indian date correctly', () => {
    const date = new Date('2024-06-15');
    const formatted = DateUtils.formatIndianDate(date);
    expect(formatted).toMatch(/\d{2}\/\d{2}\/\d{4}/);
  });
});

describe('CurrencyUtils', () => {
  test('should format Indian currency correctly', () => {
    const formatted = CurrencyUtils.formatIndianCurrency(100000);
    expect(formatted).toContain('₹');
    expect(formatted).toContain('1,00,000');
  });

  test('should format currency for different locales', () => {
    const formatted = CurrencyUtils.formatCurrency(1000, 'USD', 'en-US');
    expect(formatted).toContain('$');
    expect(formatted).toContain('1,000');
  });

  test('should get currency symbol', () => {
    expect(CurrencyUtils.getCurrencySymbol('INR')).toBe('₹');
    expect(CurrencyUtils.getCurrencySymbol('USD')).toBe('$');
  });
});

describe('ValidationUtils', () => {
  test('should validate bank account numbers', () => {
    expect(ValidationUtils.validateBankAccountNumber('12345678901234')).toBe(true);
    expect(ValidationUtils.validateBankAccountNumber('123')).toBe(false);
    expect(ValidationUtils.validateBankAccountNumber('123456789012345678901')).toBe(false);
  });

  test('should validate IFSC codes', () => {
    expect(ValidationUtils.validateIFSC('SBIN0001234')).toBe(true);
    expect(ValidationUtils.validateIFSC('HDFC0000123')).toBe(true);
    expect(ValidationUtils.validateIFSC('INVALID')).toBe(false);
  });

  test('should validate PAN numbers', () => {
    expect(ValidationUtils.validatePAN('ABCDE1234F')).toBe(true);
    expect(ValidationUtils.validatePAN('INVALID')).toBe(false);
  });

  test('should validate Indian mobile numbers', () => {
    expect(ValidationUtils.validateIndianMobile('9876543210')).toBe(true);
    expect(ValidationUtils.validateIndianMobile('+919876543210')).toBe(true);
    expect(ValidationUtils.validateIndianMobile('1234567890')).toBe(false);
  });

  test('should validate email addresses', () => {
    expect(ValidationUtils.validateEmail('user@example.com')).toBe(true);
    expect(ValidationUtils.validateEmail('invalid-email')).toBe(false);
  });
});