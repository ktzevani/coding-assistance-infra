# Agent Instructions

## Project Purpose

This repository provides shared, local-first AI infrastructure through Docker
Compose. The facility owns inference, embeddings, optional retrieval, model
storage, and GPU runtime access. Each project dev container owns its source,
dependencies, tools, tests, OpenCode configuration, permissions, and project
instructions.

Do not move project-specific logic or OpenCode into this facility by default.

## Safety Boundaries

- Treat `/opt/project` as the repository root.
- Do not start services, build images, pull models, consume the GPU, change host
  Docker state, or run disruptive runtime validation without explicit user
  approval.
- Static, isolated checks inside the repository are allowed.
- Preserve loopback-only published ports. Do not expose services remotely
  without authentication and transport security.
- Keep project workspaces read-only in RAG and do not mount project source into
  inference services.
- The development container's Docker socket is disabled by default. Do not
  enable it unless explicitly requested for a trusted agent and repository.
- `seccomp=unconfined` is limited to the development service for nested
  Bubblewrap support. Do not extend it to facility services or treat it as a
  boundary for untrusted workloads.
- Preserve user changes in a dirty worktree and do not revert unrelated edits.

## Architecture Invariants

- Ollama is the always-present base inference service.
- Coding llama.cpp is an optional routing-mode service whose client-visible
  profiles live in `config/llama-cpp/models.ini`. Embedding llama.cpp is a
  separate optional single-model service with different flags and lifecycle.
- RAG is independent of final inference: `rag-mcp` retrieves curated text and the
  project client decides whether to include it in an Ollama or llama.cpp prompt.
- RAG indexes curated documentation and durable project memory, not source trees
  by default.
- Starting RAG does not index projects automatically. Projects must be visible
  beneath the host `RAG_WORKSPACE_ROOT` mount and indexed through
  `index_project_docs`; the service sees that mount as `WORKSPACE_ROOT` at
  `/workspaces`.
- A Qdrant collection belongs to one embedding backend, model identity, and
  vector dimension. Changing embedding models requires a new collection or a
  rebuilt index.
- Keep OpenCode installation, MCP configuration, and tool permissions
  project-local.

## Implementation Guidance

- Follow existing Compose overrides, wrapper scripts, and local configuration
  patterns before adding new abstractions.
- Keep changes scoped to the owning service or document.
- Use dedicated embedding models; do not assume a coding/chat model produces
  useful embeddings.
- Treat `delete_project_index` and future destructive MCP operations as
  approval-sensitive.
- Maintain equivalent Bash and PowerShell operator behavior when changing shared
  workflows, while noting that PowerShell may not be available locally.

## Validation

Safe static checks include:

- `make test`
- `make lint`
- Focused syntax, parsing, or unit checks that do not invoke Docker services

Require explicit user approval before running:

- `make config` or `docker compose config`
- `./scripts/linux/up.sh ...` or Windows equivalents
- `./scripts/linux/pull-models.sh` or Windows equivalents
- `./scripts/linux/smoke-test.sh` or Windows equivalents
- Any Docker command that builds, starts, stops, or changes services
- Any validation that downloads models, consumes GPUs, or changes persistent
  service data

The smoke test is permissive: unavailable optional services print `SKIP`, and it
does not verify MCP discovery, indexing, retrieval quality, or agent tool use.

## Canonical Documentation

Read the relevant source before changing behavior:

- `README.md`: setup, operations, project onboarding, and verification workflows
- `docs/architecture.md`: architecture and ownership boundaries
- `docs/TODO.md`: planned work and hardening priorities
- `docs/embedding-models.md`: embedding choices, pooling, prefixes, and identity
- `docs/model-profiles.md`: model sizing and resource guidance
- `docs/gpu-profiles.md`: CPU, NVIDIA, and AMD behavior
- `docs/opencode-integration.md`: project-local OpenCode and network integration
- `docs/troubleshooting.md`: operational diagnosis
- `docs/windows-hosts.md`: Windows and Docker Desktop behavior
