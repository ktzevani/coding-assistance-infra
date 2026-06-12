# Architecture

The facility owns shared inference, embeddings, model storage, GPU runtime
access, and optional retrieval. A project dev container owns OpenCode, source,
toolchains, tests, project instructions, and permissions.

The base Compose file starts Ollama. Runtime-specific override files add CPU,
NVIDIA, or AMD behavior without duplicating the services. llama.cpp is an
explicit profile because it cannot start until a GGUF is mounted. RAG is a
separate override because inference must remain useful when retrieval is down.

Retrieval follows this order:

1. Project tools: grep, glob, read, compiler, tests, linters, and type checkers.
2. Project instructions and documentation.
3. Optional project-local LSP.
4. Narrow RAG over curated documentation and durable memory.
5. A future symbol or dependency graph, if justified.

The MCP service accepts only project names that resolve beneath `/workspaces`.
Its default patterns include README, docs, ADRs, architecture notes, AGENTS,
changelogs, and contribution guides. It does not recursively index source code.

All host ports bind to loopback. Add authentication and transport security
before adapting this design for remote access.

