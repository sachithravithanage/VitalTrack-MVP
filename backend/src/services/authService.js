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

  const phoneQuery = await db
    .collection("users")
    .where("phone", "==", normalizedPhone)
    .get();

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
      role,
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
    if (role === "patient") {
      await db.collection("patients").doc(userRecord.uid).set({
        uid: userRecord.uid,
        linkedCaregivers: [],
        medicalHistory: [],
      });
    } else if (role === "caregiver") {
      await db.collection("caregivers").doc(userRecord.uid).set({
        uid: userRecord.uid,
        linkedPatients: [],
        verificationStatus: "pending",
      });
    }

    return {
      id: userRecord.uid,
      uid: userRecord.uid,
      email: normalizedEmail,
      phone: normalizedPhone,
      name,
      role,
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
    const query = await db
      .collection("users")
      .where("phone", "==", normalizedPhone)
      .get();
    if (query.empty) {
      throw new AuthenticationError("User not found");
    }
    userDoc = query.docs[0];
  }

  const user = userDoc.data();

  // Verify password from stored hash.
  if (!user.passwordHash) {
    throw new AuthenticationError("Password verification unavailable for user");
  }

  const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
  if (!isPasswordValid) {
    throw new AuthenticationError("Invalid credentials");
  }

  return {
    id: user.uid,
    uid: user.uid,
    email: user.email,
    phone: user.phone,
    name: user.name,
    role: user.role,
    emailVerified: user.emailVerified,
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

  return userDoc.data();
}

/**
 * Update user profile
 */
export async function updateUserProfile(uid, updates) {
  const { name, phone, email } = updates;

  // Validate updates
  const validUpdates = {};

  if (name !== undefined) {
    validUpdates.name = name;
  }

  if (phone !== undefined) {
    // Check if phone is already in use
    const phoneQuery = await db
      .collection("users")
      .where("phone", "==", phone)
      .where("uid", "!=", uid)
      .get();

    if (!phoneQuery.empty) {
      throw new ConflictError("Phone number already in use");
    }

    validUpdates.phone = phone;
  }

  if (email !== undefined) {
    // Check if email is already in use
    const emailQuery = await db
      .collection("users")
      .where("email", "==", email)
      .where("uid", "!=", uid)
      .get();

    if (!emailQuery.empty) {
      throw new ConflictError("Email already in use");
    }

    validUpdates.email = email;
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
  getUserProfile,
  updateUserProfile,
  markEmailVerified,
  createCustomAuthToken,
};
