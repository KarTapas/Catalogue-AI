import nodemailer from "nodemailer";
import { describe, expect, it, vi } from "vitest";
import type { EmailMessage } from "../src/domain/ports.js";
import { UpstreamUnavailableError } from "../src/domain/errors.js";
import { ConsoleEmailSender } from "../src/adapters/consoleEmailSender.js";
import {
  buildTransportOptions,
  SmtpEmailSender,
} from "../src/adapters/smtpEmailSender.js";

const emailMessage: EmailMessage = {
  to: "sales@example.test",
  from: "catalogue@example.test",
  replyTo: "ada@example.test",
  subject: "New enquiry: Amber Kettle (#1)",
  text: "Customer message",
  html: "<p>Customer message</p>",
};

describe("ConsoleEmailSender", () => {
  it("logs only the recipient and subject", async () => {
    const info = vi.spyOn(console, "info").mockImplementation(() => undefined);

    try {
      await new ConsoleEmailSender().send(emailMessage);

      expect(info).toHaveBeenCalledWith({
        to: emailMessage.to,
        subject: emailMessage.subject,
      });
      const logged = JSON.stringify(info.mock.calls);
      expect(logged).not.toContain(emailMessage.text);
      expect(logged).not.toContain(emailMessage.html);
    } finally {
      info.mockRestore();
    }
  });
});

describe("SmtpEmailSender", () => {
  it("does not require TLS without credentials", () => {
    const options = buildTransportOptions({ host: "localhost", port: 1025 });

    expect(options).toEqual({ host: "localhost", port: 1025 });
    expect(options).not.toHaveProperty("requireTLS");
  });

  it("requires TLS when credentials are configured", () => {
    const options = buildTransportOptions({
      host: "smtp.example.test",
      port: 587,
      user: "sender",
      pass: "password",
    });

    expect(options).toEqual({
      host: "smtp.example.test",
      port: 587,
      auth: { user: "sender", pass: "password" },
      requireTLS: true,
    });
  });

  it("uses implicit TLS on port 465 when credentials are configured", () => {
    const options = buildTransportOptions({
      host: "smtp.example.test",
      port: 465,
      user: "sender",
      pass: "password",
    });

    expect(options).toEqual({
      host: "smtp.example.test",
      port: 465,
      auth: { user: "sender", pass: "password" },
      requireTLS: true,
      secure: true,
    });
  });

  it("sends through an injected Nodemailer JSON transport", async () => {
    const jsonTransport = nodemailer.createTransport({ jsonTransport: true });
    let serializedMessage = "";
    const sender = new SmtpEmailSender({
      sendMail: async (message) => {
        const info = await jsonTransport.sendMail(message);
        serializedMessage = info.message.toString();
        return info;
      },
    });

    await sender.send(emailMessage);

    expect(serializedMessage).toContain("sales@example.test");
    expect(serializedMessage).toContain("catalogue@example.test");
    expect(serializedMessage).toContain(emailMessage.subject);
    expect(serializedMessage).toContain(emailMessage.text);
    jsonTransport.close();
  });

  it("converts transport failures to a generic upstream error", async () => {
    const sender = new SmtpEmailSender({
      sendMail: () => Promise.reject(new Error("private SMTP transport detail")),
    });

    const error = await sender
      .send(emailMessage)
      .then(() => new Error("Expected email delivery to fail"), (caught: unknown) => caught);

    expect(error).toBeInstanceOf(UpstreamUnavailableError);
    expect(error).toMatchObject({
      code: "UPSTREAM_UNAVAILABLE",
      message: "Email delivery unavailable",
    });
  });
});
