import Fastify from "fastify";

export function buildApp() {
  const app = Fastify();
  app.get("/api/v1/health", () => ({ status: "ok" }));
  return app;
}
