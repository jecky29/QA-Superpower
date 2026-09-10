# QA Superpower V3 - Feature Matrix

| Capability | V3 status | Main API / component | Validation |
| --- | --- | --- | --- |
| AI requirement intelligence | Implemented | `POST /api/ai/requirements`, `lib/llm.js` | Self-test validates fallback + persistence; live LLM needs API key/network |
| Playwright visual recorder | Implemented | `/api/recorder/*`, `lib/recorder.js` | Syntax/engine detection validated; interactive run requires installed Playwright/Chromium |
| Test ↔ automation traceability | Implemented | `/api/traceability*` | Self-test creates test, automation, link, coverage |
| API collection runner | Implemented | `POST /api/api/run` | Self-test executes real localhost HTTP request + assertions |
| CI/CD GitHub | Implemented adapter | `POST /api/integrations/cicd/trigger` | Contract implemented; live call requires token/repository |
| CI/CD GitLab | Implemented adapter | same | Contract implemented; live call requires trigger token/project |
| CI/CD Jenkins | Implemented adapter | same | Contract implemented; live call requires Jenkins endpoint/credentials |
| Database validation | Implemented | `POST /api/database/validate` | SQLite tested end-to-end; PostgreSQL/MySQL require installed CLIs |
| Scheduled regression | Implemented | `/api/schedules*`, `lib/scheduler.js` | Self-test creates persistent schedule |
| Parallel execution worker | Implemented | `lib/queue.js`, `POST /api/regression/run` | Self-test executes API + DB tasks in parallel orchestration |
| History dashboard | Implemented | `GET /api/history`, `GET /api/dashboard` | Self-test validates persisted jobs and metrics |
| Jira defect generation | Implemented adapter | `POST /api/integrations/jira/defect` | Contract implemented; live call requires Jira Cloud credentials/project |
| HTML report | Implemented | `POST /api/reports/job` | Self-test generates file + signed URL |
| PDF report | Implemented | `lib/report.js` | PDF header validated and rendered to PNG successfully |
| JSON report | Implemented | `POST /api/reports/job` | Self-test generates artifact |
| Environment manager | Implemented | `/api/environments` | Self-test creates and reads environment |
| Encrypted secrets manager | Implemented | `/api/secrets`, `lib/secrets.js` | Self-test checks no plaintext value returned/stored |
| RBAC / multi-user login | Implemented | `/api/auth/*`, `/api/users`, `lib/auth.js` | Self-test authenticates admin and creates viewer |
| Password change/logout | Implemented | `/api/me/password`, `/api/auth/logout` | API implemented with current-password verification |
| Auto log checker | Retained from V2 | `POST /api/logs/analyze` | Self-test validates errors/warnings |
| Line-level debugger | Retained from V2 | `POST /api/debug` | Self-test validates Playwright issues |
| JSON converter | Retained from V2 | `POST /api/convert` | Self-test validates 3 outputs |
| Real HTTP performance | Retained from V2 | `POST /api/performance/run` | Engine executed through queue; local target guard retained |
| URL auto-capture | Retained from V2 | `POST /api/capture/url` | Implemented; requires Playwright |
| Katalon CLI runner | Retained from V2 | `POST /api/execute/katalon` | Adapter + engine detection; live run requires Katalon CLI |
| JMeter CLI runner | Retained from V2 | `POST /api/execute/jmeter` | Adapter + artifact collection; live run requires JMeter CLI |

## Test boundary

`npm test` intentionally does not call external SaaS systems or production/staging targets. GitHub, GitLab, Jenkins, Jira, live LLM, Katalon, JMeter, PostgreSQL/MySQL, and the Playwright recorder depend on credentials/binaries/environment that cannot be safely fabricated in a project self-test. Their adapters fail closed with explicit configuration errors when unavailable.
