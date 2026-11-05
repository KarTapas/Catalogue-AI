import type { Product } from "./product.js";

export interface ProductSource {
  listAll(): Promise<Product[]>;
  getById(id: number): Promise<Product>;
  listCategories(): Promise<string[]>;
  listByCategory(name: string): Promise<Product[]>;
}

export type EmailMessage = {
  to: string;
  from: string;
  replyTo?: string;
  subject: string;
  text: string;
  html: string;
};

export interface EmailSender {
  send(message: EmailMessage): Promise<void>;
}
