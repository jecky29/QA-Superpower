# QA Superpower V4 Security Notes

## Threat boundary

QA Superpower is an execution platform. Browser automation, load/API tests, database validation, Git operations and mobile automation can reach systems that ordinary dashboard software cannot. Deploy it as privileged QA infrastructure, not as a public anonymous website.

## Mandatory production actions

1. Replace the default admin password, `QA_MASTER_KEY`, and worker token before first shared deployment.
2. Terminate TLS at a trusted reverse proxy/ingress and expose only the public control-plane routes to users.
3. Restrict worker internal API access with network policy/firewall rules in addition to `QA_WORKER_TOKEN`.
4. Keep `ENABLE_REMOTE_TARGETS=false` unless remote QA/staging hosts are explicitly needed. When enabled, set `ALLOWED_TARGET_HOSTS`.
5. Keep third-party tokens in the encrypted secret vault or an external secret manager; never commit them to `.env` or Kubernetes YAML.
6. Set a dedicated `QA_MOCK_KEY` if mock endpoints are reachable outside an isolated QA network.
7. Keep the SQLite control plane at one replica.
8. Restrict filesystem permissions on `QA_DATA_DIR`, `QA_ARTIFACT_DIR`, and `QA_GIT_DIR`.
9. Rotate OIDC/LDAP/Git/Jira/Xray/Zephyr/CI credentials according to organizational policy.
10. Treat generated reports/screenshots/logs as potentially sensitive QA artifacts and apply retention controls outside this prototype.

## Authentication

Local passwords are salted and hashed by the auth service. OIDC supports PKCE, state, nonce and JWKS verification. LDAP search filters escape user input before substitution. External identities are provisioned into local RBAC roles.

## WebSockets

WebSocket connections use short-lived single-use tickets acquired through the authenticated REST API. Normal bearer session tokens are not placed in WebSocket URLs by default. Legacy query-token WebSockets require explicitly setting `ALLOW_WS_TOKEN_QUERY=true` and should not be enabled in production.

## Worker authentication

Workers use a service token separate from user sessions. In larger deployments add mTLS/service-mesh identity and rotate the worker token. Do not expose `/api/internal/*` through a public ingress if it can be avoided.

## Target SSRF protection

HTTP/browser/Appium runners use target validation. Public remote hosts are blocked by default; when remote mode is enabled, a non-empty hostname allowlist is strongly recommended. Integration adapters separately restrict Jira/custom integration hosts.

DNS rebinding and egress-layer controls are better enforced at the network layer as well; use Kubernetes NetworkPolicy, service mesh policy, cloud firewalls or egress proxies for high-assurance deployments.

## Secret handling

Vault values are encrypted using AES-256-GCM and are not returned by secret-list APIs. The application master key must be supplied out-of-band. Encryption at application level does not replace host/disk encryption or external secret-management systems.

## AI guardrails

The autonomous regression agent is a planner. It may create only allowlisted QA job types and defaults to human approval. Arbitrary shell execution, credential extraction and destructive database actions are outside its action set. Performance plans are capped to reduce accidental abusive load.

Visual screenshots and requirement text may be sent to the configured LLM provider when AI features are enabled. Apply your organization's data-handling policy before enabling those calls.

## Known V4 boundaries

- Controller metadata is SQLite, so controller HA is intentionally not supported yet.
- Artifact storage is filesystem based; Kubernetes scale-out assumes RWX storage.
- Built-in accessibility checks are not a certification suite.
- OpenAPI contract validation implements a practical subset, not every JSON Schema/OpenAPI keyword.
- Appium drivers/device lifecycle are managed by your Appium infrastructure, not by QA Superpower.
- LDAP certificate policy is configurable; keep verification enabled for real LDAPS deployments.
