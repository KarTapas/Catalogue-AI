# Catalogue AI

## 1. What this is

A product catalogue app with featured products, categories, search, product details and enquiries.
The SwiftUI app talks only to the project backend; it never calls Fake Store directly.
Enquiries are sent through a replaceable email adapter, with console and SMTP options.

Screenshots: [Home](docs/screenshots/home.png), [Category](docs/screenshots/category-mens-clothing.png), [Search](docs/screenshots/search-jacket.png), [Product detail](docs/screenshots/product-1.png), [Enquiry form](docs/screenshots/enquiry-form.png), [Validation errors](docs/screenshots/enquiry-errors.png), [Thank you](docs/screenshots/enquiry-thank-you.png), [Large text](docs/screenshots/product-large-text.png).

## 2. Tech choices

- **iOS:** Swift and SwiftUI with MVVM and Clean Architecture keep views testable and the domain independent of presentation.
- **Backend:** Node.js, TypeScript and Fastify provide a small typed HTTP API with replaceable data and email adapters.

## 3. Architecture

```text
iOS:      SwiftUI Views -> Presentation/ViewModels -> Domain <- Data
Backend:   HTTP routes -> Services -> Domain ports <- Adapters
                                               ProductSource -> Fake Store
                                               EmailSender -> Console / SMTP
```

Dependency rule: **Presentation -> Domain <- Data**; the domain imports Foundation only. Backend adapters implement domain ports, while routes and services depend on the domain. The main swap points are `ProductSource` (Fake Store or another catalogue), `EmailSender` (console or SMTP), and the iOS `DesignSystem` (shared components and tokens). See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## 4. Quick start

### Path A: Docker

```sh
docker compose up
```

The backend is on port 3000 and Mailpit's web UI is at <http://localhost:8025>.

### Path B: no Docker

```sh
cd backend
cp .env.example .env
npm ci
npm run build
npm run start:local
```

The example uses `EMAIL_PROVIDER=console`; an email summary is printed in the backend terminal. To receive SMTP mail, install and start Mailpit in another terminal, then start the backend with:

```sh
brew install mailpit
mailpit
```

```sh
cd backend
EMAIL_PROVIDER=smtp SMTP_HOST=localhost SMTP_PORT=1025 npm run start:local
```

### Run the iOS app

```sh
open ios/CatalogueApp.xcodeproj
```

Choose an iPhone Simulator in Xcode and press Run. **Simulator only; `localhost` does not work from a physical device.** See enquiries in Mailpit at <http://localhost:8025>, or read the email summary in the backend terminal when using the console provider.

## 5. Configuration

| Variable | Meaning | Example/default |
|---|---|---|
| `PORT` | Backend listen port | `3000` |
| `FAKESTORE_BASE_URL` | Upstream catalogue base URL, used by the backend only | `https://fakestoreapi.com` |
| `FEATURED_IDS` | Comma-separated featured product IDs | `1,2,3,4,5`; empty uses rating-based selection |
| `SALES_INBOX` | Enquiry recipient | `sales@example.test` |
| `EMAIL_FROM` | Sender address; required and must be configured for your mail provider | `catalogue@example.test` in the example |
| `EMAIL_PROVIDER` | `console` or `smtp` | `console` |
| `SMTP_HOST` | SMTP server hostname | `mailpit` in Docker; `localhost` without Docker |
| `SMTP_PORT` | SMTP server port | `1025` |
| `SMTP_USER` | Optional SMTP username; set together with `SMTP_PASS` | Unset |
| `SMTP_PASS` | Optional SMTP password; set together with `SMTP_USER` | Unset |
| `API_BASE_URL` (Debug) | iOS backend URL in `ios/CatalogueApp/Config/Debug.xcconfig` | `http://localhost:3000` |

For a different local port, change backend `PORT` and the port in Debug `API_BASE_URL` to match. With Docker, change the published host port and the Debug URL together; keep the container listening on port 3000.

## 6. Running tests

Backend tests, lint and build:

```sh
cd backend
npm test
npm run lint
npm run build
```

CatalogueCore tests:

```sh
cd ios/CatalogueCore
swift test
```

For the optional live contract test, start the backend first and run:

```sh
cd ios/CatalogueCore
CATALOGUE_LIVE_API_URL=http://127.0.0.1:3000 swift test
```

App build and tests: list installed simulators, then select an available iPhone. The command below worked here with an iPhone SE (3rd generation) on iOS 18.0; simulator names depend on installed runtimes.

```sh
xcrun simctl list devices available
xcodebuild -project ios/CatalogueApp.xcodeproj -scheme CatalogueApp -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.0' -derivedDataPath ios/build/DerivedData build test
```

Most recently verified counts: backend **80 tests**, CatalogueCore **31 tests** (the default run skips the optional live test; a separate configured run passed it), and app **63 tests**.

## 7. API summary

All paths are relative to `/api/v1`.

| Method | Path | Result |
|---|---|---|
| `GET` | `/health` | `{"status":"ok"}` |
| `GET` | `/products/featured` | Five featured products |
| `GET` | `/categories` | Category names |
| `GET` | `/categories/:name/products` | Category, top-rated products and remaining products |
| `GET` | `/products/search?q=...` | Matching products |
| `GET` | `/products/:id` | One product |
| `POST` | `/enquiries` | `202` with an enquiry ID |

Errors use `{ "error": { "code": "...", "message": "...", "details": [...] } }` (`details` is optional). Codes include `VALIDATION_ERROR`, `NOT_FOUND`, `UPSTREAM_UNAVAILABLE`, `RATE_LIMITED` and `INTERNAL`.

## 8. Project layout

```text
backend/                 Fastify API, domain, adapters and tests
ios/CatalogueCore/       Domain, data layer and package tests
ios/CatalogueApp/        SwiftUI app, presentation and design system
docs/                    Architecture, product brief, tasks and screenshots
.github/workflows/       CI workflow
docker-compose.yml       Backend and Mailpit services
```

## 9. Troubleshooting

| Problem | What to check |
|---|---|
| App says the backend is unreachable | Start the backend and use Retry in the app. |
| Port 3000 is already in use | Inspect the listener with `lsof -nP -iTCP:3000 -sTCP:LISTEN`; stop only a process you own or choose another port and update Debug `API_BASE_URL`. |
| Missing `.env` or `EMAIL_FROM` | For local setup, copy `backend/.env.example` to `backend/.env` and set `EMAIL_FROM`. Docker receives configuration from Compose; `npm start` without required environment values prints a configuration error. |
| No iPhone simulator is available | Run `xcrun simctl list devices available` and install an iOS Simulator runtime in Xcode. |
| App Transport Security blocks a request | Debug permits HTTP only for `localhost` for Simulator development. A physical device is not supported; do not broaden the exception. |
| Xcode project needs regeneration | XcodeGen is only needed after editing `ios/project.yml`: run `cd ios && xcodegen`. |

## 10. Verification status

| Area | Status and evidence |
|---|---|
| Backend unit tests, lint and build | Verified: 80 tests, lint and TypeScript build passed. |
| Backend startup modes | Verified in a clean copy: `start:local` with `.env` and `npm start` with environment-only configuration returned health 200; no configuration exits 1 with a clear missing-`EMAIL_FROM` message and no stack trace. |
| CatalogueCore tests | Verified: the default 31-test suite passed with the optional live test skipped; a separate run with `CATALOGUE_LIVE_API_URL` set passed all 31, including the live contract test. |
| iOS app tests | Verified: 63 tests passed on iPhone SE (3rd generation), iOS 18.0. |
| Release build and preview hooks | Verified: Release Simulator build passed; `UI_PREVIEW_ROUTE` and `enquiry-submit` are absent from its executable. |
| Mailpit enquiry flow | Verified end to end; a valid API enquiry and the app test enquiry reached Mailpit. See the [architecture notes](docs/ARCHITECTURE.md#verified-end-to-end). |
| Simulator screenshots | Captured under [`docs/screenshots`](docs/screenshots/), including the product, enquiry form, validation errors and thank-you state. |
| Docker image and Compose startup | Not verified; Docker is not installed on this machine. |
| GitHub Actions | Workflow YAML parsed locally; execution remains unverified until it runs on GitHub. |
| Swift linting | SwiftLint is not configured; adding it is a follow-up and was intentionally not included here. |
| Physical device, VoiceOver, Dynamic Type beyond the captured screenshots | Not verified. |

## 11. Time spent

| Phase | Time |
|---|---|
| Planning | TODO(author) |
| Building | TODO(author) |
| Testing | TODO(author) |
| Reviewing | TODO(author) |
| Total | TODO(author) |

## 12. More information

[DECISIONS.md](DECISIONS.md) · [AI_USAGE.md](AI_USAGE.md) · [AGENTS.md](AGENTS.md) · [docs/](docs/) · [PRD](docs/PRD.md) · [Architecture](docs/ARCHITECTURE.md) · [Tasks](docs/TASKS.md)
