// Shared Utility Functions for Unified Banking App
// Cross-platform utility functions for common operations

import { TransactionCategory, TransactionType } from '../models/core-models';

// MARK: - Date Utilities

export class DateUtils {
    /**
     * Get the start of Indian financial year for a given date
     */
    static getFinancialYearStart(date: Date = new Date()): Date {
        const year = date.getFullYear();
        const fyStart = new Date(year, 3, 1); // April 1st
        
        if (date < fyStart) {
            fyStart.setFullYear(year - 1);
        }
        
        return fyStart;
    }
    
    /**
     * Get the end of Indian financial year for a given date
     */
    static getFinancialYearEnd(date: Date = new Date()): Date {
        const fyStart = this.getFinancialYearStart(date);
        const fyEnd = new Date(fyStart);
        fyEnd.setFullYear(fyStart.getFullYear() + 1, 2, 31); // March 31st
        return fyEnd;
    }
    
    /**
     * Format date in Indian locale
     */
    static formatIndianDate(date: Date): string {
        return new Intl.DateTimeFormat('en-IN', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
        }).format(date);
    }
    
    /**
     * Get quarter for Indian financial year
     */
    static getFinancialQuarter(date: Date): { quarter: number; year: number } {
        const fyStart = this.getFinancialYearStart(date);
        const monthsDiff = ((date.getFullYear() - fyStart.getFullYear()) * 12) + (date.getMonth() - fyStart.getMonth());
        const quarter = Math.floor(monthsDiff / 3) + 1;
        
        return {
            quarter: Math.min(quarter, 4),
            year: fyStart.getFullYear()
        };
    }
    
    /**
     * Get date range for a period
     */
    static getDateRange(period: string, referenceDate: Date = new Date()): { startDate: Date; endDate: Date } {
        let endDate = new Date(referenceDate);
        let startDate = new Date(referenceDate);
        
        switch (period) {
            case 'today':
                startDate.setHours(0, 0, 0, 0);
                endDate.setHours(23, 59, 59, 999);
                break;
                
            case 'yesterday':
                startDate.setDate(startDate.getDate() - 1);
                startDate.setHours(0, 0, 0, 0);
                endDate.setDate(endDate.getDate() - 1);
                endDate.setHours(23, 59, 59, 999);
                break;
                
            case 'last_7_days':
                startDate.setDate(startDate.getDate() - 6);
                startDate.setHours(0, 0, 0, 0);
                break;
                
            case 'last_30_days':
                startDate.setDate(startDate.getDate() - 29);
                startDate.setHours(0, 0, 0, 0);
                break;
                
            case 'current_month':
                startDate.setDate(1);
                startDate.setHours(0, 0, 0, 0);
                break;
                
            case 'last_month':
                startDate.setMonth(startDate.getMonth() - 1, 1);
                startDate.setHours(0, 0, 0, 0);
                endDate.setDate(0); // Last day of previous month
                endDate.setHours(23, 59, 59, 999);
                break;
                
            case 'current_year':
                startDate.setMonth(0, 1);
                startDate.setHours(0, 0, 0, 0);
                break;
                
            case 'financial_year':
                startDate = this.getFinancialYearStart(referenceDate);
                endDate = this.getFinancialYearEnd(referenceDate);
                break;
                
            default:
                throw new Error(`Unknown period: ${period}`);
        }
        
        return { startDate, endDate };
    }
}

// MARK: - Currency Utilities

export class CurrencyUtils {
    private static readonly CURRENCY_SYMBOLS: { [key: string]: string } = {
        'INR': '₹',
        'USD': '$',
        'EUR': '€',
        'GBP': '£',
        'JPY': '¥',
        'AUD': 'A$',
        'CAD': 'C$',
        'CHF': 'CHF',
        'CNY': '¥',
        'SEK': 'kr',
        'NZD': 'NZ$'
    };
    
    /**
     * Format amount with currency
     */
    static formatCurrency(amount: number, currency: string = 'INR', locale: string = 'en-IN'): string {
        return new Intl.NumberFormat(locale, {
            style: 'currency',
            currency: currency,
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(amount);
    }
    
    /**
     * Format amount in Indian numbering system (with lakhs and crores)
     */
    static formatIndianCurrency(amount: number): string {
        const formatter = new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR',
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
        
        return formatter.format(amount);
    }
    
    /**
     * Get currency symbol
     */
    static getCurrencySymbol(currency: string): string {
        return this.CURRENCY_SYMBOLS[currency] || currency;
    }
    
    /**
     * Convert amount to words (useful for checks)
     */
    static amountToWords(amount: number, currency: string = 'INR'): string {
        if (currency === 'INR') {
            return this.convertINRToWords(amount);
        }
        // Add other currency conversions as needed
        return amount.toString();
    }
    
    private static convertINRToWords(amount: number): string {
        const ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];
        const teens = ['Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
        const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
        
        const convertChunk = (num: number): string => {
            let result = '';
            
            if (num >= 100) {
                result += ones[Math.floor(num / 100)] + ' Hundred ';
                num %= 100;
            }
            
            if (num >= 20) {
                result += tens[Math.floor(num / 10)] + ' ';
                num %= 10;
            } else if (num >= 10) {
                result += teens[num - 10] + ' ';
                return result;
            }
            
            if (num > 0) {
                result += ones[num] + ' ';
            }
            
            return result;
        };
        
        if (amount === 0) return 'Zero Rupees Only';
        
        let rupees = Math.floor(amount);
        const paise = Math.round((amount - rupees) * 100);
        
        let result = '';
        
        if (rupees >= 10000000) { // Crores
            result += convertChunk(Math.floor(rupees / 10000000)) + 'Crore ';
            rupees %= 10000000;
        }
        
        if (rupees >= 100000) { // Lakhs
            result += convertChunk(Math.floor(rupees / 100000)) + 'Lakh ';
            rupees %= 100000;
        }
        
        if (rupees >= 1000) { // Thousands
            result += convertChunk(Math.floor(rupees / 1000)) + 'Thousand ';
            rupees %= 1000;
        }
        
        if (rupees > 0) {
            result += convertChunk(rupees);
        }
        
        result += 'Rupees';
        
        if (paise > 0) {
            result += ' and ' + convertChunk(paise) + 'Paise';
        }
        
        result += ' Only';
        
        return result.trim();
    }
}

// MARK: - Validation Utilities

export class ValidationUtils {
    /**
     * Validate Indian bank account number
     */
    static validateBankAccountNumber(accountNumber: string): boolean {
        // Remove spaces and hyphens
        const cleaned = accountNumber.replace(/[\s-]/g, '');
        
        // Bank account numbers in India are typically 9-18 digits
        return /^\d{9,18}$/.test(cleaned);
    }
    
    /**
     * Validate IFSC code
     */
    static validateIFSC(ifsc: string): boolean {
        // IFSC format: 4 letters + 0 + 6 alphanumeric characters
        return /^[A-Z]{4}0[A-Z0-9]{6}$/.test(ifsc.toUpperCase());
    }
    
    /**
     * Validate PAN number
     */
    static validatePAN(pan: string): boolean {
        // PAN format: 5 letters + 4 digits + 1 letter
        return /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(pan.toUpperCase());
    }
    
    /**
     * Validate Aadhaar number
     */
    static validateAadhaar(aadhaar: string): boolean {
        // Remove spaces
        const cleaned = aadhaar.replace(/\s/g, '');
        
        // Aadhaar is 12 digits and cannot start with 0 or 1
        if (!/^[2-9]\d{11}$/.test(cleaned)) {
            return false;
        }
        
        // Luhn algorithm check
        return this.luhnCheck(cleaned);
    }
    
    /**
     * Validate credit card number using Luhn algorithm
     */
    static validateCreditCardNumber(cardNumber: string): boolean {
        const cleaned = cardNumber.replace(/[\s-]/g, '');
        
        if (!/^\d{13,19}$/.test(cleaned)) {
            return false;
        }
        
        return this.luhnCheck(cleaned);
    }
    
    /**
     * Validate email address
     */
    static validateEmail(email: string): boolean {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }
    
    /**
     * Validate Indian mobile number
     */
    static validateIndianMobile(mobile: string): boolean {
        const cleaned = mobile.replace(/[\s-+]/g, '');
        
        // Indian mobile numbers: 10 digits starting with 6, 7, 8, or 9
        // Or with country code: +91 followed by 10 digits
        return /^([6-9]\d{9}|91[6-9]\d{9})$/.test(cleaned);
    }
    
    /**
     * Luhn algorithm for checksum validation
     */
    private static luhnCheck(num: string): boolean {
        let sum = 0;
        let isEven = false;
        
        for (let i = num.length - 1; i >= 0; i--) {
            let digit = parseInt(num.charAt(i), 10);
            
            if (isEven) {
                digit *= 2;
                if (digit > 9) {
                    digit -= 9;
                }
            }
            
            sum += digit;
            isEven = !isEven;
        }
        
        return sum % 10 === 0;
    }
}

// MARK: - Text Processing Utilities

export class TextUtils {
    /**
     * Extract amount from text using various patterns
     */
    static extractAmount(text: string): number | null {
        // Common amount patterns in Indian context
        const patterns = [
            /₹[\s]*([\d,]+\.?\d*)/,           // ₹1,000.50
            /INR[\s]*([\d,]+\.?\d*)/i,        // INR 1,000.50
            /Rs\.?[\s]*([\d,]+\.?\d*)/i,      // Rs. 1,000.50
            /([\d,]+\.?\d*)[\s]*(?:₹|INR|Rs\.?)/i, // 1,000.50 Rs
            /(?:paid|spent|cost|amount|total)[\s:]*₹?[\s]*([\d,]+\.?\d*)/i,
            /([\d,]+\.?\d*)/                  // Fallback: any number
        ];
        
        for (const pattern of patterns) {
            const match = text.match(pattern);
            if (match) {
                const amountStr = match[1].replace(/,/g, '');
                const amount = parseFloat(amountStr);
                if (!isNaN(amount) && amount > 0) {
                    return amount;
                }
            }
        }
        
        return null;
    }
    
    /**
     * Infer transaction type from description
     */
    static inferTransactionType(description: string): TransactionType {
        const lowerDesc = description.toLowerCase();
        
        // Expense indicators
        const expenseKeywords = [
            'paid', 'purchase', 'bought', 'bill', 'fee', 'charge', 'debit',
            'withdrawal', 'atm', 'shopping', 'restaurant', 'fuel', 'grocery'
        ];
        
        // Income indicators
        const incomeKeywords = [
            'salary', 'credit', 'deposit', 'refund', 'cashback', 'interest',
            'dividend', 'bonus', 'received', 'income'
        ];
        
        // Transfer indicators
        const transferKeywords = [
            'transfer', 'upi', 'neft', 'rtgs', 'imps', 'sent to', 'received from'
        ];
        
        if (transferKeywords.some(keyword => lowerDesc.includes(keyword))) {
            return TransactionType.TRANSFER;
        }
        
        if (incomeKeywords.some(keyword => lowerDesc.includes(keyword))) {
            return TransactionType.INCOME;
        }
        
        if (expenseKeywords.some(keyword => lowerDesc.includes(keyword))) {
            return TransactionType.EXPENSE;
        }
        
        // Default to expense if unclear
        return TransactionType.EXPENSE;
    }
    
    /**
     * Infer transaction category from description
     */
    static inferTransactionCategory(description: string, amount: number): TransactionCategory {
        const lowerDesc = description.toLowerCase();
        
        // Category mappings with keywords
        const categoryMappings: { [key in TransactionCategory]: string[] } = {
            [TransactionCategory.SALARY]: ['salary', 'wages', 'payroll'],
            [TransactionCategory.FOOD_DINING]: ['restaurant', 'hotel', 'cafe', 'food', 'dining', 'zomato', 'swiggy'],
            [TransactionCategory.GROCERIES]: ['grocery', 'supermarket', 'vegetables', 'fruits', 'bigbasket', 'grofers'],
            [TransactionCategory.TRANSPORTATION]: ['uber', 'ola', 'taxi', 'bus', 'metro', 'auto', 'transport'],
            [TransactionCategory.FUEL]: ['petrol', 'diesel', 'fuel', 'gas', 'hp', 'ioc', 'bpcl'],
            [TransactionCategory.UTILITIES]: ['electricity', 'water', 'gas', 'internet', 'mobile', 'recharge'],
            [TransactionCategory.MEDICAL]: ['hospital', 'doctor', 'pharmacy', 'medicine', 'medical'],
            [TransactionCategory.ENTERTAINMENT]: ['movie', 'cinema', 'netflix', 'spotify', 'game'],
            [TransactionCategory.SHOPPING]: ['amazon', 'flipkart', 'mall', 'shopping', 'clothes'],
            [TransactionCategory.BANK_FEES]: ['charges', 'fee', 'penalty', 'service charge'],
            [TransactionCategory.UPI_TRANSFER]: ['upi', 'paytm', 'phonepe', 'gpay', 'bhim']
        } as any;
        
        // Check for category matches
        for (const [category, keywords] of Object.entries(categoryMappings)) {
            if (keywords.some(keyword => lowerDesc.includes(keyword))) {
                return category as TransactionCategory;
            }
        }
        
        // Amount-based inference for common categories
        if (amount >= 10000) {
            if (lowerDesc.includes('rent') || lowerDesc.includes('emi')) {
                return TransactionCategory.RENT;
            }
        }
        
        // Default categories
        return TransactionCategory.OTHER_EXPENSE;
    }
    
    /**
     * Clean and normalize transaction description
     */
    static cleanDescription(description: string): string {
        return description
            .trim()
            .replace(/\s+/g, ' ')
            .replace(/[^\w\s-.,]/g, '')
            .substring(0, 200); // Limit length
    }
    
    /**
     * Extract merchant name from description
     */
    static extractMerchantName(description: string): string | null {
        // Common patterns for merchant names in transaction descriptions
        const patterns = [
            /(?:at|@)\s+([A-Za-z0-9\s&.-]+?)(?:\s|$|,)/,
            /([A-Z][A-Za-z0-9\s&.-]+)\s+(?:BANGALORE|MUMBAI|DELHI|CHENNAI|HYDERABAD|PUNE)/i,
            /POS\s+([A-Za-z0-9\s&.-]+)/i,
            /([A-Za-z0-9\s&.-]+)\s+UPI/i
        ];
        
        for (const pattern of patterns) {
            const match = description.match(pattern);
            if (match && match[1]) {
                return match[1].trim();
            }
        }
        
        return null;
    }
}

// MARK: - Encryption Utilities

export class EncryptionUtils {
    /**
     * Generate a secure random string
     */
    static generateSecureRandom(length: number = 32): string {
        const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        let result = '';
        
        for (let i = 0; i < length; i++) {
            result += charset.charAt(Math.floor(Math.random() * charset.length));
        }
        
        return result;
    }
    
    /**
     * Hash sensitive data (one-way)
     */
    static async hashData(data: string, salt?: string): Promise<string> {
        const encoder = new TextEncoder();
        const saltBytes = salt ? encoder.encode(salt) : crypto.getRandomValues(new Uint8Array(16));
        const dataBytes = encoder.encode(data);
        
        const combined = new Uint8Array(saltBytes.length + dataBytes.length);
        combined.set(saltBytes);
        combined.set(dataBytes, saltBytes.length);
        
        const hashBuffer = await crypto.subtle.digest('SHA-256', combined);
        const hashArray = Array.from(new Uint8Array(hashBuffer));
        
        return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    }
    
    /**
     * Mask sensitive data for display
     */
    static maskAccountNumber(accountNumber: string): string {
        if (accountNumber.length <= 4) return accountNumber;
        
        const visibleLength = Math.min(4, accountNumber.length - 4);
        const maskedLength = accountNumber.length - visibleLength;
        
        return accountNumber.substring(0, visibleLength) + '*'.repeat(maskedLength);
    }
    
    /**
     * Mask card number for display
     */
    static maskCardNumber(cardNumber: string): string {
        const cleaned = cardNumber.replace(/\D/g, '');
        if (cleaned.length < 8) return cleaned;
        
        const firstFour = cleaned.substring(0, 4);
        const lastFour = cleaned.substring(cleaned.length - 4);
        const middleLength = cleaned.length - 8;
        
        return `${firstFour}${'*'.repeat(middleLength)}${lastFour}`;
    }
}

// MARK: - Data Processing Utilities

export class DataUtils {
    /**
     * Deep clone an object
     */
    static deepClone<T>(obj: T): T {
        if (obj === null || typeof obj !== 'object') return obj;
        if (obj instanceof Date) return new Date(obj.getTime()) as any;
        if (obj instanceof Array) return obj.map(item => this.deepClone(item)) as any;
        if (typeof obj === 'object') {
            const clonedObj = {} as any;
            for (const key in obj) {
                clonedObj[key] = this.deepClone(obj[key]);
            }
            return clonedObj;
        }
        return obj;
    }
    
    /**
     * Group array of objects by a key
     */
    static groupBy<T>(array: T[], keyFn: (item: T) => string): { [key: string]: T[] } {
        return array.reduce((groups, item) => {
            const key = keyFn(item);
            if (!groups[key]) {
                groups[key] = [];
            }
            groups[key].push(item);
            return groups;
        }, {} as { [key: string]: T[] });
    }
    
    /**
     * Calculate percentage change
     */
    static percentageChange(oldValue: number, newValue: number): number {
        if (oldValue === 0) return newValue > 0 ? 100 : 0;
        return ((newValue - oldValue) / Math.abs(oldValue)) * 100;
    }
    
    /**
     * Round to specified decimal places
     */
    static roundToDecimals(value: number, decimals: number = 2): number {
        return Math.round(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
    }
    
    /**
     * Calculate compound annual growth rate (CAGR)
     */
    static calculateCAGR(beginningValue: number, endingValue: number, periods: number): number {
        if (beginningValue <= 0 || endingValue <= 0 || periods <= 0) return 0;
        return (Math.pow(endingValue / beginningValue, 1 / periods) - 1) * 100;
    }
    
    /**
     * Calculate simple moving average
     */
    static simpleMovingAverage(values: number[], period: number): number[] {
        if (values.length < period) return [];
        
        const sma: number[] = [];
        for (let i = period - 1; i < values.length; i++) {
            const sum = values.slice(i - period + 1, i + 1).reduce((acc, val) => acc + val, 0);
            sma.push(sum / period);
        }
        
        return sma;
    }
    
    /**
     * Calculate standard deviation
     */
    static standardDeviation(values: number[]): number {
        if (values.length === 0) return 0;
        
        const mean = values.reduce((sum, value) => sum + value, 0) / values.length;
        const squaredDifferences = values.map(value => Math.pow(value - mean, 2));
        const avgSquaredDiff = squaredDifferences.reduce((sum, value) => sum + value, 0) / values.length;
        
        return Math.sqrt(avgSquaredDiff);
    }
}

