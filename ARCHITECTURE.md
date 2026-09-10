# QA Superpower V4 Architecture

## 1. System shape

V4 separates **control-plane responsibilities** from **execution-plane responsibilities**.

```text
Browser / QA Engineer
        |
      HTTPS
        |
+-----------------------------+
| QA Superpower Control Plane |
|-----------------------------|
| REST API + RBAC             |
| OIDC / LDAP                 |
| SQLite metadata             |
| AES-GCM secret vault        |
| Scheduler                   |
| Job lease coordinator       |
| WebSocket event hub         |
| Test-management adapters    |
| Git storage                 |
| Visual baseline metadata    |
| Autonomous agent planner    |
+--------------+--------------+
               |
       authenticated leases
               |
    +----------+----------+
    |          |          |
+---v---+  +---v---+  +---v---+
|Worker |  |Worker |  |Worker |
|API/UI |  |Perf/DB|  |Mobile |
+---+---+  +---+---+  +---+---+
    |          |          |
    +----- authorized QA targets
```

The same `TaskRuntime` is used by local execution and remote workers so result formats stay consistent.

## 2. Control plane

The control plane owns durable metadata:

- users and sessions;
- encrypted secrets and environments;
- test cases, automations and traceability;
- jobs and append-only job events;
- worker heartbeat/lease state;
- schedules;
- sync history;
- Git repository metadata;
- visual baselines;
- contracts and mock routes;
- generated test-data sets;
- autonomous-agent runs;
- audit history.

Metadata is currently SQLite/WAL for zero-setup local deployment and deterministic packaging. Therefore Kubernetes runs the controller as a **single replica**.

## 3. Distributed worker protocol

Workers authenticate with `Authorization: Worker <QA_WORKER_TOKEN>` and use internal endpoints only:

```text
POST /api/internal/workers/register
POST /api/internal/workers/heartbeat
POST /api/internal/workers/lease
POST /api/internal/jobs/:id/event
POST /api/internal/jobs/:id/complete
POST /api/internal/jobs/:id/fail
```

A worker advertises capabilities. The control plane atomically leases the oldest compatible queued job, records the assigned worker and lease expiration, and streams a `job.leased` event. A vanished worker causes lease expiry/requeue. After three attempts, the job is failed instead of looping indefinitely.

## 4. Local-only orchestration

V4 deliberately keeps two task classes on the controller:

- `regression`: it orchestrates multiple child tasks and aggregates results;
- `visual_regression`: it reads persisted controller visual-baseline metadata.

SQLite jobs submitted through the dedicated DB validation route are also marked local automatically, avoiding assumptions about shared SQLite files across worker pods.

## 5. WebSocket event path

Jobs write events to the SQLite `job_events` table first. The LiveHub then broadcasts the same event to matching WebSocket subscribers. This gives both real-time delivery and durable history/replay.

The browser does not put its normal bearer session into the WebSocket query string. Instead:

1. browser authenticates normally;
2. browser requests `POST /api/live/ticket`;
3. control plane creates a short-lived single-use random ticket;
4. browser upgrades `/ws?ticket=...`;
5. ticket is consumed during the upgrade.

Recorder frames use the same hub and can publish compressed JPEG screenshot data plus recorder state.

## 6. Enterprise identity

### OIDC

OIDC uses Authorization Code with PKCE. Server-side state includes nonce, verifier, redirect URI and expiry. Callback validation performs:

- state expiration check;
- code exchange;
- JWKS retrieval;
- RS256/ES256 signature verification;
- issuer/audience/expiry/nonce checks;
- optional allowed-email-domain check;
- external-user provisioning to local RBAC.

### LDAP

LDAP uses a configured service bind (optional), escaped user-search filter, user DN discovery and a second bind with the supplied user password. Successful users are mapped to local RBAC identities.

## 7. Secrets

Secret values are encrypted with AES-256-GCM using a key derived from `QA_MASTER_KEY`. API list operations never return plaintext values. Integration objects store secret **names**, not third-party tokens.

For distributed jobs, only required resolved environment/connection values are sent through authenticated internal worker API payloads at lease time; they are not written into the original persisted job payload.

## 8. Test-management synchronization

`TestManagement` normalizes external test inventory into local `test_cases` and records sync provenance in `external_sync`.

Adapters:

- Jira Cloud REST v3 enhanced JQL search;
- Xray Cloud authentication + GraphQL test retrieval + execution import;
- Zephyr Scale REST v2 test-case retrieval + execution creation.

Custom Jira/self-hosted integration targets require explicit hostname allowlisting.

## 9. Git test storage

`GitStorage` keeps managed working trees under `QA_GIT_DIR`. It can create a local repository, clone, pull, save generated content, commit, and optionally push.

For HTTPS token authentication, credentials are passed through temporary Git config HTTP headers. Tokens are not inserted into repository URLs.

## 10. Visual regression

Visual baselines are deterministic full-page screenshots tied to URL + viewport metadata and SHA-256. A changed screenshot can optionally invoke a multimodal LLM review with baseline/current images. Artifacts include both images and structured verdict JSON.

V4 treats AI classification as a QA decision aid, not cryptographic truth. Deterministic equality remains available independently of the model.

## 11. Service virtualization and contracts

Mock routes are persisted and served under `/mock/<service>/...`. Request-aware templates let QA suites emulate upstream dependencies with predictable status, headers, latency and payload.

The contract runner consumes persisted OpenAPI documents and selected requests, resolving path templates and checking response declaration plus core schema constraints. It is deliberately scoped and does not claim full OpenAPI/JSON Schema semantic coverage.

## 12. Mobile and accessibility

Appium integration uses W3C WebDriver HTTP sessions and vendor-prefixed Appium capabilities. No Appium server is embedded; workers talk to the authorized Appium endpoint configured in the test payload.

Accessibility uses a real Playwright page and emits findings + screenshot evidence for built-in structural checks. Browser execution can be distributed to Playwright-capable workers.

## 13. Autonomous regression agent

The agent reads bounded internal QA context: recent failures, active test inventory, automation inventory and trace links. It creates a structured regression plan either heuristically or through a configured LLM.

Only an explicit allowlist of non-destructive QA job types is accepted. Plans default to `awaiting_approval`; execution requires lead/admin approval. This separates **AI planning** from **execution authority**.

## 14. Kubernetes model

Controller:

- 1 replica;
- RWO persistent data volume;
- RWX artifact volume;
- readiness/liveness probe.

Workers:

- stateless Deployment;
- HPA 2–20 replicas;
- PDB;
- ephemeral worker-local data;
- RWX artifact volume;
- capability based polling.

### Current V4 scale boundary

Worker scale-out is real, but controller HA is not. The next HA architecture should replace:

```text
SQLite jobs/metadata -> PostgreSQL
SQLite leasing       -> PostgreSQL SKIP LOCKED or Redis/NATS/SQS
filesystem artifacts -> S3/GCS/Azure Blob + signed object URLs
single WebSocket hub -> pub/sub backed WebSocket gateways
```

Only after that migration should controller/API replicas be scaled above one.
