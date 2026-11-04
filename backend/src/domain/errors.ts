export class NotFoundError extends Error {
  readonly code: "NOT_FOUND" = "NOT_FOUND";

  constructor(message = "Product not found") {
    super(message);
    this.name = "NotFoundError";
  }
}

export class UpstreamUnavailableError extends Error {
  readonly code: "UPSTREAM_UNAVAILABLE" = "UPSTREAM_UNAVAILABLE";

  constructor() {
    super("Product source unavailable");
    this.name = "UpstreamUnavailableError";
  }
}

export class ValidationError extends Error {
  readonly code: "VALIDATION_ERROR" = "VALIDATION_ERROR";

  constructor(message = "Invalid input") {
    super(message);
    this.name = "ValidationError";
  }
}
