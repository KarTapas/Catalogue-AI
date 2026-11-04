# Memory
Running log. Agents read this FIRST and append to it LAST. Humans too.
Format: `YYYY-MM-DD HH:MM | type | note` where type = decision | convention | mistake | surprise | time

## Conventions
- Money is a string/minor units, never Float.
- Category names are URL-encoded (`men's clothing`).
- Fake Store has no search or featured endpoint; the backend implements both.

## Log
<!-- append below -->
2026-11-04 16:34 | surprise | Initial dependency ranges pulled vulnerable releases; updated to patched versions and npm install reported 0 vulnerabilities. Configured registry DNS failed, so install used a one-shot public registry override; Docker CLI unavailable for Compose validation.
2026-11-04 16:35 | mistake | Health-server cleanup initially stopped its wrapper instead of the child process; stopped the PID and verified port 3000 was clear.
