# Draft pull request: Add catalogue proof of concept

**Base:** `main` · **Head:** `feature/catalogue-poc`

## Summary

Builds the iPhone catalogue proof of concept and its Fastify backend, covering featured products, categories, search, product details and product enquiries. Product metadata and enquiries go through the backend; SwiftUI loads product images from the image URLs supplied in product data (accepted finding R2/S1).

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
- Product details are fetched by ID so deep links and stale list data do not determine the detail screen. `RemoteImage` uses `AsyncImage` for the backend-supplied image URL; see accepted finding R2/S1.
- Enquire stays disabled until the product is loaded. Field errors appear after touch or a submit attempt; a submitting guard prevents duplicate sends; a failure keeps entered values editable; success clears form values from memory.
- The API returns decimal prices as strings. The iOS app does not call Fake Store for product metadata; image URLs are fetched directly by SwiftUI and are restricted to HTTP/HTTPS schemes by the DTO mapper.

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

Then open `ios/CatalogueApp.xcodeproj` in Xcode and run on an iPhone Simulator. See [README.md](../README.md) for Docker, SMTP/Mailpit, configuration and test instructions. The author reported one manual Compose run on their machine on 2026-11-05; see the result under "How it was tested."

## How it was tested

The current unit and Simulator test results below were run for this documentation pass. Earlier live checks and the author's Compose run are labeled separately.

| Check | Result |
|---|---|
| Backend tests, lint, and build | `cd backend && npm test && npm run lint && npm run build` — 83 tests passed; lint and build exited successfully |
| Clean-copy startup | Earlier check: `npm run start:local` with `.env` and `npm start` with environment-only configuration returned health 200; without configuration, startup exited 1 with a clear missing-`EMAIL_FROM` message and no stack trace |
| CatalogueCore package tests | `cd ios/CatalogueCore && swift test` — 33 total; 32 passed and the optional live contract test was skipped |
| iOS app tests | `xcodebuild -project ios/CatalogueApp.xcodeproj -scheme CatalogueApp -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.0' -derivedDataPath ios/build/DerivedData build test` — 65 passed, 0 failed; `TEST SUCCEEDED` |
| Release configuration | Earlier Simulator build passed with `ENABLE_TESTABILITY=YES`; `UI_PREVIEW_ROUTE` and `enquiry-submit` were absent from the Release executable |
| Live API contract | Earlier configured run passed all 31 package tests, including featured products, categories, category products, search, product detail, and not-found handling against the local backend/Fake Store adapter; not rerun in this documentation pass |
| Mailpit end to end | Earlier Mailpit v1.33.0 run returned 202 and delivered a test email, as recorded in [docs/ARCHITECTURE.md](ARCHITECTURE.md#verified-end-to-end); not rerun in this documentation pass |
| Docker Compose (author report, 2026-11-05) | I ran `docker compose up --build` once; the backend started, app requests for categories, featured products, and category pages returned 200, and an app-submitted enquiry email appeared in Mailpit at <http://localhost:8025> |
| Simulator screenshots | Captured during earlier Simulator work under `docs/screenshots/`; not recaptured in this documentation pass |
| GitHub Actions | Not run; unverified |
| Physical device | Not tested; unverified |
| VoiceOver | Not tested |
| Authenticated SMTP TLS | Not verified with a real email provider |

## AI usage

I used GitHub Copilot CLI (agent) to build the code, tests, and docs under my direction. The model was the CLI default or my selection; its exact version was not recorded. I also used a separate chat assistant (Claude, via claude.ai) for planning, writing task prompts, and triaging review findings; its exact model version was not recorded. See [AI_USAGE.md](../AI_USAGE.md) for the prompts and self-review.

## Time spent

| Phase | Time |
|---|---|
| Elapsed span (first to last commit) | 1d 5h53m53s |
| Planning | Not measured; it happened mostly before the first commit and in the chat assistant |
| Building | 5h24m02s, estimated from commit timestamps and subject categories |
| Testing | 20m25s, estimated from commit timestamps and subject categories |
| Reviewing | 3h50m46s, estimated from commit timestamps and subject categories |
| Total | 9h35m13s of active time seen in commits |

I grouped commits into sessions, starting a new session after a gap of more than 90 minutes, and summed each session from its first to last commit. I divided each session's span among building, testing, and reviewing in proportion to the number of commits in those subject-based categories. The elapsed span is the time from the first to last commit; the phase breakdown is an estimate from commit timestamps, not a time log. Actual effort may differ, and the active-time total exceeds the suggested 2-3 hour time-box.

## Known limitations

- Enquiries are email-only with no persistence; Fake Store is a proof-of-concept upstream.
- Product metadata uses the backend, but product images are loaded directly by SwiftUI from the supplied image URL; see accepted finding R2/S1.
- The PRD targets Simulator, and only the Simulator was exercised; the app has no runtime Simulator-only check. Physical-device and VoiceOver testing were not performed. Dynamic Type was checked only in the captured screenshots.
- GitHub Actions remains unverified. SwiftLint is not configured.
- Authenticated SMTP TLS was not verified against a real provider. I did not record additional project-specific limitations beyond those listed here.

## What I would do next

My first three follow-ups are to persist enquiries so email failure does not lose them, run GitHub Actions with a per-job repository-root working directory, and add a backend image proxy with an allow-list and a failure UI. See [DECISIONS.md](../DECISIONS.md#what-i-would-do-next-with-another-day) for the remaining risk-ordered list.

Related drafts and reports: [DECISIONS.md](../DECISIONS.md) · [AI_USAGE.md](../AI_USAGE.md) · [Reviewer report](reviews/REVIEW.md) · [Security report](reviews/SECURITY.md).
