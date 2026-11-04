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
    Domain/               entities, repository protocols, use cases
    Data/                 APIClient, DTOs, mappers, repository implementations
  CatalogueApp/           SwiftUI app
    Presentation/         Views, ViewModels (@Observable), Navigation
    DesignSystem/         tokens + reusable components
    Composition/          DI container, Config (API base URL)
```

## Dependency rule
`Presentation -> Domain <- Data`. Domain imports Foundation only. DTOs never leave Data. Views never touch repositories directly, only ViewModels via use cases.
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

## Security basics
Validate with zod at the edge. Rate-limit `/enquiries`. Sanitise CR/LF out of any value placed in email headers. Escape user text in HTML email. CORS minimal. No secrets in code. ATS exception for `localhost` only.

## Extension points (the "grow" story)
| Change | Where |
|---|---|
| New product source | New `ProductSource` adapter; iOS unchanged |
| New email provider | New `EmailSender` adapter (SES etc.) |
| New look and feel | `DesignSystem/` tokens and components |
| Persist enquiries | New `EnquiryRepository` port + adapter |
