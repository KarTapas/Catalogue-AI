import type { FastifyInstance } from "fastify";
import {
  NotFoundError,
  UpstreamUnavailableError,
  ValidationError,
} from "../domain/errors.js";
import { ZodError } from "zod";

type ErrorDetail = {
  field: string;
  message: string;
};

function isBadRequestError(error: unknown): boolean {
  return (
    error instanceof Error &&
    "statusCode" in error &&
    error.statusCode === 400
  );
}

function validationDetails(error: ZodError): ErrorDetail[] {
  return error.issues.map((issue) => ({
    field: issue.path.map(String).join(".") || "request",
    message: "Invalid value",
  }));
}

export function registerErrorHandler(app: FastifyInstance): void {
  app.setErrorHandler((error, request, reply) => {
    if (error instanceof ZodError) {
      return reply.code(400).send({
        error: {
          code: "VALIDATION_ERROR",
          message: "Invalid request",
          details: validationDetails(error),
        },
      });
    }

    if (error instanceof ValidationError) {
      return reply.code(400).send({
        error: {
          code: "VALIDATION_ERROR",
          message: "Invalid request",
          details: [{ field: "request", message: "Invalid value" }],
        },
      });
    }

    if (error instanceof NotFoundError) {
      return reply.code(404).send({
        error: { code: "NOT_FOUND", message: error.message },
      });
    }

    if (error instanceof UpstreamUnavailableError) {
      return reply.code(502).send({
        error: {
          code: "UPSTREAM_UNAVAILABLE",
          message: error.message,
        },
      });
    }

    if (isBadRequestError(error)) {
      return reply.code(400).send({
        error: {
          code: "VALIDATION_ERROR",
          message: "Invalid request",
          details: [{ field: "request", message: "Invalid request" }],
        },
      });
    }

    request.log.error({ err: error }, "Unhandled request error");
    return reply.code(500).send({
      error: { code: "INTERNAL", message: "Internal server error" },
    });
  });

  app.setNotFoundHandler(() => {
    throw new NotFoundError("Route not found");
  });
}
