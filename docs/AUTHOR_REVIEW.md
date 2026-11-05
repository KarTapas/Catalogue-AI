# Documentation self-review

I checked factual claims in `README.md`, `DECISIONS.md`, `AI_USAGE.md`, and `docs/PR_DESCRIPTION.md` against the current source, project configuration, review reports, memory log, and Git history. I kept historical results labeled as earlier runs or author reports and did not change application code, tests, or configuration.

## Corrections and clarifications

| File and line | Original claim or wording | What was wrong or incomplete | What I changed |
|---|---|---|---|
| `README.md:3-5` | The introduction said the app was backed by the API without describing the image path. | The accepted R2/S1 behavior fetches product image URLs directly from their supplied host; product metadata and enquiries use the backend. | I added the boundary explicitly: metadata and enquiries go through the backend, while images are not proxied. |
| `README.md:153` | The TypeScript lint row said no parser dependency had been added and ESLint only checked its JavaScript config. | That was true of the initial setup, but stale: commit `38d756b` added `typescript-eslint`, and the current config applies its type-checked rules to TypeScript source and tests. | I documented the initial failure and current lint behavior, citing the commit and config. |
| `README.md:131-145` | The verification table showed the three suite counts and only a few unverified checks. | It did not distinguish this pass from earlier live checks and omitted screenshots, VoiceOver, and authenticated SMTP TLS status. | I recorded current suite results separately from earlier live checks and the author-reported Compose run, and listed the requested unverified checks. |
| `README.md:153-162` | Review/fix references used short commit IDs from the earlier history. | Several IDs did not resolve in the current history. One Swift-build reference could not be matched to a single current commit. | I updated unambiguous citations and kept the ambiguous reference with the required history-rewrite note rather than guessing. |
| `DECISIONS.md:5-23` | Assumption reasons and effort ratings were incomplete. | The PRD records requirements but not every business rationale; effort also depends on which backend and iOS files change. | I wrote first-person reasons tied to named sources, used the prescribed not-recorded wording where no rationale was supported, and rated each change with relevant files. |
| `DECISIONS.md:25-47` | Some alternatives and selection rationales were stated as though they had been recorded; one row could imply reviewer agents were launched. | Several alternatives were not in the PRD, memory, or brief, and the repository does not record why Fastify or XcodeGen was selected. `AI_USAGE.md` says the Reviewer and Security Auditor role text was followed, not launched as subagents. | I kept only source-supported alternatives, described following role guidance rather than launching agents, and used “alternatives not recorded” or the prescribed not-recorded rationale elsewhere. |
| `DECISIONS.md:72-92` | The growth row said Compose had not been run, and the next-day list treated the priority order as unconfirmed. | The author reported a Compose run on 2026-11-05, and the current task specified the first three follow-ups and their order. | I recorded the author's exact reported outcome, made no AWS-deployment claim, and reordered follow-ups as requested. |
| `AI_USAGE.md:5-31,50-61` | Tool/model and prompt details were placeholders or broad summaries. | Exact model versions and human time were not recorded; the requested prompt excerpts were supplied by the author. | I used the author's tool facts, stated that versions were not recorded, and replaced the prompt section with exactly four sourced moments. |
| `AI_USAGE.md:39-53` | The lint row said TypeScript was not linted, and several review-fix citations used old IDs. | The current config lints TypeScript, and multiple short IDs no longer resolved. | I described the initial parser failure and later `typescript-eslint` setup, then updated the resolvable commit references. |
| `docs/PR_DESCRIPTION.md:59-108` | Test counts and Docker status were drawn from earlier notes; AI details and follow-up priorities still needed author input. | The current counts were available from fresh runs; Docker was an author report, and the model versions and authenticated SMTP TLS result were not recorded. | I added a status table with current, earlier, author-reported, and unverified checks; updated AI/time details; and replaced the remaining placeholders with sourced statements. |
| `docs/reviews/REVIEW.md:13-17,131-133,176` | Fix references were stale, and the review-time Docker status read like the current status. | The fixes have current commit IDs; the review's Docker statement predates the later author report. | I updated the IDs and explicitly dated the earlier review status. |
| `docs/reviews/SECURITY.md:12,170` | S2 referenced an old commit ID. | The ID no longer resolves in the current history. | I replaced it with the current R3/S2 fix commit. S3 already recorded the single author-reported Compose run and mutable tags, so I left that finding's substance unchanged. |
| `docs/MEMORY.md:60,70-74` | Earlier entries said Docker was not run or unverified, and one fix citation was stale. | Those entries predate the author's later Compose report; without a time qualifier they looked contradictory. | I marked the old status as historical, updated the fix citation, and appended this pass's results and the output-filter mistake. |

The original PRD and architecture constraint text remains as recorded; the accepted R2/S1 image exception is stated in the current README, PR description, and review reports. I did not edit `docs/PRD.md`.

## Not-recorded rationales

The source does not record why the category count is three, why search ranking prefers title matches, why Simulator was the target, why malformed records use the current skip/fail policy, why Fastify was selected, or why XcodeGen was selected. Those cases are labeled as not recorded in `DECISIONS.md`; I did not infer a product or framework rationale.

## Candidate evidence checked

| Candidate | Result |
|---|---|
| A planning-chat example image URL returned 404 | I did not add this as an AI error: I found no supporting entry in the memory log, review reports, or Git history. The recorded image checks identify the supplied Fake Store host but do not record a failed example URL. |
| The TypeScript lint challenge was omitted or described as unresolved | Supported and corrected: `38d756b` adds `typescript-eslint`, and `backend/eslint.config.js` applies its type-checked configuration. |
| An author-notes attempt removed claims and the time table, then was reverted | Git history supports the content change and revert (`5b07137`, `e377757`). It does not record the question-by-question or “skip” exchange, so I describe only the committed diff and its revert. |
| Stale commit citations after the history rewrite | Supported by the failed `git cat-file -e` checks; unambiguous references were replaced, and one ambiguous reference remains annotated in the README. |

## Hash-check result

I replaced unambiguous references with current commits: `2590ebe` (review reports), `4528d9b` (CI path), `5293750` (R3/S2 fixes), `b77b25c` (R4/R5 tests), and `6bc7434` (review reports and memory). The old Swift-build citation remains annotated because its dated evidence spans several current commits and there is no unique subject match. The long hexadecimal values in API response examples are enquiry UUIDs, not commit citations.

## Verification claims retained

- The current test runs were backend 83 passed, CatalogueCore 33 total with 32 passed and the live test skipped, and iOS app 65 passed.
- The live contract and Mailpit checks are earlier recorded runs, not reruns from this documentation pass.
- Docker Compose was run once by the author on 2026-11-05 with the reported backend, app-request, and Mailpit outcome; I did not independently rerun it here.
- GitHub Actions, a physical device, VoiceOver, and authenticated SMTP TLS with a real provider remain unverified.
- Product images are fetched directly from supplied URLs, with loading/unavailable placeholders but no retry action or host allow-list.
