import { describe, expect, it } from "vitest";
import { parseConfig } from "../src/config.js";

describe("parseConfig", () => {
  it("parses environment values into a typed configuration", () => {
    expect(
      parseConfig({
        PORT: "3100",
        FAKESTORE_BASE_URL: "https://products.example.test",
        FEATURED_IDS: "3, 1, 42",
        SALES_INBOX: "sales@example.test",
        EMAIL_FROM: "catalogue@example.test",
        EMAIL_PROVIDER: "smtp",
        SMTP_HOST: "localhost",
        SMTP_PORT: "2525",
        SMTP_USER: "smtp-user",
        SMTP_PASS: "smtp-password",
      }),
    ).toEqual({
      port: 3100,
      fakeStoreBaseUrl: "https://products.example.test",
      featuredIds: [3, 1, 42],
      salesInbox: "sales@example.test",
      emailFrom: "catalogue@example.test",
      emailProvider: "smtp",
      smtpHost: "localhost",
      smtpPort: 2525,
      smtpUser: "smtp-user",
      smtpPass: "smtp-password",
    });
  });

  it("uses safe defaults and treats unset or empty featured ids as empty", () => {
    const defaults = parseConfig({ EMAIL_FROM: "catalogue@example.test" });

    expect(defaults).toEqual({
      port: 3000,
      fakeStoreBaseUrl: "https://fakestoreapi.com",
      featuredIds: [],
      salesInbox: "sales@example.test",
      emailFrom: "catalogue@example.test",
      emailProvider: "console",
      smtpHost: "mailpit",
      smtpPort: 1025,
    });
    expect(
      parseConfig({
        EMAIL_FROM: "catalogue@example.test",
        FEATURED_IDS: "",
      }).featuredIds,
    ).toEqual([]);
    expect(defaults.smtpUser).toBeUndefined();
    expect(defaults.smtpPass).toBeUndefined();
  });

  it("reports invalid featured ids clearly", () => {
    expect(
      () =>
        parseConfig({
          EMAIL_FROM: "catalogue@example.test",
          FEATURED_IDS: "abc",
        }),
    ).toThrow(/FEATURED_IDS/);
  });

  it("requires an email from address and a complete optional SMTP credential pair", () => {
    expect(() => parseConfig({})).toThrow(/EMAIL_FROM/);
    expect(
      () =>
        parseConfig({
          EMAIL_FROM: "catalogue@example.test",
          SMTP_USER: "smtp-user",
        }),
    ).toThrow(/SMTP_USER/);
  });

  it("rejects unsupported email providers", () => {
    expect(() =>
      parseConfig({
        EMAIL_FROM: "catalogue@example.test",
        EMAIL_PROVIDER: "mailpit",
      }),
    ).toThrow(/EMAIL_PROVIDER/);
  });
});
