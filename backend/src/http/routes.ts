import type { FastifyInstance } from "fastify";
import { z } from "zod";
import type { Enquiry } from "../domain/enquiry.js";
import { ValidationError } from "../domain/errors.js";
import type { Product } from "../domain/product.js";
import type { CatalogueService } from "../services/catalogueService.js";
import type { EnquiryService } from "../services/enquiryService.js";

const productIdParamsSchema = z.object({
  id: z
    .string()
    .regex(/^\d+$/)
    .transform(Number)
    .pipe(z.number().int().positive()),
});

const categoryParamsSchema = z.object({
  name: z.string().min(1).max(60),
});

const searchQuerySchema = z.object({
  q: z.string().trim().min(2).max(100),
});

const controlCharacters = /[\u0000-\u001F\u007F-\u009F]/;
const controlCharactersExceptNewlines =
  /[\u0000-\u0009\u000B\u000C\u000E-\u001F\u007F-\u009F]/;

const enquiryBodySchema = z.object({
  productId: z.number().int().positive(),
  name: z
    .string()
    .refine((value) => !controlCharacters.test(value))
    .trim()
    .min(1)
    .max(100),
  email: z.string().email().max(254),
  phone: z
    .string()
    .max(30)
    .regex(/^[0-9+() \-]*$/)
    .optional(),
  message: z
    .string()
    .refine((value) => !controlCharactersExceptNewlines.test(value))
    .trim()
    .min(1)
    .max(2000),
});

export type EnquiryRateLimitOptions = {
  max: number;
  timeWindowMs: number;
};

function parseInput<T>(schema: z.ZodType<T>, input: unknown): T {
  const result = schema.safeParse(input);
  if (!result.success) {
    throw result.error;
  }
  return result.data;
}

function serializeProduct(product: Product): Product {
  return {
    id: product.id,
    title: product.title,
    description: product.description,
    category: product.category,
    price: {
      amount: product.price.amount,
      currency: product.price.currency,
    },
    imageUrl: product.imageUrl,
    rating: {
      rate: product.rating.rate,
      count: product.rating.count,
    },
  };
}

export function registerRoutes(
  app: FastifyInstance,
  catalogueService: CatalogueService,
  enquiryService: EnquiryService,
  enquiryRateLimit: EnquiryRateLimitOptions,
): void {
  app.get("/api/v1/health", () => ({ status: "ok" }));

  app.get("/api/v1/products/featured", async () => {
    const products = await catalogueService.getFeatured();
    return products.map(serializeProduct);
  });

  app.get("/api/v1/categories", async () => {
    return catalogueService.listCategories();
  });

  app.get("/api/v1/categories/:name/products", async (request) => {
    const { name } = parseInput(categoryParamsSchema, request.params);
    const result = await catalogueService.getCategoryProducts(name);
    return {
      category: result.category,
      topRated: result.topRated.map(serializeProduct),
      others: result.others.map(serializeProduct),
    };
  });

  app.get("/api/v1/products/search", async (request) => {
    const { q } = parseInput(searchQuerySchema, request.query);
    const products = await catalogueService.search(q);
    return products.map(serializeProduct);
  });

  app.get("/api/v1/products/:id", async (request) => {
    const { id } = parseInput(productIdParamsSchema, request.params);
    const product = await catalogueService.getProduct(id);
    return serializeProduct(product);
  });

  app.post(
    "/api/v1/enquiries",
    {
      bodyLimit: 10 * 1024,
      config: {
        rateLimit: {
          max: enquiryRateLimit.max,
          timeWindow: enquiryRateLimit.timeWindowMs,
        },
      },
      onRequest: (request, _reply, done) => {
        const contentType = request.headers["content-type"]
          ?.split(";")[0]
          ?.trim()
          .toLowerCase();
        if (contentType !== "application/json") {
          done(
            new ValidationError("Content-Type must be application/json"),
          );
          return;
        }
        done();
      },
    },
    async (request, reply) => {
      const enquiry = parseInput<Enquiry>(enquiryBodySchema, request.body);
      const result = await enquiryService.submit(enquiry);
      return reply.code(202).send(result);
    },
  );
}
