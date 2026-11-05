import Fastify, {
  type FastifyInstance,
  type FastifyServerOptions,
} from "fastify";
import rateLimit from "@fastify/rate-limit";
import type { CatalogueService } from "./services/catalogueService.js";
import type { EnquiryService } from "./services/enquiryService.js";
import {
  RateLimitExceededError,
  registerErrorHandler,
} from "./http/errorHandler.js";
import {
  registerRoutes,
  type EnquiryRateLimitOptions,
} from "./http/routes.js";

type BuildAppOptions = {
  catalogueService: CatalogueService;
  enquiryService: EnquiryService;
  logger?: FastifyServerOptions["logger"];
  enquiryRateLimit?: EnquiryRateLimitOptions;
};

export function buildApp({
  catalogueService,
  enquiryService,
  logger,
  enquiryRateLimit,
}: BuildAppOptions): FastifyInstance {
  const app = Fastify({ logger: logger ?? true });
  registerErrorHandler(app);
  void app.register(rateLimit, {
    global: false,
    errorResponseBuilder: () => new RateLimitExceededError(),
  });
  void app.register((instance, _options, done) => {
    registerRoutes(
      instance,
      catalogueService,
      enquiryService,
      enquiryRateLimit ?? { max: 5, timeWindowMs: 60_000 },
    );
    done();
  });
  return app;
}
