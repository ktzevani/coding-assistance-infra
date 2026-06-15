# TODO

This document tracks notable follow-up work that is not required for the current
trusted, local-first scaffold but should be addressed before broader or
multi-user deployment.

## MCP Server

The current `rag-mcp` implementation is intentionally minimal and suitable for
trusted local development. The following items are the highest-priority MCP
server improvements, ordered roughly by security and operational impact.

### 1. Add Authentication And Per-Project Authorization

Require MCP clients to authenticate before they can invoke tools. Authorization
must be evaluated separately from authentication so each client can be limited
to specific projects, collections, and operations.

Suggested direction:

- Support bearer tokens or another mechanism compatible with remote MCP clients.
- Define permissions for read/search, indexing, deletion, and collection
  administration separately.
- Reject unscoped searches when a client is only authorized for specific
  projects.
- Keep credentials outside images and committed configuration, using Docker
  secrets or another deployment-appropriate secret store.
- Document token rotation and revocation.

Acceptance criteria:

- Unauthenticated requests cannot list, search, index, or delete data.
- A client authorized for one project cannot read or modify another project's
  points, even when it supplies another project or collection name directly.
- Authentication and authorization behavior has focused automated tests.

### 2. Protect Destructive Operations

Treat `delete_project_index` and any future collection-level mutation as
sensitive operations. OpenCode's example configuration already asks for user
approval before invoking `rag-mcp_delete_project_index`, but server-side controls
are still needed because not every MCP client enforces client-side permissions.

Suggested direction:

- Require an authorization scope dedicated to destructive operations.
- Consider a confirmation token, dry-run mode, or two-step delete workflow for
  high-impact operations.
- Add MCP tool annotations indicating destructive or non-idempotent behavior when
  supported by the selected SDK and clients.
- Return the number of affected points and enough identity information for an
  operator to verify the intended target.
- Log all destructive requests and outcomes.

Acceptance criteria:

- Search-only or indexing-only clients cannot delete data.
- Destructive calls are auditable and clearly identify their target and effect.
- Tests cover authorized deletion, rejected deletion, and attempts to delete
  another project's index.

### 3. Validate Streamable HTTP Origins And Harden Transport Security

The service currently relies on Compose publishing the MCP port to loopback.
Before exposing the endpoint beyond the trusted local machine, enforce the MCP
Streamable HTTP security requirements and add transport protection.

Suggested direction:

- Validate the HTTP `Origin` header to prevent DNS rebinding attacks.
- Keep loopback-only publishing as the default deployment.
- Add TLS through a trusted reverse proxy before any remote exposure.
- Combine remote exposure with authentication; TLS alone is insufficient.
- Define explicit trusted proxy and forwarded-header behavior.
- Verify protocol-version and session handling against the pinned MCP SDK.

Acceptance criteria:

- Requests from untrusted origins are rejected.
- The documented local configuration remains usable from approved project dev
  containers.
- Any documented remote configuration requires authenticated TLS and has an
  end-to-end MCP Inspector test.

### 4. Add Rate Limits And Input-Size Limits

Prevent accidental or hostile requests from exhausting embedding, Qdrant, CPU,
memory, or disk resources. Full-project indexing is substantially more expensive
than searching and should have separate controls.

Suggested direction:

- Apply per-client and global request-rate limits.
- Limit query length, `top_k`, collection-name length, project-name length,
  indexed file size, total indexed bytes, chunk count, and embedding batch size.
- Set explicit timeouts for filesystem traversal, embedding calls, and Qdrant
  operations.
- Reject unsupported or excessive values with clear tool execution errors.
- Make limits configurable with conservative defaults and document their resource
  implications.

Acceptance criteria:

- Excessive requests fail predictably without destabilizing the service.
- The server cannot be instructed to return an unbounded number of results or
  index unbounded content in one call.
- Boundary and rate-limit behavior has automated tests.

### 5. Add Per-Project Indexing Locks And Concurrency Controls

Concurrent indexing of the same project and collection can race while upserting
current points and deleting stale points. Coordinate mutations so a failed or
concurrent indexing operation cannot leave a partially replaced project index.

Suggested direction:

- Serialize indexing and deletion for each `(collection, project)` pair.
- Decide whether concurrent requests should wait, fail fast, or return the
  status of an existing indexing job.
- Limit global indexing concurrency to protect the embedding backend and Qdrant.
- Consider staging/versioning points and switching to a completed index only
  after all embeddings and upserts succeed.
- Support cancellation and clean recovery after interrupted jobs.

Acceptance criteria:

- Two concurrent indexing calls for the same project cannot corrupt or
  partially delete each other's results.
- Indexing different projects can proceed within configured concurrency limits.
- Interrupted indexing preserves the last complete usable project index.

### 6. Add Structured Errors, Audit Logging, And Observability

Improve diagnosis and accountability without exposing secrets or excessive
internal details to agents. The server should distinguish expected tool failures
from unexpected server errors and make expensive or destructive activity easy to
trace.

Suggested direction:

- Return structured MCP tool execution errors for validation, authorization,
  embedding, collection-identity, Qdrant, and timeout failures.
- Sanitize client-visible errors while retaining detailed server-side logs.
- Add request IDs and structured logs for tool name, authenticated client,
  project, collection, duration, result counts, and outcome.
- Add health and readiness checks for the MCP server, embedding backend, and
  Qdrant.
- Export useful metrics such as request latency, failures, indexed chunks,
  search result counts, and active indexing jobs.
- Define retention and privacy rules because logs may contain project names or
  query text.

Acceptance criteria:

- Operators can determine who invoked a tool, what target it affected, and
  whether it succeeded without inspecting raw container output manually.
- Clients receive actionable but sanitized errors.
- Health checks and key failure paths are covered by automated tests.
