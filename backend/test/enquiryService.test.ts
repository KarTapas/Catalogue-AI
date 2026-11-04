import { describe, expect, it } from "vitest";
import type { Enquiry } from "../src/domain/enquiry.js";
import { NotFoundError } from "../src/domain/errors.js";
import type {
  EmailMessage,
  EmailSender,
  ProductSource,
} from "../src/domain/ports.js";
import type { Product } from "../src/domain/product.js";
import { EnquiryService } from "../src/services/enquiryService.js";
import { catalogueProducts } from "./fixtures/catalogueProducts.js";

class FixtureProductSource implements ProductSource {
  constructor(private readonly products: Product[]) {}

  listAll(): Promise<Product[]> {
    return Promise.resolve(this.products);
  }

  getById(id: number): Promise<Product> {
    const product = this.products.find((candidate) => candidate.id === id);
    if (product === undefined) {
      return Promise.reject(new NotFoundError("Product not found"));
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

class RecordingEmailSender implements EmailSender {
  readonly messages: EmailMessage[] = [];
  failure: Error | undefined;

  send(message: EmailMessage): Promise<void> {
    this.messages.push(message);
    return this.failure === undefined
      ? Promise.resolve()
      : Promise.reject(this.failure);
  }
}

const enquiry: Enquiry = {
  productId: 1,
  name: "Ada Lovelace",
  email: "ada@example.test",
  phone: "+1 (555) 010-1234",
  message: "I have a question about the finish.",
};

function createService(products: Product[] = catalogueProducts) {
  const sender = new RecordingEmailSender();
  const logEntries: { enquiryId: string; productId: number }[] = [];
  const service = new EnquiryService({
    productSource: new FixtureProductSource(products),
    emailSender: sender,
    salesInbox: "sales@example.test",
    emailFrom: "catalogue@example.test",
    logger: {
      info: (entry) => logEntries.push(entry),
    },
  });

  return { service, sender, logEntries };
}

describe("EnquiryService", () => {
  it("sends a product enquiry using configured addresses and logs only IDs", async () => {
    const { service, sender, logEntries } = createService();

    const result = await service.submit(enquiry);

    expect(result.id).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
    );
    expect(sender.messages).toEqual([
      {
        to: "sales@example.test",
        from: "catalogue@example.test",
        replyTo: "ada@example.test",
        subject: "New enquiry: Amber Kettle (#1)",
        text: [
          "Product ID: 1",
          "Product: Amber Kettle",
          "Name: Ada Lovelace",
          "Email: ada@example.test",
          "Phone: +1 (555) 010-1234",
          "Message: I have a question about the finish.",
        ].join("\n"),
        html: [
          "<p><strong>Product ID:</strong> 1</p>",
          "<p><strong>Product:</strong> Amber Kettle</p>",
          "<p><strong>Name:</strong> Ada Lovelace</p>",
          "<p><strong>Email:</strong> ada@example.test</p>",
          "<p><strong>Phone:</strong> +1 (555) 010-1234</p>",
          "<p><strong>Message:</strong><br>I have a question about the finish.</p>",
        ].join(""),
      },
    ]);
    expect(logEntries).toEqual([
      { enquiryId: result.id, productId: enquiry.productId },
    ]);
    expect(JSON.stringify(logEntries)).not.toContain(enquiry.email);
    expect(JSON.stringify(logEntries)).not.toContain(enquiry.message);
  });

  it("strips control characters from header values and truncates the subject", async () => {
    const products = catalogueProducts.map((product) =>
      product.id === 1
        ? { ...product, title: `Title\r\n\u0000${"x".repeat(250)}` }
        : product,
    );
    const { service, sender } = createService(products);

    await service.submit({
      ...enquiry,
      email: "ada@example.test\r\n\u0001Bcc: attacker@example.com",
    });

    const sent = sender.messages[0];
    expect(sent?.subject.length).toBe(200);
    expect(sent?.subject).not.toMatch(/[\u0000-\u001f\u007f]/);
    expect(sent?.replyTo).toBe("ada@example.testBcc: attacker@example.com");
    expect(sent?.replyTo).not.toMatch(/[\u0000-\u001f\u007f]/);
  });

  it("HTML-escapes user-supplied values", async () => {
    const { service, sender } = createService();

    await service.submit({
      ...enquiry,
      name: "<script>alert(1)</script>",
      email: "ada<script>@example.test",
      phone: "<b>555</b>",
      message: "<script>alert(1)</script>",
    });

    expect(sender.messages[0]?.html).toContain(
      "&lt;script&gt;alert(1)&lt;/script&gt;",
    );
    expect(sender.messages[0]?.html).toContain(
      "ada&lt;script&gt;@example.test",
    );
    expect(sender.messages[0]?.html).toContain("&lt;b&gt;555&lt;/b&gt;");
    expect(sender.messages[0]?.html).not.toContain("<script>");
  });

  it("propagates unknown products without sending an email", async () => {
    const { service, sender } = createService();

    await expect(
      service.submit({ ...enquiry, productId: 9999 }),
    ).rejects.toBeInstanceOf(NotFoundError);
    expect(sender.messages).toEqual([]);
  });

  it("replaces email transport failures with a generic upstream error", async () => {
    const { service, sender } = createService();
    sender.failure = new Error("private SMTP transport detail");

    await expect(service.submit(enquiry)).rejects.toMatchObject({
      code: "UPSTREAM_UNAVAILABLE",
      message: "Could not send your enquiry. Please try again.",
    });
  });

  it("uses an empty phone in the message when phone is omitted", async () => {
    const { service, sender } = createService();

    await service.submit({
      productId: 1,
      name: "Ada Lovelace",
      email: "ada@example.test",
      message: "A question.",
    });

    expect(sender.messages[0]?.text).toContain("Phone: \n");
  });
});
