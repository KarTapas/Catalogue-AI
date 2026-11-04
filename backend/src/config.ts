import { z } from "zod";

const featuredIdsSchema = z.string().default("").transform((value, context) => {
  if (value.trim() === "") {
    return [];
  }

  const ids: number[] = [];
  for (const rawId of value.split(",")) {
    const trimmedId = rawId.trim();
    if (!/^\d+$/.test(trimmedId)) {
      context.addIssue({
        code: "custom",
        message: "must be a comma-separated list of positive integers",
      });
      return z.NEVER;
    }

    const id = Number(trimmedId);
    if (!Number.isSafeInteger(id) || id < 1) {
      context.addIssue({
        code: "custom",
        message: "must be a comma-separated list of positive integers",
      });
      return z.NEVER;
    }

    ids.push(id);
  }

  return ids;
});

const environmentSchema = z.object({
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  FAKESTORE_BASE_URL: z
    .string()
    .url()
    .default("https://fakestoreapi.com"),
  FEATURED_IDS: featuredIdsSchema,
  SALES_INBOX: z.string().email().default("sales@example.test"),
  EMAIL_FROM: z.string().email(),
  EMAIL_PROVIDER: z.enum(["console", "smtp"]).default("console"),
  SMTP_HOST: z.string().min(1).default("mailpit"),
  SMTP_PORT: z.coerce.number().int().min(1).max(65535).default(1025),
  SMTP_USER: z.string().min(1).optional(),
  SMTP_PASS: z.string().min(1).optional(),
}).superRefine((environment, context) => {
  if (
    (environment.SMTP_USER === undefined) !==
    (environment.SMTP_PASS === undefined)
  ) {
    context.addIssue({
      code: "custom",
      path: ["SMTP_USER"],
      message: "SMTP_USER and SMTP_PASS must be configured together",
    });
  }
});

export type Config = {
  port: number;
  fakeStoreBaseUrl: string;
  featuredIds: number[];
  salesInbox: string;
  emailFrom: string;
  emailProvider: "console" | "smtp";
  smtpHost: string;
  smtpPort: number;
  smtpUser?: string;
  smtpPass?: string;
};

function getRuntimeEnvironment(): Record<string, string | undefined> {
  const runtime = globalThis as typeof globalThis & {
    process: { env: Record<string, string | undefined> };
  };
  return runtime.process.env;
}

export function parseConfig(
  environment: Record<string, string | undefined> = getRuntimeEnvironment(),
): Config {
  const result = environmentSchema.safeParse(environment);
  if (!result.success) {
    const details = result.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    throw new Error(`Invalid configuration: ${details}`);
  }

  return {
    port: result.data.PORT,
    fakeStoreBaseUrl: result.data.FAKESTORE_BASE_URL,
    featuredIds: result.data.FEATURED_IDS,
    salesInbox: result.data.SALES_INBOX,
    emailFrom: result.data.EMAIL_FROM,
    emailProvider: result.data.EMAIL_PROVIDER,
    smtpHost: result.data.SMTP_HOST,
    smtpPort: result.data.SMTP_PORT,
    ...(result.data.SMTP_USER === undefined
      ? {}
      : { smtpUser: result.data.SMTP_USER }),
    ...(result.data.SMTP_PASS === undefined
      ? {}
      : { smtpPass: result.data.SMTP_PASS }),
  };
}
