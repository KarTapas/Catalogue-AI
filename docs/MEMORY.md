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
2026-11-04 18:09 | decision | Enquiries are email-only with no storage; failed delivery returns a generic 502 so the customer can retry. Customer addresses go only in replyTo/body, headers are sanitized, HTML values escaped, and application logs contain only enquiry/product IDs.
2026-11-04 18:09 | fix | The first rate-limit test showed routes had been registered before the plugin's onRoute hook, so all six requests passed; route registration now follows plugin setup and the sixth request returns 429. Corrected the stale .env.example provider comment from mailpit to console.
2026-11-04 18:21 | decision | CatalogueCore uses separate CatalogueDomain and CatalogueData SwiftPM targets; Domain has no target dependencies and imports Foundation only. Money stays Decimal and formats with its currency code; query/enquiry validation and trimming stay in Domain use cases.
2026-11-04 18:21 | surprise | Swift 6.3.3 and Xcode 26.6 are installed, so the domain tests use the built-in Swift Testing framework without adding dependencies.
2026-11-04 18:21 | fix | The initial combined architecture-doc patch missed the current layout context after T4 updates; re-read the targeted section, applied the docs separately, and verified the package build and tests.
2026-11-04 21:05 | decision | CatalogueData uses an injected base URL and HTTPTransport, maps POSIX-parsed decimal-string prices and optional image URLs to Domain, and centralizes backend errors while propagating cancellation unchanged. The T5 coverage review found no missing required cases.
2026-11-04 21:05 | fix | The first T6 build exposed missing CatalogueDomain imports and error-mapping switch returns; added the imports and explicit returns, then rebuilt without warnings.
2026-11-04 21:05 | surprise | Offline Swift tests passed with the live contract test skipped; all 31 tests passed against the local backend and live Fake Store API when CATALOGUE_LIVE_API_URL was set.
2026-11-04 21:30 | decision | XcodeGen 2.44.1 defines the app and shared scheme; its generated .xcodeproj is committed. Xcode uses Swift 5.0 language mode, matching CatalogueCore's Swift tools 5.9 default Swift 5 mode.
2026-11-04 21:30 | decision | Debug xcconfig uses http:/$()/localhost:3000 to avoid // comment parsing; Release API_BASE_URL stays unassigned pending a real host. ATS allows insecure HTTP for localhost only; production must use HTTPS and remove the exception.
2026-11-04 21:30 | mistake | Name-only xcodebuild destination selection defaulted to an unavailable latest runtime for iPhone SE (3rd generation); pinned its installed iOS 18.0 runtime in commands and AGENTS.md.
2026-11-04 21:30 | surprise | The iPhone SE simulator built, tested, and launched the placeholder; docs/screenshots/skeleton.png was captured at 750x1334.
2026-11-04 21:52 | decision | Home loads featured products and categories independently; retry reloads only failed sections while pull-to-refresh reloads both. Category capitalization is display-only, preserving the original value for routes and APIs.
2026-11-04 21:52 | fix | The first T8 build found missing return values in the preview repository's long-running loading branches; added return values after the sleep and reran build/tests successfully.
2026-11-04 21:52 | surprise | The XCTest host launched the real root view and initially triggered backend calls. The shared test scheme now disables automatic Home loading during tests, keeping test execution offline; loaded and backend-down screenshots both showed their expected states.
2026-11-04 22:15 | decision | The backend owns the top-three category split and order; iOS renders topRated and others unchanged. Home and Category share the same adaptive ProductGrid.
2026-11-04 22:15 | decision | UI_PREVIEW_ROUTE=category:<name> is read only in CatalogueApp.swift under #if DEBUG and initializes the category route for simulator screenshots; Release builds omit the hook.
2026-11-04 22:15 | fix | T9 builds exposed a missing CatalogueDomain import, a stale preview placeholder reference, missing explicit returns in preview fake branches, and a duplicate Swift Testing function name; fixed these and reran tests successfully.
2026-11-04 22:15 | surprise | simctl passes launch environment values through the SIMCTL_CHILD_ prefix. Release scheme verification also needed ENABLE_TESTABILITY=YES because the scheme builds the @testable XCTest host.
2026-11-04 22:50 | decision | Search requests run only on explicit submit; request IDs and cancellation enforce latest-submit-wins, empty results remain loaded and render as an empty state, and the client preserves backend result order.
2026-11-04 22:50 | fix | T10 compilation exposed stale search-placeholder references in Home/Category previews, duplicate test names, and a SearchBar initializer issue while adding inline validation; corrected them and reran simulator tests.
2026-11-04 22:50 | surprise | Console backend startup still requires EMAIL_FROM, so live checks used the nonsecret .test address catalogue@example.test. ENABLE_TESTABILITY is absent from project.yml; Release verification used only a command-line override. Three jacket-image placeholders were still loading in the screenshot.
