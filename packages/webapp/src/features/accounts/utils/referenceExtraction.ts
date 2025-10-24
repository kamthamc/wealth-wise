/**
 * Reference ID Extraction Utilities
 * Extract transaction reference IDs from descriptions for duplicate detection
 */

/**
 * Common patterns for transaction reference IDs across Indian banks
 */
const REFERENCE_PATTERNS = [
  // HDFC Bank patterns
  /chq\.?\/ref\.?no\.?\s*:?\s*(\w+)/i,
  /ref\.?\s*no\.?\s*:?\s*(\w+)/i,
  /chq\.?\s*no\.?\s*:?\s*(\w+)/i,

  // ICICI Bank patterns
  /ref\.?\s*#?\s*:?\s*(\w+)/i,
  /txn\.?\s*ref\.?\s*:?\s*(\w+)/i,

  // SBI patterns
  /utr\.?\s*no\.?\s*:?\s*(\w+)/i,
  /ref\.?\s*:?\s*(\w+)/i,

  // Axis Bank patterns
  /transaction\s*ref\.?\s*no\.?\s*:?\s*(\w+)/i,
  /txn\.?\s*id\.?\s*:?\s*(\w+)/i,

  // UPI patterns
  /upi\/(\d+)/i,
  /upi.*?\/(\w{12,})/i, // UPI transaction IDs are typically 12+ chars

  // IMPS/NEFT/RTGS patterns
  /imps\/(\w+)/i,
  /neft\/(\w+)/i,
  /rtgs\/(\w+)/i,

  // Generic patterns (at least 8 alphanumeric characters)
  /\b([A-Z0-9]{8,})\b/, // All caps alphanumeric, min 8 chars
  /ref\s*:?\s*(\d{6,})/i, // Reference with at least 6 digits
];

/**
 * Extract transaction reference ID from description text
 * Tries multiple patterns common across Indian banks
 */
export function extractReferenceFromDescription(
  description: string
): string | undefined {
  if (!description || description.trim() === '') {
    return undefined;
  }

  const normalized = description.trim();

  // Try each pattern in order of specificity
  for (const pattern of REFERENCE_PATTERNS) {
    const match = normalized.match(pattern);
    if (match && match[1]) {
      const refId = match[1].trim();
      // Validate it's not just common words or very short
      if (refId.length >= 6 && !isCommonWord(refId)) {
        return refId;
      }
    }
  }

  return undefined;
}

/**
 * Check if a string is a common word (not a reference ID)
 */
function isCommonWord(str: string): boolean {
  const commonWords = [
    'SALARY',
    'PAYMENT',
    'TRANSFER',
    'DEPOSIT',
    'WITHDRAWAL',
    'CREDIT',
    'DEBIT',
    'INTEREST',
    'CHARGES',
    'BALANCE',
  ];
  return commonWords.includes(str.toUpperCase());
}

/**
 * Normalize reference ID for comparison
 * Remove common prefixes/suffixes and convert to uppercase
 */
export function normalizeReferenceId(refId: string): string {
  return refId
    .toUpperCase()
    .replace(/^(REF|CHQ|TXN|UTR|UPI)[:/\s]*/i, '') // Remove common prefixes
    .replace(/[^A-Z0-9]/g, '') // Keep only alphanumeric
    .trim();
}

/**
 * Extract reference ID from transaction with fallback to description parsing
 */
export function getTransactionReference(
  explicitReference?: string,
  description?: string
): string | undefined {
  // Use explicit reference if provided
  if (explicitReference && explicitReference.trim() !== '') {
    return normalizeReferenceId(explicitReference);
  }

  // Try to extract from description
  if (description) {
    const extracted = extractReferenceFromDescription(description);
    if (extracted) {
      return normalizeReferenceId(extracted);
    }
  }

  return undefined;
}

/**
 * Check if two reference IDs match (with normalization)
 */
export function referencesMatch(ref1?: string, ref2?: string): boolean {
  if (!ref1 || !ref2) return false;

  const normalized1 = normalizeReferenceId(ref1);
  const normalized2 = normalizeReferenceId(ref2);

  return normalized1 === normalized2 && normalized1.length >= 6;
}
