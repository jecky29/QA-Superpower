# QA Superpower V4 Feature Matrix

| Capability | V4 status | Execution mode | External requirement |
|---|---|---|---|
| AI requirement intelligence | Implemented | Controller | OpenAI key optional; heuristic fallback |
| Test-case ↔ automation traceability | Implemented | Controller | None |
| Playwright execution | Implemented | Local/worker | Playwright + Chromium |
| Katalon execution | Implemented | Local/worker | Katalon CLI |
| JMeter execution | Implemented | Local/worker | JMeter CLI |
| Auto capture | Implemented | Local/worker | Playwright + Chromium |
| Performance runner | Implemented | Local/worker | Authorized target |
| API collection | Implemented | Local/worker | Authorized target |
| DB validation | Implemented | SQLite local; PG/MySQL local/worker | DB/CLI as applicable |
| Persistent scheduler | Implemented | Controller | None |
| History/dashboard | Implemented | Controller | None |
| HTML/PDF/JSON reports | Implemented | Controller | None |
| Environment & AES-GCM vault | Implemented | Controller | Strong master key |
| RBAC multi-user | Implemented | Controller | None |
| Distributed worker fleet | Implemented | Worker plane | Shared worker credential |
| Lease/heartbeat/retry | Implemented | Worker plane | None |
| Kubernetes deployment | Implemented | Worker scale-out | Cluster + RWX storage |
| WebSocket live console | Implemented | Controller | Reverse proxy must support Upgrade |
| One-time WebSocket tickets | Implemented | Controller | None |
| Real-time Playwright recorder | Implemented | Controller | Playwright + Chromium |
| OIDC SSO | Implemented | Controller | OIDC provider |
| LDAP SSO | Implemented | Controller | LDAP/LDAPS + ldapts |
| Jira synchronization | Implemented | Controller | Jira credentials |
| Xray synchronization | Implemented | Controller | Xray Cloud credentials |
| Zephyr Scale synchronization | Implemented | Controller | Zephyr token |
| Git repository test storage | Implemented | Controller | Git; token for remote push |
| Visual baseline | Implemented | Controller | Playwright + Chromium |
| Visual AI review | Implemented | Controller | OpenAI key |
| Test-data factory | Implemented | Controller | None |
| Service virtualization/mock server | Implemented | Controller | None |
| OpenAPI contract testing | Implemented subset | Local/worker | Authorized target |
| Mobile Appium | Implemented | Local/worker | Appium server/device/driver |
| Accessibility scanner | Implemented baseline rules | Local/worker | Playwright + Chromium |
| Autonomous regression agent | Implemented | Planner/controller + jobs | OpenAI optional |
| Agent approval gate/action allowlist | Implemented | Controller | lead/admin approval |
| CI/CD GitHub/GitLab/Jenkins | Preserved from V3 | Controller | Provider credentials |
| Jira defect auto-generation | Preserved from V3 | Controller | Jira credentials |

## Validation level

`npm test` executes isolated, non-destructive validation. It includes a real separate worker process and local protocol stubs for OIDC, Jira, Xray, Zephyr and Appium. This verifies our request/response adapters without claiming that a customer-specific external deployment is reachable or correctly configured.

Browser-specific recorder/visual/accessibility execution is exercised only when Playwright/Chromium is installed in the runtime. Cloud LLM visual classification, real LDAP, real SaaS accounts and physical/emulated devices require customer credentials/infrastructure.
