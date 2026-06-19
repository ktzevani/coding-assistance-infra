# Architecture

The facility owns shared inference, embeddings, model storage, GPU runtime
access, and optional retrieval. A project dev container owns OpenCode, source,
toolchains, tests, project instructions, and permissions.

The base Compose file starts Ollama. Runtime-specific override files add CPU,
NVIDIA, or AMD behavior without duplicating the services. The optional coding
llama.cpp service runs in routing mode and loads named profiles from
`config/llama-cpp/models.ini`; clients choose a profile through the OpenAI
`model` field. The separate embedding llama.cpp service loads one dedicated
embedding GGUF with embedding-specific flags. RAG is a separate override
because inference must remain useful when retrieval is down.

The router defaults to one loaded coding profile at a time and autoloads a
requested profile. Multiple profile names can share the same GGUF while varying
context, output limits, cache types, batching, sampling, or other server
parameters. The model directory and preset file are mounted read-only into the
coding service.

The Bash and PowerShell wrappers assemble the selected backend, overrides, and
profiles for operators. When GGUF embeddings are requested, they normalize
feature ordering so `docker-compose.embeddings-gguf.yml` is applied after
`docker-compose.rag.yml` and its embedding-backend selection wins. Each wrapper
records its own stack state, so operators must use the matching wrapper to stop
the stack.

RAG does not live inside an inference model. The MCP service embeds documents
and queries through either Ollama or `llama-cpp-embeddings`, stores and searches
vectors in Qdrant, then returns relevant text to the project client. OpenCode
can place that text into a prompt sent to either the Ollama coding model or the
llama.cpp coding model.

Retrieval follows this order:

1. Project tools: grep, glob, read, compiler, tests, linters, and type checkers.
2. Project instructions and documentation.
3. Optional project-local LSP.
4. Narrow RAG over curated documentation and durable memory.
5. A future symbol or dependency graph, if justified.

The MCP service accepts only project names that resolve beneath `/workspaces`.
Its collection-specific patterns are loaded from the configured RAG collections
YAML, falling back to built-in defaults for README, docs, ADRs, architecture
notes, AGENTS, changelogs, and contribution guides. It does not recursively
index source code.

Search retrieval applies `RAG_MAX_CONTEXT_TOKENS` as an approximate total
content budget, truncating the final result when necessary.

Each Qdrant collection stores a reserved identity marker and permits only one
embedding backend, model identity, and vector dimension. Changing embedding
models requires a new collection or a rebuilt index.

All host ports bind to loopback. Add authentication and transport security
before adapting this design for remote access.
