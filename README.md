# Local AI Coding Facility

A Docker Compose deployment for shared, local coding-agent infrastructure.
It runs inference, embeddings, and optional curated-document retrieval while
keeping OpenCode, source code, compilers, tests, and permissions inside each
project's own dev container.

```mermaid
flowchart LR
  P[Project dev containers<br/>OpenCode + tools] -->|inference| O[Ollama<br/>fast model]
  P -->|inference with retrieved context| L[llama.cpp<br/>strong GGUF profile]
  P -->|MCP| R[RAG MCP]
  R -->|choose embedding backend| OE[Ollama embeddings]
  R -->|choose embedding backend| GE[llama.cpp<br/>embedding GGUF]
  R <--> Q[Qdrant]
  R -.->|retrieved context returned to client| P
  O --> D[(data/ollama)]
  L --> M[(models/*.gguf)]
  GE --> M
  Q --> V[(data/qdrant)]
```

All published ports bind to `127.0.0.1`. Nothing is exposed to the LAN by
default.

## Repository Layout

```text
.devcontainer/                 Infrastructure-development container
config/                        Model, RAG, and OpenCode examples
images/                        Thin custom service images
scripts/linux/                 Linux/macOS Bash operator commands
scripts/windows/               Windows PowerShell operator commands
docs/                          Architecture and operating guidance
docker-compose.yml             Base Ollama deployment and optional services
docker-compose.{cpu,nvidia,amd,rag,embeddings-gguf,dev}.yml
```

## Prerequisites

- Docker Engine or Docker Desktop with Compose v2
- `curl` for Bash host-side smoke tests; PowerShell uses `Invoke-WebRequest`
- Enough disk space for selected models
- NVIDIA Container Toolkit for NVIDIA mode
- `/dev/kfd` and `/dev/dri` access for AMD mode

For NVIDIA, verify the host runtime first:

```bash
./scripts/linux/inspect-gpu.sh nvidia
```

GPU access is granted at container runtime by Compose. Dockerfiles only select
GPU-capable software.

## Quick Start

The baseline starts Ollama and is CPU-safe:

```bash
cp .env.example .env
./scripts/linux/up.sh cpu
./scripts/linux/pull-models.sh
./scripts/linux/smoke-test.sh
./scripts/linux/print-endpoints.sh
```

Windows PowerShell:

```powershell
Copy-Item .env.example .env
.\scripts\windows\up.ps1 cpu
.\scripts\windows\pull-models.ps1
.\scripts\windows\smoke-test.ps1
.\scripts\windows\print-endpoints.ps1
```

Use NVIDIA or AMD acceleration:

```bash
./scripts/linux/up.sh nvidia
./scripts/linux/up.sh amd
```

```powershell
.\scripts\windows\up.ps1 nvidia
.\scripts\windows\up.ps1 amd
```

Model pulls can be large. Change `FAST_MODEL_OLLAMA` in `.env` to a smaller
model before `pull-models.sh` when validating on CPU or limited hardware.

## llama.cpp

Place a GGUF file in `./models`, set its container path in `.env`, then enable
the optional service:

```dotenv
LLAMA_CPP_MODEL_PATH=/models/my-coding-model.gguf
```

```bash
./scripts/linux/up.sh nvidia llama
```

```powershell
.\scripts\windows\up.ps1 nvidia llama
```

The CPU profile uses the official `server` image and NVIDIA uses
`server-cuda`. Context, threads, batching, KV-cache types, parallel slots, and
GPU layers are all environment-controlled.

## Optional RAG

RAG indexes only curated project memory, not source trees by default. Mount
project directories beneath `./workspaces`, start the stack, then connect an
MCP client to `http://127.0.0.1:8765/mcp`.

```bash
./scripts/linux/up.sh nvidia rag
```

```powershell
.\scripts\windows\up.ps1 nvidia rag
```

The command above uses Ollama embeddings. To run the full retrieval embedding
path with an embedding-capable GGUF served by llama.cpp:

```bash
./scripts/linux/up.sh nvidia rag gguf-embeddings
```

```powershell
.\scripts\windows\up.ps1 nvidia rag gguf-embeddings
```

Use a local model:

```dotenv
LLAMA_CPP_EMBED_MODEL_PATH=/models/qwen3-embedding-0.6b-q8_0.gguf
LLAMA_CPP_EMBED_HF_REPO=
LLAMA_CPP_EMBED_POOLING=last
```

Or let llama.cpp fetch a Hugging Face GGUF into the persistent HF cache:

```dotenv
LLAMA_CPP_EMBED_MODEL_PATH=
LLAMA_CPP_EMBED_HF_REPO=Qwen/Qwen3-Embedding-0.6B-GGUF:Q8_0
LLAMA_CPP_EMBED_POOLING=last
```

Available MCP tools:

- `index_project_docs`
- `search_project_memory`
- `list_collections`
- `delete_project_index`

The RAG service detects vector size from the embedding response. A collection
cannot mix dimensions or embedding models; use a new collection or rebuild it
when changing models. See [docs/embedding-models.md](docs/embedding-models.md)
and [docs/architecture.md](docs/architecture.md).

## Endpoints

| Service | Host / project dev container | Same Compose network |
|---|---|---|
| Ollama | `http://host.docker.internal:11434/v1` | `http://ollama:11434/v1` |
| llama.cpp | `http://host.docker.internal:8080/v1` | `http://llama-cpp:8080/v1` |
| llama.cpp embeddings | `http://host.docker.internal:8081/v1` | `http://llama-cpp-embeddings:8080/v1` |
| Qdrant | `http://host.docker.internal:6333` | `http://qdrant:6333` |
| RAG MCP | `http://host.docker.internal:8765/mcp` | `http://rag-mcp:8765/mcp` |

On the host, replace `host.docker.internal` with `127.0.0.1`. Linux project
dev containers should add:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

## OpenCode Integration

OpenCode remains project-local. Start from
[`config/opencode/provider-snippet.example.jsonc`](config/opencode/provider-snippet.example.jsonc)
inside each trusted project and review its permissions before use. See
[docs/opencode-integration.md](docs/opencode-integration.md).

## Model Tuning

The `.env` file is the active v1 profile layer. Example future-compatible YAML
profiles live under `config/ollama` and `config/llama-cpp`.

For a 16 GB GPU, begin with an 8k Ollama context and one request at a time.
Enable llama.cpp only after choosing a quantization and offload level that fits.
Higher context consumes substantial KV-cache memory. See
[docs/model-profiles.md](docs/model-profiles.md).

## Development Container

Open this repository with VS Code Dev Containers to get Docker CLI, Compose,
ShellCheck, Python, Ruff, YAML tooling, and the repository mounted at
`/opt/project`. The Docker socket is mounted so the dev container can manage
the host Compose stack.

## Operations

```bash
./scripts/linux/down.sh
./scripts/linux/down.sh --remove-orphans
make config
make lint
```

Windows PowerShell equivalents:

```powershell
.\scripts\windows\down.ps1
.\scripts\windows\down.ps1 --remove-orphans
.\scripts\windows\inspect-gpu.ps1 nvidia
```

The Bash and PowerShell `up` wrappers keep separate stack-state files, so use
the matching `down` wrapper for the stack you started. See
[docs/windows-hosts.md](docs/windows-hosts.md) for Windows host details.

Persistent state lives under `DATA_ROOT`; GGUF files live under `MODEL_ROOT`.
Do not commit either.

## Upgrade And Pinning

The examples use moving image tags for an easy first run. For repeatable
deployments, replace image tags in `.env` with tested version tags or digests,
then validate all Compose variants and smoke tests before upgrading. llama.cpp
flags can change, so validate `images/llama-cpp/entrypoint.sh` when changing its
base image.

## Troubleshooting

Start with:

```bash
docker compose ps
docker compose logs ollama
./scripts/linux/inspect-gpu.sh nvidia
./scripts/linux/smoke-test.sh
```

See [docs/troubleshooting.md](docs/troubleshooting.md) for common GPU, model,
network, and retrieval failures.
