# Tasks
Do them in order. One task per PR-sized change. Each follows AGENTS.md workflow.

- [x] T0 Repo skeleton, docker-compose (backend + Mailpit), .env.example, CI stub
- [x] T1 Backend: domain types + `ProductSource` port + `FakeStoreProductSource` (+ tests with fixture)
- [x] T2 Backend: catalogue service (featured, category split, search) (+ unit tests)
- [x] T3 Backend: HTTP routes, zod validation, error handler (+ route tests)
- [x] T4 Backend: `EmailSender` port, Console + SMTP adapters, enquiry service + route, rate limit, sanitising (+ tests)
- [x] T5 iOS Core: Domain entities, protocols, use cases (+ tests)
- [ ] T6 iOS Core: APIClient, DTOs, mappers, repositories (+ tests with stubbed URLProtocol)
- [ ] T7 iOS App: DesignSystem, AppContainer, Config, ATS localhost exception
- [ ] T8 iOS: Home (featured + categories)
- [ ] T9 iOS: Category page
- [ ] T10 iOS: Search
- [ ] T11 iOS: Product detail
- [ ] T12 iOS: Enquiry form + Thank you
- [ ] T13 CI (backend tests, swiftlint, swift test, xcodebuild test)
- [ ] T14 Review pass with Reviewer + Security agents; fix findings
- [ ] T15 README, DECISIONS.md, AI_USAGE.md curated from MEMORY.md; real time log

## Definition of Done (each task)
Tests written and passing, lint clean, rules respected, docs ticked, MEMORY.md appended.
