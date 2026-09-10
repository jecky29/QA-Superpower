# QA Superpower V4 — Enterprise Distributed QA Platform

QA Superpower V4 adalah evolusi penuh dari V3 menjadi platform Quality Engineering yang memiliki **control plane**, **distributed execution workers**, enterprise identity, test-management synchronization, Git-backed test storage, real-time execution telemetry, service virtualization, contract/mobile/accessibility testing, visual regression berbasis AI, serta autonomous regression agent dengan approval gate.

V4 tetap membawa seluruh kapabilitas V3: AI requirement intelligence, test-case generation, Playwright/Katalon/JMeter execution, auto capture, log analyzer, line-level debugger, JSON converter, performance test, API collection runner, database validation, scheduler, history dashboard, Jira defect creation, HTML/PDF report, encrypted secret vault, environment manager, traceability, RBAC, dan CI/CD integrations.

## V4 capability map

| Area | Capability | Implementasi |
|---|---|---|
| Distributed execution | Worker fleet | Persistent lease, heartbeat, retry/requeue, capability routing, local/remote execution mode |
| Kubernetes | Scale-out workers | Deployment + HPA + PDB + health probes + shared RWX artifacts |
| Live telemetry | WebSocket console | Persistent job events + one-time short-lived WebSocket tickets |
| Recorder | Real-time Playwright recorder | Chromium session, streamed JPEG screenshots, click/type/navigation → Playwright steps |
| SSO | OIDC | Authorization Code + PKCE, nonce/state, JWKS signature verification, auto provisioning |
| SSO | LDAP | Bind/search/user re-bind flow using `ldapts`, RBAC auto provisioning |
| Test management | Jira | Jira Cloud REST v3 enhanced JQL pull into local test cases |
| Test management | Xray Cloud | Authentication + GraphQL test pull + execution import |
| Test management | Zephyr Scale | REST v2 test-case pull + execution push |
| Source control | Git test storage | Local/clone repository, commit, pull, optional push, token via transient Git header |
| Visual QA | Visual regression AI | Deterministic screenshot baseline/hash + optional multimodal LLM review |
| Test data | Factory | Seeded deterministic synthetic records: UUID/email/name/phone/numbers/date/boolean/string |
| Service virtualization | Mock server | Persistent routes, path params, request/query/header/body templates, latency/status/headers |
| Contract testing | OpenAPI | Endpoint/method/status/schema validation with worker execution |
| Mobile | Appium | W3C WebDriver session/actions, element find/click/type, tap, screenshot, source, back |
| Accessibility | Web accessibility | Browser scanner for critical WCAG-oriented structural rules + screenshot/JSON artifacts |
| AI agent | Autonomous regression | Context-aware plan, optional LLM planner, action allowlist, lead approval, execution tracking |
| Security | Secrets/RBAC/audit | AES-256-GCM vault, viewer/qa/lead/admin, signed artifacts, audit trail, target allowlist |

## Start locally

Requirements:

- Node.js 22+
- Git CLI
- `npm install`
- Chromium installed through Playwright for recorder/visual/accessibility/browser execution

```bash
cp .env.example .env
npm install
npx playwright install chromium
npm start
```

Open:

```text
http://127.0.0.1:7070
```

Default first-start account:

```text
username: admin
password: ChangeMe123!
```

Set a strong password and master key before first production-like startup:

```bash
ADMIN_PASSWORD='replace-me' \
QA_MASTER_KEY='a-long-random-master-key' \
npm start
```

## Distributed mode

Start the control plane:

```bash
DISTRIBUTED_MODE=true \
QA_MASTER_KEY='same-master-key' \
npm start
```

Start one or more workers from another terminal/host/container:

```bash
QA_CONTROL_PLANE_URL='http://127.0.0.1:7070' \
QA_MASTER_KEY='same-master-key' \
QA_WORKER_NAME='worker-01' \
npm run worker
```

Worker authentication can instead use an explicit `QA_WORKER_TOKEN`. In distributed mode, jobs are leased only to workers whose `QA_WORKER_CAPABILITIES` match the job type. Leases expire and are requeued up to the retry limit if a worker disappears.

Supported worker capabilities include:

```text
api_collection
performance
database
playwright
capture
katalon
jmeter
contract
accessibility
mobile_appium
```

`regression` and `visual_regression` remain controller-local in V4 because regression orchestrates child tasks and visual baselines live in controller metadata. SQLite validation is also automatically routed local when submitted through `/api/database/validate`; remote PostgreSQL/MySQL validations can be worker-executed.

## Docker Compose

The included compose file starts one controller and two workers:

```bash
docker compose up --build
```

Then open `http://127.0.0.1:7070`.

## Kubernetes

The manifest is under `k8s/qa-superpower-v4.yaml` and provides:

- one control-plane Deployment;
- worker Deployment with three initial replicas;
- HPA from 2 to 20 workers;
- worker PodDisruptionBudget;
- controller health/readiness probes;
- persistent controller metadata volume;
- RWX shared artifact volume.

```bash
kubectl apply -f k8s/qa-superpower-v4.yaml
kubectl -n qa-superpower get pods
kubectl -n qa-superpower get hpa
```

Read `k8s/README.md` before production deployment. **Do not scale the SQLite control-plane above one replica.** V4 distributes execution; control-plane HA requires a future metadata migration to PostgreSQL plus a distributed broker/lease store.

## OIDC SSO

Create an admin-managed OIDC provider from the SSO page or `POST /api/sso`:

```json
{
  "kind": "oidc",
  "name": "Corporate OIDC",
  "config": {
    "issuer": "https://id.example.com",
    "clientId": "qa-superpower",
    "clientSecretName": "oidc_client_secret",
    "scope": "openid profile email",
    "defaultRole": "qa",
    "allowedDomains": ["example.com"]
  }
}
```

Store the client secret separately in the encrypted vault. V4 discovers provider endpoints, generates state/nonce/PKCE verifier, performs code exchange, verifies RS256/ES256 ID-token signature through JWKS, checks issuer/audience/expiry/nonce, then auto-provisions a local RBAC identity.

## LDAP SSO

```json
{
  "kind": "ldap",
  "name": "Corporate LDAP",
  "config": {
    "url": "ldaps://ldap.example.com:636",
    "bindDn": "cn=qa-service,dc=example,dc=com",
    "bindPasswordSecret": "ldap_bind_password",
    "userSearchBase": "ou=people,dc=example,dc=com",
    "userFilter": "(uid={{username}})",
    "emailAttribute": "mail",
    "nameAttribute": "cn",
    "defaultRole": "qa"
  }
}
```

The service account password remains in the encrypted vault. The LDAP flow searches using the service binding and verifies the user password by binding again as the matched DN.

## Jira / Xray / Zephyr synchronization

Credentials are always referenced by secret name, not embedded in saved test cases.

Jira secret:

```json
{"email":"qa@example.com","apiToken":"..."}
```

Xray secret:

```json
{"clientId":"...","clientSecret":"..."}
```

Zephyr secret is the bearer token itself.

Example Jira pull:

```json
{
  "provider": "jira",
  "secretName": "jira_credentials",
  "site": "https://company.atlassian.net",
  "jql": "project = QA ORDER BY updated DESC",
  "limit": 50
}
```

Synchronizations are persisted in `external_sync` and visible from the UI history.

## Git-backed test storage

Create a local managed repository or clone a remote repository. Save generated automation/test artifacts through the platform, which commits each change. When `push: true`, credentials are supplied to Git through a transient HTTP header rather than written into the remote URL.

For remote repositories, put the provider token in the secret vault and reference `secretName` from the repository record.

## WebSocket live console

The frontend calls authenticated `POST /api/live/ticket`, then opens `/ws?ticket=...`. Tickets expire quickly and are single-use. Channels can subscribe to a job, recorder, worker fleet, or broad event channel. This avoids exposing the long-lived session bearer token in a WebSocket URL.

## Real-time recorder

Recorder endpoints open a Playwright Chromium session on an **authorized target**. The browser viewport is streamed to the UI over WebSocket. Clicking the streamed image sends its coordinates to the backend; typing/navigation are recorded as Playwright actions and the generated code is continuously available.

Install browser binaries first:

```bash
npm install
npx playwright install chromium
```

## Visual Regression AI

1. Create a baseline screenshot.
2. Future runs capture the same target/viewport.
3. V4 first compares deterministic SHA-256 screenshot hashes.
4. When bytes changed and `OPENAI_API_KEY` is configured, baseline and current PNGs are sent as image inputs to the configured model for QA-oriented change classification.
5. The job returns `MATCH`, `ACCEPTABLE`, or regression-oriented review information, plus baseline/current/result artifacts.

The AI verdict is advisory; critical release gates should still use human review or deterministic visual tooling appropriate to your environment.

## Test-data factory

Example:

```json
{
  "name": "Checkout Users",
  "seed": "release-2026-09",
  "count": 25,
  "schema": {
    "id": "uuid",
    "name": "name",
    "email": "email",
    "age": {"type":"integer","min":18,"max":65},
    "tier": {"enum":["FREE","PRO","ENTERPRISE"]},
    "active": "boolean"
  }
}
```

Reusing the same seed keeps generated pseudo-random values reproducible except values intentionally generated from cryptographic UUID input.

## Service virtualization

Create routes such as:

```json
{
  "service": "orders",
  "method": "GET",
  "path": "/orders/:id",
  "status": 200,
  "responseBody": {
    "id": "{{params.id}}",
    "requestId": "{{request.headers.x-request-id}}",
    "status": "PAID"
  },
  "latencyMs": 120
}
```

Call it at:

```text
GET /mock/orders/orders/ORD-101
```

Templates can reference `params.*`, `request.query.*`, `request.headers.*`, and `request.body.*`. Set `QA_MOCK_KEY` to require an `x-qa-mock-key` header on public mock routes.

## Contract testing

V4 persists OpenAPI specs and validates selected HTTP requests against declared path/method, allowed response status and core JSON-schema fields (`object`, `array`, `string`, `number/integer`, `boolean`, `required`, `enum`). See `examples/openapi-mock.json`.

This is intentionally an OpenAPI-focused contract runner, not a complete implementation of every JSON Schema/OpenAPI keyword.

## Mobile Appium

V4 talks to an Appium server through the W3C WebDriver wire protocol. Example payload is available in `examples/appium-run.json`.

Supported actions:

- find
- click
- type
- tap / W3C pointer actions
- screenshot
- source
- back

Remote Appium hosts must be explicitly allowed with the target security settings.

## Accessibility testing

The built-in browser scanner checks high-value structural rules including:

- document language;
- image alt text;
- form labels;
- accessible names for buttons/links;
- duplicate IDs;
- heading-order jumps;
- positive `tabindex`.

Results include severity counts, selectors, JSON evidence, and a full-page screenshot. This is a **WCAG-oriented baseline scanner**, not a formal accessibility certification and not a replacement for comprehensive axe/manual assistive-technology testing.

## AI autonomous regression agent

The agent builds context from recent failed jobs, test cases, active automations and traceability. When an OpenAI key is configured it can use the Responses API as a planner; otherwise it uses deterministic heuristics.

The agent may only propose an explicit allowlist of QA actions:

```text
regression
api_collection
performance
contract
accessibility
visual_regression
database
mobile_appium
```

It cannot propose arbitrary shell commands, secret extraction or destructive database operations. Plans default to `awaiting_approval`; a `lead` or `admin` must approve before jobs are submitted. Agent performance plans are capped at 120 seconds.

## Remote target protection

Remote/public destinations are blocked by default:

```bash
ENABLE_REMOTE_TARGETS=false
```

For staging systems you are authorized to test:

```bash
ENABLE_REMOTE_TARGETS=true \
ALLOWED_TARGET_HOSTS='staging.example.com,api-staging.example.com' \
npm start
```

Workers need the same target policy because network requests execute from the worker process/container.

## RBAC

- `viewer`: read platform data/results.
- `qa`: create/run QA assets and jobs.
- `lead`: scheduling, worker visibility, test-management/CI/Jira actions, agent approval.
- `admin`: user/RBAC and SSO administration plus all lower-role permissions.

## Validation

Run static checks:

```bash
npm run check
```

Run isolated V4 self-test:

```bash
npm test
```

The test uses its own `.selftest-v4` data directory and removes it afterward. It does not touch normal platform data.

The self-test validates controller health, local auth, one-time WebSocket ticket handshake, test-data generation, mock server, encrypted vault behavior, Jira/Xray/Zephyr adapters against local stubs, full OIDC PKCE/JWKS flow against a local identity stub, Git repository storage, distributed worker registration/lease/events, OpenAPI contract execution, Appium W3C adapter against a local WebDriver stub, SQLite local routing, autonomous-agent approval/execution, legacy engineering tools, report generation and dashboard metrics.

Live browser-dependent features require installed Playwright/Chromium. Real LDAP, real cloud test-management accounts, real mobile devices/Appium drivers, and real LLM visual reviews require those external systems and credentials and therefore are not falsely marked PASS by the isolated self-test.

## Security / production notes

Read `SECURITY.md`. Core points:

- never expose the control plane without HTTPS/reverse proxy in shared environments;
- replace default admin credentials and master/worker tokens;
- use network policies/firewalls around worker-internal routes;
- use allowlists for test and integration targets;
- mount secret values through a secret manager in Kubernetes rather than committing them;
- keep SQLite controller single-replica;
- use RWX artifact storage or evolve artifacts to object storage for larger clusters;
- rotate third-party tokens and keep them in the encrypted vault;
- treat autonomous AI output as a plan that still passes explicit approval/guardrails.

## Important files

```text
server.js                         V4 control plane/API
worker.js                         distributed worker
index.html                        enterprise frontend
lib/queue.js                      leasing/heartbeat/retry queue
lib/live.js                       WebSocket hub + one-time tickets
lib/sso.js                        OIDC/LDAP
lib/test-management.js            Jira/Xray/Zephyr
lib/git-storage.js                Git-backed test storage
lib/visual.js                     baseline + AI visual review
lib/test-data.js                  synthetic data factory
lib/mock-server.js                service virtualization
lib/contracts.js                  OpenAPI runner
lib/mobile.js                     Appium W3C adapter
lib/accessibility.js              browser accessibility scanner
lib/agent.js                      autonomous regression planner
lib/task-runtime.js               shared local/worker runtime
k8s/qa-superpower-v4.yaml         Kubernetes resources
scripts/selftest-v4.mjs           isolated V4 validation
```
