import { describe, expect, it } from "vitest";
import { parseConfig } from "../src/config.js";

describe("parseConfig", () => {
  it("parses environment values into a typed configuration", () => {
    expect(
      parseConfig({
        PORT: "3100",
        FAKESTORE_BASE_URL: "https://products.example.test",
        FEATURED_IDS: "3, 1, 42",
        SALES_INBOX: "sales@example.com",
        EMAIL_PROVIDER: "smtp",
        SMTP_HOST: "localhost",
        SMTP_PORT: "2525",
      }),
    ).toEqual({
      port: 3100,
      fakeStoreBaseUrl: "https://products.example.test",
      featuredIds: [3, 1, 42],
      salesInbox: "sales@example.com",
      emailProvider: "smtp",
      smtpHost: "localhost",
      smtpPort: 2525,
    });
  });

  it("uses safe defaults and treats unset or empty featured ids as empty", () => {
    const defaults = parseConfig({});

    expect(defaults).toEqual({
      port: 3000,
      fakeStoreBaseUrl: "https://fakestoreapi.com",
      featuredIds: [],
      salesInbox: "sales@example.com",
      emailProvider: "mailpit",
      smtpHost: "mailpit",
      smtpPort: 1025,
    });
    expect(parseConfig({ FEATURED_IDS: "" }).featuredIds).toEqual([]);
  });

  it("reports invalid featured ids clearly", () => {
    expect(() => parseConfig({ FEATURED_IDS: "abc" })).toThrow(
      /FEATURED_IDS/,
    );
  });
});
