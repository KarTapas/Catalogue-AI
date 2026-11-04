import type { Product } from "./product.js";

export interface ProductSource {
  listAll(): Promise<Product[]>;
  getById(id: number): Promise<Product>;
  listCategories(): Promise<string[]>;
  listByCategory(name: string): Promise<Product[]>;
}
