# Security review: `feature/catalogue-poc` against `main`

Read-only review. Local HTTP probes used synthetic `.test` data. No production service, secret, or customer data was used.

**Verdict: CHANGES REQUESTED — 0 high, 2 medium, 1 low.**

## Findings

| ID | Severity | File and line | Evidence | Risk | Suggested fix | Status |
|---|---|---|---|---|---|---|
| S1 | medium | `ios/CatalogueApp/DesignSystem/RemoteImage.swift:10`; `ios/CatalogueApp/Presentation/ProductDetail/ProductDetailView.swift:40`; `backend/src/adapters/fakeStoreProductSource.ts:34` | Product image URLs come from upstream data and are loaded with SwiftUI `AsyncImage`; the URL schema checks URL syntax but does not restrict the host. | A compromised or changed catalogue source can make the app contact an arbitrary image host, exposing the user's device IP/network metadata and bypassing the backend-only boundary. | Proxy image retrieval through the backend/data layer or enforce a documented host allowlist before rendering. | Accepted: images use the data-source URL and product metadata goes through the backend; the mapper restricts schemes to HTTP/HTTPS; proxying is deferred due to its own SSRF risk. |
| S2 | medium | `backend/src/adapters/smtpEmailSender.ts:36-40` | The Nodemailer transport sets host, port, and optional auth, but does not set `secure` or `requireTLS`. | With SMTP credentials, a server that does not offer STARTTLS may receive the login and email in plaintext. | Require TLS when credentials are configured, or use a secure transport and fail closed if TLS cannot be negotiated. | Fixed in `5293750` |
| S3 | low | `backend/Dockerfile:1`; `docker-compose.yml:19`; `.github/workflows/ci.yml:15,33,40` | `node:20-alpine`, `axllent/mailpit:latest`, and GitHub Actions `@v4` tags are mutable tags, not immutable digests/SHAs. | A tag can move to different code without a source change, weakening reproducibility and supply-chain review. | Pin container images to digests and actions to reviewed commit SHAs (while retaining update automation). | Accepted: the author reported one manual `docker compose up --build` on their machine on 2026-11-05; the backend started, app requests for categories, featured products, and category pages returned 200, and an app-submitted enquiry email appeared in Mailpit at <http://localhost:8025>. Container images remain tag-based, not digest-pinned; GitHub Actions remains unverified and action references are not SHA-pinned. |

## Security checks

### 1. Secrets and history

Tracked-artifact checks:

```text
$ git ls-files | rg '(^|/)\.env$|(^|/)node_modules/|(^|/)dist/|(^|/)\.build/|(^|/)ios/build/|(^|/)DerivedData/|(^|/)\.DS_Store$|xcuserdata/'
none

$ git ls-files | rg '(^|/)\.env(\.|$)'
backend/.env.example

$ git ls-files | rg '(^|/)\.npmrc$'
none
```

A scanner over `git --no-pager log -p --all --format= -- .` checked private-key and GitHub/AWS/Slack credential-assignment patterns, RFC1918/internal URLs, and patterns for the former employer domain and name; output: `No configured secret, private-URL, or former-employer patterns in reachable Git history`. A separate `git log --all --name-only` scan found no committed `.env` paths. No old work-domain or company-name match was found. All 222 lockfile `resolved` URLs use `https://registry.npmjs.org`.

`cd backend && npm audit --registry=https://registry.npmjs.org` returned `found 0 vulnerabilities`. The configured registry lookup had failed DNS in an earlier attempt; a first audit invocation from the repository root also failed with `ENOLOCK`, so the successful audit was rerun from `backend/` against the public registry.

### 2. Backend input and error handling

- `backend/src/http/routes.ts` validates category/product params, search query, and enquiry body with Zod before passing input to services. The health, featured, and categories routes have no user-supplied params/body/query to validate.
- The enquiry route sets `bodyLimit: 10 * 1024` and rejects non-JSON content types before parsing.
- Curl probes against the running local backend returned `400 VALIDATION_ERROR` for an invalid product ID, a too-short search, wrong content type, oversized JSON, and CR/LF in each of name/email/phone. A deliberately closed upstream returned `502 UPSTREAM_UNAVAILABLE` without the host, connection error, or stack in the response.

  ```text
  $ curl -sS -w '\nHTTP %{http_code}\n' http://127.0.0.1:3000/api/v1/products/not-a-number
  {"error":{"code":"VALIDATION_ERROR","message":"Invalid request","details":[{"field":"id","message":"Invalid value"}]}}
  HTTP 400

  $ curl -sS -w '\nHTTP %{http_code}\n' 'http://127.0.0.1:3000/api/v1/products/search?q=a'
  {"error":{"code":"VALIDATION_ERROR","message":"Invalid request","details":[{"field":"q","message":"Invalid value"}]}}
  HTTP 400

  $ curl -sS -w '\nHTTP %{http_code}\n' http://127.0.0.1:3000/api/v1/products/1
  {"error":{"code":"UPSTREAM_UNAVAILABLE","message":"Product source unavailable"}}
  HTTP 502

  $ curl -sS -w '\nHTTP %{http_code}\n' -X POST -H 'Content-Type: text/plain' --data '{}' http://127.0.0.1:3000/api/v1/enquiries
  {"error":{"code":"VALIDATION_ERROR","message":"Invalid request","details":[{"field":"request","message":"Invalid value"}]}}
  HTTP 400

  $ node -e 'process.stdout.write(JSON.stringify({productId:1,name:"Probe",email:"probe@example.test",message:"x".repeat(11000)}))' | curl -sS -w '\nHTTP %{http_code}\n' -X POST -H 'Content-Type: application/json' --data-binary @- http://127.0.0.1:3000/api/v1/enquiries
  {"error":{"code":"VALIDATION_ERROR","message":"Invalid request","details":[{"field":"request","message":"Invalid request"}]}}
  HTTP 400

  $ node -e 'process.stdout.write(JSON.stringify({productId:1,name:"Probe\r\nBcc: attacker@example.test",email:"probe@example.test",message:"Hello"}))' | curl -sS -w '\nHTTP %{http_code}\n' -X POST -H 'Content-Type: application/json' --data-binary @- http://127.0.0.1:3000/api/v1/enquiries
  {"error":{"code":"VALIDATION_ERROR","message":"Invalid request","details":[{"field":"name","message":"Invalid value"}]}}
  HTTP 400

  $ node -e 'process.stdout.write(JSON.stringify({productId:1,name:"Probe",email:"probe@example.test\r\nBcc: attacker@example.test",message:"Hello"}))' | curl -sS -w '\nHTTP %{http_code}\n' -X POST -H 'Content-Type: application/json' --data-binary @- http://127.0.0.1:3000/api/v1/enquiries
  {"error":{"code":"VALIDATION_ERROR","message":"Invalid request","details":[{"field":"email","message":"Invalid value"}]}}
  HTTP 400

  $ node -e 'process.stdout.write(JSON.stringify({productId:1,name:"Probe",email:"probe@example.test",phone:"+1\r\nBcc: attacker@example.test",message:"Hello"}))' | curl -sS -w '\nHTTP %{http_code}\n' -X POST -H 'Content-Type: application/json' --data-binary @- http://127.0.0.1:3000/api/v1/enquiries
  {"error":{"code":"VALIDATION_ERROR","message":"Invalid request","details":[{"field":"phone","message":"Invalid value"}]}}
  HTTP 400
  ```

  The backend used `FAKESTORE_BASE_URL=http://127.0.0.1:39999` for the upstream-failure probe; no public Fake Store request was made.

  ```text
  $ for index in 1 2 3 4 5 6; do curl -sS -o /dev/null -w '%{http_code}\n' -X POST -H 'Content-Type: application/json' --data '{"productId":1,"name":"Probe","email":"probe@example.test","message":"Hello"}' http://127.0.0.1:3000/api/v1/enquiries; done
  502
  502
  502
  502
  502
  429
  ```

- On a fresh backend process, the six valid-shaped requests above returned `502, 502, 502, 502, 502, 429`; the first five reached the closed synthetic upstream and the sixth response body was `{"error":{"code":"RATE_LIMITED","message":"Too many requests"}}`. The limit is five per minute and is keyed by Fastify `request.ip`. `trustProxy` is not enabled and Compose has no reverse proxy; if deployed behind a proxy, requests would be bucketed under the proxy address unless a trusted proxy policy is configured.
- The rate limiter also applies to schema-invalid JSON bodies. On a fresh process, eight quick `POST {}` requests returned `400, 400, 400, 400, 400, 429, 429, 429`:

  ```text
  $ for index in 1 2 3 4 5 6 7 8; do curl -sS -o /dev/null -w '%{http_code}\n' -X POST -H 'Content-Type: application/json' --data '{}' http://127.0.0.1:3000/api/v1/enquiries; done
  400
  400
  400
  400
  400
  429
  429
  429
  ```
- The email-service tests verify header sanitization, HTML escaping, generic delivery errors, and ID-only application logging. A real valid synthetic enquiry returned `202`; captured server output included recipient/subject and enquiry/product IDs, not the submitted name, email, phone, or message.

  Command:

  ```text
  $ curl -sS -i -X POST -H 'Content-Type: application/json' --data '{"productId":1,"name":"CustomerNameLogMarker","email":"customer.email.marker@example.test","phone":"+1 555-0137","message":"CustomerMessageLogMarker"}' http://127.0.0.1:3000/api/v1/enquiries
  HTTP/1.1 202 Accepted
  {"id":"103914a6-2b5a-4ce3-90ba-3ab7b9a0a028"}
  ```

  Its captured console output was:

  ```text
  { to: 'sales@example.test', subject: 'New enquiry: Backend Log Probe (#1)' }
  { enquiryId: '103914a6-2b5a-4ce3-90ba-3ab7b9a0a028', productId: 1 }
  ```

  The submitted markers `CustomerNameLogMarker`, `customer.email.marker@example.test`, `+1 555-0137`, and `CustomerMessageLogMarker` were absent from the log output. Fastify logged only the request path, remote address, status, and timing.

  ```text
  $ lsof -nP -iTCP:3000 -iTCP:39999 -iTCP:1025 -iTCP:8025 -sTCP:LISTEN
  no listener (all ports free after cleanup)
  ```

### 3. CORS, security headers, and email handling

- `token-goat grep '@fastify/cors|@fastify/helmet' backend/src backend/package.json --max-lines 50` found no CORS or Helmet plugin. CORS is not needed by the native iOS client; there is no browser client in this branch. Standard security headers are absent; noted, not changed.
- `enquiryService.ts` strips control characters from header values and escapes user fields before HTML insertion. The route rejects CR/LF in name, email, and phone. `backend/test/enquiryService.test.ts` verifies the resulting email content and log behavior.
- `consoleEmailSender.ts` logs configured `to` and subject. Enquiry logs contain only receipt/product IDs; no customer fields were present in the real synthetic request logs.

### 4. SSRF and URL construction

`listByCategory` applies `encodeURIComponent`, and `fetchJson` resolves the relative path against the configured base URL. In isolation, a direct adapter call with `".."` normalizes to `/products/`, while `"https://attacker.example"` stays encoded under `upstream.example`. The HTTP path goes through `CatalogueService.getCategoryProducts` (`backend/src/services/catalogueService.ts:101-119`), which first compares the user-supplied category with the upstream category list and throws `NOT_FOUND` before calling `listByCategory` when no match exists. An instrumented service probe returned `".." -> NOT_FOUND; listByCategory calls=0` and `"https://attacker.example" -> NOT_FOUND; listByCategory calls=0`. Thus neither crafted category can reach another upstream path through the current HTTP route; no SSRF/path-traversal finding is reported.

### 5. iOS data and release checks

- ATS allows insecure HTTP for `localhost` only; no `NSAllowsArbitraryLoads` setting was found. Release API configuration does not add a broad ATS exception.
- No `UserDefaults` or Keychain storage calls were found. EnquiryViewModel clears form values after success; it does not log field values.
- APIClient builds URLs with `URLComponents`/`URLQueryItem`. The product-image `AsyncImage` is the direct network exception in S1.
- The Release simulator executable was searched with `strings`; no `UI_PREVIEW_ROUTE`, `enquiry-submit`, `enquiry-errors`, or fake prefill strings were present.
- No hard-coded secret was found in the app source or tracked configuration.

### 6. Dependencies

Backend direct runtime dependencies: `@fastify/rate-limit` (enquiry limiting), `fastify` (HTTP server), `nodemailer` (SMTP), and `zod` (configuration/request validation). Development dependencies: `@eslint/js` and `eslint` (lint), `typescript` (strict build), `vitest` (tests), and `@types/node` (Node types). `npm audit` found 0 vulnerabilities.

The Swift package has no third-party package dependencies. CatalogueData depends on CatalogueDomain; the app consumes the local CatalogueCore package.

### 7. Docker and CI review

- Dockerfile uses Node 20, builds before runtime, exposes port 3000, and runs as the non-root `node` user. `.dockerignore` excludes `.env`, `node_modules`, `dist`, and tests. Compose passes the required configuration and binds backend/Mailpit ports to loopback; no real secret is committed.
- Compose uses `axllent/mailpit:latest`, and the Node image uses a mutable tag; see S4.
- CI has `contents: read`, npm caching, major-version action tags, and no secrets. The iOS project-path issue recorded as R1 in `REVIEW.md` was fixed after review; local YAML parsing and working-directory path checks passed, but GitHub Actions was not run.
- Docker was unavailable during the security review, so the review did not run the image or Compose. The author later reported one manual `docker compose up --build` on their machine on 2026-11-05: the backend started, the app's categories, featured products, and category-page requests returned 200, and an app-submitted enquiry email was visible in Mailpit at <http://localhost:8025>. The workflow YAML parsed locally, but GitHub Actions was not run and remains unverified.

## Checked and fine

- No tracked `.env` other than `.env.example`, no tracked `.npmrc`, and no forbidden build/cache artifacts.
- All backend request data is validated at the route boundary; content type and body size are enforced.
- Error responses tested against malformed requests and a closed upstream do not expose stack traces or upstream details.
- Six-request rate-limit behavior was observed; no reverse proxy is configured in the reviewed Compose setup.
- HTML email values are escaped, email-header values are sanitized, and successful enquiry handling clears iOS form data.
- ATS is localhost-only; the Release binary omits the DEBUG-only hooks.
- The public-registry dependency audit returned 0 vulnerabilities.
- Category requests are checked against the upstream category list before reaching the adapter; crafted dot-segment and URL-looking values returned `NOT_FOUND` without calling `listByCategory`.

## Resolution

S1 is accepted: images load from the data-source-provided URL while product metadata goes through the backend; the existing DTO mapper restricts image schemes to HTTP and HTTPS. A backend image proxy remains a future step and carries its own SSRF risk. S2 was fixed in `5293750`: authenticated SMTP requires TLS, and port 465 uses implicit TLS; authenticated TLS was not tested against a real provider. S3 is accepted for now: the author reported one manual Compose run on 2026-11-05 with the backend, app requests, and Mailpit outcome recorded above; container images remain tag-based, not digest-pinned, and GitHub Actions remains unverified with action references not SHA-pinned. Pinning is a next step.
