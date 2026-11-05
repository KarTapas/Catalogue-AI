# AI Usage

## Tools and models

The repository history contains `Co-authored-by: Copilot` trailers, and the build work used GitHub Copilot CLI. **Model name and version:** `TODO(author)`; they are not recorded in the repository. The author reports using a separate chat assistant for planning and writing the prompts; its name and model are `TODO(author)`. The recorded engineering tools include Git, npm/Vitest/ESLint/TypeScript, SwiftPM/Xcode, curl, and Mailpit.

## Agent instruction files

| File | How it was actually used |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Read as the repository workflow and command checklist; task prompts repeatedly required it. |
| [`.github/copilot-instructions.md`](.github/copilot-instructions.md) | It says to follow `AGENTS.md`. I read it while preparing this draft; the repo does not establish whether the CLI auto-loaded it earlier. `TODO(author)` to confirm host behavior. |
| [`.github/agents/planner.agent.md`](.github/agents/planner.agent.md) | Defines a planning-only role. It was not invoked for the implementation; it was read for this curation. |
| [`.github/agents/reviewer.agent.md`](.github/agents/reviewer.agent.md) | Its role text was read and followed when the user asked for a read-only Reviewer pass; it was not launched as a separate subagent. |
| [`.github/agents/security-auditor.agent.md`](.github/agents/security-auditor.agent.md) | Its role text was read and followed for the requested Security Auditor pass; it was not launched as a separate subagent. |
| [`.github/agents/test-writer.agent.md`](.github/agents/test-writer.agent.md) | Defines behavior-focused tests. It was not invoked as a separate agent; tests were written in the task sessions. |
| [`.github/prompts/next-task.prompt.md`](.github/prompts/next-task.prompt.md) | This is a VS Code prompt template; the task prompts came directly from the user, not this file. |
| [`docs/RULES.md`](docs/RULES.md) | Read as the coding and test constraints before implementation and review work. |
| [`docs/MEMORY.md`](docs/MEMORY.md) | Read for prior decisions and mistakes and appended after completed work. |

## Plan / spec

The work followed [`docs/PRD.md`](docs/PRD.md), [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/RULES.md`](docs/RULES.md), [`docs/DESIGN.md`](docs/DESIGN.md), [`docs/TASKS.md`](docs/TASKS.md), and [`docs/MEMORY.md`](docs/MEMORY.md). The T0-T15 sequence split the PoC into ordered vertical slices, with one task and one commit at a time; the history also shows separate review-fix and documentation commits. Prompts were handled one task at a time rather than combining unrelated implementation changes.

## Key prompts / moments (3-5)

1. **Spec and agent setup** (`11933e5`, `Add project docs and agent files`): established the PRD, architecture, rules, task list, and role files. The author should paste the original setup prompt here: `TODO(author)`. This gave later implementation tasks a written boundary.
2. **Task-by-task build prompts** (`2277549` through the T0-T13 task commits): each task asked for a bounded change, tests, commands, and a report of files/results. Original prompt text: `TODO(author)`. The author kept the work in small reviewable slices and requested real command results.
3. **Clean-state backend startup check** (`4c97cb3`, `Make backend start work without an env file`; `MEMORY.md`, 2026-11-05 03:10): a clean copy without `.env` exposed the Node startup failure. The scripts were split into environment-only `npm start` and developer-local `npm run start:local`. Original prompt text: `TODO(author)`. This made the container/CI path independent of a local file.
4. **Read-only Reviewer and Security Auditor pass** (`5238d89`, `Add review and security audit reports`): produced R1-R5 and S1-S3 findings. The author later chose targeted R1/R3/S2/R4/R5 fixes and accepted R2/S1/S3 with reasons in the reports. Original prompt text: `TODO(author)`. One review pass did edit CI despite being read-only; that mistake is recorded below.
5. **Live contract and Mailpit evidence** (`docs/ARCHITECTURE.md`, `MEMORY.md`, 2026-11-05 03:10 and 10:43): a local backend contract run and Mailpit enquiries supplied concrete API, validation, and email evidence. The author chose to document observed results rather than infer them. Original prompt text: `TODO(author)`. These live checks were not repeated during this documentation task.

## Where the AI got it wrong

| What happened | How it was caught | Fix or current status | Practice from it | Source |
|---|---|---|---|---|
| The first configured npm registry failed DNS during install. The repository evidence does not establish that it was a private registry. | `npm install` failed at registry lookup. | A one-shot public registry override was used; the security review later confirmed no `.npmrc` or private registry URL was committed. | Check registry reachability and resolved lockfile URLs; do not describe the registry as private without evidence. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-04 16:34; [`SECURITY.md`](docs/reviews/SECURITY.md), secrets/history |
| The initial backend start path depended on `.env`, which is absent in a clean container/CI copy. | A real clean-copy start without `.env` produced Node's raw missing-file error. | `npm start` now uses process environment; `start:local` loads `.env`, and startup validates missing configuration. | Test both present-file and absent-file startup paths. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-05 02:23 and 03:10; commit `4c97cb3` |
| The first ESLint setup did not parse TypeScript with ESLint's core parser. | Lint execution exposed the parser mismatch. | ESLint checks its JavaScript config; strict `tsc --noEmit` checks backend source and tests without adding a parser dependency. | Verify what a lint command actually covers; do not say ESLint itself lints TypeScript here. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-04 16:34 and 17:31 |
| iOS builds exposed missing imports/returns in previews, stale preview references, duplicate test names, and a SearchBar initializer error. | The T9/T10 build and test commands failed during compilation. | The compile issues were corrected and the affected suites rerun. | Build after each vertical slice and preserve compiler diagnostics instead of guessing. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-04 22:15 and 22:50; commits `784a386`, `105815b` |
| A name-only simulator destination selected a runtime that was not installed. | `xcodebuild` failed to find that simulator runtime. | The command and `AGENTS.md` were pinned to iPhone SE (3rd generation), iOS 18.0. | Check `xcrun simctl list devices available` and use an installed runtime. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-04 21:30 |
| The iOS CI project path was relative to the wrong working directory. | R1 reproduced `backend/ios/CatalogueApp.xcodeproj` as missing. | Fixed by using `../ios/CatalogueApp.xcodeproj` in commit `6917f81`; GitHub Actions remains unverified. | Resolve paths from each step's actual working directory and run the workflow on GitHub. | [`REVIEW.md`](docs/reviews/REVIEW.md), R1; commit `6917f81` |
| Swift grapheme-cluster counting let the client accept names/messages that JavaScript rejected by UTF-16 length. | R3 compared 51 `e` plus combining-acute graphemes against the backend's 102 UTF-16 units. | Client validation and the form counter now use `.utf16.count`; fixed in `ce0ad8e`. | Match client/server length semantics and test combining marks and emoji boundaries. | [`REVIEW.md`](docs/reviews/REVIEW.md), R3; commit `ce0ad8e` |
| A pass requested as read-only changed `ci.yml` instead of only reporting. | The worktree/diff showed a source change during the review. | The path change was later committed as the explicitly requested R1 fix; the process error is recorded in `MEMORY.md`. | Keep audit and implementation passes separate; check status before and after a read-only review. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-05 11:15; commit `6917f81` |
| The R3/S2 task stopped early and claimed there was no commit message although the prompt specified one. | The follow-up task restated the unfinished steps and required the named commits. | R3/S2 was completed in `ce0ad8e`; reports and memory were committed in `64b7908`. | Track every requested step through validation and commit; do not invent a blocker. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-05 11:15 |
| A test-only environment variable is read by production `HomeView` to suppress automatic loading. | The XCTest host launched the root view and initially triggered backend calls. | The shared test scheme sets the flag, but `HomeView` still reads it; replacing it with an injected `autoLoad` flag remains open. | Inject test behavior through construction rather than adding test-only process-environment checks to a production view. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-04 21:52; `HomeView.swift`; commit `b918a68` |
| The refresh test asserted only repository call counts, and an empty CatalogueData test inflated the suite count. | Findings R4/R5 in the review report identified the missing state assertions and empty function. | Commit `04cbf1b` makes refresh return different second-call values and asserts ordered IDs/names/categories and counts; it removes the empty test. | Assert resulting state and values; remove tests that have no behavior assertion. | [`REVIEW.md`](docs/reviews/REVIEW.md), R4/R5; commit `04cbf1b` |

## Time spent

| Phase | Time |
|---|---|
| Planning | TODO(author) |
| Building | TODO(author) |
| Testing | TODO(author) |
| Reviewing | TODO(author) |
| Total | TODO(author) |
