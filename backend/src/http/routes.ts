import type { FastifyInstance } from "fastify";
import { z } from "zod";
import type { Product } from "../domain/product.js";
import type { CatalogueService } from "../services/catalogueService.js";

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
}
