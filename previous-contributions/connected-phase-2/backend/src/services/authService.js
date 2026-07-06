import { db, auth } from "../config/firebase.js";
import bcrypt from "bcryptjs";
import {
  generateOTP,
  isExpired,
  hashData,
  generateId,
} from "../utils/helpers.js";
import {
  ValidationError,
  AuthenticationError,
  ConflictError,
  NotFoundError,
} from "../utils/errors.js";

const OTP_EXPIRY_MINUTES = 5;
const STEP_UP_EXPIRY_MINUTES = 10;

function normalizePhone(phone) {
  const digits = String(phone || "").replace(/\D/g, "");
  if (/^07\d{8}$/.test(digits)) {
    return `94${digits.slice(1)}`;
  }
  if (/^7\d{8}$/.test(digits)) {
    return `94${digits}`;
  }
  return digits;
}

function phoneVariants(phone) {
  const normalized = normalizePhone(phone);
  const variants = new Set([normalized]);

  if (/^94\d{9}$/.test(normalized)) {
    variants.add(`0${normalized.slice(2)}`);
    variants.add(normalized.slice(2));
  } else if (/^07\d{8}$/.test(normalized)) {
    variants.add(`94${normalized.slice(1)}`);
    variants.add(normalized.slice(1));
  } else if (/^7\d{8}$/.test(normalized)) {
    variants.add(`94${normalized}`);
    variants.add(`0${normalized}`);
  }

  return Array.from(variants).filter((v) => v && v.trim().length > 0);
}

async function queryUsersByPhone(phone) {
  const variants = phoneVariants(phone);
  if (variants.length === 1) {
    return db.collection("users").where("phone", "==", variants[0]).get();
  }

  return db.collection("users").where("phone", "in", variants).get();
}

function normalizeRole(role) {
  return String(role || "").toLowerCase() === "caregiver"
    ? "caregiver"
    : "patient";
}

function extractRoles(profile) {
  if (Array.isArray(profile?.roles) && profile.roles.length > 0) {
    return Array.from(
      new Set(profile.roles.map((value) => normalizeRole(value))),
    );
  }

  if (profile?.role) {
    return [normalizeRole(profile.role)];
  }

  return ["patient"];
}

function resolveActiveRole(profile) {
  const roles = extractRoles(profile);
  const preferred = normalizeRole(profile?.activeRole || profile?.role);
  return roles.includes(preferred) ? preferred : roles[0];
}

async function ensureRoleDocument(uid, role) {
  if (role === "patient") {
    await db.collection("patients").doc(uid).set(
      {
        uid,
        linkedCaregivers: [],
        medicalHistory: [],
      },
      { merge: true },
    );
    return;
  }

  if (role === "caregiver") {
    await db.collection("caregivers").doc(uid).set(
      {
        uid,
        linkedPatients: [],
        verificationStatus: "pending",
      },
      { merge: true },
    );
  }
}

/**
 * Create or update OTP for phone/email
 */
export async function createOTP(credential, type) {
  const otp = generateOTP(6);
  const timestamp = Date.now();

  // Store OTP in Firestore (expires after 5 minutes)
  await db
    .collection("otps")
    .doc(hashData(credential))
    .set(
      {
        credential,
        type, // 'phone' or 'email'
        otp: hashData(otp),
        createdAt: timestamp,
        expiresAt: timestamp + OTP_EXPIRY_MINUTES * 60 * 1000,
      },
      { merge: true },
    );

  return otp; // Return unhashed OTP to send via SMS/Email
}

/**
 * Verify OTP
 */
export async function verifyOTP(credential, inputOTP) {
  const otpDoc = await db.collection("otps").doc(hashData(credential)).get();

  if (!otpDoc.exists) {
    throw new ValidationError("OTP not found or expired");
  }

  const otpData = otpDoc.data();

  // Check if OTP is expired
  if (isExpired(otpData.createdAt, OTP_EXPIRY_MINUTES)) {
    await otpDoc.ref.delete();
    throw new ValidationError("OTP has expired");
  }

  // Verify OTP
  if (hashData(inputOTP) !== otpData.otp) {
    throw new ValidationError("Invalid OTP");
  }

  // Delete OTP after successful verification
  await otpDoc.ref.delete();

  return true;
}

/**
 * Register new user
 */
export async function registerUser(email, phone, password, name, role) {
  const normalizedRole = normalizeRole(role);
  const normalizedEmail = email ? String(email).trim().toLowerCase() : null;
  const normalizedPhone = normalizePhone(phone);
  const passwordHash = await bcrypt.hash(password, 10);
  let existingAuthUser = null;

  // Check Firebase Auth first to avoid Firestore/Auth drift issues.
  if (normalizedEmail) {
    try {
      const existingByEmail = await auth.getUserByEmail(normalizedEmail);
      if (existingByEmail) {
        existingAuthUser = existingByEmail;
      }
    } catch (error) {
      if (error.code !== "auth/user-not-found") {
        throw error;
      }
    }
  }

  try {
    const existingByPhone = await auth.getUserByPhoneNumber(
      `+${normalizedPhone}`,
    );
    if (existingByPhone) {
      if (existingAuthUser && existingAuthUser.uid !== existingByPhone.uid) {
        throw new ConflictError(
          "Phone/email belong to different existing accounts",
          "ACCOUNT_MISMATCH",
        );
      }
      existingAuthUser = existingByPhone;
    }
  } catch (error) {
    if (error.code !== "auth/user-not-found") {
      throw error;
    }
  }

  // Check if user already exists in Firestore.
  if (normalizedEmail) {
    const emailQuery = await db
      .collection("users")
      .where("email", "==", normalizedEmail)
      .get();

    if (!emailQuery.empty) {
      throw new ConflictError(
        "Email already registered",
        "EMAIL_ALREADY_EXISTS",
      );
    }
  }

  const phoneQuery = await queryUsersByPhone(normalizedPhone);

  if (!phoneQuery.empty) {
    throw new ConflictError(
      "Phone number already registered",
      "PHONE_ALREADY_EXISTS",
    );
  }

  try {
    let userRecord = existingAuthUser;

    // Create user in Firebase Auth if missing, otherwise update profile details.
    if (!userRecord) {
      userRecord = await auth.createUser({
        ...(normalizedEmail ? { email: normalizedEmail } : {}),
        password,
        phoneNumber: `+${normalizedPhone}`,
        displayName: name,
      });
    } else {
      userRecord = await auth.updateUser(userRecord.uid, {
        ...(normalizedEmail ? { email: normalizedEmail } : {}),
        password,
        phoneNumber: `+${normalizedPhone}`,
        displayName: name,
      });
    }

    const userDocRef = db.collection("users").doc(userRecord.uid);
    const existingUserDoc = await userDocRef.get();

    if (existingUserDoc.exists) {
      throw new ConflictError("User already registered", "USER_ALREADY_EXISTS");
    }

    // Create user document in Firestore
    await userDocRef.set({
      uid: userRecord.uid,
      email: normalizedEmail,
      phone: normalizedPhone,
      name,
      role: normalizedRole,
      roles: [normalizedRole],
      activeRole: normalizedRole,
      emailVerified: false,
      passwordHash,
      createdAt: new Date(),
      updatedAt: new Date(),
      isActive: true,
      profile: {
        avatar: null,
        bio: "",
      },
    });

    // Create role-specific document
    await ensureRoleDocument(userRecord.uid, normalizedRole);

    return {
      id: userRecord.uid,
      uid: userRecord.uid,
      email: normalizedEmail,
      phone: normalizedPhone,
      name,
      role: normalizedRole,
      roles: [normalizedRole],
      activeRole: normalizedRole,
      emailVerified: false,
    };
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new ConflictError(
        "Email already registered",
        "EMAIL_ALREADY_EXISTS",
      );
    }
    if (error.code === "auth/phone-number-already-exists") {
      throw new ConflictError(
        "Phone number already registered",
        "PHONE_ALREADY_EXISTS",
      );
    }
    throw error;
  }
}

/**
 * Login user and return custom token
 */
export async function loginUser(credential, password) {
  // Find user by email or phone
  let userDoc;
  const normalizedCredential = String(credential || "").trim();

  if (normalizedCredential.includes("@")) {
    // Email login
    const query = await db
      .collection("users")
      .where("email", "==", normalizedCredential.toLowerCase())
      .get();
    if (query.empty) {
      throw new AuthenticationError("User not found");
    }
    userDoc = query.docs[0];
  } else {
    // Phone login
    const normalizedPhone = normalizePhone(normalizedCredential);
    const query = await queryUsersByPhone(normalizedPhone);
    if (query.empty) {
      throw new AuthenticationError("User not found");
    }
    userDoc = query.docs[0];
  }

  const user = userDoc.data();

  if (normalizedCredential.includes("@") && user.emailVerified !== true) {
    throw new AuthenticationError("Email is not verified for sign in");
  }

  // Verify password from stored hash.
  if (!user.passwordHash) {
    throw new AuthenticationError("Password verification unavailable for user");
  }

  const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
  if (!isPasswordValid) {
    throw new AuthenticationError("Invalid credentials");
  }

  const roles = extractRoles(user);
  const activeRole = resolveActiveRole(user);

  return {
    id: user.uid,
    uid: user.uid,
    email: user.email,
    phone: user.phone,
    name: user.name,
    role: activeRole,
    roles,
    activeRole,
    emailVerified: user.emailVerified,
  };
}

export async function ensureVerifiedEmailCredential(credential) {
  const normalizedCredential = String(credential || "").trim();
  if (!normalizedCredential.includes("@")) {
    return true;
  }

  const user = await findUserByCredential(normalizedCredential);
  if (user.emailVerified !== true) {
    throw new AuthenticationError("Email is not verified");
  }

  return true;
}

export async function createStepUpToken(uid, purpose) {
  const token = generateId().replace(/-/g, "");
  const tokenHash = hashData(`${uid}:${token}`);
  const now = Date.now();

  await db
    .collection("stepUpSessions")
    .doc(tokenHash)
    .set({
      uid,
      purpose,
      createdAt: now,
      expiresAt: now + STEP_UP_EXPIRY_MINUTES * 60 * 1000,
      consumed: false,
    });

  return token;
}

export async function consumeStepUpToken(uid, token, purpose) {
  const normalizedToken = String(token || "").trim();
  if (!normalizedToken) {
    throw new ValidationError("Step-up token is required");
  }

  const tokenHash = hashData(`${uid}:${normalizedToken}`);
  const sessionRef = db.collection("stepUpSessions").doc(tokenHash);
  const sessionDoc = await sessionRef.get();

  if (!sessionDoc.exists) {
    throw new AuthenticationError("Invalid step-up token");
  }

  const session = sessionDoc.data();
  if (session.uid !== uid) {
    throw new AuthenticationError("Step-up token does not belong to user");
  }

  if (purpose && session.purpose !== purpose) {
    throw new AuthenticationError("Step-up token purpose mismatch");
  }

  if (session.consumed === true) {
    throw new AuthenticationError("Step-up token already used");
  }

  if (Date.now() > Number(session.expiresAt || 0)) {
    await sessionRef.delete();
    throw new AuthenticationError("Step-up token expired");
  }

  await sessionRef.update({
    consumed: true,
    consumedAt: Date.now(),
  });

  return true;
}

/**
 * Find user by email or phone credential
 */
export async function findUserByCredential(credential) {
  let userDoc;
  const normalizedCredential = String(credential || "").trim();

  if (normalizedCredential.includes("@")) {
    const query = await db
      .collection("users")
      .where("email", "==", normalizedCredential.toLowerCase())
      .get();
    if (query.empty) {
      throw new NotFoundError("User not found");
    }
    userDoc = query.docs[0];
  } else {
    const normalizedPhone = normalizePhone(normalizedCredential);
    const query = await queryUsersByPhone(normalizedPhone);
    if (query.empty) {
      throw new NotFoundError("User not found");
    }
    userDoc = query.docs[0];
  }

  return userDoc.data();
}

/**
 * Reset password using credential
 */
export async function resetPasswordByCredential(credential, newPassword) {
  const user = await findUserByCredential(credential);

  const passwordHash = await bcrypt.hash(newPassword, 10);

  await db.collection("users").doc(user.uid).update({
    passwordHash,
    updatedAt: new Date(),
  });

  await auth.updateUser(user.uid, { password: newPassword });

  return {
    uid: user.uid,
    email: user.email,
    phone: user.phone,
  };
}

/**
 * Create a Firebase custom token for a user ID
 */
export async function createCustomAuthToken(uid) {
  return auth.createCustomToken(uid);
}

/**
 * Get user profile
 */
export async function getUserProfile(uid) {
  const userDoc = await db.collection("users").doc(uid).get();

  if (!userDoc.exists) {
    throw new NotFoundError("User not found");
  }

  const profile = userDoc.data();
  const roles = extractRoles(profile);
  const activeRole = resolveActiveRole(profile);

  return {
    ...profile,
    role: activeRole,
    roles,
    activeRole,
  };
}

export async function enableUserRole(uid, role) {
  const normalizedRole = normalizeRole(role);
  const profile = await getUserProfile(uid);
  const roles = extractRoles(profile);

  if (!roles.includes(normalizedRole)) {
    roles.push(normalizedRole);
  }

  const activeRole = resolveActiveRole({
    ...profile,
    roles,
    activeRole: profile.activeRole,
  });

  await db.collection("users").doc(uid).update({
    roles,
    role: activeRole,
    activeRole,
    updatedAt: new Date(),
  });

  await ensureRoleDocument(uid, normalizedRole);
  return getUserProfile(uid);
}

export async function setActiveUserRole(uid, role) {
  const normalizedRole = normalizeRole(role);
  const profile = await getUserProfile(uid);
  const roles = extractRoles(profile);

  if (!roles.includes(normalizedRole)) {
    throw new ValidationError("Role is not enabled for this user");
  }

  await db.collection("users").doc(uid).update({
    role: normalizedRole,
    activeRole: normalizedRole,
    updatedAt: new Date(),
  });

  return getUserProfile(uid);
}

/**
 * Update user profile
 */
export async function updateUserProfile(uid, updates) {
  const { name, phone, email } = updates;

  // Validate updates
  const validUpdates = {};
  const currentProfile = await getUserProfile(uid);

  if (name !== undefined) {
    validUpdates.name = name;
  }

  if (phone !== undefined) {
    const normalizedPhone = normalizePhone(phone);
    const variants = phoneVariants(normalizedPhone);

    // Check if phone is already in use
    const phoneQuery =
      variants.length === 1
        ? await db.collection("users").where("phone", "==", variants[0]).get()
        : await db.collection("users").where("phone", "in", variants).get();

    const hasConflict = phoneQuery.docs.some((doc) => doc.data().uid !== uid);

    if (hasConflict) {
      throw new ConflictError("Phone number already in use");
    }

    validUpdates.phone = normalizedPhone;
  }

  if (email !== undefined) {
    const normalizedEmail = String(email).trim().toLowerCase();

    // Check if email is already in use
    const emailQuery = await db
      .collection("users")
      .where("email", "==", normalizedEmail)
      .where("uid", "!=", uid)
      .get();

    if (!emailQuery.empty) {
      throw new ConflictError("Email already in use");
    }

    validUpdates.email = normalizedEmail;

    if (currentProfile.email !== normalizedEmail) {
      validUpdates.emailVerified = false;
      await auth.updateUser(uid, { email: normalizedEmail });
    }
  }

  validUpdates.updatedAt = new Date();

  await db.collection("users").doc(uid).update(validUpdates);

  return {
    ...(await getUserProfile(uid)),
  };
}

/**
 * Mark email as verified
 */
export async function markEmailVerified(uid) {
  await auth.updateUser(uid, { emailVerified: true });

  await db.collection("users").doc(uid).update({
    emailVerified: true,
    updatedAt: new Date(),
  });

  return true;
}

export default {
  createOTP,
  verifyOTP,
  registerUser,
  loginUser,
  findUserByCredential,
  resetPasswordByCredential,
  getUserProfile,
  updateUserProfile,
  markEmailVerified,
  enableUserRole,
  setActiveUserRole,
  ensureVerifiedEmailCredential,
  createStepUpToken,
  consumeStepUpToken,
  createCustomAuthToken,
};
