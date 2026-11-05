import nodemailer from "nodemailer";
import type { EmailMessage, EmailSender } from "../domain/ports.js";
import { UpstreamUnavailableError, ValidationError } from "../domain/errors.js";

type SmtpOptions = {
  host: string;
  port: number;
  user?: string;
  pass?: string;
};

type SmtpTransportOptions = {
  host: string;
  port: number;
  auth?: {
    user: string;
    pass: string;
  };
  requireTLS?: boolean;
  secure?: boolean;
};

type MailTransporter = {
  sendMail(message: EmailMessage): Promise<unknown>;
};

export function buildTransportOptions({
  host,
  port,
  user,
  pass,
}: SmtpOptions): SmtpTransportOptions {
  const transportOptions: SmtpTransportOptions = { host, port };

  if (user !== undefined && pass !== undefined) {
    transportOptions.auth = { user, pass };
    transportOptions.requireTLS = true;
    if (port === 465) {
      transportOptions.secure = true;
    }
  }

  return transportOptions;
}

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

    this.transporter = nodemailer.createTransport(buildTransportOptions(options));
  }

  async send(message: EmailMessage): Promise<void> {
    try {
      await this.transporter.sendMail(message);
    } catch {
      throw new UpstreamUnavailableError("Email delivery unavailable");
    }
  }
}
