import Fastify from "fastify";

export function buildApp() {
  const app = Fastify();
  app.get("/api/v1/health", async () => ({ status: "ok" }));
  return app;
}
