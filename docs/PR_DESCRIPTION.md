# Draft pull request: Add catalogue proof of concept

**Base:** `main` · **Head:** `feature/catalogue-poc`

## Summary

Builds the iPhone catalogue proof of concept and its Fastify backend, covering featured products, categories, search, product details and product enquiries. The app talks only to the backend; the backend owns the Fake Store and email integrations.

## What was built by acceptance criterion

| Criterion | Implementation and evidence |
|---|---|
| **US1 — Featured products** | The home screen loads the configured five products, with a rating-based fallback. Covered by the backend and iOS suites. [Home screenshot](screenshots/home.png). |
| **US2 — Categories** | The category screen shows the top-rated products and the remaining products. Covered by the backend and iOS suites. [Category screenshot](screenshots/category-mens-clothing.png). |
| **US3 — Search** | Search is handled by the backend; the app presents results and a single empty-state message. Covered by backend and iOS tests. [Results](screenshots/search-jacket.png) · [Empty state](screenshots/search-empty.png). |
| **US4 — Product details** | Details load by product ID, including image, price, rating and description; Enquire is enabled only after a product loads. Not-found and large-text states are covered. [Detail](screenshots/product-1.png) · [Not found](screenshots/product-not-found.png) · [Large text](screenshots/product-large-text.png). |
| **US5 — Enquiry** | The form validates contact details, submits to the backend, preserves input after failure, and shows a Thank you state after success. Backend, package and app tests cover the flow. [Form](screenshots/enquiry-form.png) · [Validation errors](screenshots/enquiry-errors.png) · [Thank you](screenshots/enquiry-thank-you.png). |

## Architecture and key decisions

- iOS follows Presentation -> Domain <- Data; the domain imports Foundation only and dependency injection is through initializers.
- The backend uses ports and adapters: `ProductSource` isolates the Fake Store integration, and `EmailSender` supports console and SMTP providers.
- Product details are fetched by ID so deep links and stale list data do not determine the detail screen.
- Enquire stays disabled until the product is loaded. Field errors appear after touch or a submit attempt; a submitting guard prevents duplicate sends; a failure keeps entered values editable; success clears form values from memory.
- The API returns decimal prices as strings. The iOS app does not call Fake Store directly.

See [docs/ARCHITECTURE.md](ARCHITECTURE.md) for the full contracts and boundaries.

## Assumptions

The implementation follows [PRD assumptions A1-A7](PRD.md#assumptions-gaps-in-the-brief-mirrored-in-decisionsmd):

- **A1:** Featured product IDs are configured by `FEATURED_IDS`, with a top-rated fallback.
- **A2:** Category top-rated means the top three by rating, with review count breaking ties.
- **A3:** Search is server-side, case-insensitive across title, description and category; the query is trimmed and at least two characters.
- **A4:** Empty or short searches return `400 VALIDATION_ERROR`; the app disables the search button.
- **A5:** Enquiries contain name, email, optional phone, message and product ID.
- **A6:** Enquiries are emailed, not stored in a database.
- **A7:** The target is iPhone, iOS 17+, portrait and Simulator only.

## What was dropped and why

Nothing from the agreed US1-US5 scope was dropped. Authentication, cart, payments, admin UI, offline cache, pagination, iPad layout, localization and analytics are PRD non-goals, not deferred acceptance criteria.

## How to run

For a local backend:

```sh
cd backend
cp .env.example .env
npm ci
npm run build
npm run start:local
```

Then open `ios/CatalogueApp.xcodeproj` in Xcode and run on an iPhone Simulator. See [README.md](../README.md) for Docker, SMTP/Mailpit, configuration and test instructions. Docker startup is not verified on this machine.

## How it was tested

- **Backend:** `cd backend && npm test && npm run lint && npm run build` — 80 tests; lint and build passed.
- **Clean-copy startup:** `npm run start:local` with `.env` and `npm start` with environment-only configuration both returned health `200`; without configuration, startup exited `1` with a clear missing-`EMAIL_FROM` message and no stack trace.
- **CatalogueCore:** `cd ios/CatalogueCore && swift test` — 31-test suite passed with the optional live test skipped. `cd ios/CatalogueCore && CATALOGUE_LIVE_API_URL=http://127.0.0.1:3000 swift test` passed all 31, including `liveBackendContract()`.
- **iOS app:** `xcodebuild -project ios/CatalogueApp.xcodeproj -scheme CatalogueApp -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.0' -derivedDataPath ios/build/DerivedData build test` — 63 tests passed.
- **Release configuration:** Simulator build passed with `ENABLE_TESTABILITY=YES` supplied on the command line; `UI_PREVIEW_ROUTE` and `enquiry-submit` were absent from the Release executable.
- **Live API contract:** passed against the locally running backend and its Fake Store adapter, including featured products, categories, category products, search, product detail and not-found handling.
- **Mailpit E2E:** with Mailpit v1.33.0, a valid API enquiry returned `202` with ID `6e6fa904-01f3-44c3-b13f-b742818cc659`. Mailpit received subject `New enquiry: Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops (#1)` at `sales@example.test`, with Reply-To `smtp.test@example.test`; the body contained the product, customer details and message. A name containing CR/LF followed by `Bcc:` returned `400 VALIDATION_ERROR`, and Mailpit remained at one message with no Bcc. The app's `enquiry-submit:1` flow delivered a second message with Reply-To `test.customer@example.test`. The recorded result is in [docs/ARCHITECTURE.md](ARCHITECTURE.md#verified-end-to-end).
- **GitHub Actions and Docker:** not run here; both remain unverified.

## AI usage

Tools used included GitHub Copilot CLI (GPT-6 Luna), token-goat source navigation, Git, npm/Vitest/ESLint/TypeScript, SwiftPM/Xcode, curl and Mailpit. Project instruction files followed: `AGENTS.md`, `docs/RULES.md`, `docs/ARCHITECTURE.md`, `docs/TASKS.md`, `docs/MEMORY.md` and `docs/PRD.md`. No subagents were used.

## Known limitations

- Enquiries are email-only with no persistence; Fake Store is a proof-of-concept upstream.
- The app is Simulator-only; physical-device and VoiceOver testing were not performed. Dynamic Type was checked only in the captured screenshots.
- Docker and GitHub Actions remain unverified. SwiftLint is not configured.
- **TODO(author):** Add any project-specific limitations discovered during review.

## What I would do next

Candidate follow-ups are persistent enquiry storage, a production catalogue source, VoiceOver/device testing, SwiftLint, and running the Docker and GitHub Actions checks. **TODO(author):** Prioritize these based on product needs and explain the rationale.
