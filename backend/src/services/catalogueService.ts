import {
  NotFoundError,
  UpstreamUnavailableError,
  ValidationError,
} from "../domain/errors.js";
import type { ProductSource } from "../domain/ports.js";
import type { Product } from "../domain/product.js";

type CatalogueLogger = {
  warn(message: string): void;
};

type CatalogueServiceOptions = {
  productSource: ProductSource;
  featuredIds: number[];
  logger?: CatalogueLogger;
};

const FEATURED_LIMIT = 5;

const defaultLogger: CatalogueLogger = {
  warn: (message) => console.warn(message),
};

function compareByRating(left: Product, right: Product): number {
  return (
    right.rating.rate - left.rating.rate ||
    right.rating.count - left.rating.count ||
    left.id - right.id
  );
}

export class CatalogueService {
  private readonly productSource: ProductSource;
  private readonly featuredIds: number[];
  private readonly logger: CatalogueLogger;

  constructor({
    productSource,
    featuredIds,
    logger = defaultLogger,
  }: CatalogueServiceOptions) {
    this.productSource = productSource;
    this.featuredIds = [...featuredIds];
    this.logger = logger;
  }

  async getFeatured(): Promise<Product[]> {
    const featured: Product[] = [];
    const includedIds = new Set<number>();
    const attemptedIds = new Set<number>();

    for (const id of this.featuredIds) {
      if (featured.length === FEATURED_LIMIT) {
        break;
      }
      if (attemptedIds.has(id)) {
        continue;
      }
      attemptedIds.add(id);

      try {
        const product = await this.productSource.getById(id);
        if (!includedIds.has(product.id)) {
          featured.push(product);
          includedIds.add(product.id);
        }
      } catch (error) {
        if (!(error instanceof NotFoundError)) {
          throw error;
        }
        this.logger.warn(`Configured featured product ${id} was not found`);
      }
    }

    if (featured.length < FEATURED_LIMIT) {
      const allProducts = await this.productSource.listAll();
      const topRated = [...allProducts].sort(compareByRating);
      for (const product of topRated) {
        if (featured.length === FEATURED_LIMIT) {
          break;
        }
        if (includedIds.has(product.id)) {
          continue;
        }
        featured.push(product);
        includedIds.add(product.id);
      }
    }

    if (featured.length < FEATURED_LIMIT) {
      throw new UpstreamUnavailableError();
    }
    return featured;
  }

  listCategories(): Promise<string[]> {
    return this.productSource.listCategories();
  }

  async getCategoryProducts(
    name: string,
  ): Promise<{ category: string; topRated: Product[]; others: Product[] }> {
    const categories = await this.productSource.listCategories();
    const category = categories.find(
      (candidate) => candidate.toLowerCase() === name.toLowerCase(),
    );
    if (category === undefined) {
      throw new NotFoundError("Category not found");
    }

    const products = await this.productSource.listByCategory(category);
    const sortedProducts = [...products].sort(compareByRating);
    return {
      category,
      topRated: sortedProducts.slice(0, 3),
      others: sortedProducts.slice(3),
    };
  }

  async search(query: string): Promise<Product[]> {
    const trimmedQuery = query.trim();
    if (trimmedQuery.length < 2 || trimmedQuery.length > 100) {
      throw new ValidationError("Search query must be between 2 and 100 characters");
    }

    const terms = trimmedQuery.toLowerCase().split(/\s+/);
    const products = await this.productSource.listAll();
    const matches = products
      .filter((product) => {
        const searchableText =
          `${product.title} ${product.description} ${product.category}`.toLowerCase();
        return terms.every((term) => searchableText.includes(term));
      })
      .map((product) => ({
        product,
        titleMatch: terms.every((term) =>
          product.title.toLowerCase().includes(term),
        ),
      }))
      .sort(
        (left, right) =>
          Number(right.titleMatch) - Number(left.titleMatch) ||
          right.product.rating.rate - left.product.rating.rate ||
          left.product.id - right.product.id,
      );

    return matches.map(({ product }) => product);
  }

  getProduct(id: number): Promise<Product> {
    return this.productSource.getById(id);
  }
}
