import {
  afterEach,
  beforeEach,
  describe,
  expect,
  it,
} from "vitest";
import { buildApp } from "../src/app.js";
import {
  NotFoundError,
  UpstreamUnavailableError,
} from "../src/domain/errors.js";
import type { ProductSource } from "../src/domain/ports.js";
import type { Product } from "../src/domain/product.js";
import { CatalogueService } from "../src/services/catalogueService.js";
import { EnquiryService } from "../src/services/enquiryService.js";
import { catalogueProducts } from "./fixtures/catalogueProducts.js";

type ErrorResponse = {
  error: {
    code: string;
    message: string;
    details?: { field: string; message: string }[];
  };
};

class InMemoryProductSource implements ProductSource {
  constructor(private readonly products: Product[]) {}

  listAll(): Promise<Product[]> {
    return Promise.resolve([...this.products]);
  }

  getById(id: number): Promise<Product> {
    const product = this.products.find((candidate) => candidate.id === id);
    if (product === undefined) {
      return Promise.reject(new NotFoundError());
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

function makeApp(
  productSource: ProductSource = new InMemoryProductSource(catalogueProducts),
  featuredIds = [1, 2, 3, 4, 5],
): ReturnType<typeof buildApp> {
  return buildApp({
    catalogueService: new CatalogueService({ productSource, featuredIds }),
    enquiryService: new EnquiryService({
      productSource,
      emailSender: { send: () => Promise.resolve() },
      salesInbox: "sales@example.test",
      emailFrom: "catalogue@example.test",
    }),
    logger: false,
  });
}

describe("HTTP routes", () => {
  let app: ReturnType<typeof buildApp>;

  beforeEach(() => {
    app = makeApp();
  });

  afterEach(async () => {
    await app.close();
  });

  it("returns the health response", async () => {
    const response = await app.inject({ method: "GET", url: "/api/v1/health" });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toStrictEqual({ status: "ok" });
  });

  it("returns five featured products with the exact Product shape", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/api/v1/products/featured",
    });

    expect(response.statusCode).toBe(200);
    expect(response.json<Product[]>()).toStrictEqual(catalogueProducts.slice(0, 5));
  });

  it("returns categories", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/api/v1/categories",
    });

    expect(response.statusCode).toBe(200);
    expect(response.json<string[]>()).toStrictEqual([
      "kitchen & dining",
      "garden",
      "electronics",
      "men's clothing",
    ]);
  });

  it("returns the category split for an encoded apostrophe and space", async () => {
    const categoryName = encodeURIComponent("men's clothing");
    const response = await app.inject({
      method: "GET",
      url: `/api/v1/categories/${categoryName}/products`,
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toStrictEqual({
      category: "men's clothing",
      topRated: [catalogueProducts[9]],
      others: [],
    });
  });

  it("returns a field-specific validation error for an overlong category", async () => {
    const response = await app.inject({
      method: "GET",
      url: `/api/v1/categories/${"a".repeat(61)}/products`,
    });

    expect(response.statusCode).toBe(400);
    expect(response.json<ErrorResponse>()).toStrictEqual({
      error: {
        code: "VALIDATION_ERROR",
        message: "Invalid request",
        details: [{ field: "name", message: "Invalid value" }],
      },
    });
  });

  it("returns NOT_FOUND for an unknown category", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/api/v1/categories/toys/products",
    });

    expect(response.statusCode).toBe(404);
    expect(response.json<ErrorResponse>()).toStrictEqual({
      error: { code: "NOT_FOUND", message: "Category not found" },
    });
  });

  it("returns matching products for a valid search", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/api/v1/products/search?q=wireless",
    });

    expect(response.statusCode).toBe(200);
    expect(response.json<Product[]>()).toStrictEqual(catalogueProducts.slice(6, 8));
  });

  it("returns an empty array when a search has no matches", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/api/v1/products/search?q=unicorn",
    });

    expect(response.statusCode).toBe(200);
    expect(response.json<Product[]>()).toStrictEqual([]);
  });

  it("returns a field-specific validation error when q is missing", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/api/v1/products/search",
    });

    expect(response.statusCode).toBe(400);
    expect(response.json<ErrorResponse>()).toStrictEqual({
      error: {
        code: "VALIDATION_ERROR",
        message: "Invalid request",
        details: [{ field: "q", message: "Invalid value" }],
      },
    });
  });

  it.each([
    ["one character", "/api/v1/products/search?q=a"],
    ["overlong", `/api/v1/products/search?q=${"a".repeat(101)}`],
  ])("returns a field-specific validation error for %s queries", async (_label, url) => {
    const response = await app.inject({ method: "GET", url });

    expect(response.statusCode).toBe(400);
    expect(response.json<ErrorResponse>()).toStrictEqual({
      error: {
        code: "VALIDATION_ERROR",
        message: "Invalid request",
        details: [{ field: "q", message: "Invalid value" }],
      },
    });
  });

  it.each(["abc", "0", "-1"])(
    "rejects invalid product id %s",
    async (id) => {
      const response = await app.inject({
        method: "GET",
        url: `/api/v1/products/${id}`,
      });

      expect(response.statusCode).toBe(400);
      expect(response.json<ErrorResponse>()).toStrictEqual({
        error: {
          code: "VALIDATION_ERROR",
          message: "Invalid request",
          details: [{ field: "id", message: "Invalid value" }],
        },
      });
    },
  );

  it("returns one product with only the documented fields", async () => {
    const product = catalogueProducts[0];
    if (product === undefined) {
      throw new Error("Missing test fixture product");
    }
    const productWithExtras = Object.assign(
      {
        ...product,
        price: { ...product.price, internal: "hidden" },
        rating: { ...product.rating, internal: "hidden" },
      },
      { internal: "hidden" },
    );
    const source = new InMemoryProductSource([
      productWithExtras,
      ...catalogueProducts.slice(1),
    ]);
    await app.close();
    app = makeApp(source);

    const response = await app.inject({
      method: "GET",
      url: "/api/v1/products/1",
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toStrictEqual(product);
  });

  it("returns NOT_FOUND for an unknown product id", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/api/v1/products/9999",
    });

    expect(response.statusCode).toBe(404);
    expect(response.json<ErrorResponse>()).toStrictEqual({
      error: { code: "NOT_FOUND", message: "Product not found" },
    });
  });

  it("does not capture featured or search routes as product ids", async () => {
    const featuredResponse = await app.inject({
      method: "GET",
      url: "/api/v1/products/featured",
    });
    const searchResponse = await app.inject({
      method: "GET",
      url: "/api/v1/products/search?q=wireless",
    });

    expect(featuredResponse.statusCode).toBe(200);
    expect(featuredResponse.json<Product[]>()).toHaveLength(5);
    expect(searchResponse.statusCode).toBe(200);
    expect(searchResponse.json<Product[]>()).toHaveLength(2);
  });

  it("maps upstream failures to 502 without internal details", async () => {
    const source = new InMemoryProductSource(catalogueProducts);
    source.listAll = () => Promise.reject(new UpstreamUnavailableError());
    await app.close();
    app = makeApp(source, []);

    const response = await app.inject({
      method: "GET",
      url: "/api/v1/products/featured",
    });

    expect(response.statusCode).toBe(502);
    expect(response.json<ErrorResponse>()).toStrictEqual({
      error: {
        code: "UPSTREAM_UNAVAILABLE",
        message: "Product source unavailable",
      },
    });
  });

  it("returns a generic 500 response without the internal error or stack", async () => {
    const source = new InMemoryProductSource(catalogueProducts);
    source.listAll = () =>
      Promise.reject(new Error("sensitive internal detail"));
    await app.close();
    app = makeApp(source, []);

    const response = await app.inject({
      method: "GET",
      url: "/api/v1/products/featured",
    });

    expect(response.statusCode).toBe(500);
    expect(response.json<ErrorResponse>()).toStrictEqual({
      error: { code: "INTERNAL", message: "Internal server error" },
    });
  });

  it("returns unknown routes in the standard NOT_FOUND format", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/api/v1/unknown",
    });

    expect(response.statusCode).toBe(404);
    expect(response.json<ErrorResponse>()).toStrictEqual({
      error: { code: "NOT_FOUND", message: "Route not found" },
    });
  });

  it("maps Fastify JSON parse errors to a validation response", async () => {
    app.post("/parse-test", (request) => request.body);
    const response = await app.inject({
      method: "POST",
      url: "/parse-test",
      headers: { "content-type": "application/json" },
      payload: "{",
    });

    expect(response.statusCode).toBe(400);
    expect(response.json<ErrorResponse>()).toStrictEqual({
      error: {
        code: "VALIDATION_ERROR",
        message: "Invalid request",
        details: [{ field: "request", message: "Invalid request" }],
      },
    });
  });
});
