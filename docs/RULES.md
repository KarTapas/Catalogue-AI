# Rules

## General
1. One task = one small diff, with tests in the same change.
2. Do not add dependencies without asking. Prefer the standard library.
3. Never call Fake Store API from iOS. Only the backend adapter may.
4. No secrets in code or git. Config via `.env` (see `.env.example`) and xcconfig.
5. Follow ARCHITECTURE.md boundaries. If a rule blocks you, stop and ask.

## Swift
- Swift 5.9+/6, iOS 17+, SwiftUI, `@Observable`, async/await.
- No force unwrap (`!`), no `try!`, no `fatalError` in app code.
- Domain imports Foundation only. No DTOs, no SwiftUI in Domain.
- DI through initialisers. No singletons except the composition root.
- Every ViewModel exposes `LoadState`; every screen has loading, empty and error UI with Retry.
- Types: `struct` by default; `final class` only when needed. Mark `@MainActor` on ViewModels.
- Build URLs with `URLComponents` / `URLQueryItem` (never string concatenation) so `men's clothing` is encoded.
- Accessibility: labels on images and buttons, Dynamic Type friendly, no colour-only meaning.
- ATS: exception for `localhost` only. Never `NSAllowsArbitraryLoads`.

## TypeScript (backend)
- `strict` mode, no `any`. Validate all inputs with zod.
- Routes are thin; logic lives in services; I/O lives in adapters behind ports.
- Errors are typed and mapped to the error model in one place.
- Never put raw user input into email headers; strip CR/LF; escape HTML.

## Testing
- Test behaviour, not mocks. A test that only asserts "mock was called" is not enough.
- Critical path must be covered: featured selection, category split, search matching, enquiry validation, error states.
- Backend: Vitest, with a fake `ProductSource` and fake `EmailSender`. iOS: Swift Testing / XCTest with fake repositories.
- Tests are deterministic. No real network.

## Definition of Done
Builds, tests pass, lint clean, no rule violations, TASKS.md ticked, MEMORY.md appended.
