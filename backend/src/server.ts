import { buildApp } from "./app.js";
import { parseConfig } from "./config.js";

const config = parseConfig();
const app = buildApp();

await app.listen({ host: "0.0.0.0", port: config.port });
