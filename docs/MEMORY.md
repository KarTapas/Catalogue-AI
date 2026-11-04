# Memory
Running log. Agents read this FIRST and append to it LAST. Humans too.
Format: `YYYY-MM-DD HH:MM | type | note` where type = decision | convention | mistake | surprise | time

## Conventions
- Money is a string/minor units, never Float.
- Category names are URL-encoded (`men's clothing`).
- Fake Store has no search or featured endpoint; the backend implements both.

## Log
<!-- append below -->
2026-11-04 16:34 | surprise | Initial dependency ranges pulled vulnerable releases; updated to patched versions and npm install reported 0 vulnerabilities. Configured registry DNS failed, so install used a one-shot public registry override; Docker CLI unavailable for Compose validation.
2026-11-04 16:35 | mistake | Health-server cleanup initially stopped its wrapper instead of the child process; stopped the PID and verified port 3000 was clear.
2026-11-04 17:16 | decision | Fake Store list responses skip malformed products; null or empty single-product responses map to NOT_FOUND, while malformed single products map to UPSTREAM_UNAVAILABLE.
2026-11-04 17:16 | surprise | ESLint's core parser cannot parse TypeScript; with dependencies unchanged, lint now runs ESLint on its JS config and strict tsc checks source and tests. All 201 lockfile resolved URLs use registry.npmjs.org; no .npmrc is committed.
2026-11-04 17:31 | decision | Featured IDs retain configured order, skip and warn on missing IDs, then top up with unique products ranked by rating/count/id; fewer than five available products fail instead of returning a short list. Search trims input, AND-matches all terms across title/description/category, and ranks title matches before rating/id.
2026-11-04 17:31 | surprise | Type-aware lint needs an explicit TypeScript project that includes tests. Config reads Node's environment through a narrow global type because @types/node is not installed; no additional runtime dependency was added.
2026-11-04 17:31 | fix | Enabling type-aware lint exposed issues in the health handler, error-code literal types, and fake-fetch callback types; corrected them without disabling rules.
2026-11-04 17:51 | decision | server.ts owns the adapter/service composition; HTTP routes receive only CatalogueService, validate with Zod, project the documented Product fields, and use one structured error handler.
2026-11-04 17:51 | fix | Lint flagged a test-only Fastify parse handler marked async without await; removed async and reran the full backend checks successfully.
2026-11-04 17:51 | surprise | Live Fake Store smoke requests succeeded; products/9999 returned NOT_FOUND, search?q=jacket returned four products, and port 3000 was confirmed free after stopping the server.
