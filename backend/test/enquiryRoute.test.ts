import type { FastifyInstance } from "fastify";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { buildApp } from "../src/app.js";
import { CatalogueService } from "../src/services/catalogueService.js";
import { EnquiryService } from "../src/services/enquiryService.js";
import { NotFoundError } from "../src/domain/errors.js";
import type { Enquiry } from "../src/domain/enquiry.js";
import type {
  EmailMessage,
  EmailSender,
  ProductSource,
} from "../src/domain/ports.js";
import type { Product } from "../src/domain/product.js";
import { catalogueProducts } from "./fixtures/catalogueProducts.js";

type ApiError = {
  error: {
    code: string;
    message: string;
    details?: { field: string; message: string }[];
  };
};

class FixtureProductSource implements ProductSource {
  constructor(private readonly products: Product[]) {}

  listAll(): Promise<Product[]> {
    return Promise.resolve(this.products);
  }

  getById(id: number): Promise<Product> {
    const product = this.products.find((candidate) => candidate.id === id);
    if (product === undefined) {
      return Promise.reject(new NotFoundError("Product not found"));
    }
    return Promise.resolve(product);
  }

  listCategories(): Promise<string[]> {
    return Promise.resolve([
      ...new Set(this.products.map((product) => product.category)),
    ]);
  }

  listByCategory(name: string): Promise<Product[]> {
    return Promise.resolve(
      this.products.filter((product) => product.category === name),
    );
  }
}

class RecordingEmailSender implements EmailSender {
  readonly messages: EmailMessage[] = [];
  failure: Error | undefined;

  send(message: EmailMessage): Promise<void> {
    this.messages.push(message);
    return this.failure === undefined
      ? Promise.resolve()
      : Promise.reject(this.failure);
  }
}

const validEnquiry: Enquiry = {
  productId: 1,
  name: "Ada Lovelace",
  email: "ada@example.test",
  phone: "+1 (555) 010-1234",
  message: "I have a question.",
};

let app: FastifyInstance | undefined;
let emailSender: RecordingEmailSender;

function currentApp(): FastifyInstance {
  if (app === undefined) {
    throw new Error("App was not initialized");
  }
  return app;
}

function createApp(
  productSource: ProductSource,
  sender: RecordingEmailSender,
  enquiryRateLimit: { max: number; timeWindowMs: number } = {
    max: 5,
    timeWindowMs: 60_000,
  },
): FastifyInstance {
  return buildApp({
    catalogueService: new CatalogueService({
      productSource,
      featuredIds: [],
    }),
    enquiryService: new EnquiryService({
      productSource,
      emailSender: sender,
      salesInbox: "sales@example.test",
      emailFrom: "catalogue@example.test",
      logger: { info: () => undefined },
    }),
    logger: false,
    enquiryRateLimit,
  });
}

beforeEach(() => {
  emailSender = new RecordingEmailSender();
  app = createApp(new FixtureProductSource(catalogueProducts), emailSender);
});

afterEach(async () => {
  if (app !== undefined) {
    await app.close();
    app = undefined;
  }
});

describe("POST /api/v1/enquiries", () => {
  it("returns 202 and sends one email using configured addresses", async () => {
    const response = await currentApp().inject({
      method: "POST",
      url: "/api/v1/enquiries",
      payload: {
        ...validEnquiry,
        name: "  Ada Lovelace  ",
        message: "  I have a question.\nThank you.  ",
      },
    });

    expect(response.statusCode).toBe(202);
    expect(response.json<{ id: string }>().id).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
    );
    expect(emailSender.messages).toHaveLength(1);
    expect(emailSender.messages[0]).toMatchObject({
      to: "sales@example.test",
      from: "catalogue@example.test",
      replyTo: "ada@example.test",
      subject: "New enquiry: Amber Kettle (#1)",
    });
    expect(emailSender.messages[0]?.text).toContain("Name: Ada Lovelace");
    expect(emailSender.messages[0]?.text).toContain(
      "Message: I have a question.\nThank you.",
    );
  });

  it("rejects missing required fields with field details", async () => {
    const response = await currentApp().inject({
      method: "POST",
      url: "/api/v1/enquiries",
      payload: { productId: 1 },
    });

    expect(response.statusCode).toBe(400);
    const error = response.json<ApiError>().error;
    expect(error.code).toBe("VALIDATION_ERROR");
    expect(error.details?.map((detail) => detail.field)).toEqual(
      expect.arrayContaining(["name", "email", "message"]),
    );
    expect(emailSender.messages).toHaveLength(0);
  });

  it.each([
    ["bad email", { email: "not-an-email" }, "email"],
    [
      "email header injection",
      { email: "ada@example.test\r\nBcc: attacker@example.com" },
      "email",
    ],
    ["name header injection", { name: "Ada\r\nBcc: attacker@example.com" }, "name"],
    ["over-long name", { name: "A".repeat(101) }, "name"],
    ["over-long message", { message: "M".repeat(2001) }, "message"],
    ["empty message", { message: "   " }, "message"],
    ["message control character", { message: "Hello\u0000world" }, "message"],
    ["bad phone", { phone: "555-ABC" }, "phone"],
    ["over-long phone", { phone: "1".repeat(31) }, "phone"],
  ])("rejects %s with validation details", async (_label, fields, field) => {
    const response = await currentApp().inject({
      method: "POST",
      url: "/api/v1/enquiries",
      payload: { ...validEnquiry, ...fields },
    });

    expect(response.statusCode).toBe(400);
    const error = response.json<ApiError>().error;
    expect(error.code).toBe("VALIDATION_ERROR");
    expect(error.details?.map((detail) => detail.field)).toContain(field);
    expect(emailSender.messages).toHaveLength(0);
  });

  it.each([0, "abc"])("rejects invalid productId %s", async (productId) => {
    const response = await currentApp().inject({
      method: "POST",
      url: "/api/v1/enquiries",
      payload: { ...validEnquiry, productId },
    });

    expect(response.statusCode).toBe(400);
    const error = response.json<ApiError>().error;
    expect(error.code).toBe("VALIDATION_ERROR");
    expect(error.details?.map((detail) => detail.field)).toContain("productId");
    expect(emailSender.messages).toHaveLength(0);
  });

  it("rejects non-JSON and oversized request bodies", async () => {
    const nonJson = await currentApp().inject({
      method: "POST",
      url: "/api/v1/enquiries",
      headers: { "content-type": "text/plain" },
      payload: JSON.stringify(validEnquiry),
    });
    expect(nonJson.statusCode).toBe(400);
    expect(nonJson.json<ApiError>().error.code).toBe("VALIDATION_ERROR");

    const oversized = await currentApp().inject({
      method: "POST",
      url: "/api/v1/enquiries",
      payload: {
        ...validEnquiry,
        message: "M".repeat(10 * 1024),
      },
    });
    expect(oversized.statusCode).toBe(400);
    expect(oversized.json<ApiError>().error.code).toBe("VALIDATION_ERROR");
    expect(emailSender.messages).toHaveLength(0);
  });

  it("returns 404 for an unknown product", async () => {
    const response = await currentApp().inject({
      method: "POST",
      url: "/api/v1/enquiries",
      payload: { ...validEnquiry, productId: 9999 },
    });

    expect(response.statusCode).toBe(404);
    expect(response.json<ApiError>().error.code).toBe("NOT_FOUND");
    expect(emailSender.messages).toHaveLength(0);
  });

  it("returns a generic 502 when email delivery fails", async () => {
    emailSender.failure = new Error("private SMTP transport detail");

    const response = await currentApp().inject({
      method: "POST",
      url: "/api/v1/enquiries",
      payload: validEnquiry,
    });

    expect(response.statusCode).toBe(502);
    const body = response.json<ApiError>();
    expect(body.error).toEqual({
      code: "UPSTREAM_UNAVAILABLE",
      message: "Could not send your enquiry. Please try again.",
    });
    expect(response.body).not.toContain("private SMTP transport detail");
  });

  it("returns the standard rate-limit error on the sixth request", async () => {
    let response: Awaited<ReturnType<FastifyInstance["inject"]>> | undefined;
    for (let index = 0; index < 6; index += 1) {
      response = await currentApp().inject({
        method: "POST",
        url: "/api/v1/enquiries",
        payload: validEnquiry,
      });
      expect(response.statusCode).toBe(index < 5 ? 202 : 429);
    }

    expect(response?.json<ApiError>().error).toEqual({
      code: "RATE_LIMITED",
      message: "Too many requests",
    });
    expect(emailSender.messages).toHaveLength(5);
    const health = await currentApp().inject({
      method: "GET",
      url: "/api/v1/health",
    });
    expect(health.statusCode).toBe(200);
  });
});
