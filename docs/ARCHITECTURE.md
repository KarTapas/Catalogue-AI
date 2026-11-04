# Architecture

## System
```
iOS app (SwiftUI) --HTTP/JSON--> Backend (Fastify, TS) --> Fake Store API
                                         |
                                         +--SMTP--> Mailpit (dev) / real provider later
```

## Repo layout
```
backend/                  routes -> services -> ports; adapters implement ports
  src/domain/             Product, Enquiry, errors, ports (ProductSource, EmailSender)
  src/services/           catalogue logic (featured, category split, search), enquiry
  src/adapters/           FakeStoreProductSource, SmtpEmailSender, ConsoleEmailSender
  src/http/               Fastify routes, schemas (zod), error handler
ios/
  CatalogueCore/          local Swift Package (swift test, no UI)
    Package.swift         separate CatalogueDomain and CatalogueData targets
    Sources/
      CatalogueDomain/    Foundation-only entities, protocols, validation, use cases
      CatalogueData/      API client, DTOs, mappers, repository implementations
    Tests/
      CatalogueDomainTests/
      CatalogueDataTests/
  CatalogueApp/           SwiftUI app
    Presentation/         Views, ViewModels (@Observable), Navigation
    DesignSystem/         tokens + reusable components
    Composition/          DI container, Config (API base URL)
```

## Dependency rule
`Presentation -> Domain <- Data`. Domain imports Foundation only. DTOs never leave Data. Views never touch repositories directly, only ViewModels via use cases.
The Swift package has two library targets: `CatalogueData` depends on `CatalogueDomain`, while `CatalogueDomain` has no target dependencies. SwiftPM therefore prevents Domain from importing Data at compile time.
Backend: `http -> services -> domain <- adapters`.

## iOS patterns
- MVVM: `@Observable` ViewModel per screen exposing `LoadState<T>` = idle | loading | loaded(T) | failed(AppError).
- Use cases are small structs with `execute(...) async throws`.
- DI via initialisers; one `AppContainer` builds the graph. Previews/tests inject fakes.
- Async/await only. `NavigationStack` with typed routes.

## API contract (base `/api/v1`)
| Method | Path | Returns |
|---|---|---|
| GET | `/health` | `{status:"ok"}` |
| GET | `/products/featured` | `Product[]` (5) |
| GET | `/categories` | `string[]` |
| GET | `/categories/:name/products` | `{category, topRated: Product[], others: Product[]}` |
| GET | `/products/search?q=` | `Product[]` |
| GET | `/products/:id` | `Product` |
| POST | `/enquiries` | `202 {id}` |

`Product`: `{id:number, title, description, category, price:{amount:string, currency:"USD"}, imageUrl, rating:{rate:number,count:number}}`
Money is a string or integer minor units. Never a binary float in the domain.

`POST /enquiries` body: `{productId, name, email, phone?, message}`

## Error model
All errors: `{error:{code, message, details?}}`
Codes: `VALIDATION_ERROR` (400), `NOT_FOUND` (404), `UPSTREAM_UNAVAILABLE` (502), `RATE_LIMITED` (429), `INTERNAL` (500).
iOS maps these to `AppError` with user-friendly messages.

## iOS Data layer
`CatalogueData` depends on `CatalogueDomain` and Foundation only. `APIClient` receives its base URL through `APIConfiguration` and sends requests through the injectable `HTTPTransport`; production uses an ephemeral, no-cache URL session with a 10-second timeout. Internal DTOs are mapped to Domain entities in one place, including parsing decimal-string prices with a POSIX locale. Tests inject a fake transport and do not use the network.

| Response or transport failure | Domain result |
|---|---|
| Connectivity, DNS, connection loss, or timeout `URLError` | `AppError.unreachable` |
| `400 VALIDATION_ERROR` | `AppError.validation(fields:)`, populated from `details` |
| `404` | `AppError.notFound` |
| `429` | `AppError.rateLimited` |
| `502` or another `5xx` | `AppError.serverUnavailable` |
| Malformed response, unexpected status, or other transport error | `AppError.unexpected` |
| Task cancellation | `CancellationError` (propagated unchanged) |

## API examples
Trimmed responses captured by a live smoke test against the Fake Store API:

| Request | Response |
|---|---|
| `curl -i http://localhost:3000/api/v1/health` | `200 {"status":"ok"}` |
| `curl -i http://localhost:3000/api/v1/products/featured` | `200 Product[5]`, IDs `[12, 11, 3, 18, 5]` |
| `curl -i http://localhost:3000/api/v1/categories` | `200 ["electronics","jewelery","men's clothing","women's clothing"]` |
| `curl -i "http://localhost:3000/api/v1/categories/men's%20clothing/products"` | `200 {"category":"men's clothing","topRated":3,"others":1}` |
| `curl -i 'http://localhost:3000/api/v1/products/search?q=jacket'` | `200 Product[4]`, IDs `[3, 17, 16, 15]` |
| `curl -i http://localhost:3000/api/v1/products/1` | `200 Product`, ID `1`, title `Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops` |
| `curl -i http://localhost:3000/api/v1/products/9999` | `404 {"error":{"code":"NOT_FOUND","message":"Product not found"}}` |

### Enquiries

`POST /api/v1/enquiries` accepts `productId`, `name`, `email`, optional `phone`, and `message`. It emails the configured sales inbox without storing the enquiry; successful delivery returns `202 {"id":"..."}`. Validation errors return `400 VALIDATION_ERROR`, an unknown product returns `404 NOT_FOUND`, delivery failures return a generic `502 UPSTREAM_UNAVAILABLE`, and the route is limited to five requests per minute per IP (`429 RATE_LIMITED`).

Requests and trimmed responses captured by the live console-email smoke test:

| Request | Response |
|---|---|
| `curl -i -X POST http://localhost:3000/api/v1/enquiries -H 'content-type: application/json' -d '{"productId":1,"name":"Live Smoke Test","email":"customer@example.test","phone":"+1 (555) 010-1234","message":"Smoke enquiry"}'` | `202 {"id":"77296a67-68e8-462a-bacd-71916df499fd"}` |
| `curl -i -X POST http://localhost:3000/api/v1/enquiries -H 'content-type: application/json' -d '{"productId":1,"name":"Live Smoke Test","email":"not-an-email","message":"Smoke enquiry"}'` | `400 {"error":{"code":"VALIDATION_ERROR","message":"Invalid request","details":[{"field":"email","message":"Invalid value"}]}}` |
| `curl -i -X POST http://localhost:3000/api/v1/enquiries -H 'content-type: application/json' -d '{"productId":9999,"name":"Live Smoke Test","email":"customer@example.test","message":"Smoke enquiry"}'` | `404 {"error":{"code":"NOT_FOUND","message":"Product not found"}}` |

### Verified end to end

With Mailpit v1.33.0, a valid enquiry returned `202` with id `6e6fa904-01f3-44c3-b13f-b742818cc659`. Mailpit received subject `New enquiry: Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops (#1)` at `sales@example.test`, with Reply-To `smtp.test@example.test`; the body contained the product, customer details, and requested message. A name containing CR/LF followed by `Bcc:` returned `400 VALIDATION_ERROR`; Mailpit remained at one message with no Bcc. The app's `enquiry-submit:1` route delivered a second message with Reply-To `test.customer@example.test`.

## Security basics
Validate with zod at the edge. Rate-limit `/enquiries`. Sanitise CR/LF out of any value placed in email headers. Escape user text in HTML email. CORS minimal. No secrets in code. ATS exception for `localhost` only.

## Extension points (the "grow" story)
| Change | Where |
|---|---|
| New product source | New `ProductSource` adapter; iOS unchanged |
| New email provider | New `EmailSender` adapter (SES etc.) |
| New look and feel | `DesignSystem/` tokens and components |
| Persist enquiries | New `EnquiryRepository` port + adapter |
