import { describe, expect, it } from "vitest";
import { FakeStoreProductSource } from "../src/adapters/fakeStoreProductSource.js";
import {
  NotFoundError,
  UpstreamUnavailableError,
} from "../src/domain/errors.js";
import fakeStoreProducts from "./fixtures/fakeStoreProducts.json" with {
  type: "json",
};

const baseUrl = "https://fakestoreapi.test";

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body) ?? "", {
    status,
    headers: { "content-type": "application/json" },
  });
}

function makeSource(fetchFn: typeof fetch, timeoutMs = 5_000) {
  return new FakeStoreProductSource({ baseUrl, fetchFn, timeoutMs });
}

describe("FakeStoreProductSource", () => {
  it("maps product data and formats prices as decimal strings", async () => {
    const source = makeSource(() => Promise.resolve(jsonResponse(fakeStoreProducts)));

    const products = await source.listAll();

    expect(products).toHaveLength(4);
    expect(products[0]).toEqual({
      id: 1,
      title: "Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops",
      description: "A lightweight backpack designed for daily use and travel.",
      category: "men's clothing",
      price: { amount: "109.95", currency: "USD" },
      imageUrl: "https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg",
      rating: { rate: 3.9, count: 120 },
    });
    expect(products.map((product) => product.price.amount)).toEqual([
      "109.95",
      "22.30",
      "55.99",
      "168.00",
    ]);
  });

  it("gets and maps a product by id", async () => {
    const source = makeSource(() =>
      Promise.resolve(jsonResponse(fakeStoreProducts[2])),
    );

    const product = await source.getById(3);

    expect(product).toMatchObject({
      id: 3,
      title: "Mens Cotton Jacket",
      price: { amount: "55.99", currency: "USD" },
      imageUrl: "https://fakestoreapi.com/img/71li-ujtlUL._AC_UX679_.jpg",
    });
  });

  it.each(["", "null"])(
    "maps an empty or null body for an unknown id to NotFoundError",
    async (body) => {
      const source = makeSource(() =>
        Promise.resolve(new Response(body, { status: 200 })),
      );
      const request = source.getById(999);

      await expect(request).rejects.toBeInstanceOf(NotFoundError);
      await expect(request).rejects.toMatchObject({ code: "NOT_FOUND" });
    },
  );

  it("lists categories", async () => {
    const categories = ["men's clothing", "jewelery"];
    const source = makeSource(() => Promise.resolve(jsonResponse(categories)));

    await expect(source.listCategories()).resolves.toEqual(categories);
  });

  it("encodes category names and returns mapped products", async () => {
    const category = "men's clothing";
    let requestedUrl = "";
    const fetchFn: typeof fetch = (input) => {
      requestedUrl =
        typeof input === "string"
          ? input
          : input instanceof URL
            ? input.href
            : input.url;
      return Promise.resolve(jsonResponse([fakeStoreProducts[0]]));
    };
    const source = makeSource(fetchFn);

    const products = await source.listByCategory(category);

    expect(products).toHaveLength(1);
    expect(products[0]).toMatchObject({
      id: 1,
      category,
      price: { amount: "109.95", currency: "USD" },
    });
    expect(new URL(requestedUrl).pathname).toBe(
      `/products/category/${encodeURIComponent(category)}`,
    );
  });

  it("maps non-2xx responses to a generic upstream error", async () => {
    const source = makeSource(
      () =>
        Promise.resolve(
          new Response("private upstream details", { status: 503 }),
        ),
    );
    const request = source.listAll();

    await expect(request).rejects.toBeInstanceOf(UpstreamUnavailableError);
    await expect(request).rejects.toMatchObject({
      code: "UPSTREAM_UNAVAILABLE",
      message: "Product source unavailable",
    });
  });

  it("maps network failures to a generic upstream error", async () => {
    const source = makeSource(() =>
      Promise.reject(new Error("private network details")),
    );
    const request = source.listAll();

    await expect(request).rejects.toBeInstanceOf(UpstreamUnavailableError);
    await expect(request).rejects.toMatchObject({
      code: "UPSTREAM_UNAVAILABLE",
      message: "Product source unavailable",
    });
  });

  it("maps aborted requests to a generic upstream error", async () => {
    const fetchFn: typeof fetch = async (_input, init) =>
      new Promise<Response>((_resolve, reject) => {
        const signal = init?.signal;
        if (signal === undefined || signal === null) {
          reject(new Error("Fetch signal was not provided"));
          return;
        }

        signal.addEventListener(
          "abort",
          () => reject(new Error("Fetch was aborted")),
          { once: true },
        );
      });
    const source = makeSource(fetchFn, 1);
    const request = source.listAll();

    await expect(request).rejects.toBeInstanceOf(UpstreamUnavailableError);
    await expect(request).rejects.toMatchObject({
      code: "UPSTREAM_UNAVAILABLE",
      message: "Product source unavailable",
    });
  });

  it("skips malformed items in a product collection", async () => {
    const malformedProduct = { ...fakeStoreProducts[0], price: "109.95" };
    const source = makeSource(() =>
      Promise.resolve(
        jsonResponse([fakeStoreProducts[1], malformedProduct, null]),
      ),
    );

    const products = await source.listAll();

    expect(products).toHaveLength(1);
    expect(products[0]).toMatchObject({
      id: 2,
      title: "Mens Casual Premium Slim Fit T-Shirts",
      price: { amount: "22.30", currency: "USD" },
    });
  });
});
