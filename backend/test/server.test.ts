import { describe, expect, it } from "vitest";
import { buildApp } from "../src/app.js";

describe("GET /api/v1/health", () => {
  it("returns an ok status", async () => {
    const app = buildApp();

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
