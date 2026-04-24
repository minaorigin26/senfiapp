/**
 * Senfi Security Utilities
 * Input validation and sanitization for all user-facing inputs.
 * Used before any data reaches Supabase.
 */

// ─── Constants ────────────────────────────────────────────────────────────────

export const MAX_INPUT_LENGTH = 500;
export const MAX_AMOUNT = 9_999_999;
export const MAX_TAG_LENGTH = 50;
export const MAX_DESCRIPTION_LENGTH = 200;

// ─── Input Sanitization ───────────────────────────────────────────────────────

/**
 * Strip HTML tags and script content from user text.
 * Prevents XSS if data ever renders in a web context.
 */
export function sanitizeInput(text: string): string {
  if (!text || typeof text !== 'string') return '';

  return text
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/<[^>]*>/g, '')
    .replace(/javascript:/gi, '')
    .replace(/on\w+\s*=/gi, '')
    .trim()
    .slice(0, MAX_INPUT_LENGTH);
}

/**
 * Sanitize a tag name: lowercase slug, alphanumeric + hyphens only.
 */
export function sanitizeTag(tag: string): string {
  if (!tag || typeof tag !== 'string') return '';

  return tag
    .trim()
    .toLowerCase()
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9\-áéíóúüñ]/g, '')
    .slice(0, MAX_TAG_LENGTH);
}

// ─── Amount Validation ────────────────────────────────────────────────────────

/**
 * Validate a monetary amount.
 * Returns true if valid: positive number, max 2 decimals, within allowed range.
 */
export function validateAmount(amount: number): boolean {
  if (typeof amount !== 'number') return false;
  if (!isFinite(amount)) return false;
  if (amount <= 0) return false;
  if (amount > MAX_AMOUNT) return false;

  // Max 2 decimal places
  const decimals = (amount.toString().split('.')[1] ?? '').length;
  if (decimals > 2) return false;

  return true;
}

/**
 * Parse and validate an amount from a string input.
 * Returns the parsed number or null if invalid.
 */
export function parseAmount(raw: string): number | null {
  if (!raw || typeof raw !== 'string') return null;

  // Remove currency symbols and thousands separators
  const cleaned = raw
    .replace(/[RD$€£¥,\s]/g, '')
    .replace(/\./g, (match, offset, str) => {
      // Keep only the last dot as decimal separator
      const lastDot = str.lastIndexOf('.');
      return offset === lastDot ? '.' : '';
    });

  const amount = parseFloat(cleaned);
  if (isNaN(amount)) return null;
  if (!validateAmount(amount)) return null;

  return amount;
}

// ─── Text Validation ──────────────────────────────────────────────────────────

/**
 * Validate a free-text field (name, description, notes).
 */
export function validateText(
  text: string,
  maxLength: number = MAX_INPUT_LENGTH
): { valid: boolean; error?: string } {
  if (!text || text.trim().length === 0) {
    return { valid: false, error: 'Campo requerido.' };
  }
  if (text.trim().length > maxLength) {
    return { valid: false, error: `Máximo ${maxLength} caracteres.` };
  }
  return { valid: true };
}

/**
 * Validate an email address (basic RFC check).
 */
export function validateEmail(email: string): boolean {
  if (!email || typeof email !== 'string') return false;
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email.trim()) && email.length <= 254;
}

// ─── Rate Limiting (client-side guard) ───────────────────────────────────────

const actionTimestamps: Map<string, number[]> = new Map();

/**
 * Simple client-side rate limiter.
 * @param action  - unique action name
 * @param maxCalls - max allowed calls
 * @param windowMs - time window in milliseconds
 */
export function isRateLimited(
  action: string,
  maxCalls: number = 5,
  windowMs: number = 60_000
): boolean {
  const now = Date.now();
  const timestamps = actionTimestamps.get(action) ?? [];

  const recent = timestamps.filter((t) => now - t < windowMs);
  recent.push(now);
  actionTimestamps.set(action, recent);

  return recent.length > maxCalls;
}
