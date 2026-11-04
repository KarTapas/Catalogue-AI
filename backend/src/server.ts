import { FakeStoreProductSource } from "./adapters/fakeStoreProductSource.js";
import { buildApp } from "./app.js";
import { parseConfig } from "./config.js";
import { CatalogueService } from "./services/catalogueService.js";

const config = parseConfig();
const productSource = new FakeStoreProductSource({
  baseUrl: config.fakeStoreBaseUrl,
});
const catalogueService = new CatalogueService({
  productSource,
  featuredIds: config.featuredIds,
});
const app = buildApp({ catalogueService });

await app.listen({ host: "0.0.0.0", port: config.port });
