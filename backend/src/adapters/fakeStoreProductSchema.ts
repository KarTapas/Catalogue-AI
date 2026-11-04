import { z } from "zod";

export const fakeStoreProductSchema = z.object({
  id: z.number().int().positive(),
  title: z.string().min(1),
  description: z.string(),
  category: z.string().min(1),
  price: z.number().finite().nonnegative(),
  image: z.string().url(),
  rating: z.object({
    rate: z.number().finite().nonnegative(),
    count: z.number().int().nonnegative(),
  }),
});

export const fakeStoreCategoriesSchema = z.array(z.string().min(1));

export type FakeStoreProduct = z.infer<typeof fakeStoreProductSchema>;
