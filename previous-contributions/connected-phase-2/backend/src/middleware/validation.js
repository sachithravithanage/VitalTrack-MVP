import { ValidationError } from "../utils/errors.js";

/**
 * Validate request body against schema
 */
export function validateBody(schema) {
  return (req, res, next) => {
    try {
      const { error, value } = schema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
      });

      if (error) {
        const details = error.details.map((err) => ({
          field: err.path.join("."),
          message: err.message,
        }));

        throw new ValidationError("Invalid request body", details);
      }

      req.validatedBody = value;
      next();
    } catch (err) {
      if (err instanceof ValidationError) {
        return res.status(400).json({
          success: false,
          error: {
            code: err.code,
            message: err.message,
            details: err.details,
          },
        });
      }

      res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Invalid request body",
        },
      });
    }
  };
}

/**
 * Validate query parameters
 */
export function validateQuery(schema) {
  return (req, res, next) => {
    try {
      const { error, value } = schema.validate(req.query, {
        abortEarly: false,
      });

      if (error) {
        throw new ValidationError("Invalid query parameters");
      }

      req.validatedQuery = value;
      next();
    } catch (err) {
      res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Invalid query parameters",
        },
      });
    }
  };
}

/**
 * Validate URL parameters
 */
export function validateParams(schema) {
  return (req, res, next) => {
    try {
      const { error, value } = schema.validate(req.params, {
        abortEarly: false,
      });

      if (error) {
        throw new ValidationError("Invalid URL parameters");
      }

      req.validatedParams = value;
      next();
    } catch (err) {
      res.status(400).json({
        success: false,
        error: {
          code: "VALIDATION_ERROR",
          message: "Invalid URL parameters",
        },
      });
    }
  };
}

export default {
  validateBody,
  validateQuery,
  validateParams,
};
