# Decisions

This draft is based on `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/MEMORY.md`, the review reports, the current code, and the branch history. `TODO(author)` marks rationale or effort judgments that those sources do not record.

## Assumptions

The A1-A7 gap and assumption text is copied from `docs/PRD.md`. The final column describes the implementation, not just the assumption.

| # | Gap | Assumption | Why | How easy to change | What the code actually does today |
|---|---|---|---|---|---|
| A1 | Who "chooses" the 5 featured? | Backend config `FEATURED_IDS`; fallback to top 5 by rating | `TODO(author)` — the PRD records the assumption, not its business rationale. | ID selection is configuration; changing fallback behavior requires a service change. `TODO(author)` to rate the effort. | `CatalogueService.getFeatured()` preserves configured ID order, skips missing IDs, removes duplicates, and tops up from the catalogue sorted by rating, rating count, then ID. It throws `UPSTREAM_UNAVAILABLE` if fewer than five unique products remain. |
| A2 | "Top rated" in a category | Top 3 by `rating.rate` (ties: higher `rating.count`), then the rest | `TODO(author)` — the PRD records the rule, not why three is the right number. | The split is in one backend service method; changing it also changes the API's displayed groups. `TODO(author)` to rate the effort. | Category names are compared case-insensitively. Products are ordered by rating descending, count descending, then ID ascending; the first three are `topRated` and the rest remain in that order. |
| A3 | Search scope | Server-side, case-insensitive, title + description + category, trimmed, min 2 chars | `TODO(author)` — the PRD records the scope, not the ranking rationale. | Search behavior and bounds live in the backend service and client `SearchQuery`; changing the contract requires both sides to agree. `TODO(author)` to rate the effort. | The backend trims the query, requires 2-100 JavaScript UTF-16 code units, AND-matches every whitespace-separated term across title, description, or category, then ranks products with every query term in the title first, followed by rating and ID. The client also enforces 2-100 UTF-16 code units and sends only on explicit submit. |
| A4 | Empty/short search | Server returns 400 `VALIDATION_ERROR`; app disables the button | `TODO(author)` — this matches the PRD behavior; the product rationale is not recorded. | The client has a local query guard and the backend validates at the route. `TODO(author)` to rate the effort. | The client disables search when the trimmed query is outside 2-100 UTF-16 code units. The server independently trims and validates the query and returns `400 VALIDATION_ERROR` for an invalid value. |
| A5 | Enquiry fields | name, email, phone (optional), message, productId | `TODO(author)` — the PRD identifies the fields but not the rationale for each. | Limits are duplicated in client and server validation; update both together. `TODO(author)` to rate the effort. | `productId` must be positive. Name and message must be nonempty after trimming and are limited to 100 and 2,000 UTF-16 code units; email must be valid and at most 254; optional phone is at most 30 and permits digits, spaces, `+`, `-`, `(` and `)`. The iOS submit use case trims values; server Zod trims name/message, not email/phone. |
| A6 | Enquiry storage | None. Email only. DB is a next step | The PRD explicitly leaves a database as a next step; any further reason is `TODO(author)`. | Adding storage needs a new backend repository port and adapter, per the architecture extension point. `TODO(author)` to rate the effort. | The service looks up the product and sends email; it does not persist the enquiry. A delivery failure returns a generic 502, so the enquiry is lost and the customer must retry. |
| A7 | Platform | iPhone, iOS 17+, portrait, Simulator only | `TODO(author)` — the PRD states the target, not its rationale. | Deployment target and orientation are project configuration; device support needs a separate verification pass. `TODO(author)` to rate the effort. | The XcodeGen project targets iOS 17.0 and `Info.plist` declares portrait orientation. The Simulator is the verified environment; there is no runtime check that restricts execution to Simulator, and physical-device behavior is unverified. |
| B1 | What if there are fewer than five distinct products? | Do not return a short featured list. | This behavior is recorded in `docs/MEMORY.md`; the business rationale is `TODO(author)`. | Change `CatalogueService.getFeatured()` and its tests; `TODO(author)` to rate the effort. | Missing configured IDs are skipped and unique catalogue products top up the list. If the result still has fewer than five, the service throws `UPSTREAM_UNAVAILABLE`. |
| B2 | What if upstream products are malformed? | Skip malformed list items; fail a malformed single-product request. | The adapter keeps malformed records out of the domain; any alternative product policy is `TODO(author)`. | The behavior is isolated in `FakeStoreProductSource`; `TODO(author)` to rate the effort. | `fetchProducts()` uses the Zod schema and skips invalid items. `getById()` maps a null response to `NOT_FOUND` and a malformed product to `UPSTREAM_UNAVAILABLE`. |
| B3 | How is money represented? | Decimal string in the backend contract; `Decimal` in iOS Domain. | The contract avoids binary floating-point money; the exact product/pricing rationale is `TODO(author)`. | The API, mapper, and Domain `Money` type must change together. `TODO(author)` to rate the effort. | The Fake Store adapter writes a two-decimal string with `toFixed(2)` and currency `USD`; iOS parses it as `Decimal`. Ratings, not prices, use floating-point values. |
| B4 | How are category names matched? | Case-insensitive comparison. | This was recorded as a build decision in `docs/MEMORY.md`; further rationale is `TODO(author)`. | One backend service comparison; `TODO(author)` to rate the effort. | `getCategoryProducts()` lowercases the requested name and available category names before matching, then uses the canonical upstream category for the product request. |
| B5 | What is the Release API host? | Leave `API_BASE_URL` empty until a production host exists. | The production host is not recorded; `TODO(author)` to supply one before release. | Set the Release xcconfig value without changing the app code; `TODO(author)` to rate the operational effort. | `ios/CatalogueApp/Config/Release.xcconfig` has an empty `API_BASE_URL`; `AppConfig` rejects a missing or empty URL, so a Release app needs a real value to start. |
| B6 | How are product images fetched? | Use the image URL supplied with product data; do not add a proxy in this PoC. | R2/S1 was accepted: a proxy is a next step and adds its own SSRF risk. | A proxy would add backend retrieval, validation, caching, and an allow-list; `TODO(author)` to rate the effort. | `DTOMapper.imageURL` accepts only HTTP/HTTPS URLs with a host; `RemoteImage` uses SwiftUI `AsyncImage` to load that URL directly. The mapper does not enforce a host allow-list. |

## Key design decisions

| Decision | Alternatives | Why | Trade-off |
|---|---|---|---|
| Require a backend between iOS and catalogue/email providers (brief constraint 2). Product metadata and enquiries use it; product images are the accepted direct-network exception in R2/S1. | Calling Fake Store from iOS or sending email from iOS, which conflicts with the brief's backend boundary. | The PRD requires the app to use the project backend. The backend owns the Fake Store and email integrations and gives the app a stable JSON contract. | There is another service to configure and run. Images still load from the URL in backend-provided data. |
| Use Fastify for the backend HTTP server. | `TODO(author)` — the repository does not record which alternative frameworks were evaluated. | The code and README document a small typed HTTP API; why Fastify was selected is not recorded. `TODO(author)`. | Fastify and its plugin lifecycle are part of the server and test setup. |
| Put product and email I/O behind `ProductSource` and `EmailSender` ports. | Put provider calls directly in services. | The PRD says the product source and email provider are expected to change; the ports make those adapters replaceable without moving service rules. | Adds interfaces and composition wiring in `backend/src/server.ts`. |
| Keep `CatalogueDomain` and `CatalogueData` as separate Swift package targets. | One package target with a convention-only boundary. | `CatalogueDomain` has no target dependencies and `CatalogueData` depends on it, so SwiftPM enforces the dependency direction at compile time. | Package and test structure has more targets to maintain. |
| Inject `HTTPTransport` instead of stubbing requests with `URLProtocol`. | Intercept `URLSession` through `URLProtocol`. | `APIClient` accepts a transport and tests use a deterministic fake without network access. | The fake tests the API client boundary, not the real `URLSessionTransport`; a direct offline test of that transport remains a next step. |
| Define the app in XcodeGen YAML and commit the generated Xcode project. | Hand-edit the project file only. | `ios/project.yml` is the project definition and the generated `.xcodeproj` is tracked for reviewers. The original selection rationale is `TODO(author)`. | The generated project must be regenerated when its YAML source changes. |
| Configure the API base URL through xcconfig and `Info.plist`. | Hard-code a URL in app source. | `AppConfig` reads and validates the configured URL; Debug uses localhost and Release is intentionally blank pending a real host. | Release cannot start until a production API URL is supplied. |
| Permit insecure HTTP only for `localhost` in ATS. | Allow arbitrary insecure loads or require HTTPS for local development. | The Simulator talks to the local backend over HTTP; the security report confirms there is no broad ATS exception. | `localhost` does not refer to a backend on a physical device; production must use HTTPS. |
| Run search on explicit submit and use request IDs/cancellation for latest-submit-wins. | Search on every keystroke or accept whichever response arrives last. | The PRD describes tapping the search button; the request ID prevents an older response replacing newer results. | No live autocomplete; cancellation and request state add ViewModel logic. |
| Let the backend calculate the category top-three split and let iOS render it as returned. | Recalculate the split on iOS. | The API contract returns `topRated` and `others`, and the architecture says the client preserves that split and order. | The client depends on the backend's ordering contract. |
| Validate on both client and server, counting string lengths as UTF-16 code units. | Validate only at one boundary or count Swift grapheme clusters. | R3 showed JavaScript `.length` and Swift `String.count` could disagree; client and server now use compatible limits. | Validation rules are duplicated and must stay synchronized. |
| Defend email headers at both the HTTP boundary and email service. | Sanitize only when constructing the email. | The route rejects CR/LF and the service strips header controls; HTML values are separately escaped. This is the documented defense against header and HTML injection. | The two layers require tests and coordinated maintenance. |
| Use Mailpit for local SMTP. | Send local development mail to a real provider. | Compose provides a local SMTP service and a web UI, so local email flow can be inspected without production credentials. | Mailpit does not verify authenticated TLS negotiation with a real provider. |
| Keep `npm start` environment-only and add `start:local` for `.env`. | Make every start require Node's `--env-file=.env`. | Docker and CI pass environment variables and may not have `.env`; the clean-copy test exposed Node 20's missing-file error. `dev` selects the local or environment-only path. | Developers use the explicit `start:local` command when they want `.env` loaded. |
| Separate read-only review from fixes, using Reviewer and Security Auditor roles. | Mix findings and implementation in one pass. | The history has separate review reports and follow-up commits; findings can be triaged before targeted changes. | The first review pass accidentally edited CI; the process needs a worktree check to preserve read-only reviews. |
| Load images from the source URL included in product data (accepted R2/S1). | Proxy images through the backend or enforce a host allow-list. | The current app uses `AsyncImage`; the accepted resolution defers a proxy because it adds SSRF risk. The DTO mapper limits schemes to HTTP and HTTPS. | The device still contacts the supplied host directly; no host allow-list or proxy is present. |
| Require TLS only when SMTP credentials are configured; use implicit TLS on port 465. | Require TLS for all SMTP connections or send authenticated credentials without TLS. | S2 was fixed while preserving unauthenticated Mailpit SMTP. `requireTLS` is set with credentials, and port 465 also sets `secure`. | Authenticated TLS has not been tested with a real provider. |
| Keep the Xcode app target in Swift 5 language mode. | Enable strict Swift 6 language mode now. | `SWIFT_VERSION` is `5.0`, matching the package's Swift tools 5.9 Swift 5 mode, as recorded in `docs/MEMORY.md`. | Strict Swift 6 concurrency checking remains future work. |
| Keep Search visible as a compact icon-only button inside the field row. | Use a full-width button below the field or hide the submit control. | US3 requires tapping the search button; this preserves that action and keyboard Search behavior while reducing vertical space. | Preserve 44pt targets and explicit disabled state/semantics. |

## Dropped or simplified, and why

| Item | Why it is out |
|---|---|
| Authentication | The PRD lists it as a non-goal, so it was outside this PoC time-box. `TODO(author)` for any product-specific rationale. |
| Cart | The PRD lists it as a non-goal, so it was outside this PoC time-box. `TODO(author)` for any product-specific rationale. |
| Payments | The PRD lists it as a non-goal, so it was outside this PoC time-box. `TODO(author)` for any product-specific rationale. |
| Admin UI | The PRD lists it as a non-goal, so it was outside this PoC time-box. `TODO(author)` for any product-specific rationale. |
| Offline cache | The PRD lists it as a non-goal, so it was outside this PoC time-box. `TODO(author)` for any product-specific rationale. |
| Pagination | The PRD lists it as a non-goal, so it was outside this PoC time-box; revisit it if catalogue size requires it. `TODO(author)` to judge priority. |
| iPad layout | The PRD lists it as a non-goal, so it was outside this PoC time-box. `TODO(author)` for any product-specific rationale. |
| Localisation | The PRD lists it as a non-goal, so it was outside this PoC time-box. `TODO(author)` for any product-specific rationale. |
| Analytics | The PRD lists it as a non-goal, so it was outside this PoC time-box. `TODO(author)` for any product-specific rationale. |
| Enquiry persistence | PRD assumption A6 keeps enquiries email-only, but a failed delivery currently loses the enquiry; persistence is deferred beyond this PoC time-box. `TODO(author)` to confirm the accepted business risk. |
| Image proxy | R2/S1 is accepted for this PoC time-box; a proxy adds SSRF exposure and needs an allow-list/caching design. `TODO(author)` to decide when to revisit it. |
| SwiftLint | T13 explicitly deferred SwiftLint; no extra lint tool was added in this time-box. |
| Security headers | The security report records that the headers are absent; adding them was deferred beyond this PoC time-box. `TODO(author)` to set the security bar and priority. |
| Proxy-aware rate limiting | Enquiry limiting is keyed by `request.ip`; `trustProxy` is off and the Compose setup has no reverse proxy. Proxy-aware deployment behavior was not exercised in this PoC time-box; `TODO(author)` to define the deployment topology. |

## How the design supports growth beyond the PoC

| Change | Existing seam | What is not exercised |
|---|---|---|
| Swap the product source | Implement `ProductSource` in `backend/src/domain/ports.ts`, add an adapter beside `backend/src/adapters/fakeStoreProductSource.ts`, and compose it in `backend/src/server.ts`. | Only Fake Store is implemented; a second source was not tested. |
| Swap the email provider for AWS SES | Implement `EmailSender` in `backend/src/domain/ports.ts`; `ConsoleEmailSender` and `SmtpEmailSender` show the current adapters. | No SES adapter or AWS email service was exercised. |
| Replace the look and feel | Replace tokens and components under `ios/CatalogueApp/DesignSystem/`. | A second design system or a creative-team redesign was not exercised. |
| Deploy the stateless backend container to AWS | `backend/Dockerfile` builds a Node container; configuration is provided through the environment. | Docker/Compose was not run on this machine and no AWS deployment was made. |
| Add enquiry persistence | Add the backend `EnquiryRepository` port and adapter described in `docs/ARCHITECTURE.md`; the existing iOS port with that name is for remote submission, not persistence. | There is no backend persistence port or database adapter today; this growth path was not exercised. |

## What I would do next with another day

**The order of these priorities is `TODO(author)`; the first three are candidates, not an approved ranking.**

1. Persist enquiries so a failed email does not lose the enquiry.
2. Run `docker compose up` and fix any image or Compose issues; neither was run on this machine.
3. Verify authenticated SMTP TLS against a real provider; current tests cover transport options, not a provider handshake.
4. Run CI on GitHub and move the iOS jobs to a per-job repository-root working directory.
5. Add an offline test for the production `URLSessionTransport`.
6. Replace `CATALOGUE_DISABLE_AUTOMATIC_HOME_LOAD` with an injected `autoLoad` flag.
7. Add a backend image proxy with an allow-list and SSRF controls.
8. Add security headers and define proxy-aware rate limiting for the deployment topology.
9. Pin container images by digest and GitHub Actions by commit SHA.
10. Add SwiftLint.
11. Enable and resolve strict Swift 6 concurrency diagnostics.
12. Run VoiceOver and Dynamic Type checks beyond the captured screenshots.
13. Add pagination if product size or performance requires it.
