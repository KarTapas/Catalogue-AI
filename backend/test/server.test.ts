import { describe, expect, it } from "vitest";
import { buildApp } from "../src/app.js";
import { NotFoundError } from "../src/domain/errors.js";
import type { ProductSource } from "../src/domain/ports.js";
import { CatalogueService } from "../src/services/catalogueService.js";

describe("GET /api/v1/health", () => {
  it("returns an ok status", async () => {
    const productSource: ProductSource = {
      listAll: () => Promise.resolve([]),
      getById: () => Promise.reject(new NotFoundError()),
      listCategories: () => Promise.resolve([]),
      listByCategory: () => Promise.resolve([]),
    };
    const catalogueService = new CatalogueService({
      productSource,
      featuredIds: [],
    });
    const app = buildApp({ catalogueService, logger: false });

    try {
      const response = await app.inject({
        method: "GET",
        url: "/api/v1/health",
      });

      expect(response.statusCode).toBe(200);
      expect(response.json()).toEqual({ status: "ok" });
    } finally {
      await app.close();
    }
  });
});
