# AGENTS.md

## Read first (every task)
docs/RULES.md, docs/ARCHITECTURE.md, docs/MEMORY.md, then the current task in docs/TASKS.md.

## Project
iOS catalogue app (SwiftUI, MVVM + Clean Architecture) + Node/TypeScript (Fastify) backend.
The app talks ONLY to our backend. Never call Fake Store API from iOS.

## Commands
- Backend: `cd backend && npm test && npm run lint`
- iOS core: `cd ios/CatalogueCore && swift test`
- iOS app: `xcodebuild test -scheme CatalogueApp -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.0'`
- Run all: `docker compose up`

## Hard rules
- Presentation -> Domain <- Data. Domain imports Foundation only.
- No `!`, no `try!`. DI through initialisers. LoadState on every ViewModel.
- Validate on client AND server. No secrets in code.
- One task = one small diff, tests included.

## Workflow
1. Plan in 3-5 bullets; wait for approval on anything architectural.
2. Test first where practical.
3. Run the commands above before saying "done".
4. Tick TASKS.md and append to docs/MEMORY.md (decisions, surprises, mistakes).

## Never
Add dependencies without asking, refactor unrelated files, edit docs/PRD.md, or fabricate test results.
