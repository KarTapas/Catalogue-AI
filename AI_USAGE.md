# AI Usage

## Tools and models

The repository history contains `Co-authored-by: Copilot` trailers, and the build work used GitHub Copilot CLI. The author reports using a separate chat assistant for planning and writing the prompts. The recorded engineering tools include Git, npm/Vitest/ESLint/TypeScript, SwiftPM/Xcode, curl, and Mailpit.

## Agent instruction files

| File | How it was actually used |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Read as the repository workflow and command checklist; task prompts repeatedly required it. |
| [`.github/copilot-instructions.md`](.github/copilot-instructions.md) | The Copilot CLI auto-loaded this file for my task sessions; it says to follow `AGENTS.md`. |
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

I skipped the original prompt text for these examples and removed the entries.

## Where the AI got it wrong

| What happened | How it was caught | Fix or current status | Practice from it | Source |
|---|---|---|---|---|
| The first configured npm registry failed DNS during install. The repository evidence does not establish that it was a private registry. | `npm install` failed at registry lookup. | A one-shot public registry override was used; the security review later confirmed no `.npmrc` or private registry URL was committed. | Check registry reachability and resolved lockfile URLs; do not describe the registry as private without evidence. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-04 16:34; [`SECURITY.md`](docs/reviews/SECURITY.md), secrets/history |
| The initial backend start path depended on `.env`, which is absent in a clean container/CI copy. | A real clean-copy start without `.env` produced Node's raw missing-file error. | `npm start` now uses process environment; `start:local` loads `.env`, and startup validates missing configuration. | Test both present-file and absent-file startup paths. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-05 02:23 and 03:10; commit `4c97cb3` |
| The first ESLint setup did not parse TypeScript with ESLint's core parser. | Lint execution exposed the parser mismatch. | ESLint checks its JavaScript config; strict `tsc --noEmit` checks backend source and tests without adding a parser dependency. | Verify what a lint command actually covers; do not say ESLint itself lints TypeScript here. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-04 16:34 and 17:31 |
| iOS builds exposed missing imports/returns in previews, stale preview references, duplicate test names, and a SearchBar initializer error. | The T9/T10 build and test commands failed during compilation. | The compile issues were corrected and the affected suites rerun. | Build after each vertical slice and preserve compiler diagnostics instead of guessing. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-04 22:15 and 22:50; commits `784a386`, `105815b` |
| A name-only simulator destination selected a runtime that was not installed. | `xcodebuild` failed to find that simulator runtime. | The command and `AGENTS.md` were pinned to iPhone SE (3rd generation), iOS 18.0. | Check `xcrun simctl list devices available` and use an installed runtime. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-04 21:30 |
| The iOS CI project path was relative to the wrong working directory. | R1 reproduced `backend/ios/CatalogueApp.xcodeproj` as missing. | Fixed by using `../ios/CatalogueApp.xcodeproj` in commit `4528d9b`; GitHub Actions remains unverified. | Resolve paths from each step's actual working directory and run the workflow on GitHub. | [`REVIEW.md`](docs/reviews/REVIEW.md), R1; commit `4528d9b` |
| Swift grapheme-cluster counting let the client accept names/messages that JavaScript rejected by UTF-16 length. | R3 compared 51 `e` plus combining-acute graphemes against the backend's 102 UTF-16 units. | Client validation and the form counter now use `.utf16.count`; fixed in `5293750`. | Match client/server length semantics and test combining marks and emoji boundaries. | [`REVIEW.md`](docs/reviews/REVIEW.md), R3; commit `5293750` |
| A pass requested as read-only changed `ci.yml` instead of only reporting. | The worktree/diff showed a source change during the review. | The path change was later committed as the explicitly requested R1 fix; the process error is recorded in `MEMORY.md`. | Keep audit and implementation passes separate; check status before and after a read-only review. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-05 11:15; commit `4528d9b` |
| The R3/S2 task stopped early and claimed there was no commit message although the prompt specified one. | The follow-up task restated the unfinished steps and required the named commits. | R3/S2 was completed in `5293750`; reports and memory were committed in `6bc7434`. | Track every requested step through validation and commit; do not invent a blocker. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-05 11:15 |
| A test-only environment variable is read by production `HomeView` to suppress automatic loading. | The XCTest host launched the root view and initially triggered backend calls. | The shared test scheme sets the flag, but `HomeView` still reads it; replacing it with an injected `autoLoad` flag remains open. | Inject test behavior through construction rather than adding test-only process-environment checks to a production view. | [`MEMORY.md`](docs/MEMORY.md), 2026-11-04 21:52; `HomeView.swift`; commit `b918a68` |
| The refresh test asserted only repository call counts, and an empty CatalogueData test inflated the suite count. | Findings R4/R5 in the review report identified the missing state assertions and empty function. | Commit `b77b25c` makes refresh return different second-call values and asserts ordered IDs/names/categories and counts; it removes the empty test. | Assert resulting state and values; remove tests that have no behavior assertion. | [`REVIEW.md`](docs/reviews/REVIEW.md), R4/R5; commit `b77b25c` |

## Time spent

I could not defend time estimates for planning, building, testing, or reviewing, so I have not calculated a total.
