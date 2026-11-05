# Interview prep

## Architecture in five lines

1. I keep SwiftUI screens and ViewModels in Presentation, with use cases and entities in Domain (`docs/ARCHITECTURE.md`, `ios/CatalogueApp/Presentation/`).
2. `CatalogueCore` separates Foundation-only `CatalogueDomain` from `CatalogueData`, which implements the API repositories and injected HTTP transport (`ios/CatalogueCore/Package.swift`).
3. Product metadata and enquiry requests go through the Fastify backend; product images are the accepted direct-network exception (`backend/src/http/routes.ts`, `ios/CatalogueApp/DesignSystem/RemoteImage.swift`).
4. Backend routes validate input and call services; services depend on `ProductSource` and `EmailSender` ports (`backend/src/http/routes.ts`, `backend/src/domain/ports.ts`).
5. Fake Store, console email, and SMTP are adapters composed at startup, and tests inject fakes (`backend/src/server.ts`, `backend/src/adapters/`).

## Likely follow-up questions

### 1. Where are the boundaries?

- The iOS dependency rule is Presentation -> Domain <- Data; Domain has no target dependencies.
- The backend flow is HTTP -> services -> domain, with adapters implementing domain ports.
- The app uses the backend for product metadata and enquiries; `RemoteImage` directly loads image URLs.
- Sources: `docs/ARCHITECTURE.md`, `ios/CatalogueCore/Package.swift`, `backend/src/server.ts`, `ios/CatalogueApp/DesignSystem/RemoteImage.swift`.

### 2. Why use ports and adapters?

- `ProductSource` isolates the Fake Store integration, and `EmailSender` isolates console and SMTP delivery.
- The service rules depend on those interfaces rather than on provider implementations.
- The PRD expects the product source and email provider to change.
- Sources: `backend/src/domain/ports.ts`, `backend/src/services/catalogueService.ts`, `backend/src/services/enquiryService.ts`, `backend/src/server.ts`, `docs/PRD.md`.

### 3. Why is the backend mandatory?

- The PRD says the iOS app talks to the project backend and not to Fake Store for product data.
- The backend owns catalogue and enquiry APIs and keeps provider configuration out of the app.
- Product images are a documented R2/S1 exception: SwiftUI fetches their supplied URLs directly.
- Sources: `docs/PRD.md`, `backend/src/http/routes.ts`, `docs/reviews/REVIEW.md`, `ios/CatalogueApp/DesignSystem/RemoteImage.swift`.

### 4. How do featured products and categories work?

- Configured featured IDs retain their order; missing IDs are skipped and rating-ranked products fill gaps.
- The service fails if it still cannot produce five unique featured products.
- Category matching is case-insensitive; products sort by rating, rating count, then ID, with the first three returned as `topRated`.
- Sources: `backend/src/config.ts`, `backend/src/services/catalogueService.ts`, `backend/test/catalogueService.test.ts`.

### 5. How does search work?

- The backend trims a query of 2-100 UTF-16 code units and AND-matches each term across title, description, and category.
- Products matching all terms in the title rank first, followed by rating and ID.
- The client uses 2-100 UTF-16 code units and submits explicitly; request IDs and cancellation enforce latest-submit-wins.
- Sources: `backend/src/http/routes.ts`, `backend/src/services/catalogueService.ts`, `ios/CatalogueCore/Sources/CatalogueDomain/Validation/SearchQuery.swift`, `ios/CatalogueApp/Presentation/Search/`.

### 6. Why validate on both sides?

- The UI can prevent obvious invalid submissions, but the backend is also an API boundary and validates independently.
- R3 found JavaScript UTF-16 lengths and Swift grapheme counts could disagree, so the client now uses UTF-16 counts too.
- The enquiry rules cover product ID, required fields, email, optional phone, message length, and control characters.
- Sources: `backend/src/http/routes.ts`, `ios/CatalogueCore/Sources/CatalogueDomain/Validation/EnquiryValidator.swift`, `docs/reviews/REVIEW.md` (R3).

### 7. What security choices are important?

- The backend validates request bodies, rate-limits enquiries, sanitizes email headers, and escapes user values in HTML.
- Authenticated SMTP requires TLS, but no real provider handshake was tested.
- ATS permits local HTTP for `localhost`; product images still load directly and have no host allow-list.
- Sources: `backend/src/http/routes.ts`, `backend/src/services/enquiryService.ts`, `backend/src/adapters/smtpEmailSender.ts`, `ios/CatalogueApp/Info.plist`, `docs/reviews/SECURITY.md`.

### 8. What is the testing strategy?

- Vitest covers backend services, adapters, routes, and configuration with fakes and fixtures.
- Swift Testing covers the Domain and Data packages; the API client tests inject a fake `HTTPTransport`.
- ViewModel tests cover app behavior, and the optional live contract test is skipped unless configured.
- Current runs were 83 backend tests, 33 package tests (32 passed and one skipped), and 65 app tests.
- Sources: `backend/test/`, `ios/CatalogueCore/Tests/`, `ios/CatalogueAppTests/`, `docs/MEMORY.md`.

### 9. What did the AI get wrong?

- The first TypeScript lint setup did not parse TypeScript; `typescript-eslint` was later added and the docs had to be corrected.
- A requested read-only review edited CI, and a later task stopped before completing its requested steps.
- I checked and corrected stale commit citations; one old Swift-build citation remains marked ambiguous.
- Sources: `AI_USAGE.md`, `docs/MEMORY.md`, commits `38d756b`, `4528d9b`, `5293750`, `e377757`.

### 10. What would you do with another day?

- First, I would persist enquiries so email delivery failure does not lose them.
- Second, I would run GitHub Actions and use a per-job repository-root working directory.
- Third, I would add a backend image proxy with an allow-list and a failure UI.
- Sources: `DECISIONS.md`, `docs/ARCHITECTURE.md`, `docs/reviews/SECURITY.md`.

### 11. What is verified about Docker and CI?

- The author reported one `docker compose up --build` run on 2026-11-05.
- The backend started, app requests for categories, featured products, and category pages returned 200, and an enquiry email appeared in Mailpit.
- GitHub Actions was not run; the Docker result is a single author report, not a repeated run in this documentation pass.
- Sources: `README.md`, `docs/PR_DESCRIPTION.md`, `docs/reviews/SECURITY.md` (S3).

### 12. Why do images load from an external host?

- `RemoteImage` uses `AsyncImage` with the URL returned in product data, so image traffic bypasses `CatalogueData` and the backend.
- It shows loading and unavailable placeholders, but it does not retry and the mapper does not enforce a host allow-list.
- A proxy is a next step because it needs an allow-list and SSRF controls.
- Sources: `ios/CatalogueApp/DesignSystem/RemoteImage.swift`, `ios/CatalogueCore/Sources/CatalogueData/Mapping/DTOMapper.swift`, `docs/reviews/SECURITY.md` (S1).

## Five small live changes

| Change | Files and tests to touch |
|---|---|
| Change the category top-rated count | `backend/src/services/catalogueService.ts`, `backend/test/catalogueService.test.ts`, and `DECISIONS.md` (A2), after clarifying the requirement. |
| Add a field to an enquiry | `backend/src/domain/enquiry.ts`, `backend/src/http/routes.ts`, `backend/src/services/enquiryService.ts`, `ios/CatalogueCore/Sources/CatalogueDomain/Entities/Enquiry.swift`, `ios/CatalogueCore/Sources/CatalogueDomain/Validation/EnquiryValidator.swift`, `ios/CatalogueCore/Sources/CatalogueData/DTOs/EnquiryDTO.swift`, `ios/CatalogueApp/Presentation/Enquiry/EnquiryViewModel.swift`, and `ios/CatalogueApp/Presentation/Enquiry/EnquiryView.swift`; extend `backend/test/enquiryRoute.test.ts`, `backend/test/enquiryService.test.ts`, `ios/CatalogueCore/Tests/CatalogueDomainTests/DomainModelTests.swift`, `ios/CatalogueCore/Tests/CatalogueDomainTests/UseCaseTests.swift`, `ios/CatalogueCore/Tests/CatalogueDataTests/RemoteEnquiryRepositoryTests.swift`, and `ios/CatalogueAppTests/EnquiryViewModelTests.swift`. |
| Change the featured fallback | `backend/src/services/catalogueService.ts`, `backend/test/catalogueService.test.ts`, and `DECISIONS.md` (A1); also update `backend/src/config.ts` and `backend/test/config.test.ts` if the config contract changes. |
| Add a category sort | `backend/src/services/catalogueService.ts` and `backend/test/catalogueService.test.ts`; keep the API order contract and category display in sync in `docs/ARCHITECTURE.md` and `ios/CatalogueAppTests/CategoryViewModelTests.swift`. |
| Change the search minimum length | `backend/src/http/routes.ts`, `backend/src/services/catalogueService.ts`, `ios/CatalogueCore/Sources/CatalogueDomain/Validation/SearchQuery.swift`, and `ios/CatalogueApp/Presentation/Search/SearchResultsViewModel.swift` (local validation message); update `backend/test/httpRoutes.test.ts`, `backend/test/catalogueService.test.ts`, `ios/CatalogueCore/Tests/CatalogueDomainTests/DomainModelTests.swift`, `ios/CatalogueCore/Tests/CatalogueDomainTests/UseCaseTests.swift`, and `ios/CatalogueAppTests/SearchResultsViewModelTests.swift`. |

## Five facts I must not overclaim

1. I did not test a physical device or VoiceOver, and the app has no runtime Simulator-only check.
2. GitHub Actions has not run. Docker Compose was run once by the author, not independently rerun here.
3. Authenticated SMTP TLS was not verified against a real email provider.
4. Product images use supplied external URLs; there is no backend proxy, host allow-list, or retry action.
5. Exact AI model versions and actual human time were not recorded; the phase breakdown is an estimate from commit timestamps.
