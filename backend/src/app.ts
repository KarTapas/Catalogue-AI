import Fastify, {
  type FastifyInstance,
  type FastifyServerOptions,
} from "fastify";
import type { CatalogueService } from "./services/catalogueService.js";
import { registerErrorHandler } from "./http/errorHandler.js";
import { registerRoutes } from "./http/routes.js";

type BuildAppOptions = {
  catalogueService: CatalogueService;
  logger?: FastifyServerOptions["logger"];
};

export function buildApp({
  catalogueService,
  logger,
}: BuildAppOptions): FastifyInstance {
  const app = Fastify({ logger: logger ?? true });
  registerErrorHandler(app);
  registerRoutes(app, catalogueService);
  return app;
}
