# Kickoff prompt (paste into Copilot agent mode / cloud agent)

You are building an AI-native product catalogue PoC. Read AGENTS.md, docs/PRD.md, docs/ARCHITECTURE.md, docs/RULES.md, docs/DESIGN.md, docs/TASKS.md and docs/MEMORY.md first.

Work through docs/TASKS.md in order, ONE task at a time:
1. Plan in 3-5 bullets.
2. Implement with tests in the same change.
3. Run the commands listed in AGENTS.md. Do not claim success unless they pass.
4. Tick the task in docs/TASKS.md.
5. Append decisions, surprises and mistakes (with timestamps) to docs/MEMORY.md.
6. Commit on a feature branch with a clear message, then continue.

Rules: the app only talks to our backend; no force unwraps; no new dependencies without asking; stop and write the question in MEMORY.md if a requirement is unclear, choosing the most reasonable assumption and recording it.

Cloud agent (Linux): do T0-T4 only (backend). iOS tasks T5+ need macOS/Xcode: do those locally in Copilot agent mode.

When all tasks are done, run the Reviewer and Security Auditor agents, fix findings, then draft AI_USAGE.md and DECISIONS.md from docs/MEMORY.md and git log. Mark anything uncertain as TODO.
