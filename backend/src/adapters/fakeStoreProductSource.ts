import {
  NotFoundError,
  UpstreamUnavailableError,
  ValidationError,
} from "../domain/errors.js";
import type { ProductSource } from "../domain/ports.js";
import type { Product } from "../domain/product.js";
import {
  fakeStoreCategoriesSchema,
  fakeStoreProductSchema,
  type FakeStoreProduct,
} from "./fakeStoreProductSchema.js";

type FakeStoreProductSourceOptions = {
  baseUrl: string;
  fetchFn?: typeof fetch;
  timeoutMs?: number;
};

function isUnknownArray(value: unknown): value is unknown[] {
  return Array.isArray(value);
}

function mapProduct(product: FakeStoreProduct): Product {
  return {
    id: product.id,
    title: product.title,
    description: product.description,
    category: product.category,
    price: {
      amount: product.price.toFixed(2),
      currency: "USD",
    },
    imageUrl: product.image,
    rating: {
      rate: product.rating.rate,
      count: product.rating.count,
    },
  };
}

export class FakeStoreProductSource implements ProductSource {
  private readonly baseUrl: URL;
  private readonly fetchFn: typeof fetch;
  private readonly timeoutMs: number;

  constructor({
    baseUrl,
    fetchFn = fetch,
    timeoutMs = 5_000,
  }: FakeStoreProductSourceOptions) {
    let parsedBaseUrl: URL;
    try {
      parsedBaseUrl = new URL(baseUrl);
    } catch {
      throw new ValidationError("Invalid product source base URL");
    }

    if (
      (parsedBaseUrl.protocol !== "http:" &&
        parsedBaseUrl.protocol !== "https:") ||
      parsedBaseUrl.search.length > 0 ||
      parsedBaseUrl.hash.length > 0
    ) {
      throw new ValidationError("Invalid product source base URL");
    }

    if (!Number.isFinite(timeoutMs) || timeoutMs <= 0) {
      throw new ValidationError("Invalid product source timeout");
    }

    if (!parsedBaseUrl.pathname.endsWith("/")) {
      parsedBaseUrl.pathname += "/";
    }

    this.baseUrl = parsedBaseUrl;
    this.fetchFn = fetchFn;
    this.timeoutMs = timeoutMs;
  }

  async listAll(): Promise<Product[]> {
    return this.fetchProducts("products");
  }

  async getById(id: number): Promise<Product> {
    if (!Number.isSafeInteger(id) || id < 1) {
      throw new ValidationError();
    }

    const payload = await this.fetchJson(`products/${id}`);
    if (payload === null) {
      throw new NotFoundError();
    }

    const result = fakeStoreProductSchema.safeParse(payload);
    if (!result.success) {
      throw new UpstreamUnavailableError();
    }

    return mapProduct(result.data);
  }

  async listCategories(): Promise<string[]> {
    const payload = await this.fetchJson("products/categories");
    const result = fakeStoreCategoriesSchema.safeParse(payload);
    if (!result.success) {
      throw new UpstreamUnavailableError();
    }

    return result.data;
  }

  async listByCategory(name: string): Promise<Product[]> {
    if (name.trim().length === 0) {
      throw new ValidationError();
    }

    return this.fetchProducts(
      `products/category/${encodeURIComponent(name)}`,
    );
  }

  private async fetchProducts(path: string): Promise<Product[]> {
    const payload = await this.fetchJson(path);
    if (!isUnknownArray(payload)) {
      throw new UpstreamUnavailableError();
    }

    const products: Product[] = [];
    for (const item of payload) {
      const result = fakeStoreProductSchema.safeParse(item);
      if (result.success) {
        products.push(mapProduct(result.data));
      }
    }

    return products;
  }

  private async fetchJson(path: string): Promise<unknown> {
    const controller = new AbortController();
    const timeoutId = setTimeout(
      () => controller.abort(),
      this.timeoutMs,
    );

    try {
      let response: Response;
      try {
        response = await this.fetchFn(new URL(path, this.baseUrl), {
          signal: controller.signal,
        });
      } catch {
        throw new UpstreamUnavailableError();
      }

      if (!response.ok) {
        throw new UpstreamUnavailableError();
      }

      let body: string;
      try {
        body = await response.text();
      } catch {
        throw new UpstreamUnavailableError();
      }

      if (body.trim().length === 0) {
        return null;
      }

      try {
        const payload: unknown = JSON.parse(body);
        return payload;
      } catch {
        throw new UpstreamUnavailableError();
      }
    } finally {
      clearTimeout(timeoutId);
    }
  }
}
