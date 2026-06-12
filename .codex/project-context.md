# Local AI Coding Facility - Project Context

Last updated: 2026-06-12

## Purpose

This repository is a Docker Compose deployment for shared local AI
infrastructure used by software-development agents.

The facility owns:

- Ollama inference and model storage.
- llama.cpp coding inference with GGUF models.
- Optional dedicated llama.cpp GGUF embeddings.
- Optional Qdrant vector storage and curated-document RAG MCP service.
- Model initialization, diagnostics, and GPU/runtime helpers.

Each project dev container continues to own:

- Source code, project dependencies, compilers, tests, and developer tools.
- OpenCode installation and project-specific OpenCode configuration.
- Project instructions such as `AGENTS.md`.
- Tool and MCP permissions.

Do not move OpenCode or project logic into this central facility by default.

## Workspace Boundary

This project lives at `/opt/project`. Treat `/opt/project` as the project root.

Do not run validation that could start services, build images, pull models,
consume the GPU, change host Docker state, or disrupt the containing workspace
unless the user explicitly approves it. Static, isolated checks inside this
directory are acceptable.

## Current State

The initial implementation and the GGUF embeddings extension are complete as a
scaffold. The repository contains:

- Base Compose deployment with Ollama.
- CPU, NVIDIA, AMD/ROCm, RAG, GGUF-embedding, and dev overrides.
- Optional llama.cpp coding server.
- Optional dedicated llama.cpp embedding server.
- Optional Qdrant and Python RAG MCP service.
- Idempotent Ollama model-init container.
- Host and container diagnostics scripts.
- Equivalent Bash and Windows PowerShell operator scripts.
- Example OpenCode provider configuration.
- Model profile examples and operating documentation.
- Infrastructure-development dev container.

Static checks performed on 2026-06-12:

- Bash syntax passed for scripts and entrypoints.
- Python source, JSON, TOML, and YAML parsing passed.
- Focused collection-identity, stale-point cleanup, collection-pattern, and
  context-budget unit tests pass.
- ShellCheck does not currently pass. It reports sourced-file notices and
  `SC2154` warnings for arrays initialized in `scripts/linux/common.sh`.
- Bash operator scripts and container entrypoints are tracked as executable.

Docker CLI and Compose v2.40.3 are available in the current dev container.
Static `docker compose config` validation was declined during the latest audit
and has not been run. Generated stack-state files and persistent Ollama/Qdrant
data show that operator scripts and services have been used previously, but
current running services, built images, endpoints, GPU behavior, and end-to-end
runtime behavior were not inspected.

PowerShell is unavailable in the current dev container, so `.ps1`
parser/execution validation has not been run here. A generated PowerShell
stack-state file is present, indicating the PowerShell wrapper has been used in
another environment.

## Architecture

```text
Project dev container / OpenCode
  |-- inference --------------------> Ollama coding model
  |-- inference with RAG context ---> llama.cpp coding GGUF
  `-- MCP --------------------------> rag-mcp
                                        |-- embeddings --> Ollama
                                        |-- embeddings --> llama.cpp embedding GGUF
                                        `-- vectors ----> Qdrant
```

RAG is independent of the final inference backend. `rag-mcp` retrieves text and
returns it to the project client; the client can include that text in a prompt
sent to either Ollama or llama.cpp.

The coding llama.cpp server and embedding llama.cpp server are separate
services because they use different models, flags, lifecycle, and resource
profiles.

All published service ports bind to `127.0.0.1` by default.

## Compose Topology

Primary entrypoint:

- `docker-compose.yml`: Ollama plus optional profile-based services.

Overrides:

- `docker-compose.cpu.yml`: CPU llama.cpp settings.
- `docker-compose.nvidia.yml`: configurable NVIDIA GPU reservations and CUDA
  llama.cpp image.
- `docker-compose.amd.yml`: Ollama ROCm image and AMD device exposure.
- `docker-compose.rag.yml`: Qdrant and `rag-mcp`.
- `docker-compose.embeddings-gguf.yml`: points RAG at llama.cpp embeddings.
- `docker-compose.dev.yml`: repository-development container.

Profiles:

- `llama`: coding llama.cpp server.
- `embeddings-gguf`: dedicated llama.cpp embedding server.
- `init`: one-shot Ollama model initialization.
- `diagnostics`: endpoint and GPU diagnostics.
- `dev`: repository-development container.

Wrapper behavior:

- `./scripts/linux/up.sh <cpu|nvidia|amd> [features...]`
- `.\scripts\windows\up.ps1 <cpu|nvidia|amd> [features...]`
- Features are `llama`, `rag`, `gguf-embeddings`, `diagnostics`, and `dev`.
- `gguf-embeddings` requires `rag`.
- Feature order is intentionally normalized so the GGUF embedding override is
  applied after the RAG override.
- `./scripts/linux/down.sh` uses `.local-ai-stack` generated by `up.sh`.
- `.\scripts\windows\down.ps1` uses `.local-ai-stack.ps.json` generated by
  `up.ps1`.
- Use the matching `down` wrapper because Bash and PowerShell maintain separate
  stack-state files.

Examples:

```bash
./scripts/linux/up.sh cpu
./scripts/linux/up.sh nvidia llama
./scripts/linux/up.sh nvidia rag
./scripts/linux/up.sh nvidia rag gguf-embeddings
./scripts/linux/down.sh
```

Windows PowerShell equivalents:

```powershell
.\scripts\windows\up.ps1 cpu
.\scripts\windows\up.ps1 nvidia llama
.\scripts\windows\up.ps1 nvidia rag
.\scripts\windows\up.ps1 nvidia rag gguf-embeddings
.\scripts\windows\down.ps1
```

## Services

### Ollama

- Always present in the base Compose deployment.
- Host endpoint: `http://127.0.0.1:11434/v1`
- Network endpoint: `http://ollama:11434/v1`
- Persistent data: `${DATA_ROOT}/ollama`
- Default coding model: `devstral:24b`
- Default Ollama embedding model: `qwen3-embedding:0.6b`

### llama.cpp Coding Server

- Service: `llama-cpp`
- Profile: `llama`
- Host endpoint: `http://127.0.0.1:8080/v1`
- Network endpoint: `http://llama-cpp:8080/v1`
- Loads a read-only GGUF from `${MODEL_ROOT}`.
- Entrypoint: `images/llama-cpp/entrypoint.sh`
- Parameters include context, GPU layers, threads, batch sizes, KV-cache types,
  parallel slots, and continuous batching.

### llama.cpp Embedding Server

- Service: `llama-cpp-embeddings`
- Profile: `embeddings-gguf`
- Host endpoint: `http://127.0.0.1:8081/v1`
- Network endpoint: `http://llama-cpp-embeddings:8080/v1`
- Entrypoint: `images/llama-cpp/embedding-entrypoint.sh`
- Runs `llama-server --embedding` with configurable pooling.
- Can use a local GGUF path or `LLAMA_CPP_EMBED_HF_REPO`.
- Persistent llama.cpp download cache: `${DATA_ROOT}/llama-cpp-cache`

### RAG MCP

- Service: `rag-mcp`
- Endpoint: `http://127.0.0.1:8765/mcp`
- Implementation: `images/rag-mcp/src/rag_mcp/server.py`
- Embedding backends: `ollama` or `llama-cpp`.
- Collection-specific include/exclude patterns load from YAML with built-in
  fallbacks.
- Search results respect an approximate total context-token budget.
- Qdrant collection vector size is detected from the embedding response.
- Stored points include embedding backend and model identity.
- Each collection stores a reserved identity marker and rejects a different
  backend or model identity.
- Searches filter by backend and model to avoid mixing incompatible vectors.
- A collection rejects a changed vector dimension with a clear error.

MCP tools:

- `index_project_docs`
- `search_project_memory`
- `list_collections`
- `delete_project_index`

RAG indexes curated project memory only:

- `README*`
- `docs/**`
- `adr/**`
- `architecture/**`
- `AGENTS.md`
- `CHANGELOG*`
- `CONTRIBUTING*`

It intentionally does not recursively index source code.

## GGUF Embedding Models

Recommended 16 GB workstation default:

```dotenv
LLAMA_CPP_EMBED_MODEL_PATH=
LLAMA_CPP_EMBED_HF_REPO=Qwen/Qwen3-Embedding-0.6B-GGUF:Q8_0
LLAMA_CPP_EMBED_MODEL_ID=qwen3-embedding-0.6b-q8_0
LLAMA_CPP_EMBED_POOLING=last
QDRANT_COLLECTION=project_memory_qwen3
```

Documented options:

- Qwen3 Embedding 0.6B GGUF: recommended default, multilingual/code retrieval,
  `last` pooling, 1024 dimensions.
- Qwen3 Embedding 4B and 8B GGUF: stronger but heavier options for larger
  hardware.
- EmbeddingGemma 300M GGUF: small resource-efficient option, model-default
  pooling, 768 dimensions.
- Nomic Embed Text v1.5 GGUF: English-focused, `mean` pooling, requires
  `search_document: ` and `search_query: ` prefixes.
- BGE-M3 community GGUF conversions: multilingual long-document option;
  conversion provenance and pooling must be verified.

Do not assume a general coding/chat GGUF produces useful embeddings. Use a
dedicated embedding model. Changing embedding models requires a new Qdrant
collection or a rebuilt index, even if vector dimensions happen to match.

Model examples live in `config/llama-cpp/embedding-models.example.yaml`.
Detailed guidance lives in `docs/embedding-models.md`.

## Important Configuration

Copy `.env.example` to `.env` when deploying. Major groups:

- General paths and ports.
- Runtime backend and image selections.
- Ollama model and runtime settings.
- llama.cpp coding server settings.
- llama.cpp embedding server settings.
- RAG embedding backend, prefixes, collection, and chunking settings.

Default mode is CPU-safe:

```dotenv
GPU_BACKEND=cpu
EMBEDDING_BACKEND=ollama
```

To use GGUF embeddings, the wrapper adds the required Compose override:

```bash
./scripts/linux/up.sh nvidia rag gguf-embeddings
```

## Repository Map

```text
.codex/project-context.md             This future-agent handoff
.devcontainer/devcontainer.json       Infrastructure development container
.env.example                          Deployment parameters
docker-compose.yml                    Base deployment
docker-compose.*.yml                  Runtime and feature overrides
config/                               Example model/RAG/OpenCode configuration
images/dev/                           Development image
images/llama-cpp/                     Coding and embedding llama.cpp wrappers
images/model-init/                    Ollama model pull/init image
images/diagnostics/                   Endpoint diagnostics image
images/rag-mcp/                       Python MCP retrieval service
scripts/linux/                        Linux/macOS Bash operator commands
scripts/windows/                      Windows PowerShell operator commands
docs/                                 Architecture and operating documentation
models/                               Local GGUF mount, ignored except .gitkeep
workspaces/                            Read-only project mounts for RAG
```

## Security And Boundaries

- Ports are loopback-only by default.
- Models and persistent service data are mounted, not baked into images.
- Project workspaces are mounted read-only into RAG.
- No arbitrary project directories are mounted into inference services.
- OpenCode remains project-local with project-specific permissions.
- Review OpenCode and MCP configuration before using untrusted repositories.
- Add authentication and transport security before any remote exposure.

## Known Gaps And Risks

- Docker Compose merge/configuration has not been validated in this audit.
- Current images, services, endpoints, and GPU behavior have not been inspected.
- PowerShell scripts have not been parser-validated or executed because
  PowerShell is unavailable in the current dev container.
- `make lint` currently fails ShellCheck because sourced-file relationships are
  not declared and `up.sh` arrays initialized by `common.sh` trigger `SC2154`.
- llama.cpp upstream images and flags use moving tags and should eventually be
  pinned after runtime testing.
- Ollama, Qdrant, and other official images currently use moving tags.
- AMD support only covers Ollama ROCm; llama.cpp ROCm is not implemented.
- The AMD `/dev/kfd` and `/dev/dri` path is intended for native Linux and
  generally does not work through Docker Desktop on Windows.
- The RAG MCP implementation is intentionally minimal and currently has focused
  unit coverage for collection identity, stale-point cleanup, collection-pattern,
  and context-budget policies.
- RAG currently depends on the base Ollama service even when GGUF embeddings
  are selected, because Ollama is always part of the base deployment.
- The example OpenCode provider uses model IDs `code-fast` and `code-strong`,
  which do not match the default served model IDs.
- OpenCode MCP configuration for `rag-mcp` is documented conceptually but is
  not included in the provider snippet yet.

## Next Sensible Work

With explicit approval for Docker/runtime validation:

1. Run `docker compose config` for CPU, NVIDIA, AMD, RAG, and GGUF embedding
   combinations.
2. Reconcile the remaining documented behavior and configuration gaps listed
   under Known Gaps And Risks.
3. Pin tested image versions or digests.
4. Validate llama.cpp coding and embedding server entrypoint flags against the
   pinned image.
5. Exercise Ollama and llama.cpp `/v1/embeddings` through `rag-mcp`.
6. Add focused tests for embedding response parsing, dimension mismatch, path
   confinement, curated-file selection, and backend/model filtering.
7. Add an example OpenCode MCP configuration for `rag-mcp`.

Do not perform runtime steps without explicit user approval.

## Documentation

Use these files as the source of truth for operator guidance:

- `README.md`
- `docs/architecture.md`
- `docs/embedding-models.md`
- `docs/model-profiles.md`
- `docs/gpu-profiles.md`
- `docs/opencode-integration.md`
- `docs/troubleshooting.md`
- `docs/windows-hosts.md`

The central architectural rule remains:

```text
Shared facility:
  inference, embeddings, optional retrieval, model storage, GPU usage

Per-project dev container:
  OpenCode, source code, project tools, tests, permissions, instructions
```
