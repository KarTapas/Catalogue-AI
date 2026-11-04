import { FakeStoreProductSource } from "./adapters/fakeStoreProductSource.js";
import { ConsoleEmailSender } from "./adapters/consoleEmailSender.js";
import { SmtpEmailSender } from "./adapters/smtpEmailSender.js";
import { buildApp } from "./app.js";
import { parseConfig } from "./config.js";
import { CatalogueService } from "./services/catalogueService.js";
import { EnquiryService } from "./services/enquiryService.js";

const config = parseConfig();
const productSource = new FakeStoreProductSource({
  baseUrl: config.fakeStoreBaseUrl,
});
const catalogueService = new CatalogueService({
  productSource,
  featuredIds: config.featuredIds,
});
const emailSender =
  config.emailProvider === "smtp"
    ? new SmtpEmailSender({
        host: config.smtpHost,
        port: config.smtpPort,
        ...(config.smtpUser === undefined ? {} : { user: config.smtpUser }),
        ...(config.smtpPass === undefined ? {} : { pass: config.smtpPass }),
      })
    : new ConsoleEmailSender();
const enquiryService = new EnquiryService({
  productSource,
  emailSender,
  salesInbox: config.salesInbox,
  emailFrom: config.emailFrom,
});
const app = buildApp({ catalogueService, enquiryService });

await app.listen({ host: "0.0.0.0", port: config.port });
