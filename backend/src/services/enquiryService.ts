import { randomUUID } from "node:crypto";
import type { Enquiry } from "../domain/enquiry.js";
import { UpstreamUnavailableError } from "../domain/errors.js";
import type { EmailMessage, EmailSender, ProductSource } from "../domain/ports.js";

type EnquiryLogger = {
  info(details: { enquiryId: string; productId: number }): void;
};

type EnquiryServiceOptions = {
  productSource: ProductSource;
  emailSender: EmailSender;
  salesInbox: string;
  emailFrom: string;
  logger?: EnquiryLogger;
};

const defaultLogger: EnquiryLogger = {
  info: (details) => console.info(details),
};

const htmlEscapes: Record<string, string> = {
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
  '"': "&quot;",
  "'": "&#39;",
};

function stripHeaderControls(value: string): string {
  return value.replace(/[\u0000-\u001F\u007F-\u009F]/g, "");
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (character) => htmlEscapes[character] ?? character);
}

export class EnquiryService {
  private readonly productSource: ProductSource;
  private readonly emailSender: EmailSender;
  private readonly salesInbox: string;
  private readonly emailFrom: string;
  private readonly logger: EnquiryLogger;

  constructor({
    productSource,
    emailSender,
    salesInbox,
    emailFrom,
    logger = defaultLogger,
  }: EnquiryServiceOptions) {
    this.productSource = productSource;
    this.emailSender = emailSender;
    this.salesInbox = salesInbox;
    this.emailFrom = emailFrom;
    this.logger = logger;
  }

  async submit(enquiry: Enquiry): Promise<{ id: string }> {
    const product = await this.productSource.getById(enquiry.productId);
    const id = randomUUID();
    const subject = stripHeaderControls(
      `New enquiry: ${product.title} (#${product.id})`,
    ).slice(0, 200);
    const safeReplyTo = stripHeaderControls(enquiry.email);
    const phone = enquiry.phone ?? "";
    const email: EmailMessage = {
      to: this.salesInbox,
      from: this.emailFrom,
      replyTo: safeReplyTo,
      subject,
      text: [
        `Product ID: ${product.id}`,
        `Product: ${product.title}`,
        `Name: ${enquiry.name}`,
        `Email: ${enquiry.email}`,
        `Phone: ${phone}`,
        `Message: ${enquiry.message}`,
      ].join("\n"),
      html: [
        `<p><strong>Product ID:</strong> ${product.id}</p>`,
        `<p><strong>Product:</strong> ${escapeHtml(product.title)}</p>`,
        `<p><strong>Name:</strong> ${escapeHtml(enquiry.name)}</p>`,
        `<p><strong>Email:</strong> ${escapeHtml(enquiry.email)}</p>`,
        `<p><strong>Phone:</strong> ${escapeHtml(phone)}</p>`,
        `<p><strong>Message:</strong><br>${escapeHtml(enquiry.message).replace(/\r\n|\r|\n/g, "<br>")}</p>`,
      ].join(""),
    };

    try {
      await this.emailSender.send(email);
    } catch {
      throw new UpstreamUnavailableError(
        "Could not send your enquiry. Please try again.",
      );
    }

    this.logger.info({ enquiryId: id, productId: product.id });
    return { id };
  }
}
