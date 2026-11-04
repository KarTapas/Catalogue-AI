# Branch review: `feature/catalogue-poc` against `main`

Read-only review against `docs/RULES.md` and `docs/ARCHITECTURE.md`. The diff is 158 files, 14,214 additions, and 18 deletions. No implementation files were changed during the review.

**Verdict: CHANGES REQUESTED — 1 high, 2 medium, 2 low.**

## Findings

| ID | File and line | Rule violated | Severity | Evidence command or snippet | Suggested fix |
|---|---|---|---|---|---|
| R1 | `.github/workflows/ci.yml:64-70` | The iOS CI job must build the project from a path that exists in its working directory. | high | The step runs with `working-directory: backend` while invoking `ios/CatalogueApp.xcodeproj`; `test -e backend/ios/CatalogueApp.xcodeproj` reports `missing`. | Run `xcodebuild` from the repository root or use `../ios/CatalogueApp.xcodeproj`. |
| R2 | `ios/CatalogueApp/DesignSystem/RemoteImage.swift:10`; `ios/CatalogueApp/Presentation/ProductDetail/ProductDetailView.swift:40` | iOS must access the network through `CatalogueData`; the PRD says the app never calls Fake Store. | medium | `RemoteImage` uses `AsyncImage(url:)`, and ProductDetailView passes the backend-provided `product.imageURL`. The image is fetched directly by SwiftUI, outside `CatalogueData`. | Proxy images through the backend/data layer, or explicitly revise the network-boundary requirement and document an allowlist and privacy implications. |
| R3 | `backend/src/http/routes.ts:36,48`; `ios/CatalogueCore/Sources/CatalogueDomain/Validation/EnquiryValidator.swift:18,45` | Client and server validation must agree. | medium | For `"e\u0301"` repeated 51 times, JavaScript reports `102` UTF-16 code units while Swift reports `51` grapheme clusters. The name/message pass the client count but exceed the server's Zod `.max()` limit. | Define a shared Unicode normalization and length-counting policy, then apply it on both sides. |
| R4 | `ios/CatalogueAppTests/HomeViewModelTests.swift:154-167` | Tests should assert resulting behavior, not only fake call counts. | low | `refreshReloadsBothSections` asserts only `featured == 2` and `categories == 2`; it does not assert refreshed values or state. | Assert the refreshed featured products and categories in the ViewModel state. |
| R5 | `ios/CatalogueCore/Tests/CatalogueDataTests/CatalogueDataTests.swift:5` | Tests should verify behavior. | low | `catalogueDataTargetBuilds() {}` has no assertions and contributes to the test count. | Remove the empty test or replace it with a behavior assertion. |

## Pass 1 evidence

### CI finding evidence

```text
$ rg -n 'working-directory: backend|xcodebuild' .github/workflows/ci.yml
22: working-directory: backend
64: xcodebuild
70: working-directory: backend

$ test -e backend/ios/CatalogueApp.xcodeproj && echo exists || echo missing
missing
```

### 1. Layering

- `token-goat grep 'import Catalogue|import Foundation' ios/CatalogueCore/Sources/CatalogueDomain --max-lines 100` found only `import Foundation` in CatalogueDomain.
- `token-goat grep 'Repository|APIClient|URLSession|AsyncImage' ios/CatalogueApp/Presentation ios/CatalogueApp/DesignSystem --max-lines 120` found no APIClient references in screens. Repository references are in `*Previews.swift` preview hosts and their fake repositories. `AppContainer` is the production composition root and constructs `URLSessionTransport` from CatalogueData.
- The same network search found `RemoteImage.swift:10` using `AsyncImage`; this is the direct image-network exception recorded as R2.
- `token-goat grep 'adapters|fastify' backend/src/domain backend/src/http/routes.ts --max-lines 100` found no domain imports from adapters/Fastify and no adapter imports in routes. Routes do import Fastify's route types.

### 2. Fake Store isolation

Command and output:

```text
$ rg -n -i 'fakestoreapi' ios
ios/CatalogueCore/Tests/CatalogueDataTests/APIJSONFixtures.swift:7: "https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg"

$ rg --hidden -n -i 'fakestoreapi' . -g '!.git/**' -g '!backend/src/adapters/**' -g '!backend/test/**' -g '!docs/**' -g '!**/node_modules/**' -g '!**/dist/**'
./docker-compose.yml:9: FAKESTORE_BASE_URL: https://fakestoreapi.com
./README.md:72: ... used by the backend only ...
./backend/.env.example:2: FAKESTORE_BASE_URL=https://fakestoreapi.com
./backend/src/config.ts:46: ... https://fakestoreapi.com
./ios/CatalogueCore/Tests/CatalogueDataTests/APIJSONFixtures.swift:7: ... fakestoreapi.com/img/...
```

The literal search finds no Fake Store API call in app implementation code. It does **not** prove the app has no external request: the `AsyncImage` data flow in R2 downloads the `imageURL` received from the backend.

### 3. Swift rules

- Command: `token-goat grep 'try!|as!|fatalError|[A-Za-z0-9_]+!|[)\\]}]!|print\\(|NSLog\\(' ios/CatalogueApp ios/CatalogueCore/Sources --max-lines 100`

  Output: `No matches`; this covers force unwraps/IUO declarations, `try!`, `as!`, `fatalError`, `print`, and `NSLog`.
- Command: `token-goat grep 'Color\\(red:|Color\\(\\.sRGB|\\.font\\(\\.system\\(size:' ios/CatalogueApp/Presentation --max-lines 100`

  Output: `No matches`. Raw spacing and component dimensions:

  ```text
  $ token-goat grep 'spacing: 0|frame\\(minHeight: 128\\)|frame\\(height: 280\\)' ios/CatalogueApp/Presentation --max-lines 100
  EnquiryView.swift:131 frame(minHeight: 128)
  EnquiryView.swift:154,206 safeAreaInset spacing: 0
  ProductDetailView.swift:43 frame(height: 280)
  ProductDetailView.swift:85 safeAreaInset spacing: 0
  ```

  All nonzero visual spacing uses `Spacing` tokens; the three raw spacing values are explicit zero-gap safe-area insets.
- Command: `token-goat grep 'URL\\(string:.*\\+' ios/CatalogueApp ios/CatalogueCore/Sources --max-lines 100`

  Output: `No matches`. `CatalogueData/APIClient.swift` uses `URLComponents` and `URLQueryItem`; `AppConfig.swift` and the DTO mapper also use `URLComponents`.

### 4. TypeScript rules and email content

- `token-goat grep '\\bany\\b|console\\.log' backend/src --max-lines 100` found no TypeScript `any` or `console.log`.
- The `as` matches are `as const` for literal error codes and narrow `globalThis` type extensions in configuration/startup; none bypasses Zod validation.
- `enquiryService.ts:30-34,62-86` removes header control characters and HTML-escapes product title, name, email, phone, and message. `backend/test/enquiryService.test.ts` has tests for header sanitization and HTML escaping.
- `console.info` logs the configured recipient/subject or enquiry/product IDs; no customer field values are logged.

### 5. Money

`token-goat grep 'Float|Double|Money|amount' ios/CatalogueCore/Sources/CatalogueDomain ios/CatalogueCore/Sources/CatalogueData backend/src/domain backend/src/adapters backend/src/http --max-lines 100` found:

- iOS Domain money uses `Decimal`; its DTO uses a decimal `String`.
- Backend Domain money uses a decimal `string`, and the adapter formats upstream prices with `toFixed(2)`.
- `Double` is used for rating values only. No `Float`/`Double` carries money.

### 6. State handling

Command: `token-goat grep 'LoadStateView|LoadState<' ios/CatalogueApp/Presentation ios/CatalogueApp/DesignSystem --max-lines 120`

Output: Home uses `LoadStateView` independently for categories and featured products; Category, Search, and ProductDetail use it for their load states. The shared view handles idle, loading, loaded/empty, and failed/retry states. Search has an explicit no-results state. Enquiry uses its own editing/submitting/succeeded/failed state machine; a list-style empty state does not apply. No missing loading/error handling was identified for the data-fetch screens.

### 7. Test quality and critical paths

The call-only/empty test scan found:

- `HomeViewModelTests.refreshReloadsBothSections`: fake call counts only; see R4.
- `CatalogueDataTests.catalogueDataTargetBuilds`: empty; see R5.

Commands: `token-goat brief 'ios/CatalogueAppTests/HomeViewModelTests.swift::refreshReloadsBothSections'`, `token-goat brief 'ios/CatalogueCore/Tests/CatalogueDataTests/CatalogueDataTests.swift::catalogueDataTargetBuilds'`, and `token-goat grep 'enquir|rate.limit|Content-Type' backend/test --max-lines 120`.

Output: the refresh test contains two call-count expectations and no state/value assertion; the CatalogueData test is an empty function. Enquiry route/service tests cover validation, rate limiting, HTML escaping, header sanitization, and ID-only logging.

Critical-path coverage:

| Path | Tests |
|---|---|
| Featured selection | `backend/test/catalogueService.test.ts`: fallback ranking, configured order, missing IDs/top-up, duplicate removal, and fewer-than-five behavior. |
| Category split | `catalogueService.test.ts` (`splits a case-insensitive category...`) and `backend/test/httpRoutes.test.ts` (`returns the category split for an encoded apostrophe and space`). |
| Search matching | `catalogueService.test.ts`: case-insensitive fields, all-term matching, ranking/ties, invalid lengths, and no matches. |
| Enquiry validation and email content | `backend/test/enquiryRoute.test.ts`, `backend/test/enquiryService.test.ts` (header sanitization, HTML escaping, logs), and `ios/CatalogueAppTests/EnquiryViewModelTests.swift`. |
| Error mapping | `ios/CatalogueCore/Tests/CatalogueDataTests/HTTPErrorMappingTests.swift` and `backend/test/httpRoutes.test.ts` (generic upstream/internal errors). |
| ViewModel state transitions | `HomeViewModelTests`, `CategoryViewModelTests`, `SearchResultsViewModelTests`, `ProductDetailViewModelTests`, and `EnquiryViewModelTests`. |

No listed critical path lacks behavior coverage. The two test-quality issues are R4 and R5.

### 8. Documentation versus code

Command: `rg -n -i 'only to|never to Fake Store|does not call Fake Store directly|HTTP/JSON' README.md docs/ARCHITECTURE.md docs/PRD.md docs/PR_DESCRIPTION.md`

Output: matches at `README.md:6`, `docs/ARCHITECTURE.md:5`, `docs/PRD.md:62`, and `docs/PR_DESCRIPTION.md:7,25`; all conflict with the direct `AsyncImage` path in R2.

- `README.md:6`, `docs/ARCHITECTURE.md:5`, `docs/PRD.md:62`, and `docs/PR_DESCRIPTION.md:7,25` say the app only talks to the backend / never calls Fake Store. That is not true for product images: ProductDetailView passes a backend-provided URL to `AsyncImage`.
- The documented backend, CatalogueCore, and app test counts match the observed results below. The default CatalogueCore run skips the optional live contract test; the configured live run passed it.
- The Mailpit end-to-end result in `docs/ARCHITECTURE.md` and `docs/PR_DESCRIPTION.md` was recorded in the earlier T12 work but was not re-run during this review.
- README/PR documentation correctly says Docker and GitHub Actions were not run. Links to the screenshots and root `DECISIONS.md`/`AI_USAGE.md` resolve.

### 9. Dead code, duplicates, placeholders, and TODOs

- `token-goat grep 'TODO|FIXME|PlaceholderView' ios/CatalogueApp backend/src --max-lines 100` returned no TODO/FIXME or leftover placeholder-view matches. `RemoteImage.placeholder()` is an intentional loading/error presentation, not a leftover feature view.
- No duplicate production implementation was identified in the reviewed paths. No whole-program unused-Swift-symbol analysis was run; the empty CatalogueData test is the only obviously inert tracked source found.

### Test/build commands and results

```text
cd backend && npm test && npm run lint && npm run build
Test Files  8 passed (8)
Tests       80 passed (80)
Lint/build  exited 0

cd ios/CatalogueCore && swift test
CatalogueCore suite: 31 tests; optional live contract test skipped in the offline run; suite passed.

CATALOGUE_LIVE_API_URL=http://127.0.0.1:3000 swift test
CatalogueCore suite: all 31 tests passed, including the live contract test against the running backend/Fake Store adapter.

xcodebuild -project ios/CatalogueApp.xcodeproj -scheme CatalogueApp -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.0' -derivedDataPath ios/build/DerivedData build test
XCTest result: 63 passed, 0 failed.

xcodebuild -project ios/CatalogueApp.xcodeproj -scheme CatalogueApp -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.0' -derivedDataPath ios/build/DerivedData -configuration Release ENABLE_TESTABILITY=YES build
Release simulator build succeeded; strings search found no UI_PREVIEW_ROUTE, enquiry-submit, enquiry-errors, or fake prefill strings.

git diff --check main...HEAD
git diff --check: clean
```

## Things that were checked and are fine

- CatalogueDomain imports Foundation only; backend domain is isolated from adapters and Fastify.
- Product and enquiry API error responses use the documented shape; tests cover upstream/internal error redaction and iOS error mapping.
- Money uses Decimal/decimal strings; rating is the only Double value found.
- The app has no force unwraps, `try!`, `as!`, `fatalError`, print, or NSLog matches.
- Featured, category, search, enquiry, error-mapping, and ViewModel transition paths have behavior tests; real test totals are recorded above.
- Debug-only preview/enquiry hooks are absent from the Release executable.
