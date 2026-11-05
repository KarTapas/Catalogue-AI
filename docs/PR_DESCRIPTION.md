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

Then open `ios/CatalogueApp.xcodeproj` in Xcode and run on an iPhone Simulator. See [README.md](../README.md) for Docker, SMTP/Mailpit, configuration and test instructions. Docker startup is not verified on this machine.

## How it was tested

- **Backend:** `cd backend && npm test && npm run lint && npm run build` — 83 tests passed; lint and build passed.
- **Clean-copy startup:** `npm run start:local` with `.env` and `npm start` with environment-only configuration both returned health `200`; without configuration, startup exited `1` with a clear missing-`EMAIL_FROM` message and no stack trace.
- **CatalogueCore:** `cd ios/CatalogueCore && swift test` — 33 test cases total; 32 passed and the optional live contract test was skipped. The earlier configured live-contract result is documented in `docs/MEMORY.md` and was not rerun in this change.
- **iOS app:** `xcodebuild -project ios/CatalogueApp.xcodeproj -scheme CatalogueApp -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.0' -derivedDataPath ios/build/DerivedData build test` — 65 tests passed.
- **Release configuration:** Simulator build passed with `ENABLE_TESTABILITY=YES` supplied on the command line; `UI_PREVIEW_ROUTE` and `enquiry-submit` were absent from the Release executable.
- **Live API contract:** previously passed against the local backend and its Fake Store adapter, including featured products, categories, category products, search, product detail and not-found handling; not rerun in this change.
- **Mailpit E2E:** the earlier Mailpit v1.33.0 result is recorded in [docs/ARCHITECTURE.md](ARCHITECTURE.md#verified-end-to-end); it was not rerun in this change.
- **GitHub Actions and Docker:** not run here; both remain unverified.

## AI usage

The repository history contains Copilot co-author trailers. Per the author, GitHub Copilot CLI was used for implementation and a separate chat assistant was used for planning and writing prompts; model names and versions are not recorded in the repository. See [AI_USAGE.md](../AI_USAGE.md) for the draft account.

## Known limitations

- Enquiries are email-only with no persistence; Fake Store is a proof-of-concept upstream.
- Product metadata uses the backend, but product images are loaded directly by SwiftUI from the supplied image URL; see accepted finding R2/S1.
- The PRD targets Simulator, and only the Simulator was exercised; the app has no runtime Simulator-only check. Physical-device and VoiceOver testing were not performed. Dynamic Type was checked only in the captured screenshots.
- Docker and GitHub Actions remain unverified. SwiftLint is not configured.
- **TODO(author):** Add any project-specific limitations discovered during review.

## What I would do next

Candidate follow-ups are persistent enquiry storage, a production catalogue source, VoiceOver/device testing, SwiftLint, and running the Docker and GitHub Actions checks. **TODO(author):** Prioritize these based on product needs and explain the rationale.

Related drafts and reports: [DECISIONS.md](../DECISIONS.md) · [AI_USAGE.md](../AI_USAGE.md) · [Reviewer report](reviews/REVIEW.md) · [Security report](reviews/SECURITY.md).
