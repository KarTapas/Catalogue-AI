import nodemailer from "nodemailer";
import type { EmailMessage, EmailSender } from "../domain/ports.js";
import { UpstreamUnavailableError, ValidationError } from "../domain/errors.js";

type SmtpOptions = {
  host: string;
  port: number;
  user?: string;
  pass?: string;
};

type MailTransporter = {
  sendMail(message: EmailMessage): Promise<unknown>;
};

export class SmtpEmailSender implements EmailSender {
  private readonly transporter: MailTransporter;

  constructor(options: SmtpOptions | MailTransporter) {
    if ("sendMail" in options) {
      this.transporter = options;
      return;
    }

    if ((options.user === undefined) !== (options.pass === undefined)) {
      throw new ValidationError(
        "SMTP_USER and SMTP_PASS must be configured together",
      );
    }

    const auth =
      options.user === undefined || options.pass === undefined
        ? undefined
        : { user: options.user, pass: options.pass };

    this.transporter = nodemailer.createTransport({
      host: options.host,
      port: options.port,
      ...(auth === undefined ? {} : { auth }),
    });
  }

  async send(message: EmailMessage): Promise<void> {
    try {
      await this.transporter.sendMail(message);
    } catch {
      throw new UpstreamUnavailableError("Email delivery unavailable");
    }
  }
}
