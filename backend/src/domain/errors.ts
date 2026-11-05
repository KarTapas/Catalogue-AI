export class NotFoundError extends Error {
  readonly code = "NOT_FOUND" as const;

  constructor(message = "Product not found") {
    super(message);
    this.name = "NotFoundError";
  }
}

export class UpstreamUnavailableError extends Error {
  readonly code = "UPSTREAM_UNAVAILABLE" as const;

  constructor(message = "Product source unavailable") {
    super(message);
    this.name = "UpstreamUnavailableError";
  }
}

export class ValidationError extends Error {
  readonly code = "VALIDATION_ERROR" as const;

  constructor(message = "Invalid input") {
    super(message);
    this.name = "ValidationError";
  }
}
