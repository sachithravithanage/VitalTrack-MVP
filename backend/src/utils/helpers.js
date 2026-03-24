import { v4 as uuidv4 } from "uuid";
import crypto from "crypto";

/**
 * Generate a unique ID
 */
export function generateId() {
  return uuidv4();
}

/**
 * Generate a 6-digit OTP
 */
export function generateOTP(length = 6) {
  let otp = "";
  for (let i = 0; i < length; i++) {
    otp += Math.floor(Math.random() * 10);
  }
  return otp;
}

/**
 * Generate a caregiver link code (6 digits)
 */
export function generateLinkCode() {
  return generateOTP(6);
}

/**
 * Hash data using SHA256
 */
export function hashData(data) {
  return crypto.createHash("sha256").update(data).digest("hex");
}

/**
 * Check if timestamp is expired
 */
export function isExpired(timestamp, expiryMinutes) {
  const now = Date.now();
  const expiry = timestamp + expiryMinutes * 60 * 1000;
  return now > expiry;
}

/**
 * Format timestamp-like values to ISO string
 */
export function formatTimestamp(timestamp) {
  if (!timestamp) return null;
  if (timestamp.toDate) {
    return timestamp.toDate().toISOString();
  }
  return new Date(timestamp).toISOString();
}

/**
 * Parse duration string to milliseconds
 */
export function parseDuration(duration) {
  const units = {
    ms: 1,
    s: 1000,
    m: 60000,
    h: 3600000,
    d: 86400000,
  };

  const match = duration.match(/^(\d+)([a-z]+)$/);
  if (!match) return null;

  const [, value, unit] = match;
  return parseInt(value) * (units[unit] || 1);
}

/**
 * Calculate age from date of birth
 */
export function calculateAge(dob) {
  const today = new Date();
  const birthDate = new Date(dob);
  let age = today.getFullYear() - birthDate.getFullYear();
  const monthDiff = today.getMonth() - birthDate.getMonth();

  if (
    monthDiff < 0 ||
    (monthDiff === 0 && today.getDate() < birthDate.getDate())
  ) {
    age--;
  }

  return age;
}

/**
 * Sanitize filename for storage
 */
export function sanitizeFilename(filename) {
  return filename
    .toLowerCase()
    .replace(/[^a-z0-9]/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-+|-+$/g, "");
}

/**
 * Deep clone object
 */
export function deepClone(obj) {
  return JSON.parse(JSON.stringify(obj));
}

/**
 * Paginate array
 */
export function paginate(array, page = 1, pageSize = 20) {
  const startIndex = (page - 1) * pageSize;
  const endIndex = startIndex + pageSize;

  return {
    data: array.slice(startIndex, endIndex),
    pagination: {
      page,
      pageSize,
      total: array.length,
      pages: Math.ceil(array.length / pageSize),
    },
  };
}

export default {
  generateId,
  generateOTP,
  generateLinkCode,
  hashData,
  isExpired,
  formatTimestamp,
  parseDuration,
  calculateAge,
  sanitizeFilename,
  deepClone,
  paginate,
};
