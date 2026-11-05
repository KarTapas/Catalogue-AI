import type { EmailMessage, EmailSender } from "../domain/ports.js";

export class ConsoleEmailSender implements EmailSender {
  send(message: EmailMessage): Promise<void> {
    console.info({ to: message.to, subject: message.subject });
    return Promise.resolve();
  }
}
