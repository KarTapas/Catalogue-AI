import { describe, expect, it } from "vitest";
import { CatalogueService } from "../src/services/catalogueService.js";
import {
  NotFoundError,
  UpstreamUnavailableError,
  ValidationError,
} from "../src/domain/errors.js";
import type { ProductSource } from "../src/domain/ports.js";
import type { Product } from "../src/domain/product.js";
import { catalogueProducts } from "./fixtures/catalogueProducts.js";

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

function makeService(
  featuredIds: number[] = [],
  logger?: { warn(message: string): void },
): CatalogueService {
  return new CatalogueService({
    productSource: new InMemoryProductSource(catalogueProducts),
    featuredIds,
    logger,
  });
}

describe("CatalogueService", () => {
  it("returns the top five rated products when featured ids are empty", async () => {
    const products = await makeService().getFeatured();

    expect(products.map((product) => product.id)).toEqual([9, 5, 2, 1, 3]);
    expect(products).toHaveLength(5);
  });

  it("preserves configured featured id order", async () => {
    const products = await makeService([8, 3, 1, 7, 5]).getFeatured();

    expect(products.map((product) => product.id)).toEqual([8, 3, 1, 7, 5]);
    expect(products).toHaveLength(5);
  });

  it("skips missing configured ids, warns, and tops up by rating", async () => {
    const warnings: string[] = [];
    const products = await makeService([999, 3, 1, 999], {
      warn: (message) => warnings.push(message),
    }).getFeatured();

    expect(products.map((product) => product.id)).toEqual([3, 1, 9, 5, 2]);
    expect(products).toHaveLength(5);
    expect(warnings).toEqual([
      "Configured featured product 999 was not found",
    ]);
  });

  it("does not return duplicate featured products", async () => {
    const products = await makeService([1, 1, 2, 2, 3]).getFeatured();
    const productIds = products.map((product) => product.id);

    expect(productIds).toEqual([1, 2, 3, 9, 5]);
    expect(productIds).toHaveLength(5);
    expect(new Set(productIds).size).toBe(5);
  });

  it("fails when fewer than five unique products are available", async () => {
    const service = new CatalogueService({
      productSource: new InMemoryProductSource(catalogueProducts.slice(0, 4)),
      featuredIds: [],
    });

    await expect(service.getFeatured()).rejects.toBeInstanceOf(
      UpstreamUnavailableError,
    );
  });

  it("passes categories through from the source", async () => {
    await expect(makeService().listCategories()).resolves.toEqual([
      "kitchen & dining",
      "garden",
      "electronics",
      "men's clothing",
    ]);
  });

  it("splits a case-insensitive category by rating, count, and id", async () => {
    const result = await makeService().getCategoryProducts("KITCHEN & DINING");

    expect(result.category).toBe("kitchen & dining");
    expect(result.topRated.map((product) => product.id)).toEqual([2, 1, 3]);
    expect(result.others.map((product) => product.id)).toEqual([4]);
  });

  it("returns no others when a category has fewer than three products", async () => {
    const result = await makeService().getCategoryProducts("garden");

    expect(result.topRated.map((product) => product.id)).toEqual([5, 6]);
    expect(result.others).toEqual([]);
  });

  it("supports category names containing an apostrophe", async () => {
    const result = await makeService().getCategoryProducts("MEN'S CLOTHING");

    expect(result.category).toBe("men's clothing");
    expect(result.topRated.map((product) => product.id)).toEqual([10]);
    expect(result.others).toEqual([]);
  });

  it("throws NotFoundError for unknown categories", async () => {
    await expect(
      makeService().getCategoryProducts("toys"),
    ).rejects.toBeInstanceOf(NotFoundError);
  });

  it("passes product lookups through and preserves NotFoundError", async () => {
    const service = makeService();

    await expect(service.getProduct(4)).resolves.toEqual(catalogueProducts[3]);
    await expect(service.getProduct(999)).rejects.toBeInstanceOf(NotFoundError);
  });

  it("searches case-insensitively across titles, descriptions, and categories", async () => {
    const service = makeService();

    expect((await service.search("WIRELESS")).map((product) => product.id)).toEqual([
      7, 8,
    ]);
    expect((await service.search("battery")).map((product) => product.id)).toEqual([
      7,
    ]);
    expect((await service.search(" GARDEN ")).map((product) => product.id)).toEqual([
      5, 6,
    ]);
  });

  it("requires every trimmed whitespace-separated query term to match", async () => {
    const service = makeService();

    expect(
      (await service.search("  wireless   mouse  ")).map((product) => product.id),
    ).toEqual([8]);
    expect(
      (await service.search("wireless cobalt")).map((product) => product.id),
    ).toEqual([8]);
  });

  it("ranks title matches before rating and id", async () => {
    const products = await makeService().search("amber");

    expect(products.map((product) => product.id)).toEqual([1, 11, 9]);
  });

  it("sorts rating ties by lower id in search results", async () => {
    const products = await makeService().search("kitchen");

    expect(products.map((product) => product.id)).toEqual([1, 2, 3, 4]);
  });

  it("rejects too-short and too-long search queries", async () => {
    const service = makeService();

    await expect(service.search(" a ")).rejects.toBeInstanceOf(ValidationError);
    await expect(
      service.search("x".repeat(101)),
    ).rejects.toBeInstanceOf(ValidationError);
  });

  it("returns an empty array when there are no search matches", async () => {
    await expect(makeService().search("unicorn")).resolves.toEqual([]);
  });
});
