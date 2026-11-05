# Catalogue AI

A SwiftUI catalogue app backed by a Node/TypeScript API. This quick start uses the no-Docker backend path and an iPhone Simulator.

## 1. Prerequisites

- macOS (verified here on macOS 26.3.1)
- Xcode 26.6 (used for the app build and Simulator tests)
- Node.js 20 or newer (verified here with Node v24.14.0)
- Docker through OrbStack or Docker Desktop is optional; use it only for Path B.
- Mailpit is optional; the default console provider prints enquiry email summaries in the backend terminal.

## 2. Run the backend

### Path A: no Docker

This is the path verified in a temporary local clone.

```sh
cd backend
cp .env.example .env
npm ci
npm run build
npm run start:local
```

The example configuration sets `EMAIL_PROVIDER=console`. A successful enquiry prints its email summary in this terminal.

**Optional: see real emails in Mailpit.** In another terminal, install and start Mailpit:

```sh
brew install mailpit
mailpit
```

In `backend/.env`, set the following values, then restart the backend with `npm run start:local`:

```dotenv
EMAIL_PROVIDER=smtp
EMAIL_FROM=catalogue@example.test
SALES_INBOX=sales@example.test
SMTP_HOST=localhost
SMTP_PORT=1025
```

Open the Mailpit inbox at <http://localhost:8025>. Mailpit listens for SMTP on port 1025.

### Path B: Docker

```sh
docker compose up --build
```

The backend is at <http://localhost:3000/api/v1/health>; the Mailpit inbox is at <http://localhost:8025>. The author ran `docker compose up --build` on their machine on 2026-11-05. The backend container started; the app's requests for categories, featured products, and category pages all returned HTTP 200; and an enquiry submitted in the app produced an email visible in Mailpit at <http://localhost:8025>. This is a single author-reported run.

## 3. Check the backend before opening the app

Run these from a second terminal while the backend is running:

```sh
curl -sS -w '\nHTTP %{http_code}\n' http://localhost:3000/api/v1/health
curl -sS -w '\nHTTP %{http_code}\n' http://localhost:3000/api/v1/products/featured
curl -sS -w '\nHTTP %{http_code}\n' http://localhost:3000/api/v1/categories
curl -sS -w '\nHTTP %{http_code}\n' "http://localhost:3000/api/v1/categories/men's%20clothing/products"
curl -sS -w '\nHTTP %{http_code}\n' 'http://localhost:3000/api/v1/products/search?q=jacket'
curl -sS -w '\nHTTP %{http_code}\n' http://localhost:3000/api/v1/products/9999
curl -sS -w '\nHTTP %{http_code}\n' 'http://localhost:3000/api/v1/products/search?q=x'
```

Expected results:

| Request | Expected response |
|---|---|
| Health | `200` and `{"status":"ok"}` |
| Featured | `200` and a JSON `Product[]` array of 5 products, IDs `[1, 2, 3, 4, 5]`, with no wrapper object |
| Categories | `200` and `["electronics","jewelery","men's clothing","women's clothing"]` |
| Men's clothing | `200` and `{"category":"men's clothing","topRated":[3 products],"others":[1 product]}` |
| Search for `jacket` | `200` and a JSON `Product[]` array of 4 products, IDs `[3, 17, 16, 15]` |
| Unknown product `9999` | `404` and `{"error":{"code":"NOT_FOUND","message":"Product not found"}}` |
| One-character search | `400` and `{"error":{"code":"VALIDATION_ERROR","message":"Invalid request","details":[{"field":"q","message":"Invalid value"}]}}` |

Each `Product` has `{id:number, title:string, description:string, category:string, price:{amount:string, currency:"USD"}, imageUrl:string, rating:{rate:number, count:number}}`. Money is returned as a decimal string.

## 4. Run the iOS app

Open the Xcode project, select an iPhone Simulator, and press Run:

```sh
open ios/CatalogueApp.xcodeproj
```

**Simulator only.** `localhost` does not reach the Mac from a physical device. The app does not enforce this restriction at runtime.

For the command-line alternative, list available simulators and use the exact command verified here. Substitute a simulator name and OS version that are installed on your machine:

```sh
xcrun simctl list devices available
xcodebuild -project ios/CatalogueApp.xcodeproj -scheme CatalogueApp -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.0' -derivedDataPath ios/build/DerivedData build test
```

## 5. What you should see

1. **Home (US1):** five featured products and category chips.
2. **Category (US2):** tap a category chip to see **Top rated** products first, then **More** products in that category.
3. **Search (US3):** enter `jacket` and tap **Search** to see results; submit a term with no matches to see the empty state. A one-character query keeps the Search button disabled.
4. **Product detail (US4):** tap a product tile to open its detail screen; the **Enquire** button stays pinned at the bottom.
5. **Enquiry (US5):** submit the form empty to see inline errors. Submit valid details to reach **Thank you**; the email appears in Mailpit when using SMTP or as a summary in the backend terminal when using the console provider.

To see the backend error state, stop the backend with Ctrl-C, then pull to refresh on Home. The error screen has a Retry action; the screenshot is [home-error.png](docs/screenshots/home-error.png). Start the backend again and tap **Retry**.

## 6. Running the tests

Backend tests, lint, and build:

```sh
cd backend
npm test
npm run lint
npm run build
```

CatalogueCore package tests:

```sh
cd ios/CatalogueCore
swift test
```

The app build and tests use the Simulator command from section 4. These counts and verification notes reflect the recorded runs for this README:

| Check | Result |
|---|---|
| Backend | 83 tests passed; lint and TypeScript build passed |
| CatalogueCore | 33 tests total: 32 passed and the optional live contract test was skipped |
| iOS app | 65 tests passed; `xcodebuild` reported `TEST SUCCEEDED` |
| Docker Compose | Author-reported run on 2026-11-05: backend started; app requests for categories, featured products, and category pages returned 200; an app-submitted enquiry email appeared in Mailpit at <http://localhost:8025> |
| GitHub Actions | Not run; unverified |
| Physical device | Not tested; unverified |

## Challenges faced and how they were handled

| Challenge | What happened | How it was found | How it was handled | Source |
|---|---|---|---|---|
| npm registry access and lockfile | The configured registry DNS failed during the first install. | The install failed; the lockfile and committed npm configuration were checked afterward. | Used a one-shot public registry override for installation and verified resolved URLs use `registry.npmjs.org`; no private `.npmrc` was committed. | [MEMORY.md, 2026-11-04 16:34 and 17:16](docs/MEMORY.md); [2026-11-05 04:44](docs/MEMORY.md) |
| Local `.env` startup | A clean-state check exposed that `npm start` consumes process-environment values only, while `start:local` loads `.env`. | A temporary clean copy was started with and without `.env`, then checked for health and a clear configuration error. | Kept distinct `start`, `start:local`, and `dev` paths; the README uses `start:local` after copying `.env.example`. | [MEMORY.md, 2026-11-05 02:23 and 03:10](docs/MEMORY.md); commit `4c97cb3` |
| TypeScript linting | ESLint's core parser could not parse TypeScript. | The first TypeScript lint setup failed on `.ts` files. | Without adding a dependency, ESLint checks its JavaScript config and strict `tsc` checks backend source and tests. | [MEMORY.md, 2026-11-04 17:16](docs/MEMORY.md) |
| Fake Store has no search or featured endpoints | Those app features could not be delegated to the upstream API. | The upstream adapter and API behavior were checked during T1/T2. | The backend derives featured products and search results from the product list. | [MEMORY.md, 2026-11-04 16:34](docs/MEMORY.md); commit `d7b2ecf` |
| Category names contain spaces and apostrophes | A name such as `men's clothing` must remain a single category path segment. | The category request and URL construction were checked in adapter and live API work. | URL-encode the category name as one path segment; the encoded request is shown above. | [MEMORY.md, 2026-11-04 16:34](docs/MEMORY.md); [SECURITY.md §4](docs/reviews/SECURITY.md) |
| Generated Xcode project and xcconfig URL | The project is generated with XcodeGen, and `//` in an xcconfig URL is parsed as a comment. | Project generation and the Debug base URL were checked during the iOS scaffold. | Committed the generated `.xcodeproj`; used `http:/$()/localhost:3000` in Debug xcconfig to preserve the URL. | [MEMORY.md, 2026-11-04 21:30](docs/MEMORY.md) |
| App Transport Security | Local Simulator development needs HTTP, but arbitrary insecure loads must stay disabled. | The ATS configuration was reviewed with the app configuration. | Added an exception for `localhost` only; no `NSAllowsArbitraryLoads`. | [MEMORY.md, 2026-11-04 21:30](docs/MEMORY.md) |
| Simulator runtime selection | A name-only Xcode destination selected a runtime that was not installed. | The Simulator build failed to resolve that destination. | Pinned the working command to iPhone SE (3rd generation), iOS 18.0; use a device name and runtime installed on your machine. | [MEMORY.md, 2026-11-04 21:30](docs/MEMORY.md) |
| Backend-down Home state | A stopped backend should produce a recoverable error rather than a blank screen. | Backend-down and loaded Home screenshots were checked. | Home presents an error state with Retry; pull to refresh and retry are described above. | [MEMORY.md, 2026-11-04 21:52](docs/MEMORY.md); commit `b918a68` |
| iOS CI project path (R1) | The iOS CI step ran from `backend/` but used a repository-root project path. | The review checked path resolution from the job working directory. | Fixed the CI project path in commit `6917f81`; GitHub Actions itself remains unverified. | [R1, REVIEW.md](docs/reviews/REVIEW.md) |
| Client/server string lengths (R3) | Swift grapheme-cluster counts could accept strings that the backend rejects by UTF-16 length. | Review used repeated `e` plus combining acute accent as a counterexample. | Aligned client validation and the visible counter to UTF-16 code units. | [R3, REVIEW.md](docs/reviews/REVIEW.md); commit `ce0ad8e` |
| Product image loading (R2/S1) | Images load directly from Fake Store-provided URLs (`fakestoreapi.com` in the checked data) and may remain slow or show an unavailable placeholder on network failure. | Review noted `AsyncImage` bypasses `CatalogueData`; screenshots also showed image placeholders still loading. | `RemoteImage` shows loading and unavailable placeholders, but has no retry action. An image proxy is a next step and needs SSRF controls. | [R2, REVIEW.md](docs/reviews/REVIEW.md); [S1, SECURITY.md](docs/reviews/SECURITY.md); [MEMORY.md, 2026-11-04 22:50](docs/MEMORY.md) |
| Docker Compose verification | The author reported on 2026-11-05 that `docker compose up --build` started the backend, app requests for categories, featured products, and category pages returned 200, and an app-submitted enquiry email appeared in Mailpit. | The author reported the container startup, app responses, and visible Mailpit email. | Record the single manual run; GitHub Actions and physical-device use remain unverified. | Author report (2026-11-05); [S3, SECURITY.md](docs/reviews/SECURITY.md) |
| Read-only review changed CI | A review pass that was meant to report only also edited `ci.yml`. | The change was noticed during the follow-up review and worktree inspection. | Tracked the path issue as R1 and made the fix in a separate commit. | [MEMORY.md, 2026-11-05 11:15](docs/MEMORY.md); commit `6917f81` |
| R3/S2 task stopped early | A follow-up task skipped requested steps and incorrectly claimed no commit message was given. | The unfinished checklist was compared with the original prompt. | Resumed the remaining checks and recorded the fixes and documentation in separate commits. | [MEMORY.md, 2026-11-05 11:15](docs/MEMORY.md); commits `ce0ad8e` and `64b7908` |
| Swift build errors during implementation | Builds exposed stale previews, missing returns/imports, duplicate test names, and unsupported accessibility modifiers. | Compiler diagnostics identified each issue. | Corrected the affected code and reran the relevant build and test commands. | [MEMORY.md, 2026-11-04 21:52, 22:15, 22:50; 2026-11-05 12:31](docs/MEMORY.md); commit `d087cb9` |

TODO(author): Rephrase or confirm the AI-process challenge rows in your own words.

With another day, the first listed candidate is to persist enquiries so a failed email does not lose them; the priority order is still for the author to confirm in [DECISIONS.md](DECISIONS.md#what-i-would-do-next-with-another-day).

## Troubleshooting

| Problem | What to check |
|---|---|
| The app says “Unable to connect” | Start the backend with `npm run start:local` from `backend/`. |
| Port 3000 is already in use | Run `lsof -nP -iTCP:3000 -sTCP:LISTEN`; stop only a process you own. |
| Missing `.env` or `EMAIL_FROM` | Copy `.env.example` to `.env`. If configuration validation fails, its diagnostic names the missing variable, such as `EMAIL_FROM`. |
| Images are slow or blank | Images load from `fakestoreapi.com` and require internet access. `RemoteImage` shows an unavailable placeholder but does not retry. |
| No simulator runtime or the destination name is not found | Run `xcrun simctl list devices available` and choose an installed simulator name and OS version. |
| `docker` command not found | Docker is optional for Path A; install OrbStack or Docker Desktop only if you want Path B. |
| Xcode asks to trust or install components | Follow Xcode's prompt and allow the requested platform components to finish installing. |
| The generated Xcode project needs regeneration | XcodeGen is needed only after changing `ios/project.yml`; run `cd ios && xcodegen`. |

## More information

[Architecture](docs/ARCHITECTURE.md) · [PRD](docs/PRD.md) · [Tasks](docs/TASKS.md) · [Decisions](DECISIONS.md) · [Review](docs/reviews/REVIEW.md) · [Security review](docs/reviews/SECURITY.md) · [AI usage](AI_USAGE.md)

## Time spent

| Phase | Time |
|---|---|
| Planning | TODO(author) |
| Building | TODO(author) |
| Testing | TODO(author) |
| Reviewing | TODO(author) |
| Total | TODO(author) |
