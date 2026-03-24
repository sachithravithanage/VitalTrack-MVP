import validator from "validator";
import { ValidationError, AuthenticationError } from "./errors.js";

export function validateEmail(email) {
  if (!email || !validator.isEmail(email)) {
    throw new ValidationError("Invalid email address");
  }
  return email.toLowerCase();
}

export function validatePhone(phone) {
  const cleanPhone = String(phone || "").replace(/\D/g, "");

  if (!cleanPhone) {
    throw new ValidationError("Invalid phone number");
  }

  // Sri Lankan mobile formats supported:
  // 07XXXXXXXX, 7XXXXXXXX, 94XXXXXXXXX, +94XXXXXXXXX
  if (/^07\d{8}$/.test(cleanPhone)) {
    return `94${cleanPhone.slice(1)}`;
  }

  if (/^7\d{8}$/.test(cleanPhone)) {
    return `94${cleanPhone}`;
  }

  if (/^94\d{9}$/.test(cleanPhone)) {
    return cleanPhone;
  }

  throw new ValidationError("Invalid Sri Lankan mobile number");
}

export function validatePassword(password) {
  if (!password || password.length < 6) {
    throw new ValidationError("Password must be at least 6 characters");
  }
  return password;
}

export function validateOTP(otp) {
  if (!otp || otp.length !== 6 || !/^\d{6}$/.test(otp)) {
    throw new ValidationError("Invalid OTP format");
  }
  return otp;
}

export function validateUserRole(role) {
  const validRoles = ["patient", "caregiver"];
  if (!validRoles.includes(role)) {
    throw new ValidationError(
      `Invalid role. Must be one of: ${validRoles.join(", ")}`,
    );
  }
  return role;
}

export function validateDiseaseType(disease) {
  const validDiseases = ["dengue", "ratFever"];
  if (!validDiseases.includes(disease)) {
    throw new ValidationError(
      `Invalid disease type. Must be one of: ${validDiseases.join(", ")}`,
    );
  }
  return disease;
}

export function validateCoordinates(lat, lng) {
  const latitude = parseFloat(lat);
  const longitude = parseFloat(lng);

  if (isNaN(latitude) || isNaN(longitude)) {
    throw new ValidationError("Invalid coordinates");
  }

  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    throw new ValidationError("Coordinates out of range");
  }

  return { latitude, longitude };
}

export function validateName(name) {
  const trimmedName = (name || "").trim();
  if (!trimmedName || trimmedName.length < 2) {
    throw new ValidationError("Name must be at least 2 characters");
  }
  if (trimmedName.length > 100) {
    throw new ValidationError("Name must not exceed 100 characters");
  }
  return trimmedName;
}

export function validateRecordValues(values) {
  if (!values || typeof values !== "object") {
    throw new ValidationError("Record values must be an object");
  }

  // Validate numeric fields
  const numericFields = ["temperature", "fluidIntake", "urineOutput"];
  for (const field of numericFields) {
    if (values[field] !== undefined) {
      const num = parseFloat(values[field]);
      if (isNaN(num) || num < 0) {
        throw new ValidationError(`${field} must be a positive number`);
      }
    }
  }

  // Validate boolean fields
  const booleanFields = ["bodyPain", "vomiting", "headache", "rash"];
  for (const field of booleanFields) {
    if (values[field] !== undefined && typeof values[field] !== "boolean") {
      throw new ValidationError(`${field} must be a boolean`);
    }
  }

  return values;
}

export function validateTokenFormat(token) {
  if (!token || typeof token !== "string") {
    throw new AuthenticationError("Invalid token format");
  }
  return token;
}

export default {
  validateEmail,
  validatePhone,
  validatePassword,
  validateOTP,
  validateUserRole,
  validateDiseaseType,
  validateCoordinates,
  validateName,
  validateRecordValues,
  validateTokenFormat,
};
