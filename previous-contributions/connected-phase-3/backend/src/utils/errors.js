/**
 * Custom error classes for API responses
 */

export class ApiError extends Error {
  constructor(message, statusCode = 500, code = "INTERNAL_ERROR") {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class ValidationError extends ApiError {
  constructor(message, details = null) {
    super(message, 400, "VALIDATION_ERROR");
    this.details = details;
  }
}

export class AuthenticationError extends ApiError {
  constructor(message = "Unauthorized") {
    super(message, 401, "AUTHENTICATION_ERROR");
  }
}

export class AuthorizationError extends ApiError {
  constructor(message = "Forbidden") {
    super(message, 403, "AUTHORIZATION_ERROR");
  }
}

export class NotFoundError extends ApiError {
  constructor(message = "Not found") {
    super(message, 404, "NOT_FOUND");
  }
}

export class ConflictError extends ApiError {
  constructor(message = "Conflict", code = "CONFLICT") {
    super(message, 409, code);
  }
}

export class RateLimitError extends ApiError {
  constructor(message = "Too many requests") {
    super(message, 429, "RATE_LIMIT_EXCEEDED");
  }
}

export function handleError(error, res) {
  console.error("Error:", error);

  if (error instanceof ApiError) {
    return res.status(error.statusCode).json({
      success: false,
      error: {
        code: error.code,
        message: error.message,
        ...(error.details && { details: error.details }),
      },
    });
  }

  // Auth-adapter errors
  if (typeof error.code === "string" && error.code.includes("auth/")) {
    const statusCode = error.code === "auth/user-not-found" ? 404 : 400;
    return res.status(statusCode).json({
      success: false,
      error: {
        code: error.code,
        message: error.message,
      },
    });
  }

  return res.status(500).json({
    success: false,
    error: {
      code: "INTERNAL_ERROR",
      message: "An unexpected error occurred",
    },
  });
}

export default ApiError;
