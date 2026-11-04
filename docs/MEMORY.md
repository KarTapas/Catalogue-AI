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
